import { MessageHttpClient } from '../network/clients/MessageHttpClient';
import { LocalDatabase } from '../database/LocalDatabase';
import { Message } from '../models/DataModels';
import { RandomUtil } from '@wondertek/wdkitlib';
import { AppLogger } from '../utils/AppLogger';

interface PendingMessage {
  roomId: string;
  content: Record<string, string | object>;
  txnId: string;
  resolve: (eventId: string) => void;
  reject: (error: Error) => void;
}

export interface IMessageManager {
  deleteMessage(roomId: string, eventId: string, reason?: string): Promise<void>;
  forwardMessage(roomId: string, content: Record<string, string | object>): Promise<string>;
  getMessages(roomId: string, limit?: number, beforeEventId?: string): Promise<Message[]>;
}

export class MessageManager implements IMessageManager {
  private logger = AppLogger.getLogger(MessageManager);
  private messageHttpClient: MessageHttpClient;
  private localDatabase: LocalDatabase;
  private offlineQueue: PendingMessage[] = [];

  constructor(
    localDatabase: LocalDatabase,
    messageHttpClient: MessageHttpClient
  ) {
    this.localDatabase = localDatabase;
    this.messageHttpClient = messageHttpClient;
  }

  async deleteMessage(roomId: string, eventId: string, reason?: string): Promise<void> {
    try {
      const txnId: string = this.generateTransactionId();
      await this.messageHttpClient.redactEvent(roomId, eventId, txnId, reason);
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      this.logger.error('Failed to delete message: ' + errMsg);
      throw new Error('Failed to delete message: ' + errMsg);
    }
  }

  async forwardMessage(roomId: string, content: Record<string, string | object>): Promise<string> {
    const txnId: string = this.generateTransactionId();
    try {
      return await this.messageHttpClient.sendEvent(roomId, 'm.room.message', txnId, content);
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      this.logger.error('Failed to forward message: ' + errMsg);
      throw new Error('Failed to forward message: ' + errMsg);
    }
  }

  async getMessages(roomId: string, limit: number = 50, beforeEventId?: string): Promise<Message[]> {
    return this.localDatabase.getMessages(roomId, limit, beforeEventId);
  }

  async getMessage(roomId: string, eventId: string): Promise<Message | null> {
    const messages: Message[] = await this.localDatabase.getMessages(roomId, 1);
    return messages.find((m: Message): boolean => m.eventId === eventId) || null;
  }

  private generateTransactionId(): string {
    return `m${Date.now()}${RandomUtil.generateUUIDRandom().replace(/-/g, '').substring(0, 7)}`;
  }

  queueOfflineMessage(roomId: string, content: Record<string, string | object>, resolve: (eventId: string) => void,
    reject: (error: Error) => void): void {
    const pending: PendingMessage = {
      roomId: roomId,
      content: content,
      txnId: this.generateTransactionId(),
      resolve: resolve,
      reject: reject
    };

    this.offlineQueue.push(pending);
  }

  async processOfflineQueue(): Promise<void> {
    if (this.offlineQueue.length === 0) {
      return;
    }

    this.logger.info(`Processing ${this.offlineQueue.length} offline messages`);

    const queue: PendingMessage[] = [];
    for (let i = 0; i < this.offlineQueue.length; i++) {
      queue.push(this.offlineQueue[i]);
    }
    this.offlineQueue = [];

    for (let i = 0; i < queue.length; i++) {
      const pending: PendingMessage = queue[i];
      try {
        const eventId: string = await this.messageHttpClient.sendEvent(
          pending.roomId,
          'm.room.message',
          pending.txnId,
          pending.content
        );
        pending.resolve(eventId);
      } catch (error) {
        const errMsg: string = error instanceof Error ? error.message : String(error);
        pending.reject(new Error(errMsg));
      }
    }
  }

  async retryFailedMessage(roomId: string, message: Message): Promise<string> {
    const txnId: string = this.generateTransactionId();
    return await this.messageHttpClient.sendEvent(roomId, message.type, txnId, message.content);
  }
}
