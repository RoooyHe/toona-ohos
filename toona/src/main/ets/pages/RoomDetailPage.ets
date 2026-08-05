import { ToastUtils } from '../utils/ToastUtils';
import { QuickDialogManager, QuickDialogParams, QuickDialogController } from 'quickdialog';
import { Message } from '../models/DataModels';
import { MessageStatus, PresenceState } from '../models/MatrixTypes';
import { ServiceRegistry } from '../services/ServiceRegistry';
import { MediaManager } from '../services/MediaManager';
import { VerificationService } from '../services/VerificationService';
import { MessageActionHandler, ReplyQuoteData } from '../services/MessageActionHandler';
import { MediaActionHandler } from '../services/MediaActionHandler';
import { RoomMetadataLoader, MemberPresence } from '../services/RoomMetadataLoader';
import { HarmonyFilePicker } from '../platform/adapters/HarmonyFilePicker';
import { HarmonyAudioRecorder } from '../platform/adapters/HarmonyAudioRecorder';
import { HarmonyClipboard } from '../platform/adapters/HarmonyClipboard';
import { ShareManager } from '../services/ShareManager';
import { DeviceSecurityManager } from '../services/DeviceSecurityManager';
import { getThemeColors } from '../utils/ThemeManager';
import { MessageBubble } from './components/MessageBubble';
import { MessageInputBar } from './components/MessageInputBar';
import { MemberListPanel } from './components/MemberListPanel';
import { MessageActionMenu } from './components/MessageActionMenu';
import { ReplyQuote } from './components/ReplyQuote';
import { EditMessage } from './components/EditMessage';
import { ReactionPicker } from './components/ReactionPicker';
import { StickerPicker } from './components/StickerPicker';
import { MessageSourceDialog } from './components/MessageSourceDialog';
import { MessageReportDialog } from './components/MessageReportDialog';
import { formatTime, getTimeGroupLabel, shouldShowTimeGroup, getReplySenderName } from '../utils/MessageFormatter';
import { media } from '@kit.MediaKit';
import common from '@ohos.app.ability.common';
import curves from '@ohos.curves';
import { AppLogger } from '../utils/AppLogger';

const logger = AppLogger.getLogger('RoomDetailPage');

interface StickerInfo {
  w: number;
  h: number;
  mimetype: string;
}

interface StickerContent {
  url: string;
  body: string;
  info: StickerInfo;
}

@Builder
export function RoomDetailPageBuilder(name: string, param: Object) {
  RoomDetailPage({
    roomId: ((param as Record<string, Object>)['roomId'] as string) || '',
    roomName: ((param as Record<string, Object>)['roomName'] as string) || '聊天室'
  })
}

@Component
struct RecordingDialogContent {
  private dialogController: QuickDialogController | undefined = undefined
  @State waveScale: number = 1.0

  aboutToAppear() {
    animateTo({
      duration: 800,
      curve: curves.springMotion(),
      iterations: -1,
      playMode: PlayMode.Alternate
    }, () => {
      this.waveScale = 1.3;
    })
  }

