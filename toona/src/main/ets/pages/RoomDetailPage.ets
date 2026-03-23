import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { RoomManager } from '../services/RoomManager';
import { Message, Room } from '../models/DataModels';
import { SyncManager } from '../services/SyncManager';
import { MessageStatus } from '../models/MatrixTypes';

@Entry
struct RoomDetailPage {
  @State roomId: string = '';
  @State roomName: string = '';
  @State messages: Message[] = [];
  @State inputText: string = '';
  @State isLoading: boolean = true;
  @State showMenu: boolean = false;
  private roomManager: RoomManager = RoomManager.getInstance();
  private syncManager: SyncManager = SyncManager.getInstance();
  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params) {
      this.roomId = params.roomId || '';
      this.roomName = params.roomName || '聊天室';
    }
    this.loadMessages();

    this.syncManager.setRoomLeftCallback((leftRoomId: string) => {
      if (leftRoomId === this.roomId) {
        promptAction.showToast({ message: '已离开房间' });
        router.back();
      }
    });

    this.syncManager.setNewMessagesCallback((msgRoomId: string, newMessages: Room[]) => {
      if (msgRoomId === this.roomId) {
        this.loadMessages();
      }
    });
  }

  aboutToDisappear() {
    this.syncManager.clearAllCallbacks();
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
    if (!this.inputText.trim()) {
      return;
    }

    const messageText = this.inputText.trim();
    this.inputText = '';

    const msgContent: Record<string, string | object> = {
      'msgtype': 'm.text',
      'body': messageText
    };

    const tempMessage: Message = Message.createPendingMessage(this.roomId, msgContent);
    tempMessage.timestamp = Date.now();

    this.messages.push(tempMessage);

    try {
      const messageManager = await import('../services/MessageManager');
      await messageManager.MessageManager.getInstance().sendTextMessage(this.roomId, messageText);

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
      router.back();
    } catch (error) {
      console.error('Failed to leave room:', error);
      promptAction.showToast({ message: '离开失败' });
    }
  }

  formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    return date.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' });
  }

  build() {
    Column() {
      Row() {
        Button('←')
          .fontSize(24)
          .backgroundColor('transparent')
          .fontColor('#333333')
          .width(44)
          .height(44)
          .onClick(() => {
            router.back();
          });

        Text(this.roomName)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1);

        Button('⋮')
          .fontSize(20)
          .backgroundColor('transparent')
          .fontColor('#333333')
          .width(44)
          .height(44)
          .onClick(() => {
            this.showMenu = !this.showMenu;
          });
      }
      .width('100%')
      .height(56)
      .padding({ left: 10, right: 10 })
      .backgroundColor('#f5f5f5');

      if (this.showMenu) {
        Column() {
          Button('离开房间')
            .fontSize(16)
            .backgroundColor('#ffffff')
            .fontColor('#e53935')
            .width('100%')
            .height(44)
            .onClick(() => {
              this.showMenu = false;
              this.leaveRoom();
            });
        }
        .width('160')
        .backgroundColor('#ffffff')
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

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40);
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else if (this.messages.length === 0) {
        Column() {
          Text('暂无消息')
            .fontSize(16)
            .fontColor('#999999');
          Text('发送第一条消息')
            .fontSize(14)
            .fontColor('#cccccc')
            .margin({ top: 5 });
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else {
        List({ scroller: this.scroller }) {
          ForEach(this.messages, (message: Message) => {
            ListItem() {
              if (message.isOutgoing) {
                this.outgoingMessage(message);
              } else {
                this.incomingMessage(message);
              }
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
        });
      }

      Row() {
        TextInput({ placeholder: '输入消息...', text: this.inputText })
          .fontSize(16)
          .backgroundColor('#f5f5f5')
          .borderRadius(20)
          .height(40)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.inputText = value;
          })
          .onSubmit(() => {
            this.sendMessage();
          });

        Button('发送')
          .fontSize(16)
          .fontColor('#ffffff')
          .backgroundColor('#10a37f')
          .borderRadius(20)
          .width(60)
          .height(40)
          .margin({ left: 10 })
          .enabled(this.inputText.trim().length > 0)
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
      .backgroundColor('#ffffff');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff');
  }

  @Builder
  outgoingMessage(message: Message) {
    Column() {
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
      .backgroundColor('#10a37f')
      .borderRadius(18)
      .alignItems(VerticalAlign.Bottom);

      Text(this.formatTime(message.timestamp))
        .fontSize(11)
        .fontColor('#999999')
        .margin({ top: 2 });
    }
    .width('100%')
    .alignItems(HorizontalAlign.End)
    .margin({ top: 5, bottom: 5 });
  }

  @Builder
  incomingMessage(message: Message) {
    Column() {
      Row() {
        Text(message.getMessageBody())
          .fontSize(16)
          .fontColor('#333333')
          .margin({
            left: 12,
            right: 12,
            top: 8,
            bottom: 8
          });
      }
      .backgroundColor('#f0f0f0')
      .borderRadius(18)
      .alignItems(VerticalAlign.Bottom);

      Text(this.formatTime(message.timestamp))
        .fontSize(11)
        .fontColor('#999999')
        .margin({ top: 2 });
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 5, bottom: 5 });
  }
}
