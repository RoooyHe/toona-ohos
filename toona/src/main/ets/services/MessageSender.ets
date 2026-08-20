import { MessageHttpClient } from '../network/clients/MessageHttpClient';
import { AppLogger } from '../utils/AppLogger';
import { RandomUtil } from '@wondertek/wdkitlib';

export interface ReplyQuoteData {
  eventId: string;
  sender: string;
  body: string;
}

export interface IMessageSender {
  sendText(roomId: string, text: string, replyQuote?: ReplyQuoteData | null): Promise<string>;
  sendSticker(roomId: string, url: string, body: string): Promise<string>;
  sendMedia(roomId: string, content: Record<string, string | object>): Promise<string>;
  editMessage(roomId: string, eventId: string, newText: string): Promise<string>;
}

export class MessageSender implements IMessageSender {
  private logger = AppLogger.getLogger(MessageSender);
  private messageHttpClient: MessageHttpClient;

  constructor(messageHttpClient: MessageHttpClient) {
    this.messageHttpClient = messageHttpClient;
  }

  async sendText(roomId: string, text: string, replyQuote?: ReplyQuoteData | null): Promise<string> {
    const content: Record<string, string | object> = {
      'msgtype': 'm.text',
      'body': text
    };

    if (replyQuote) {
      const inReplyTo: Record<string, string> = { 'event_id': replyQuote.eventId };
      const relatesTo: Record<string, object> = { 'm.in_reply_to': inReplyTo as object };
      content['m.relates_to'] = relatesTo as object;
      const reference: Record<string, string> = { 'event_id': replyQuote.eventId, 'sender': replyQuote.sender };
      content['m.reference'] = reference as object;
    }

    const txnId: string = this.generateTransactionId();
    try {
      return await this.messageHttpClient.sendEvent(roomId, 'm.room.message', txnId, content);
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      this.logger.error('Failed to send text message: ' + errMsg);
      throw new Error('Failed to send text message: ' + errMsg);
    }
  }

  async sendSticker(roomId: string, url: string, body: string): Promise<string> {
    const content: Record<string, string | object> = {
      'msgtype': 'm.sticker',
      'body': body,
      'url': url
    };

    const txnId: string = this.generateTransactionId();
    try {
      return await this.messageHttpClient.sendEvent(roomId, 'm.sticker', txnId, content);
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      this.logger.error('Failed to send sticker: ' + errMsg);
      throw new Error('Failed to send sticker: ' + errMsg);
    }
  }

  async sendMedia(roomId: string, content: Record<string, string | object>): Promise<string> {
    const txnId: string = this.generateTransactionId();
    try {
      return await this.messageHttpClient.sendEvent(roomId, 'm.room.message', txnId, content);
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      this.logger.error('Failed to send media message: ' + errMsg);
      throw new Error('Failed to send media message: ' + errMsg);
    }
  }

  async editMessage(roomId: string, eventId: string, newText: string): Promise<string> {
    const newContent: Record<string, string | object> = {
      'msgtype': 'm.text',
      'body': newText
    };
    const relatesTo: Record<string, string | object> = {
      'event_id': eventId,
      'rel_type': 'm.replace'
    };
    const content: Record<string, string | object> = {
      'msgtype': 'm.text',
      'body': newText,
      'm.new_content': newContent as object,
      'm.relates_to': relatesTo as object
    };

    const txnId: string = this.generateTransactionId();
    try {
      return await this.messageHttpClient.sendEvent(roomId, 'm.room.message', txnId, content);
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      this.logger.error('Failed to edit message: ' + errMsg);
      throw new Error('Failed to edit message: ' + errMsg);
    }
  }

  private generateTransactionId(): string {
    return `m${Date.now()}${RandomUtil.generateUUIDRandom().replace(/-/g, '').substring(0, 7)}`;
  }
}
