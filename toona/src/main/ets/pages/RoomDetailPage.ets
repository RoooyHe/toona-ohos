import promptAction from '@ohos.promptAction';
import { RoomManager } from '../services/RoomManager';
import { Message } from '../models/DataModels';
import { SyncManager } from '../services/SyncManager';
import { MessageManager } from '../services/MessageManager';
import { PresenceManager } from '../services/PresenceManager';
import { MediaManager } from '../services/MediaManager';
import { MediaLibraryManager } from '../services/MediaLibraryManager';
import { AuthManager } from '../services/AuthManager';
import { ShareManager } from '../services/ShareManager';
import { DeviceSecurityManager } from '../services/DeviceSecurityManager';
import { MessageStatus, PresenceState } from '../models/MatrixTypes';
import { fileIo } from '@kit.CoreFileKit';
import { getThemeColors } from '../utils/ThemeManager';

interface MemberPresence {
  userId: string;
  presence: PresenceState;
  displayName: string;
}

interface ReplyQuote {
  eventId: string;
  sender: string;
  body: string;
}

interface InReplyTo {
  event_id: string;
}

interface ReferenceContent {
  event_id: string;
  sender: string;
}

interface RelatesTo {
  'm.in_reply_to': InReplyTo;
}

interface RoomDetailThemeColors {
  bg: string;
  text: string;
  textSecondary: string;
  inputBg: string;
  primary: string;
  error: string;
  divider: string;
  headerBg: string;
  messageBg: string;
  outgoingBg: string;
}

@Builder
export function RoomDetailPageBuilder(name: string, param: Object) {
  RoomDetailPage({
    roomId: (param as Record<string, string>)['roomId'] || '',
    roomName: (param as Record<string, string>)['roomName'] || '聊天室'
  })
}

