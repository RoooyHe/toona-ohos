import promptAction from '@ohos.promptAction';
import { Message, MessageStatus } from '../../models/DataModels';
import { MediaManager } from '../../services/MediaManager';
import { getThemeColors } from '../../utils/ThemeManager';

interface BubbleThemeColors {
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

@Component
export struct MessageBubble {
  @ObjectLink message: Message;
  isOutgoing: boolean = false;
  onLongPress: (message: Message) => void = () => {};
  private mediaManager: MediaManager = MediaManager.getInstance();

  aboutToAppear(): void {
  }

  getThemeColors(): BubbleThemeColors {
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

  formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    return date.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' });
  }

  build() {
    Column() {
      if (this.message.replyEventId) {
        Row() {
          Text('↳ ')
            .fontSize(12)
            .fontColor(this.getThemeColors().primary);
          Text('回复消息')
            .fontSize(12)
            .fontColor(this.getThemeColors().textSecondary);
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 4 });
      }

      if (this.message.isImageMessage()) {
        // 1. 图片消息气泡
        Image(this.mediaManager.getThumbnailUrl(this.message.content['url'] as string, 200, 200, 'scale'))
          .width(200)
          .height(200)
          .borderRadius(18)
          .objectFit(ImageFit.Cover)
          .margin(8)
          .onClick(() => {
            promptAction.showToast({ message: '图片: ' + this.message.getMessageBody() });
          })
          .gesture(
            LongPressGesture()
              .onAction(() => {
                this.onLongPress(this.message);
              })
          );
      } else if (this.message.content && this.message.content['msgtype'] === 'm.audio') {
        // ✅ 2. 新增：语音/音频消息气泡
        Row() {
          // 播放图标 (暂时复用麦克风图标 app.media.phone，有播放图标可以替换成 app.media.play)
          Image($r('app.media.phone'))
            .width(20)
            .height(20)
            .fillColor(this.isOutgoing ? '#ffffff' : this.getThemeColors().primary)

          Text('语音消息')
            .fontSize(16)
            .fontColor(this.isOutgoing ? '#ffffff' : this.getThemeColors().text)
            .margin({ left: 8 })

          if (this.message.status === MessageStatus.SENDING) {
            Text('...')
              .fontSize(12)
              .fontColor('#cccccc')
              .margin({ left: 8 });
          } else if (this.message.status === MessageStatus.FAILED) {
            Text('!')
              .fontSize(12)
              .fontColor('#e53935')
              .margin({ left: 8 });
          }
        }
        .backgroundColor(this.isOutgoing ? this.getThemeColors().outgoingBg : this.getThemeColors().messageBg)
        .borderRadius(18)
        .padding({ left: 16, right: 16, top: 10, bottom: 10 }) // 加大 padding，让气泡饱满
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          promptAction.showToast({ message: '语音播放功能开发中...' });
        })
        .gesture(
          LongPressGesture()
            .onAction(() => {
              this.onLongPress(this.message);
            })
        );
      } else if (this.message.isFileMessage()) {
        // 3. 其他文件附件气泡
        Row() {
          Image($r('app.media.add'))
            .width(40)
            .height(40)
            .borderRadius(8)
            .backgroundColor(this.getThemeColors().inputBg)
            .padding(8);
          Column() {
            Text(this.message.getMessageBody())
              .fontSize(14)
              .fontColor(this.isOutgoing ? '#ffffff' : this.getThemeColors().text)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
            Text('文件')
              .fontSize(12)
              .fontColor(this.isOutgoing ? '#cccccc' : this.getThemeColors().textSecondary);
          }
          .layoutWeight(1)
          .margin({ left: 8 });
        }
        .backgroundColor(this.isOutgoing ? this.getThemeColors().outgoingBg : this.getThemeColors().messageBg)
        .borderRadius(18)
        .padding(12)
        .alignItems(VerticalAlign.Center)
        .gesture(
          LongPressGesture()
            .onAction(() => {
              this.onLongPress(this.message);
            })
        );
      } else {
        // 4. 普通文本消息气泡
        Row() {
          Text(this.message.getMessageBody())
            .fontSize(16)
            .fontColor(this.isOutgoing ? '#ffffff' : this.getThemeColors().text)
            .margin({
              left: 12,
              right: 12,
              top: 8,
              bottom: 8
            });

          if (this.message.status === MessageStatus.SENDING) {
            Text('...')
              .fontSize(12)
              .fontColor('#cccccc')
              .margin({ right: 8 });
          } else if (this.message.status === MessageStatus.FAILED) {
            Text('!')
              .fontSize(12)
              .fontColor('#e53935')
              .margin({ right: 8 });
          }
        }
        .backgroundColor(this.isOutgoing ? this.getThemeColors().outgoingBg : this.getThemeColors().messageBg)
        .borderRadius(18)
        .alignItems(VerticalAlign.Bottom)
        .gesture(
          LongPressGesture()
            .onAction(() => {
              this.onLongPress(this.message);
            })
        );
      }

      Text(this.formatTime(this.message.timestamp))
        .fontSize(11)
        .fontColor(this.getThemeColors().textSecondary)
        .margin({ top: 2 });
    }
    .width('100%')
    .alignItems(this.isOutgoing ? HorizontalAlign.End : HorizontalAlign.Start)
    .margin({ top: 5, bottom: 5 });
  }
}