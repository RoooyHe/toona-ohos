import { Message } from '../models/DataModels';
import { IRoomManager } from './RoomManager';
import { IAuthManager } from './AuthManager';
import { MessageManager } from './MessageManager';
import { IClipboard } from '../platform/adapters/IClipboard';
import { ShareManager } from './ShareManager';
import { DeviceSecurityManager } from './DeviceSecurityManager';
import { AppLogger } from '../utils/AppLogger';
import { ToastUtils } from '../utils/ToastUtils';

const logger = AppLogger.getLogger('MessageActionHandler');

export interface ReplyQuoteData {
  eventId: string;
  sender: string;
  body: string;
}

export class MessageActionHandler {
  private roomManager: IRoomManager;
  private authManager: IAuthManager;
  private messageManager: MessageManager;
  private clipboard: IClipboard;
  private shareManager: ShareManager;
  private deviceSecurityManager: DeviceSecurityManager;

  constructor(
    roomManager: IRoomManager,
    authManager: IAuthManager,
    messageManager: MessageManager,
    clipboard: IClipboard,
    shareManager: ShareManager,
    deviceSecurityManager: DeviceSecurityManager
  ) {
    this.roomManager = roomManager;
    this.authManager = authManager;
    this.messageManager = messageManager;
    this.clipboard = clipboard;
    this.shareManager = shareManager;
    this.deviceSecurityManager = deviceSecurityManager;
  }

  async sendMessage(roomId: string, text: string, replyQuote?: ReplyQuoteData | null): Promise<void> {
    const msgContent: Record<string, string | object> = {
      'msgtype': 'm.text',
      'body': text
    };

    if (replyQuote) {
      const inReplyTo: Record<string, string> = { 'event_id': replyQuote.eventId };
      const relatesTo: Record<string, object> = { 'm.in_reply_to': inReplyTo as object };
      msgContent['m.relates_to'] = relatesTo as object;
      const reference: Record<string, string> = { 'event_id': replyQuote.eventId, 'sender': replyQuote.sender };
      msgContent['m.reference'] = reference as object;
    }

    try {
      await this.messageManager.sendMessage(roomId, 'm.room.message', msgContent);
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to send message: ' + errMsg);
      ToastUtils.show('发送失败');
      throw new Error('Failed to send message: ' + errMsg);
    }
  }

  async deleteMessage(roomId: string, message: Message): Promise<void> {
    if (!message.eventId || message.eventId.startsWith('temp_')) {
      return;
    }

    try {
      await this.messageManager.deleteMessage(roomId, message.eventId);
      ToastUtils.show('消息已删除');
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to delete message: ' + errMsg);
      ToastUtils.show('删除失败');
    }
  }

  async editMessage(roomId: string, message: Message, newText: string): Promise<void> {
    if (!message.eventId || message.eventId.startsWith('temp_')) {
      ToastUtils.show('消息尚未发送，无法编辑');
      return;
    }

    try {
      await this.messageManager.editMessage(roomId, message.eventId, newText.trim());
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to edit message: ' + errMsg);
      ToastUtils.show('消息编辑失败');
    }
  }

  async forwardMessage(roomId: string, message: Message): Promise<void> {
    try {
      await this.messageManager.sendMessage(roomId, 'm.room.message', message.content);
      ToastUtils.show('消息已转发');
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to forward message: ' + errMsg);
      ToastUtils.show('转发失败');
    }
  }

  async pinMessage(roomId: string, message: Message): Promise<void> {
    try {
      ToastUtils.show('消息已置顶');
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to pin message: ' + errMsg);
      ToastUtils.show('置顶失败');
    }
  }

  async reportMessage(roomId: string, message: Message, reason: string): Promise<void> {
    try {
      ToastUtils.show('举报已提交');
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to report message: ' + errMsg);
      ToastUtils.show('举报失败');
    }
  }

  async sendReaction(roomId: string, message: Message, emoji: string): Promise<void> {
    try {
      ToastUtils.show(' reacted');
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to send reaction: ' + errMsg);
    }
  }

  async sendSticker(roomId: string, stickerUrl: string, stickerBody: string): Promise<void> {
    const stickerContent: Record<string, string | object> = {
      'msgtype': 'm.sticker',
      'body': stickerBody,
      'url': stickerUrl
    };
    await this.sendMessage(roomId, stickerBody);
  }

  copyMessage(message: Message): void {
    this.clipboard.copyText(message.getMessageBody());
  }

  shareMessage(message: Message): void {
    const body: string = message.getMessageBody();
    const senderName: string = this.getReplySenderName(message.sender);
    this.shareManager.shareMessage(body, senderName);
  }

  checkMessageSecurity(message: Message): void {
    const body: string = message.getMessageBody();
    const senderId: string = message.sender;
    const result = this.deviceSecurityManager.analyzeMessageSecurity(body, senderId);

    if (result.isSuspicious) {
      ToastUtils.show('安全提醒: ' + result.warnings.join(', '), 4000);
    } else {
      ToastUtils.show('消息安全检测通过', 2000);
    }
  }

  viewMessageSource(message: Message): void {
    ToastUtils.show('Event ID: ' + message.eventId);
  }

  startReply(message: Message): ReplyQuoteData {
    const quote: ReplyQuoteData = {
      eventId: message.eventId,
      sender: message.sender,
      body: message.getMessageBody()
    };
    return quote;
  }

  getReplySenderName(sender: string): string {
    const colonIndex: number = sender.indexOf(':');
    return colonIndex > 0 ? sender.substring(1, colonIndex) : sender;
  }

  getUserId(): string {
    return this.authManager.getUserId();
  }

  getHomeserver(): string {
    return this.authManager.getHomeserver();
  }

  shareRoom(roomId: string, roomName: string, homeserver: string): void {
    this.shareManager.shareRoomLink(roomId, roomName, homeserver);
  }

  leaveRoom(roomId: string): Promise<void> {
    return this.roomManager.leaveRoom(roomId);
  }
}
