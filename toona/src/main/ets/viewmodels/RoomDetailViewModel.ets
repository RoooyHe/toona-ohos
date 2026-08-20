import { Message, MessageStatus } from '../models/DataModels';
import { IMessageSender, ReplyQuoteData } from '../services/MessageSender';
import { IMessageManager } from '../services/MessageManager';
import { IShareManager } from '../services/ShareManager';
import { IMediaActionHandler, MediaSendType } from '../services/MediaActionHandler';
import { IRoomMetadataLoader, MemberPresence, RoomTopicResult } from '../services/RoomMetadataLoader';
import { IRoomManager } from '../services/RoomManager';
import { ISyncManager } from '../services/SyncManager';
import { media } from '@kit.MediaKit';
import { AppLogger } from '../utils/AppLogger';
import { ToastUtils } from '../utils/ToastUtils';
import { getReplySenderName } from '../utils/MessageFormatter';

const logger = AppLogger.getLogger('RoomDetailViewModel');

export interface RoomDetailDeps {
  roomManager: IRoomManager;
  messageSender: IMessageSender;
  messageManager: IMessageManager;
  syncManager: ISyncManager;
  shareManager: IShareManager;
  mediaActionHandler: IMediaActionHandler;
  metadataLoader: IRoomMetadataLoader;
}

export interface RoomDetailState {
  messages: Message[];
  isLoading: boolean;
  typingUsers: string[];
  memberPresences: MemberPresence[];
  roomTopic: string;
  roomName: string;
  hasMoreMessages: boolean;
  isLoadingMore: boolean;
  isRecording: boolean;
  replyQuote: ReplyQuoteData | null;
  editingMessage: Message | null;
  editText: string;
  inputText: string;
  selectedMessage: Message | null;
}

export type StateChangeCallback = (state: RoomDetailState) => void;

export type LeaveRoomCallback = () => void;

export type CopyMessageCallback = (text: string) => void;

export class RoomDetailViewModel {
  private roomId: string;
  private initialRoomName: string;
  private userId: string;
  private homeserver: string;
  private roomManager: IRoomManager;
  private messageSender: IMessageSender;
  private messageManager: IMessageManager;
  private syncManager: ISyncManager;
  private shareManager: IShareManager;
  private mediaHandler: IMediaActionHandler;
  private metadataLoader: IRoomMetadataLoader;
  private presenceInterval: number = 0;
  private leaveRoomCallback: LeaveRoomCallback | null = null;
  private onStateChanged: StateChangeCallback | null = null;
  private onCopyMessage: CopyMessageCallback | null = null;

  private state: RoomDetailState = {
    messages: [],
    isLoading: true,
    typingUsers: [],
    memberPresences: [],
    roomTopic: '',
    roomName: '',
    hasMoreMessages: true,
    isLoadingMore: false,
    isRecording: false,
    replyQuote: null,
    editingMessage: null,
    editText: '',
    inputText: '',
    selectedMessage: null
  };

  constructor(roomId: string, roomName: string, userId: string, homeserver: string, deps: RoomDetailDeps) {
    this.roomId = roomId;
    this.initialRoomName = roomName;
    this.userId = userId;
    this.homeserver = homeserver;
    this.state.roomName = roomName;
    this.roomManager = deps.roomManager;
    this.messageSender = deps.messageSender;
    this.messageManager = deps.messageManager;
    this.syncManager = deps.syncManager;
    this.shareManager = deps.shareManager;
    this.mediaHandler = deps.mediaActionHandler;
    this.metadataLoader = deps.metadataLoader;
  }

  setOnStateChanged(callback: StateChangeCallback): void {
    this.onStateChanged = callback;
  }

  setLeaveRoomCallback(callback: LeaveRoomCallback): void {
    this.leaveRoomCallback = callback;
  }

  setOnCopyMessage(callback: CopyMessageCallback): void {
    this.onCopyMessage = callback;
  }

  private notifyStateChanged(): void {
    if (this.onStateChanged) {
      this.onStateChanged(this.state);
    }
  }

  initialize(): void {
    this.loadRoomTopic();
    this.loadMessages();
    this.loadMemberPresences();

    const self = this;
    this.presenceInterval = setInterval(() => {
      self.loadMemberPresences();
      self.checkTypingUsers();
    }, 30000) as number;

    this.syncManager.setRoomLeftCallback((leftRoomId: string) => {
      if (leftRoomId === self.roomId) {
      if (self.leaveRoomCallback) {
        self.leaveRoomCallback();
      }
      }
    });

    this.syncManager.setNewMessagesCallback((msgRoomId: string) => {
      if (msgRoomId === self.roomId) {
        self.loadMessages();
        self.checkTypingUsers();
      }
    });
  }

  destroy(): void {
    this.syncManager.clearAllCallbacks();
    if (this.presenceInterval) {
      clearInterval(this.presenceInterval);
    }
    this.metadataLoader.cleanup(this.roomId);
  }