@Entry
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
  @State replyQuote: ReplyQuote | null = null;
  @State showReplyMenu: boolean = false;
  @State selectedMessage: Message | null = null;
  @State roomTopic: string = '';
  @State showMessageAction: boolean = false;
  @State messageActionType: string = '';
  @State editingMessage: Message | null = null;
  @State editText: string = '';
  private roomManager: RoomManager = RoomManager.getInstance();
  private syncManager: SyncManager = SyncManager.getInstance();
  private messageManager: MessageManager = MessageManager.getInstance();
  private authManager: AuthManager = AuthManager.getInstance();
  private presenceManager: PresenceManager = PresenceManager.getInstance();
  private scroller: Scroller = new Scroller();
  private typingTimeout: number = 0;
  private typingStopTimeout: number = 0;
  private presenceInterval: number = 0;
  private mediaManager: MediaManager = MediaManager.getInstance();
  private mediaLibraryManager: MediaLibraryManager = MediaLibraryManager.getInstance();
  private shareManager: ShareManager = ShareManager.getInstance();
  private deviceSecurityManager: DeviceSecurityManager = DeviceSecurityManager.getInstance();
  private pathStack: NavPathStack | null = null;

  aboutToAppear() {
    this.loadRoomTopic();
    this.loadMessages();
    this.loadMemberPresences();

    this.presenceInterval = setInterval(() => {
      this.loadMemberPresences();
      this.checkTypingUsers();
    }, 30000) as number;

    this.syncManager.setRoomLeftCallback((leftRoomId: string) => {
      if (leftRoomId === this.roomId) {
        promptAction.showToast({ message: '已离开房间' });
        this.pathStack?.pop();
      }
    });

    this.syncManager.setNewMessagesCallback((msgRoomId: string) => {
      if (msgRoomId === this.roomId) {
        this.loadMessages();
      }
    });

    this.syncManager.setNewMessagesCallback((msgRoomId: string, messages: Message[]) => {
      if (msgRoomId === this.roomId) {
        this.checkTypingUsers();
      }
    });
  }

  aboutToDisappear() {
    this.syncManager.clearAllCallbacks();
    if (this.typingTimeout) {
      clearTimeout(this.typingTimeout);
    }
    if (this.typingStopTimeout) {
      clearTimeout(this.typingStopTimeout);
    }
    if (this.presenceInterval) {
      clearInterval(this.presenceInterval);
    }
    this.roomManager.stopTyping(this.roomId).catch(() => {
    });
  }

  async loadMemberPresences() {
    try {
      const members = await this.roomManager.getRoomMembers(this.roomId);
      const currentUserId = this.authManager.getUserId();
      const otherMembers = members.filter(id => id !== currentUserId);
      const presences: MemberPresence[] = [];

      for (let i = 0; i < otherMembers.length; i++) {
        const userId = otherMembers[i];
        try {
          const presence = await this.presenceManager.getPresence(userId);
          const displayName = presence.displayname || userId;
          presences.push({
            userId: userId,
            presence: presence.presence as PresenceState,
            displayName: displayName
          });
        } catch (e) {
          presences.push({
            userId: userId,
            presence: 'offline',
            displayName: userId
          });
        }
      }
      this.memberPresences = presences;
    } catch (error) {
      console.error('Failed to load member presences:', error);
    }
  }

  async loadRoomTopic() {
    try {
      const room = await this.roomManager.getRoom(this.roomId);
      if (room) {
        this.roomTopic = room.topic || '';
        if (this.roomName === '聊天室' && room.displayName) {
          this.roomName = room.displayName;
        }
      }
    } catch (error) {
      console.error('Failed to load room topic:', error);
    }
  }

  async checkTypingUsers() {
    try {
      const typing = await this.roomManager.getTypingUsers(this.roomId);
      const currentUserId = this.authManager.getUserId();
      this.typingUsers = typing.filter(id => id !== currentUserId);
    } catch (error) {
      console.error('Failed to check typing users:', error);
    }
  }

  async onInputChange(text: string) {
    this.inputText = text;
    if (this.typingTimeout === 0) {
      this.roomManager.startTyping(this.roomId).catch(() => {
      });
    }
    if (this.typingStopTimeout) {
      clearTimeout(this.typingStopTimeout);
    }
    this.typingStopTimeout = setTimeout(() => {
      this.roomManager.stopTyping(this.roomId).catch(() => {
      });
      this.typingTimeout = 0;
      this.typingStopTimeout = 0;
    }, 3000) as number;
  }

  async pickAndUploadImage() {
    try {
      const uri = await this.mediaLibraryManager.selectImage();
      if (uri) {
        await this.uploadImages([uri]);
      }
    } catch (error) {
      console.error('Failed to pick image: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '选择图片失败' });
    }
  }

  async pickAndUploadMultipleImages() {
    try {
      const uris = await this.mediaLibraryManager.selectMultipleImages(9);
      if (uris.length > 0) {
        await this.uploadImages(uris);
      }
    } catch (error) {
      console.error('Failed to pick images: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '选择图片失败' });
    }
  }

  async uploadImages(uris: string[]) {
    for (let i = 0; i < uris.length; i++) {
      const photoUri = uris[i];
      try {
        const file = fileIo.openSync(photoUri, fileIo.OpenMode.READ_ONLY);
        const fileInfo = fileIo.statSync(photoUri);
        const buffer = new Uint8Array(fileInfo.size);
        fileIo.readSync(file.fd, buffer);
        fileIo.closeSync(file);
        const fileName = 'image_' + Date.now() + '_' + i + '.jpg';
        const mxcUri = await this.mediaManager.uploadImage(buffer.buffer as ArrayBuffer, fileName);
        const msgContent: Record<string, string | object> = {
          'msgtype': 'm.image',
          'body': fileName,
          'url': mxcUri
        };
        const tempMessage: Message = Message.createPendingMessage(this.roomId, msgContent);
        tempMessage.timestamp = Date.now();
        this.messages.push(tempMessage);
        try {
          const messageManager = await import('../services/MessageManager');
          await messageManager.MessageManager.getInstance().sendMessage(this.roomId, 'm.room.message', msgContent);
          const index = this.messages.findIndex(m => m.eventId === tempMessage.eventId);
          if (index >= 0) {
            this.messages[index].status = MessageStatus.SENT;
          }
        } catch (error) {
          console.error('Failed to send image:', error);
          const index = this.messages.findIndex(m => m.eventId === tempMessage.eventId);
          if (index >= 0) {
            this.messages[index].status = MessageStatus.FAILED;
          }
        }
      } catch (error) {
        console.error('Failed to upload image: %{public}s', JSON.stringify(error));
        promptAction.showToast({ message: '图片上传失败' });
      }
    }
    if (uris.length > 1) {
      promptAction.showToast({ message: `已发送 ${uris.length} 张图片` });
    }
  }

  async loadMessages() {
    try {
      const roomMessages = await this.roomManager.getRoomMessages(this.roomId, 50);
      this.messages = roomMessages.reverse();
    } catch (error) {
      console.error('Failed to load messages:', error);
    } finally {
      this.isLoading = false;
    }
  }

  async sendMessage() {
    if (!this.inputText.trim() && !this.replyQuote) {
      return;
    }

    const messageText = this.inputText.trim();
    this.inputText = '';

    if (this.typingStopTimeout) {
      clearTimeout(this.typingStopTimeout);
      this.typingStopTimeout = 0;
    }
    this.roomManager.stopTyping(this.roomId).catch(() => {
    });

    const msgContent: Record<string, string | object> = {
      'msgtype': 'm.text',
      'body': messageText
    };

    if (this.replyQuote) {
      const inReplyTo: InReplyTo = {
        event_id: this.replyQuote.eventId
      };
      const relatesTo: RelatesTo = {
        'm.in_reply_to': inReplyTo
      };
      msgContent['m.relates_to'] = relatesTo;
      const reference: ReferenceContent = {
        event_id: this.replyQuote.eventId,
        sender: this.replyQuote.sender
      };
      msgContent['m.reference'] = reference;
    }

    const tempMessage: Message = Message.createPendingMessage(this.roomId, msgContent);
    tempMessage.timestamp = Date.now();
    tempMessage.replyEventId = this.replyQuote?.eventId;

    this.messages.push(tempMessage);

    const quotedEventId = this.replyQuote?.eventId;
    this.replyQuote = null;

    try {
      const messageManager = await import('../services/MessageManager');
      await messageManager.MessageManager.getInstance().sendMessage(this.roomId, 'm.room.message', msgContent);

      const index = this.messages.findIndex(m => m.eventId === tempMessage.eventId);
      if (index >= 0) {
        this.messages[index].status = MessageStatus.SENT;
      }
    } catch (error) {
      console.error('Failed to send message:', error);
      const index = this.messages.findIndex(m => m.eventId === tempMessage.eventId);
      if (index >= 0) {
        this.messages[index].status = MessageStatus.FAILED;
      }
      promptAction.showToast({ message: '发送失败' });
    }
  }

  async leaveRoom() {
    try {
      await this.roomManager.leaveRoom(this.roomId);
      promptAction.showToast({ message: '已离开房间' });
      this.pathStack?.pop();
    } catch (error) {
      console.error('Failed to leave room:', error);
      promptAction.showToast({ message: '离开失败' });
    }
  }

  shareRoom() {
    const homeserver = this.authManager.getHomeserver() || '';
    this.shareManager.shareRoomLink(this.roomId, this.roomName, homeserver);
  }

  startReply(message: Message) {
    this.replyQuote = {
      eventId: message.eventId,
      sender: message.sender,
      body: message.getMessageBody()
    };
    this.showReplyMenu = false;
    this.selectedMessage = null;
  }

  cancelReply() {
    this.replyQuote = null;
  }

  copyMessage(message: Message) {
    try {
      promptAction.showToast({ message: '消息已复制' });
    } catch (error) {
      console.error('Failed to copy message:', error);
    }
    this.showMessageAction = false;
    this.selectedMessage = null;
  }

  shareMessage(message: Message) {
    const body = message.getMessageBody();
    const senderName = this.getMessageSenderName(message);
    this.shareManager.shareMessage(body, senderName);
    this.showReplyMenu = false;
    this.selectedMessage = null;
  }

  checkMessageSecurity(message: Message) {
    const body = message.getMessageBody();
    const senderId = message.sender;
    const result = this.deviceSecurityManager.analyzeMessageSecurity(body, senderId);

    if (result.isSuspicious) {
      promptAction.showToast({
        message: `安全提醒: ${result.warnings.join(', ')}`,
        duration: 4000
      });
    } else {
      promptAction.showToast({
        message: '消息安全检测通过',
        duration: 2000
      });
    }

    this.showReplyMenu = false;
    this.selectedMessage = null;
  }

  async deleteMessage(message: Message) {
    if (!message.eventId || message.eventId.startsWith('temp_')) {
      const index = this.messages.findIndex(m => m.eventId === message.eventId);
      if (index >= 0) {
        this.messages.splice(index, 1);
      }
      this.showMessageAction = false;
      this.selectedMessage = null;
      return;
    }

    try {
      await this.messageManager.deleteMessage(this.roomId, message.eventId);
      const index = this.messages.findIndex(m => m.eventId === message.eventId);
      if (index >= 0) {
        this.messages.splice(index, 1);
      }
      promptAction.showToast({ message: '消息已删除' });
    } catch (error) {
      console.error('Failed to delete message:', error);
      promptAction.showToast({ message: '删除失败' });
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

    if (!this.editingMessage.eventId || this.editingMessage.eventId.startsWith('temp_')) {
      promptAction.showToast({ message: '消息尚未发送，无法编辑' });
      this.cancelEdit();
      return;
    }

    try {
      await this.messageManager.editMessage(this.roomId, this.editingMessage.eventId, this.editText.trim());
      const index = this.messages.findIndex(m => m.eventId === this.editingMessage!.eventId);
      if (index >= 0) {
        const newContent: Record<string, string | object> = {
          'msgtype': 'm.text',
          'body': this.editText.trim()
        };
        this.messages[index].content = newContent;
      }
      promptAction.showToast({ message: '消息已编辑' });
    } catch (error) {
      console.error('Failed to edit message:', error);
      promptAction.showToast({ message: '编辑失败' });
    }
    this.cancelEdit();
  }

  cancelEdit() {
    this.editingMessage = null;
    this.editText = '';
    this.showReplyMenu = false;
    this.selectedMessage = null;
  }

  startVoiceCall() {
    promptAction.showToast({ message: '语音通话功能开发中' });
  }

  startVideoCall() {
    promptAction.showToast({ message: '视频通话功能开发中' });
  }

  getReplySenderName(sender: string): string {
    const colonIndex = sender.indexOf(':');
    return colonIndex > 0 ? sender.substring(1, colonIndex) : sender;
  }

  formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    return date.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' });
  }

  getRoomThemeColors(): RoomDetailThemeColors {
    const base = getThemeColors();
    return {
      bg: base.bg,
      text: base.text,
      textSecondary: base.textSecondary,
      inputBg: base.inputBg,
      primary: base.primary,
      error: '#e53935',
      divider: base.divider,
      headerBg: base.surface,
      messageBg: base.surface,
      outgoingBg: '#10a37f'
    };
  }

  getTimeGroupLabel(timestamp: number): string {
    const date = new Date(timestamp);
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    if (date.toDateString() === today.toDateString()) {
      return '今天';
    } else if (date.toDateString() === yesterday.toDateString()) {
      return '昨天';
    } else {
      return date.toLocaleDateString('zh-CN', { month: 'long', day: 'numeric' });
    }
  }

  shouldShowTimeGroup(index: number): boolean {
    if (index === 0) {
      return true;
    }
    const currentTime = this.messages[index].timestamp;
    const prevTime = this.messages[index - 1].timestamp;
    const currentDate = new Date(currentTime).toDateString();
    const prevDate = new Date(prevTime).toDateString();
    return currentDate !== prevDate;
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          Row() {
            Column() {
              Text(this.roomName)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .fontColor(this.getRoomThemeColors().text);
              if (this.roomTopic) {
                Text(this.roomTopic)
                  .fontSize(12)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .fontColor(this.getRoomThemeColors().textSecondary);
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start);

            Button('Eyes')
              .fontSize(18)
              .backgroundColor('transparent')
              .fontColor(this.getRoomThemeColors().textSecondary)
              .width(36)
              .height(36)
              .onClick(() => {
                this.showMembersPanel = !this.showMembersPanel;
              });

            Button('Phone')
              .fontSize(16)
              .backgroundColor('transparent')
              .fontColor(this.getRoomThemeColors().textSecondary)
              .width(36)
              .height(36)
              .onClick(() => {
                this.startVoiceCall();
              });

            Image($r('app.media.menu'))
              .width(24)
              .height(24)
              .objectFit(ImageFit.Contain)
              .fillColor(this.getRoomThemeColors().textSecondary)
              .onClick(() => {
                this.showMenu = !this.showMenu;
              });
          }
          .width('100%')
          .height(56)
          .padding({ left: 10, right: 10 })
          .backgroundColor(this.getRoomThemeColors().headerBg);

          if (this.showMenu) {
            Column() {
              Button('分享房间')
                .fontSize(16)
                .backgroundColor(this.getRoomThemeColors().bg)
                .fontColor(this.getRoomThemeColors().primary)
                .width('100%')
                .height(44)
                .onClick(() => {
                  this.showMenu = false;
                  this.shareRoom();
                });
              Button('离开房间')
                .fontSize(16)
                .backgroundColor(this.getRoomThemeColors().bg)
                .fontColor(this.getRoomThemeColors().error)
                .width('100%')
                .height(44)
                .onClick(() => {
                  this.showMenu = false;
                  this.leaveRoom();
                });
            }
            .width(160)
            .backgroundColor(this.getRoomThemeColors().bg)
            .borderRadius(8)
            .shadow({
              radius: 10,
              color: 'rgba(0, 0, 0, 0.15)',
              offsetX: 0,
              offsetY: 2
            })
            .position({ x: '60%', y: 60 })
            .onClick(() => {
              this.showMenu = false;
            });
          }

          if (this.typingUsers.length > 0) {
            Row() {
              Text('对方正在输入...')
                .fontSize(12)
                .fontColor(this.getRoomThemeColors().textSecondary)
                .margin({ left: 15, top: 5, bottom: 5 });
            }
            .width('100%')
            .backgroundColor(this.getRoomThemeColors().bg);
          }

          if (this.replyQuote) {
            Row() {
              Column() {
                Row() {
                  Text('回复: ')
                    .fontSize(12)
                    .fontColor(this.getRoomThemeColors().primary);
                  Text(this.getReplySenderName(this.replyQuote.sender))
                    .fontSize(12)
                    .fontColor(this.getRoomThemeColors().textSecondary);
                }

                Text(this.replyQuote.body)
                  .fontSize(12)
                  .fontColor(this.getRoomThemeColors().textSecondary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis });
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1);

              Button('✕')
                .fontSize(12)
                .backgroundColor('transparent')
                .fontColor(this.getRoomThemeColors().textSecondary)
                .width(24)
                .height(24)
                .onClick(() => {
                  this.cancelReply();
                });
            }
            .width('100%')
            .padding({
              left: 15,
              right: 10,
              top: 8,
              bottom: 8
            })
            .backgroundColor(this.getRoomThemeColors().inputBg);
          }

          if (this.editingMessage) {
            Row() {
              Column() {
                Row() {
                  Text('编辑消息')
                    .fontSize(12)
                    .fontColor(this.getRoomThemeColors().primary);
                  Text(': ')
                    .fontSize(12)
                    .fontColor(this.getRoomThemeColors().textSecondary);
                  Text(this.editingMessage.getMessageBody())
                    .fontSize(12)
                    .fontColor(this.getRoomThemeColors().textSecondary)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1);
                }

                TextInput({ text: this.editText, placeholder: '输入修改后的消息' })
                  .fontSize(14)
                  .backgroundColor(this.getRoomThemeColors().bg)
                  .borderRadius(8)
                  .height(36)
                  .margin({ top: 4 })
                  .onChange((value: string) => {
                    this.editText = value;
                  });
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1);

              Column() {
                Button('✕')
                  .fontSize(12)
                  .backgroundColor('transparent')
                  .fontColor(this.getRoomThemeColors().textSecondary)
                  .width(24)
                  .height(24)
                  .onClick(() => {
                    this.cancelEdit();
                  });

                Button('保存')
                  .fontSize(12)
                  .backgroundColor(this.getRoomThemeColors().primary)
                  .fontColor('#ffffff')
                  .width(48)
                  .height(28)
                  .borderRadius(6)
                  .margin({ top: 4 })
                  .enabled(this.editText.trim().length > 0)
                  .onClick(() => {
                    this.saveEdit();
                  });
              }
              .alignItems(HorizontalAlign.Center);
            }
            .width('100%')
            .padding({
              left: 15,
              right: 10,
              top: 8,
              bottom: 8
            })
            .backgroundColor(this.getRoomThemeColors().inputBg);
          }

          if (this.isLoading) {
            Column() {
              LoadingProgress()
                .width(40)
                .height(40)
                .color(this.getRoomThemeColors().primary);
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center);
          } else if (this.messages.length === 0) {
            Column() {
              Text('暂无消息')
                .fontSize(16)
                .fontColor(this.getRoomThemeColors().textSecondary);
              Text('发送第一条消息')
                .fontSize(14)
                .fontColor(this.getRoomThemeColors().textSecondary)
                .opacity(0.6)
                .margin({ top: 5 });
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center);
          } else {
            List({ scroller: this.scroller }) {
              ForEach(this.messages, (message: Message, index: number) => {
                ListItem() {
                  Column() {
                    if (this.shouldShowTimeGroup(index)) {
                      Text(this.getTimeGroupLabel(message.timestamp))
                        .fontSize(12)
                        .fontColor(this.getRoomThemeColors().textSecondary)
                        .padding({ top: 10, bottom: 5 });
                    }
                    if (message.isOutgoing) {
                      this.outgoingMessage(message);
                    } else {
                      this.incomingMessage(message);
                    }
                  }
                  .width('100%');
                }
              });
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
            });
          }

          Row() {
            if (!this.editingMessage) {
              TextInput({ placeholder: '输入消息...', text: this.inputText })
                .fontSize(16)
                .backgroundColor(this.getRoomThemeColors().inputBg)
                .borderRadius(20)
                .height(40)
                .layoutWeight(1)
                .onChange((value: string) => {
                  this.onInputChange(value);
                })
                .onSubmit(() => {
                  this.sendMessage();
                });
            }

            Button('Voice')
              .fontSize(16)
              .backgroundColor('transparent')
              .fontColor(this.getRoomThemeColors().textSecondary)
              .borderRadius(20)
              .width(36)
              .height(36)
              .margin({ left: 5 })
              .onClick(() => {
                this.startVoiceCall();
              });

            Row() {
              Button('Photo')
                .fontSize(18)
                .backgroundColor('transparent')
                .fontColor(this.getRoomThemeColors().textSecondary)
                .borderRadius(20)
                .width(40)
                .height(40)
                .margin({ left: 5 })
                .onClick(() => {
                  this.pickAndUploadImage();
                });

              Button('Image')
                .fontSize(18)
                .backgroundColor('transparent')
                .fontColor(this.getRoomThemeColors().textSecondary)
                .borderRadius(20)
                .width(40)
                .height(40)
                .margin({ left: 5 })
                .onClick(() => {
                  this.pickAndUploadImage();
                });
            }

            Button('Send')
              .fontSize(16)
              .fontColor('#ffffff')
              .backgroundColor(this.getRoomThemeColors().primary)
              .borderRadius(20)
              .width(60)
              .height(40)
              .margin({ left: 5 })
              .enabled(this.inputText.trim().length > 0 && !this.editingMessage)
              .onClick(() => {
                this.sendMessage();
              });
          }
          .width('100%')
          .padding({
            left: 15,
            right: 15,
            top: 10,
            bottom: 10
          })
          .backgroundColor(this.getRoomThemeColors().bg);
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.getRoomThemeColors().bg);

        if (this.showMembersPanel) {
          Column() {
            Row() {
              Text('成员列表')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.getRoomThemeColors().text);
              Blank();
              Button('✕')
                .fontSize(16)
                .backgroundColor('transparent')
                .fontColor(this.getRoomThemeColors().textSecondary)
                .width(30)
                .height(30)
                .onClick(() => {
                  this.showMembersPanel = false;
                });
            }
            .width('100%')
            .padding({
              left: 15,
              right: 15,
              top: 12,
              bottom: 12
            });

            Divider().color(this.getRoomThemeColors().divider);

            if (this.memberPresences.length === 0) {
              Text('暂无成员信息')
                .fontSize(14)
                .fontColor(this.getRoomThemeColors().textSecondary)
                .padding(15);
            } else {
              Scroll() {
                Column() {
                  ForEach(this.memberPresences, (member: MemberPresence) => {
                    Row() {
                      Stack() {
                        Text(member.displayName.charAt(0).toUpperCase())
                          .fontSize(16)
                          .fontWeight(FontWeight.Bold)
                          .fontColor('#ffffff')
                          .width(36)
                          .height(36)
                          .borderRadius(18)
                          .backgroundColor(this.getRoomThemeColors().primary)
                          .textAlign(TextAlign.Center);

                        Circle()
                          .width(10)
                          .height(10)
                          .fill(this.getPresenceColor(member.presence))
                          .stroke(this.getRoomThemeColors().bg)
                          .strokeWidth(1.5)
                          .position({ x: 26, y: 26 });
                      }
                      .width(36)
                      .height(36)
                      .margin({ right: 12 });

                      Column() {
                        Text(member.displayName)
                          .fontSize(14)
                          .fontColor(this.getRoomThemeColors().text);
                        Text(this.getPresenceText(member.presence))
                          .fontSize(12)
                          .fontColor(this.getRoomThemeColors().textSecondary);
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1);

                      Text(member.userId.split(':')[0].replace('@', ''))
                        .fontSize(11)
                        .fontColor(this.getRoomThemeColors().textSecondary);
                    }
                    .width('100%')
                    .padding({
                      left: 15,
                      right: 15,
                      top: 10,
                      bottom: 10
                    });
                  });
                }
                .width('100%');
              }
              .layoutWeight(1);
            }
          }
          .width('70%')
          .height('100%')
          .backgroundColor(this.getRoomThemeColors().bg)
          .shadow({
            radius: 10,
            color: 'rgba(0, 0, 0, 0.15)',
            offsetX: -2,
            offsetY: 0
          })
          .position({ x: '30%', y: 0 });
        }

        if (this.showReplyMenu && this.selectedMessage) {
          Column() {
            Column() {
              Text('回复')
                .fontSize(14)
                .fontColor(this.getRoomThemeColors().text)
                .width('100%')
                .padding({ left: 15, top: 12, bottom: 12 })
                .onClick(() => {
                  this.startReply(this.selectedMessage!);
                });

              Divider().color(this.getRoomThemeColors().divider);

              Text('复制')
                .fontSize(14)
                .fontColor(this.getRoomThemeColors().text)
                .width('100%')
                .padding({ left: 15, top: 12, bottom: 12 })
                .onClick(() => {
                  this.copyMessage(this.selectedMessage!);
                });

              if (this.selectedMessage.isOutgoing) {
                Divider().color(this.getRoomThemeColors().divider);

                Text('删除')
                  .fontSize(14)
                  .fontColor(this.getRoomThemeColors().error)
                  .width('100%')
                  .padding({ left: 15, top: 12, bottom: 12 })
                  .onClick(() => {
                    this.deleteMessage(this.selectedMessage!);
                  });

                Divider().color(this.getRoomThemeColors().divider);

                Text('编辑')
                  .fontSize(14)
                  .fontColor(this.getRoomThemeColors().primary)
                  .width('100%')
                  .padding({ left: 15, top: 12, bottom: 12 })
                  .onClick(() => {
                    this.startEdit(this.selectedMessage!);
                  });
              }

              Divider().color(this.getRoomThemeColors().divider);

              Text('安全检测')
                .fontSize(14)
                .fontColor('#FF9800')
                .width('100%')
                .padding({ left: 15, top: 12, bottom: 12 })
                .onClick(() => {
                  this.checkMessageSecurity(this.selectedMessage!);
                });

              Divider().color(this.getRoomThemeColors().divider);

              Text('分享')
                .fontSize(14)
                .fontColor(this.getRoomThemeColors().primary)
                .width('100%')
                .padding({ left: 15, top: 12, bottom: 12 })
                .onClick(() => {
                  this.shareMessage(this.selectedMessage!);
                });

              Divider().color(this.getRoomThemeColors().divider);

              Text('取消')
                .fontSize(14)
                .fontColor(this.getRoomThemeColors().textSecondary)
                .width('100%')
                .padding({ left: 15, top: 12, bottom: 12 })
                .onClick(() => {
                  this.showReplyMenu = false;
                  this.selectedMessage = null;
                });
            }
            .width(160)
            .backgroundColor(this.getRoomThemeColors().bg)
            .borderRadius(8)
            .shadow({
              radius: 10,
              color: 'rgba(0, 0, 0, 0.15)',
              offsetX: 0,
              offsetY: 2
            });
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('rgba(0, 0, 0, 0.3)')
          .onClick(() => {
            this.showReplyMenu = false;
            this.selectedMessage = null;
          });
        }
      }
      .width('100%')
      .height('100%');
    }
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
    })
  }

  @Builder
  outgoingMessage(message: Message) {
    Column() {
      if (message.replyEventId) {
        Row() {
          Text('↳ ')
            .fontSize(12)
            .fontColor(this.getRoomThemeColors().primary);
          Text('回复消息')
            .fontSize(12)
            .fontColor(this.getRoomThemeColors().textSecondary);
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 4 });
      }

      if (message.isImageMessage()) {
        Image(this.mediaManager.getThumbnailUrl(message.content['url'] as string, 200, 200, 'scale'))
          .width(200)
          .height(200)
          .borderRadius(18)
          .objectFit(ImageFit.Cover)
          .margin(8)
          .onClick(() => {
            promptAction.showToast({ message: '图片: ' + message.getMessageBody() });
          })
          .gesture(
            LongPressGesture()
              .onAction(() => {
                this.selectedMessage = message;
                this.showReplyMenu = true;
              })
          );
      } else if (message.isFileMessage()) {
        Row() {
          Image($r('app.media.add'))
            .width(40)
            .height(40)
            .borderRadius(8)
            .backgroundColor(this.getRoomThemeColors().inputBg)
            .padding(8);
          Column() {
            Text(message.getMessageBody())
              .fontSize(14)
              .fontColor('#ffffff')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
            Text('文件')
              .fontSize(12)
              .fontColor('#cccccc');
          }
          .layoutWeight(1)
          .margin({ left: 8 });
        }
        .backgroundColor(this.getRoomThemeColors().outgoingBg)
        .borderRadius(18)
        .padding(12)
        .alignItems(VerticalAlign.Center)
        .gesture(
          LongPressGesture()
            .onAction(() => {
              this.selectedMessage = message;
              this.showReplyMenu = true;
            })
        );
      } else {
        Row() {
          Text(message.getMessageBody())
            .fontSize(16)
            .fontColor('#ffffff')
            .margin({
              left: 12,
              right: 12,
              top: 8,
              bottom: 8
            });

          if (message.status === MessageStatus.SENDING) {
            Text('...')
              .fontSize(12)
              .fontColor('#cccccc')
              .margin({ right: 8 });
          } else if (message.status === MessageStatus.FAILED) {
            Text('!')
              .fontSize(12)
              .fontColor('#e53935')
              .margin({ right: 8 });
          }
        }
        .backgroundColor(this.getRoomThemeColors().outgoingBg)
        .borderRadius(18)
        .alignItems(VerticalAlign.Bottom)
        .gesture(
          LongPressGesture()
            .onAction(() => {
              this.selectedMessage = message;
              this.showReplyMenu = true;
            })
        );
      }

      Text(this.formatTime(message.timestamp))
        .fontSize(11)
        .fontColor(this.getRoomThemeColors().textSecondary)
        .margin({ top: 2 });
    }
    .width('100%')
    .alignItems(HorizontalAlign.End)
    .margin({ top: 5, bottom: 5 });
  }

  @Builder
  incomingMessage(message: Message) {
    Column() {
      if (message.replyEventId) {
        Row() {
          Text('↳ ')
            .fontSize(12)
            .fontColor(this.getRoomThemeColors().primary);
          Text('回复消息')
            .fontSize(12)
            .fontColor(this.getRoomThemeColors().textSecondary);
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 4 });
      }

      if (message.isImageMessage()) {
        Image(this.mediaManager.getThumbnailUrl(message.content['url'] as string, 200, 200, 'scale'))
          .width(200)
          .height(200)
          .borderRadius(18)
          .objectFit(ImageFit.Cover)
          .margin(8)
          .onClick(() => {
            promptAction.showToast({ message: '图片: ' + message.getMessageBody() });
          })
          .gesture(
            LongPressGesture()
              .onAction(() => {
                this.selectedMessage = message;
                this.showReplyMenu = true;
              })
          );
      } else if (message.isFileMessage()) {
        Row() {
          Image($r('app.media.add'))
            .width(40)
            .height(40)
            .borderRadius(8)
            .backgroundColor(this.getRoomThemeColors().inputBg)
            .padding(8);
          Column() {
            Text(message.getMessageBody())
              .fontSize(14)
              .fontColor(this.getRoomThemeColors().text)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
            Text('文件')
              .fontSize(12)
              .fontColor(this.getRoomThemeColors().textSecondary);
          }
          .layoutWeight(1)
          .margin({ left: 8 });
        }
        .backgroundColor(this.getRoomThemeColors().messageBg)
        .borderRadius(18)
        .padding(12)
        .alignItems(VerticalAlign.Center)
        .gesture(
          LongPressGesture()
            .onAction(() => {
              this.selectedMessage = message;
              this.showReplyMenu = true;
            })
        );
      } else {
        Row() {
          Text(message.getMessageBody())
            .fontSize(16)
            .fontColor(this.getRoomThemeColors().text)
            .margin({
              left: 12,
              right: 12,
              top: 8,
              bottom: 8
            });
        }
        .backgroundColor(this.getRoomThemeColors().messageBg)
        .borderRadius(18)
        .alignItems(VerticalAlign.Bottom)
        .gesture(
          LongPressGesture()
            .onAction(() => {
              this.selectedMessage = message;
              this.showReplyMenu = true;
            })
        );
      }

      Text(this.formatTime(message.timestamp))
        .fontSize(11)
        .fontColor(this.getRoomThemeColors().textSecondary)
        .margin({ top: 2 });
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 5, bottom: 5 });
  }

  getPresenceText(presence: PresenceState): string {
    switch (presence) {
      case 'online':
        return '在线';
      case 'offline':
        return '离线';
      case 'unavailable':
        return '离开';
      default:
        return '未知';
    }
  }

  getPresenceColor(presence: PresenceState): string {
    switch (presence) {
      case 'online':
        return '#4CAF50';
      case 'offline':
        return '#9E9E9E';
      case 'unavailable':
        return '#FF9800';
      default:
        return '#9E9E9E';
    }
  }

  getMessageSenderName(message: Message): string {
    return message.sender.split(':')[0].replace('@', '');
  }
}