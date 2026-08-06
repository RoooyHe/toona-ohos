import { ToastUtils } from '../utils/ToastUtils';
import { QuickDialogManager, QuickDialogParams, QuickDialogController } from 'quickdialog';
import { Message } from '../models/DataModels';
import { ServiceRegistry } from '../services/ServiceRegistry';
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
import { getTimeGroupLabel, shouldShowTimeGroup } from '../utils/MessageFormatter';
import { RoomDetailViewModel, RoomDetailState } from '../viewmodels/RoomDetailViewModel';
import { MemberPresence } from '../services/RoomMetadataLoader';
import { ReplyQuoteData } from '../services/MessageActionHandler';
import { media } from '@kit.MediaKit';
import curves from '@ohos.curves';

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
  private recordingDialogController: QuickDialogController | undefined = undefined;
  pathStack: NavPathStack = new NavPathStack();
  private viewModel: RoomDetailViewModel | null = null;

  aboutToAppear() {
    const registry = ServiceRegistry.getCurrent();
    this.viewModel = new RoomDetailViewModel(this.roomId, this.roomName, registry);

    const self = this;
    this.viewModel.setLeaveRoomCallback(() => {
      ToastUtils.show('已离开房间');
      self.pathStack.pop();
    });

    this.viewModel.setOnStateChanged((state: RoomDetailState) => {
      self.messages = state.messages;
      self.isLoading = state.isLoading;
      self.typingUsers = state.typingUsers;
      self.memberPresences = state.memberPresences;
      self.roomTopic = state.roomTopic;
      self.roomName = state.roomName;
      self.hasMoreMessages = state.hasMoreMessages;
      self.isLoadingMore = state.isLoadingMore;
      self.isRecording = state.isRecording;
      self.replyQuote = state.replyQuote;
      self.editingMessage = state.editingMessage;
      self.editText = state.editText;
      self.inputText = state.inputText;
      self.selectedMessage = state.selectedMessage;
    });

    this.viewModel.initialize();
  }

  aboutToDisappear() {
    if (this.viewModel) {
      this.viewModel.destroy();
    }
  }

  async onInputChange(text: string) {
    if (!this.viewModel) return;
    this.viewModel.onInputChange(text);
  }

  async handleSelectImage() {
    if (!this.viewModel) return;
    await this.viewModel.handleSelectImage();
  }

  async startRecording() {
    if (!this.viewModel) return;
    const context: Object = getContext(this);
    const result: Object | null = await this.viewModel.startRecording(context);
    if (result) {
      const recordData: Record<string, Object> = result as Record<string, Object>;
      this.avRecorder = recordData['avRecorder'] as media.AVRecorder;
      this.audioPath = recordData['audioPath'] as string;
      this.audioFd = recordData['audioFd'] as number;
      this.viewModel.setRecording(true);
      this.recordingDialogController = QuickDialogManager.newBuilder(
        this.getUIContext(),
        wrapBuilder(RecordingDialogBuilder)
      ).build();
      this.recordingDialogController.show();
    }
  }

  async stopAndSendRecording() {
    if (!this.viewModel || !this.avRecorder || !this.isRecording) return;
    this.recordingDialogController?.dismiss();
    await this.viewModel.stopRecording(this.avRecorder, this.audioPath, this.audioFd);
  }

  async loadMoreMessages() {
    if (!this.viewModel) return;
    await this.viewModel.loadMoreMessages();
  }

  async sendMessage() {
    if (!this.viewModel) return;
    await this.viewModel.sendMessage();
  }

  async leaveRoom() {
    if (!this.viewModel) return;
    await this.viewModel.leaveRoom();
  }

  shareRoom() {
    if (!this.viewModel) return;
    this.viewModel.shareRoom();
  }

  startReply(message: Message) {
    if (!this.viewModel) return;
    this.viewModel.startReply(message);
    this.showReplyMenu = false;
  }

  cancelReply() {
    if (!this.viewModel) return;
    this.viewModel.cancelReply();
  }

  copyMessage(message: Message): void {
    if (!this.viewModel) return;
    this.viewModel.copyMessage(message);
    this.showMessageAction = false;
  }

  shareMessage(message: Message) {
    if (!this.viewModel) return;
    this.viewModel.shareMessage(message);
    this.showReplyMenu = false;
  }

  checkMessageSecurity(message: Message) {
    if (!this.viewModel) return;
    this.viewModel.checkMessageSecurity(message);
    this.showReplyMenu = false;
  }

  async deleteMessage(message: Message) {
    if (!this.viewModel) return;
    await this.viewModel.deleteMessage(message);
    this.showMessageAction = false;
  }

  startEdit(message: Message) {
    if (!this.viewModel) return;
    this.viewModel.startEdit(message);
    this.showReplyMenu = false;
  }

  async saveEdit() {
    if (!this.viewModel) return;
    await this.viewModel.saveEdit();
  }

  cancelEdit() {
    if (!this.viewModel) return;
    this.viewModel.cancelEdit();
  }

  startVoiceCall() {
    ToastUtils.show('语音通话功能开发中');
  }

  startVideoCall() {
    ToastUtils.show('视频通话功能开发中');
  }

  onMessageLongPress(message: Message) {
    if (!this.viewModel) return;
    this.viewModel.onMessageLongPress(message);
    this.showReplyMenu = true;
  }

  navigateToRoomSettings() {
    ToastUtils.show('房间设置');
  }

  async sendReaction(emoji: string) {
    if (!this.viewModel) return;
    await this.viewModel.sendReaction(emoji);
    this.showReactionPicker = false;
  }

  async sendSticker(stickerUrl: string, stickerBody: string) {
    if (!this.viewModel) return;
    await this.viewModel.sendSticker(stickerUrl, stickerBody);
    this.showStickerPicker = false;
  }

  async forwardMessage(message: Message) {
    if (!this.viewModel) return;
    await this.viewModel.forwardMessage(message);
    this.showMessageAction = false;
  }

  async pinMessage(message: Message) {
    if (!this.viewModel) return;
    await this.viewModel.pinMessage(message);
    this.showMessageAction = false;
  }

  viewMessageSource(message: Message) {
    if (!this.viewModel) return;
    this.viewModel.viewMessageSource(message);
    this.showMessageAction = false;
  }

  async reportMessage(reason: string) {
    if (!this.viewModel) return;
    await this.viewModel.reportMessage(reason);
    this.showReportDialog = false;
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
          if (this.viewModel) {
            this.viewModel.startEdit(this.editingMessage!);
          }
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
                    isOutgoing: message.sender === (this.viewModel?.getUserId() || ''),
                    mediaManager: this.viewModel?.getMediaManager()!,
                    verificationService: this.viewModel?.getVerificationService()!,
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
