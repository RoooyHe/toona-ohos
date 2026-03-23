import { MatrixHttpClient } from '../network/MatrixHttpClient';
import { SendMessageResult, TextMessageContent } from '../models/MatrixTypes';
import { AuthManager } from './AuthManager';
import { LocalDatabase } from '../database/LocalDatabase';
import { Message, MessageStatus } from '../models/DataModels';

interface PendingMessage {
  roomId: string;
  content: Record<string, string | object>;
  txnId: string;
  resolve: (eventId: string) => void;
  reject: (error: Error) => void;
}

export class MessageManager {
  private static instance: MessageManager;
  private httpClient: MatrixHttpClient;
  private authManager: AuthManager;
  private localDatabase: LocalDatabase;
  
  private pendingMessages: Map<string, PendingMessage> = new Map();
  private offlineQueue: PendingMessage[] = [];

  private constructor() {
    this.authManager = AuthManager.getInstance();
    this.httpClient = this.authManager.getHttpClient();
    this.localDatabase = LocalDatabase.getInstance();
  }

  static getInstance(): MessageManager {
    if (!MessageManager.instance) {
      MessageManager.instance = new MessageManager();
    }
    return MessageManager.instance;
  }

  async sendTextMessage(roomId: string, text: string): Promise<string> {
    const content: TextMessageContent = {
      msgtype: 'm.text',
      body: text
    };

    return this.sendMessage(roomId, 'm.room.message', content);
  }

  async sendEmoteMessage(roomId: string, text: string): Promise<string> {
    const content: TextMessageContent = {
      msgtype: 'm.emote',
      body: text
    };

    return this.sendMessage(roomId, 'm.room.message', content);
  }

  async sendNoticeMessage(roomId: string, text: string): Promise<string> {
    const content: TextMessageContent = {
      msgtype: 'm.notice',
      body: text
    };

    return this.sendMessage(roomId, 'm.room.message', content);
  }

  async sendMessage(roomId: string, eventType: string, content: Record<string, string | object>): Promise<string> {
    const txnId = this.generateTransactionId();
    const encodedRoomId = encodeURIComponent(roomId);

    try {
      const response = await this.httpClient.put<SendMessageResult>(
        `/rooms/${encodedRoomId}/send/${eventType}/${txnId}`,
        content
      );

      return response.event_id;
    } catch (error) {
      console.error('Failed to send message:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to send message: ${errMsg}`);
    }
  }

  async sendReplyMessage(roomId: string, eventId: string, text: string): Promise<string> {
    const content = {
      'm.relates_to': {
        'm.in_reply_to': {
          'event_id': eventId
        }
      },
      'msgtype': 'm.text',
      'body': text
    };

    return this.sendMessage(roomId, 'm.room.message', content);
  }

  async editMessage(roomId: string, eventId: string, newText: string): Promise<string> {
    const content = {
      'msgtype': 'm.text',
      'body': newText,
      'm.new_content': {
        'msgtype': 'm.text',
        'body': newText
      },
      'm.relates_to': {
        'event_id': eventId,
        'rel_type': 'm.replace'
      }
    };

    const txnId = this.generateTransactionId();
    const encodedRoomId = encodeURIComponent(roomId);

    try {
      const response = await this.httpClient.put<SendMessageResult>(
        `/rooms/${encodedRoomId}/send/${'m.room.message'}/${txnId}`,
        content
      );

      return response.event_id;
    } catch (error) {
      console.error('Failed to edit message:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to edit message: ${errMsg}`);
    }
  }

  async deleteMessage(roomId: string, eventId: string, reason?: string): Promise<void> {
    const encodedRoomId = encodeURIComponent(roomId);
    const encodedEventId = encodeURIComponent(eventId);

    try {
      await this.httpClient.put(`/rooms/${encodedRoomId}/redact/${encodedEventId}`, {
        reason: reason
      });
    } catch (error) {
      console.error('Failed to delete message:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to delete message: ${errMsg}`);
    }
  }

  async getMessage(roomId: string, eventId: string): Promise<Message | null> {
    const messages = await this.localDatabase.getMessages(roomId, 1);
    return messages.find(m => m.eventId === eventId) || null;
  }

  private generateTransactionId(): string {
    return `m${Date.now()}${Math.random().toString(36).substring(2, 9)}`;
  }

  queueOfflineMessage(roomId: string, content: Record<string, string | object>, resolve: (eventId: string) => void, reject: (error: Error) => void): void {
    const pending: PendingMessage = {
      roomId,
      content,
      txnId: this.generateTransactionId(),
      resolve,
      reject
    };

    this.offlineQueue.push(pending);
  }

  async processOfflineQueue(): Promise<void> {
    if (this.offlineQueue.length === 0) {
      return;
    }

    console.info(`Processing ${this.offlineQueue.length} offline messages`);

    const queue = [...this.offlineQueue];
    this.offlineQueue = [];

    for (const pending of queue) {
      try {
        const eventId = await this.sendMessage(
          pending.roomId,
          'm.room.message',
          pending.content
        );
        pending.resolve(eventId);
      } catch (error) {
        pending.reject(error);
      }
    }
  }

  isOnline(): boolean {
    return this.authManager.isLoggedIn();
  }

  async retryFailedMessage(roomId: string, message: Message): Promise<string> {
    return this.sendMessage(roomId, message.type, message.content);
  }
}