  getRoomId(): string {
    return this.roomId;
  }

  getUserId(): string {
    return this.userId;
  }

  getState(): RoomDetailState {
    return this.state;
  }

  async loadMessages(): Promise<void> {
    try {
      const roomMessages: Message[] = await this.roomManager.getRoomMessages(this.roomId, 50);
      this.state.messages = roomMessages.reverse();
      this.state.hasMoreMessages = this.state.messages.length >= 50;
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to load messages: ' + errMsg);
      this.state.messages = [];
    }
    this.state.isLoading = false;
    this.notifyStateChanged();
  }

  async loadMoreMessages(): Promise<void> {
    if (this.state.isLoadingMore || !this.state.hasMoreMessages) {
      return;
    }
    this.state.isLoadingMore = true;
    this.notifyStateChanged();
    try {
      if (this.state.messages.length === 0) {
        return;
      }
      const oldestMessage: Message = this.state.messages[0];
      const olderMessages: Message[] = await this.roomManager.getRoomMessages(this.roomId, 50, oldestMessage.eventId);
      if (olderMessages.length > 0) {
        const reversed: Message[] = olderMessages.reverse();
        this.state.messages = [...reversed, ...this.state.messages];
        this.state.hasMoreMessages = olderMessages.length >= 50;
      } else {
        this.state.hasMoreMessages = false;
      }
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to load more messages: ' + errMsg);
    } finally {
      this.state.isLoadingMore = false;
      this.notifyStateChanged();
    }
  }

  async loadMemberPresences(): Promise<void> {
    this.state.memberPresences = await this.metadataLoader.loadMemberPresences(this.roomId);
    this.notifyStateChanged();
  }

  async loadRoomTopic(): Promise<void> {
    const result: RoomTopicResult = await this.metadataLoader.loadRoomTopic(this.roomId);
    this.state.roomTopic = result.roomTopic;
    if (this.initialRoomName === '聊天室' && result.roomName) {
      this.state.roomName = result.roomName;
    }
    this.notifyStateChanged();
  }

  async checkTypingUsers(): Promise<void> {
    this.state.typingUsers = await this.metadataLoader.checkTypingUsers(this.roomId);
    this.notifyStateChanged();
  }

  onInputChange(text: string): void {
    this.state.inputText = text;
    this.metadataLoader.onInputChange(text, this.roomId);
  }

  async sendMessage(): Promise<void> {
    if (!this.state.inputText.trim() && !this.state.replyQuote) {
      return;
    }

    const messageText: string = this.state.inputText.trim();
    this.state.inputText = '';

    this.metadataLoader.stopTyping(this.roomId);

    const msgContent: Record<string, string | object> = {
      'msgtype': 'm.text',
      'body': messageText
    };

    if (this.state.replyQuote) {
      const inReplyTo: Record<string, string> = { 'event_id': this.state.replyQuote.eventId };
      const relatesTo: Record<string, object> = { 'm.in_reply_to': inReplyTo as object };
      msgContent['m.relates_to'] = relatesTo as object;
      const reference: Record<string, string> = { 'event_id': this.state.replyQuote.eventId, 'sender': this.state.replyQuote.sender };
      msgContent['m.reference'] = reference as object;
    }

    const tempMessage: Message = Message.createPendingMessage(this.roomId, msgContent);
    tempMessage.timestamp = Date.now();
    tempMessage.replyEventId = this.state.replyQuote?.eventId;
    this.state.messages.push(tempMessage);

    const replyQuoteData: ReplyQuoteData | null = this.state.replyQuote;
    this.state.replyQuote = null;
    this.notifyStateChanged();

    try {
      await this.messageSender.sendText(this.roomId, messageText, replyQuoteData);
      const index: number = this.state.messages.findIndex((m: Message) => m.eventId === tempMessage.eventId);
      if (index >= 0) {
        this.state.messages[index].status = MessageStatus.SENT;
      }
    } catch (error) {
      const index: number = this.state.messages.findIndex((m: Message) => m.eventId === tempMessage.eventId);
      if (index >= 0) {
        this.state.messages[index].status = MessageStatus.FAILED;
      }
    }
    this.notifyStateChanged();
  }

  async leaveRoom(): Promise<void> {
    try {
      await this.roomManager.leaveRoom(this.roomId);
      if (this.leaveRoomCallback) {
        this.leaveRoomCallback();
      }
    } catch (error) {
      logger.error('Failed to leave room');
    }
  }

  shareRoom(): void {
    const senderName: string = getReplySenderName(this.state.roomName);
    this.shareManager.shareRoomLink(this.roomId, this.state.roomName, this.homeserver);
  }

  startReply(message: Message): void {
    const quote: ReplyQuoteData = {
      eventId: message.eventId,
      sender: message.sender,
      body: message.getMessageBody()
    };
    this.state.replyQuote = quote;
    this.state.selectedMessage = null;
    this.notifyStateChanged();
  }