  build() {
    Column() {
      Stack() {
        Circle()
          .width(60)
          .height(60)
          .fill(Color.White)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height(160)
    .backgroundColor('#33000000')
    .borderRadius(20)
    .margin({ left: 40, right: 40 })
  }
}

@Builder
function RecordingDialogBuilder(dialogParams: QuickDialogParams) {
  RecordingDialogContent()
}

@Component
struct RoomDetailPage {
  @State roomId: string = '';
  @State roomName: string = '';
  @State messages: Message[] = [];
  @State inputText: string = '';
  @State isLoading: boolean = true;
  @State showMenu: boolean = false;
  @State typingUsers: string[] = [];
  @State memberPresences: MemberPresence[] = [];
  @State showMembersPanel: boolean = false;
  @State replyQuote: ReplyQuoteData | null = null;
  @State showReplyMenu: boolean = false;
  @State selectedMessage: Message | null = null;
  @State roomTopic: string = '';
  @State showMessageAction: boolean = false;
  @State messageActionType: string = '';
  @State editingMessage: Message | null = null;
  @State editText: string = '';
  @State isRecording: boolean = false;
  @State showReactionPicker: boolean = false;
  @State showStickerPicker: boolean = false;
  @State hasMoreMessages: boolean = true;
  @State isLoadingMore: boolean = false;
  @State showMessageSource: boolean = false;
  @State showReportDialog: boolean = false;
  private avRecorder: media.AVRecorder | undefined = undefined;
  private audioPath: string = '';
  private audioFd: number = -1;
  private scroller: Scroller = new Scroller();
  private presenceInterval: number = 0;
  private recordingDialogController: QuickDialogController | undefined = undefined;
  pathStack: NavPathStack = new NavPathStack();
  private messageHandler: MessageActionHandler | null = null;
  private mediaHandler: MediaActionHandler | null = null;
  private metadataLoader: RoomMetadataLoader | null = null;
  private mediaManager: MediaManager | null = null;
  private verificationService: VerificationService | null = null;

  aboutToAppear() {
    const registry = ServiceRegistry.getCurrent();
    const roomManager = registry.getRoomManager();
    const authManager = registry.getAuthManager();
    const messageManager = registry.getMessageManager();
    const presenceManager = registry.getPresenceManager();
    this.mediaManager = registry.getMediaManager();
    this.verificationService = registry.getVerificationService();

    const filePicker = new HarmonyFilePicker();
    const audioRecorder = new HarmonyAudioRecorder();
    const clipboard = new HarmonyClipboard();

    this.messageHandler = new MessageActionHandler(
      roomManager,
      authManager,
      messageManager,
      clipboard,
      ShareManager.getInstance(),
      DeviceSecurityManager.getInstance()
    );

    this.mediaHandler = new MediaActionHandler(
      filePicker,
      audioRecorder,
      this.mediaManager,
      messageManager
    );

    this.metadataLoader = new RoomMetadataLoader(
      roomManager,
      authManager,
      presenceManager
    );

    this.loadRoomTopic();
    this.loadMessages();
    this.loadMemberPresences();

    const self = this;
    this.presenceInterval = setInterval(() => {
      self.loadMemberPresences();
      self.checkTypingUsers();
    }, 30000) as number;

    registry.getSyncManager().setRoomLeftCallback((leftRoomId: string) => {
      if (leftRoomId === self.roomId) {
        ToastUtils.show('已离开房间');
        self.pathStack.pop();
      }
    });

    registry.getSyncManager().setNewMessagesCallback((msgRoomId: string) => {
      if (msgRoomId === self.roomId) {
        self.loadMessages();
        self.checkTypingUsers();
      }
    });
  }

  aboutToDisappear() {
    ServiceRegistry.getCurrent().getSyncManager().clearAllCallbacks();
    if (this.presenceInterval) {
      clearInterval(this.presenceInterval);
    }
    if (this.metadataLoader) {
      this.metadataLoader.cleanup(this.roomId);
    }
  }

  async loadMemberPresences() {
    if (!this.metadataLoader) return;
    this.memberPresences = await this.metadataLoader.loadMemberPresences(this.roomId);
  }

  async loadRoomTopic() {
    if (!this.metadataLoader) return;
    const result = await this.metadataLoader.loadRoomTopic(this.roomId);
    this.roomTopic = result.roomTopic;
    if (this.roomName === '聊天室' && result.roomName) {
      this.roomName = result.roomName;
    }
  }

  async checkTypingUsers() {
    if (!this.metadataLoader) return;
    this.typingUsers = await this.metadataLoader.checkTypingUsers(this.roomId);
  }

  async onInputChange(text: string) {
    this.inputText = text;
    if (!this.metadataLoader) return;
    this.metadataLoader.onInputChange(text, this.roomId);
  }

  async handleSelectImage() {
    if (!this.mediaHandler) return;
    await this.mediaHandler.selectAndUploadImage(this.roomId);
  }

  async startRecording() {
    if (!this.mediaHandler) return;
    const context: Object = getContext(this);
    const result: Object | null = await this.mediaHandler.startRecording(context);
    if (result) {
      const recordData: Record<string, Object> = result as Record<string, Object>;
      this.avRecorder = recordData['avRecorder'] as media.AVRecorder;
      this.audioPath = recordData['audioPath'] as string;
      this.audioFd = recordData['audioFd'] as number;
      this.isRecording = true;
      this.recordingDialogController = QuickDialogManager.newBuilder(
        this.getUIContext(),
        wrapBuilder(RecordingDialogBuilder)
      ).build();
      this.recordingDialogController.show();
    }
  }

  async stopAndSendRecording() {
    if (!this.mediaHandler || !this.avRecorder || !this.isRecording) return;
    try {
      const recordingResult = await this.mediaHandler.stopRecording(this.avRecorder, this.audioPath, this.audioFd);
      if (recordingResult) {
        await this.mediaHandler.uploadAndSendAudio(this.roomId, recordingResult.buffer, recordingResult.fileName, recordingResult.buffer.byteLength);
      }
    } catch (err) {
      const errMsg: string = err instanceof Error ? err.message : String(err);
      logger.error('Failed to stop recording: ' + errMsg);
    } finally {
      this.isRecording = false;
      this.recordingDialogController?.dismiss();
    }
  }

  async loadMessages() {
    if (!this.metadataLoader) return;
    const registry = ServiceRegistry.getCurrent();
    const roomManager = registry.getRoomManager();
    try {
      const roomMessages: Message[] = await roomManager.getRoomMessages(this.roomId, 50);
      this.messages = roomMessages.reverse();
      this.hasMoreMessages = this.messages.length >= 50;
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to load messages: ' + errMsg);
      this.messages = [];
    }
    this.isLoading = false;
  }

  async loadMoreMessages() {
    if (this.isLoadingMore || !this.hasMoreMessages) {
      return;
    }
    this.isLoadingMore = true;
    const registry = ServiceRegistry.getCurrent();
    const roomManager = registry.getRoomManager();
    try {
      if (this.messages.length === 0) {
        return;
      }
      const oldestMessage: Message = this.messages[0];
      const olderMessages: Message[] = await roomManager.getRoomMessages(this.roomId, 50, oldestMessage.eventId);
      if (olderMessages.length > 0) {
        const reversed: Message[] = olderMessages.reverse();
        this.messages = [...reversed, ...this.messages];
        this.hasMoreMessages = olderMessages.length >= 50;
      } else {
        this.hasMoreMessages = false;
      }
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to load more messages: ' + errMsg);
    } finally {
      this.isLoadingMore = false;
    }
  }

  async sendMessage() {
    if (!this.inputText.trim() && !this.replyQuote) {
      return;
    }
    if (!this.messageHandler) return;

    const messageText: string = this.inputText.trim();
    this.inputText = '';

    if (this.metadataLoader) {
      this.metadataLoader.stopTyping(this.roomId);
    }

    const msgContent: Record<string, string | object> = {
      'msgtype': 'm.text',
      'body': messageText
    };

    if (this.replyQuote) {
      const inReplyTo: Record<string, string> = { 'event_id': this.replyQuote.eventId };
      const relatesTo: Record<string, object> = { 'm.in_reply_to': inReplyTo as object };
      msgContent['m.relates_to'] = relatesTo as object;
      const reference: Record<string, string> = { 'event_id': this.replyQuote.eventId, 'sender': this.replyQuote.sender };
      msgContent['m.reference'] = reference as object;
    }

    const tempMessage: Message = Message.createPendingMessage(this.roomId, msgContent);
    tempMessage.timestamp = Date.now();
    tempMessage.replyEventId = this.replyQuote?.eventId;
    this.messages.push(tempMessage);

    const replyQuoteData: ReplyQuoteData | null = this.replyQuote;
    this.replyQuote = null;

    try {
      await this.messageHandler.sendMessage(this.roomId, messageText, replyQuoteData);
      const index: number = this.messages.findIndex((m: Message) => m.eventId === tempMessage.eventId);
      if (index >= 0) {
        this.messages[index].status = MessageStatus.SENT;
      }
    } catch (error) {
      const index: number = this.messages.findIndex((m: Message) => m.eventId === tempMessage.eventId);
      if (index >= 0) {
        this.messages[index].status = MessageStatus.FAILED;
      }
      ToastUtils.show('发送失败');
    }
  }

  async leaveRoom() {
    if (!this.messageHandler) return;
    try {
      await this.messageHandler.leaveRoom(this.roomId);
      ToastUtils.show('已离开房间');
      this.pathStack?.pop();
    } catch (error) {
      ToastUtils.show('离开失败');
    }
  }

  shareRoom() {
    if (!this.messageHandler) return;
    const homeserver: string = this.messageHandler.getHomeserver() || '';
    this.messageHandler.shareRoom(this.roomId, this.roomName, homeserver);
  }

  startReply(message: Message) {
    if (!this.messageHandler) return;
    const quote: ReplyQuoteData = this.messageHandler.startReply(message);
    this.replyQuote = quote;
    this.showReplyMenu = false;
    this.selectedMessage = null;
  }

  cancelReply() {
    this.replyQuote = null;
  }

  copyMessage(message: Message): void {
    if (!this.messageHandler) return;
    this.messageHandler.copyMessage(message);
    this.showMessageAction = false;
    this.selectedMessage = null;
  }

  shareMessage(message: Message) {
    if (!this.messageHandler) return;
    this.messageHandler.shareMessage(message);
    this.showReplyMenu = false;
    this.selectedMessage = null;
  }

  checkMessageSecurity(message: Message) {
    if (!this.messageHandler) return;
    this.messageHandler.checkMessageSecurity(message);
    this.showReplyMenu = false;
    this.selectedMessage = null;
  }

  async deleteMessage(message: Message) {
    if (!message.eventId || message.eventId.startsWith('temp_')) {
      const index: number = this.messages.findIndex((m: Message) => m.eventId === message.eventId);
      if (index >= 0) {
        this.messages.splice(index, 1);
      }
      this.showMessageAction = false;
      this.selectedMessage = null;
      return;
    }

    if (!this.messageHandler) return;
    await this.messageHandler.deleteMessage(this.roomId, message);
    const index: number = this.messages.findIndex((m: Message) => m.eventId === message.eventId);
    if (index >= 0) {
      this.messages.splice(index, 1);
    }
    this.showMessageAction = false;
    this.selectedMessage = null;
  }

  startEdit(message: Message) {
    this.editingMessage = message;
    this.editText = message.getMessageBody();
    this.showReplyMenu = false;
    this.selectedMessage = null;
  }

  async saveEdit() {
    if (!this.editingMessage || !this.editText.trim()) {
      this.cancelEdit();
      return;
    }
    if (!this.messageHandler) return;

    if (!this.editingMessage.eventId || this.editingMessage.eventId.startsWith('temp_')) {
      ToastUtils.show('消息尚未发送，无法编辑');
      this.cancelEdit();
      return;
    }

    await this.messageHandler.editMessage(this.roomId, this.editingMessage, this.editText.trim());
    this.cancelEdit();
  }

  cancelEdit() {
    this.editingMessage = null;
    this.editText = '';
    this.showReplyMenu = false;
    this.selectedMessage = null;
  }

  startVoiceCall() {
    ToastUtils.show('语音通话功能开发中');
  }

  startVideoCall() {
    ToastUtils.show('视频通话功能开发中');
  }

  onMessageLongPress(message: Message) {
    this.selectedMessage = message;
    this.showReplyMenu = true;
  }

  navigateToRoomSettings() {
    ToastUtils.show('房间设置');
  }

  async sendReaction(emoji: string) {
    if (!this.messageHandler || !this.selectedMessage) return;
    await this.messageHandler.sendReaction(this.roomId, this.selectedMessage, emoji);
    this.showReactionPicker = false;
    this.selectedMessage = null;
  }

  async sendSticker(stickerUrl: string, stickerBody: string) {
    if (!this.messageHandler) return;
    await this.messageHandler.sendSticker(this.roomId, stickerUrl, stickerBody);
    this.showStickerPicker = false;
  }

  async forwardMessage(message: Message) {
    if (!this.messageHandler) return;
    await this.messageHandler.forwardMessage(this.roomId, message);
    this.showMessageAction = false;
    this.selectedMessage = null;
  }

  async pinMessage(message: Message) {
    if (!this.messageHandler) return;
    await this.messageHandler.pinMessage(this.roomId, message);
    this.showMessageAction = false;
    this.selectedMessage = null;
  }

  viewMessageSource(message: Message) {
    if (!this.messageHandler) return;
    this.messageHandler.viewMessageSource(message);
    this.showMessageAction = false;
    this.selectedMessage = null;
  }

  async reportMessage(reason: string) {
    if (!this.messageHandler || !this.selectedMessage) return;
    await this.messageHandler.reportMessage(this.roomId, this.selectedMessage, reason);
    this.showReportDialog = false;
    this.selectedMessage = null;
  }

  @Builder
  buildHeader() {
    Row() {
      Column() {
        Text(this.roomName)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .fontColor(getThemeColors().text);
        if (this.roomTopic) {
          Text(this.roomTopic)
            .fontSize(12)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontColor(getThemeColors().textSecondary);
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);

      Image($r('app.media.fllow'))
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
        .fillColor(getThemeColors().textSecondary)
        .onClick(() => {
          this.showMembersPanel = !this.showMembersPanel;
        });

      Image($r('app.media.tel'))
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
        .fillColor(getThemeColors().textSecondary)
        .onClick(() => {
          this.startVoiceCall();
        });

      Image($r('app.media.menu'))
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
        .fillColor(getThemeColors().textSecondary)
        .onClick(() => {
          this.showMenu = !this.showMenu;
        });
    }
    .width('100%')
    .height(56)
    .padding({ left: 10, right: 10 })
    .backgroundColor(getThemeColors().surface);
  }

  @Builder
  buildRoomMenu() {
    if (this.showMenu) {
      Column() {
        Button('房间设置')
          .fontSize(16)
          .backgroundColor(getThemeColors().bg)
          .fontColor(getThemeColors().primary)
          .width('100%')
          .height(44)
          .onClick(() => {
            this.showMenu = false;
            this.navigateToRoomSettings();
          });
        Button('分享房间')
          .fontSize(16)
          .backgroundColor(getThemeColors().bg)
          .fontColor(getThemeColors().primary)
          .width('100%')
          .height(44)
          .onClick(() => {
            this.showMenu = false;
            this.shareRoom();
          });
        Button('离开房间')
          .fontSize(16)
          .backgroundColor(getThemeColors().bg)
          .fontColor(getThemeColors().error)
          .width('100%')
          .height(44)
          .onClick(() => {
            this.showMenu = false;
            this.leaveRoom();
          });
      }
      .width(160)
      .backgroundColor(getThemeColors().surface)
      .borderRadius(8)
      .position({ x: 0, y: 56 })
    }
  }

  @Builder
  buildTypingIndicator() {
    if (this.typingUsers.length > 0) {
      Row() {
        Text(this.typingUsers.join(', ') + ' 正在输入...')
          .fontSize(12)
          .fontColor(getThemeColors().textSecondary)
      }
      .padding({ left: 15, right: 15, top: 5, bottom: 5 })
      .width('100%')
    }
  }

  @Builder
  buildReplyQuote() {
    if (this.replyQuote) {
      ReplyQuote({
        replyQuote: this.replyQuote,
        onCancel: () => {
          this.cancelReply();
        }
      });
    }
  }

  @Builder
  buildEditMessage() {
    if (this.editingMessage) {
      EditMessage({
        editingMessage: this.editingMessage,
        editText: this.editText,
        onCancel: () => {
          this.cancelEdit();
        },
        onSave: (text: string) => {
          this.editText = text;
          this.saveEdit();
        }
      });
    }
  }

  @Builder
  buildMessageList() {
    if (this.isLoading) {
      Column() {
        LoadingProgress()
        Text('加载中...')
          .fontSize(14)
          .fontColor(getThemeColors().textSecondary)
          .margin({ top: 10 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else if (this.messages.length === 0) {
      Column() {
        Text('暂无消息')
          .fontSize(16)
          .fontColor(getThemeColors().textSecondary)
        Text('发送第一条消息')
          .fontSize(14)
          .fontColor(getThemeColors().textSecondary)
          .margin({ top: 5 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else {
      Column() {
        if (this.hasMoreMessages) {
          ListItem() {
            Button(this.isLoadingMore ? 'Loading...' : 'Load Earlier Messages')
              .fontSize(14)
              .fontColor(getThemeColors().primary)
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.loadMoreMessages();
              })
          }
          .width('100%')
          .padding({ top: 10, bottom: 10 })
        }
        List({ scroller: this.scroller }) {
          ForEach(this.messages, (message: Message, index: number) => {
            ListItem() {
              Column() {
                if (shouldShowTimeGroup(this.messages, index)) {
                  Text(getTimeGroupLabel(message.timestamp))
                    .fontSize(12)
                    .fontColor(getThemeColors().textSecondary)
                    .margin({ bottom: 8 })
                    .width('100%')
                    .textAlign(TextAlign.Center)
                }
                if (message.type === 'm.room.member' || message.type === 'm.room.create') {
                  if (message.type === 'm.room.member') {
                    Text(message.sender + ' 加入了房间')
                      .fontSize(14)
                      .fontColor(getThemeColors().textSecondary)
                      .margin({ bottom: 4 })
                  } else if (message.type === 'm.room.create') {
                    Text(message.sender + ' 创建了该房间')
                      .fontSize(14)
                      .fontColor(getThemeColors().textSecondary)
                      .margin({ bottom: 4 })
                  }
                } else {
                  MessageBubble({
                    message: message,
                    isOutgoing: message.sender === (this.messageHandler?.getUserId() || ''),
                    mediaManager: this.mediaManager!,
                    verificationService: this.verificationService!,
                    onLongPress: () => {
                      this.onMessageLongPress(message);
                    }
                  })
                  .onClick(() => {
                    this.selectedMessage = message;
                    this.showMessageAction = true;
                    this.messageActionType = 'action';
                  })
                  Row().height(0)
                }
              }
              .width('100%')
            }
          }, (item: Message) => item.eventId)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({
          left: 15,
          right: 15,
          top: 10,
          bottom: 10
        })
        .onClick(() => {
          this.showMenu = false;
          this.showMembersPanel = false;
          this.showMessageAction = false;
        })
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  buildInputBar() {
    MessageInputBar({
      inputText: this.inputText,
      editingMessage: this.editingMessage,
      onVoiceClick: (event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.startRecording();
        }
        else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.stopAndSendRecording();
        }
      },
      onInputChange: (text: string) => {
        this.onInputChange(text);
      },
      onSendMessage: () => {
        this.sendMessage();
      },
      onPickImage: () => {
        this.handleSelectImage();
      }
    });
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          this.buildHeader();
          this.buildRoomMenu();
          this.buildTypingIndicator();
          this.buildReplyQuote();
          this.buildEditMessage();
          this.buildMessageList();
          this.buildInputBar();
        }
        .width('100%')
        .height('100%')
        .backgroundColor(getThemeColors().bg);

        if (this.showMembersPanel) {
          MemberListPanel({
            memberPresences: this.memberPresences,
            showMembersPanel: this.showMembersPanel,
            onClose: () => {
              this.showMembersPanel = false;
            }
          });
        }

        MessageActionMenu({
          showReplyMenu: this.showReplyMenu,
          selectedMessage: this.selectedMessage!,
          onReply: (message: Message) => {
            this.startReply(message);
          },
          onCopy: (message: Message) => {
            this.copyMessage(message);
          },
          onDelete: (message: Message) => {
            this.deleteMessage(message);
          },
          onEdit: (message: Message) => {
            this.startEdit(message);
          },
          onSecurityCheck: (message: Message) => {
            this.checkMessageSecurity(message);
          },
          onShare: (message: Message) => {
            this.shareMessage(message);
          },
          onReact: (message: Message) => {
            this.showReactionPicker = true;
            this.selectedMessage = message;
          },
          onForward: (message: Message) => {
            this.forwardMessage(message);
          },
          onPin: (message: Message) => {
            this.pinMessage(message);
          },
          onReport: (message: Message) => {
            this.showReportDialog = true;
            this.selectedMessage = message;
          },
          onClose: () => {
            this.showMessageAction = false;
            this.selectedMessage = null;
          }
        });

        ReactionPicker({
          isVisible: this.showReactionPicker,
          onReaction: (emoji: string) => {
            this.sendReaction(emoji);
          },
          onClose: () => {
            this.showReactionPicker = false;
            this.selectedMessage = null;
          }
        });

        StickerPicker({
          isVisible: this.showStickerPicker,
          onSticker: (stickerUrl: string, stickerBody: string) => {
            this.sendSticker(stickerUrl, stickerBody);
          },
          onClose: () => {
            this.showStickerPicker = false;
          }
        });

        MessageSourceDialog({
          isVisible: this.showMessageSource,
          message: this.selectedMessage!,
          onClose: () => {
            this.showMessageSource = false;
            this.selectedMessage = null;
          }
        });

        MessageReportDialog({
          isVisible: this.showReportDialog,
          message: this.selectedMessage!,
          onReport: (reason: string) => {
            this.reportMessage(reason);
          },
          onClose: () => {
            this.showReportDialog = false;
            this.selectedMessage = null;
          }
        });
      }
      .width('100%')
      .height('100%')
      .backgroundColor(getThemeColors().bg)
    }
    .hideTitleBar(true)
  }
}