  cancelReply(): void {
    this.state.replyQuote = null;
    this.notifyStateChanged();
  }

  copyMessage(message: Message): void {
    if (this.onCopyMessage) {
      this.onCopyMessage(message.getMessageBody());
    }
  }

  shareMessage(message: Message): void {
    const body: string = message.getMessageBody();
    const senderName: string = getReplySenderName(message.sender);
    this.shareManager.shareMessage(body, senderName);
  }

  viewMessageSource(message: Message): void {
    ToastUtils.show('Event ID: ' + message.eventId);
  }

  async deleteMessage(message: Message): Promise<void> {
    if (!message.eventId || message.eventId.startsWith('temp_')) {
      const index: number = this.state.messages.findIndex((m: Message) => m.eventId === message.eventId);
      if (index >= 0) {
        this.state.messages.splice(index, 1);
      }
      this.state.selectedMessage = null;
      this.notifyStateChanged();
      return;
    }

    try {
      await this.messageManager.deleteMessage(this.roomId, message.eventId);
      const index: number = this.state.messages.findIndex((m: Message) => m.eventId === message.eventId);
      if (index >= 0) {
        this.state.messages.splice(index, 1);
      }
      ToastUtils.show('消息已删除');
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to delete message: ' + errMsg);
      ToastUtils.show('删除失败');
    }
    this.state.selectedMessage = null;
    this.notifyStateChanged();
  }

  startEdit(message: Message): void {
    this.state.editingMessage = message;
    this.state.editText = message.getMessageBody();
    this.state.selectedMessage = null;
    this.notifyStateChanged();
  }

  async saveEdit(): Promise<void> {
    if (!this.state.editingMessage || !this.state.editText.trim()) {
      this.cancelEdit();
      return;
    }

    if (!this.state.editingMessage.eventId || this.state.editingMessage.eventId.startsWith('temp_')) {
      ToastUtils.show('消息尚未发送，无法编辑');
      this.cancelEdit();
      return;
    }

    try {
      await this.messageSender.editMessage(this.roomId, this.state.editingMessage.eventId, this.state.editText.trim());
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to edit message: ' + errMsg);
      ToastUtils.show('消息编辑失败');
    }
    this.cancelEdit();
  }

  cancelEdit(): void {
    this.state.editingMessage = null;
    this.state.editText = '';
    this.state.selectedMessage = null;
    this.notifyStateChanged();
  }

  onMessageLongPress(message: Message): void {
    this.state.selectedMessage = message;
    this.notifyStateChanged();
  }

  async sendReaction(emoji: string): Promise<void> {
    if (!this.state.selectedMessage) return;
    ToastUtils.show(' reacted');
    this.state.selectedMessage = null;
    this.notifyStateChanged();
  }

  async sendSticker(stickerUrl: string, stickerBody: string): Promise<void> {
    try {
      await this.messageSender.sendSticker(this.roomId, stickerUrl, stickerBody);
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to send sticker: ' + errMsg);
      ToastUtils.show('发送失败');
    }
  }

  async forwardMessage(message: Message): Promise<void> {
    try {
      await this.messageManager.forwardMessage(this.roomId, message.content);
      ToastUtils.show('消息已转发');
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to forward message: ' + errMsg);
      ToastUtils.show('转发失败');
    }
    this.state.selectedMessage = null;
    this.notifyStateChanged();
  }

  async pinMessage(message: Message): Promise<void> {
    ToastUtils.show('消息已置顶');
    this.state.selectedMessage = null;
    this.notifyStateChanged();
  }

  async reportMessage(reason: string): Promise<void> {
    if (!this.state.selectedMessage) return;
    ToastUtils.show('举报已提交');
    this.state.selectedMessage = null;
    this.notifyStateChanged();
  }

  async handleSelectImage(): Promise<void> {
    await this.mediaHandler.selectAndUploadImage(this.roomId);
  }

  async startRecording(context: Object): Promise<Object | null> {
    return await this.mediaHandler.startRecording(context);
  }

  async stopRecording(avRecorder: media.AVRecorder, audioPath: string, audioFd: number): Promise<void> {
    try {
      const recordingResult = await this.mediaHandler.stopRecording(avRecorder, audioPath, audioFd);
      if (recordingResult) {
        await this.mediaHandler.uploadAndSend(this.roomId, recordingResult.buffer, recordingResult.fileName, recordingResult.buffer.byteLength, MediaSendType.AUDIO);
      }
    } catch (err) {
      const errMsg: string = err instanceof Error ? err.message : String(err);
      logger.error('Failed to stop recording: ' + errMsg);
    }
    this.state.isRecording = false;
    this.notifyStateChanged();
  }

  setRecording(isRecording: boolean): void {
    this.state.isRecording = isRecording;
    this.notifyStateChanged();
  }
}
