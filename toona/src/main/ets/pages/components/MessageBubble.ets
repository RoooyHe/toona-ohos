import { ToastUtils } from '../../utils/ToastUtils';
import { Message, MessageStatus } from '../../models/DataModels';
import { MediaManager } from '../../services/MediaManager';
import { getThemeColors } from '../../utils/ThemeManager';
import media from '@ohos.multimedia.media';
import { AppLogger } from '../../utils/AppLogger';


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

const logger = AppLogger.getLogger('MessageBubble');

@Component
export struct MessageBubble {
  @ObjectLink message: Message;
  // 🎙️ 语音相关状态
  @State isPlaying: boolean = false;
  @State playProgress: number = 0;
  private avPlayer: media.AVPlayer | null = null;
  private durationMs: number = 0;
  // 🌀 微信同款动画状态：当前点亮的声波格数 (1, 2, 3)
  @State waveIndex: number = 3; // 默认静止时显示满格(3)
  private animationInterval: number = -1; // 定时器 ID
  isOutgoing: boolean = false;
  onLongPress: (message: Message) => void = () => {
  };
  private mediaManager: MediaManager = MediaManager.getInstance();

  aboutToAppear(): void {
    // 解析语音消息的时长 (如果有的话)
    if (this.message.content && this.message.content['msgtype'] === 'm.audio') {
      const info = this.message.content['info'] as Record<string, Object>;
      if (info && info['duration']) {
        this.durationMs = info['duration'] as number;
      }
    }
  }

  // 计算语音气泡的动态宽度 (最小 80px，最大 240px)
  getVoiceBubbleWidth(): number {
    const minWidth = 80;
    const maxWidth = 240;

    // 如果没有获取到时长，给一个默认宽度
    if (!this.durationMs || this.durationMs <= 0) {
      return 120;
    }

    const durationSeconds = this.durationMs / 1000;
    // 假设 60 秒达到最大宽度，按对数/线性比例计算
    let width = minWidth + (durationSeconds / 60) * (maxWidth - minWidth);
    return Math.min(Math.max(width, minWidth), maxWidth);
  }

  // 格式化时长显示 (如 12")
  getVoiceDurationText(): string {
    if (!this.durationMs || this.durationMs <= 0) {
      return '';
    }
    return `${Math.round(this.durationMs / 1000)}"`;
  }

  // 🔊 播放或暂停语音
  async togglePlayVoice() {
    if (this.isPlaying && this.avPlayer) {
      await this.avPlayer.stop();
      this.isPlaying = false;
      this.playProgress = 0;
      this.stopPlayAnimation(); // ✅ 停止动画
      return;
    }

    try {
      if (!this.avPlayer) {
        this.avPlayer = await media.createAVPlayer();
        this.setupPlayerListeners();
      } else {
        await this.avPlayer.reset();
      }

      const mxcUrl = this.message.content['url'] as string;
      const httpUrl = this.mediaManager.getHttpUrl(mxcUrl);

      this.isPlaying = true;
      this.playProgress = 0;
      this.startPlayAnimation(); // ✅ 启动动画

      this.avPlayer.url = httpUrl;

    } catch (err) {
      logger.error('播放失败:', err);
      this.isPlaying = false;
      this.stopPlayAnimation(); // ✅ 失败时停止动画
      ToastUtils.show('语音播放失败');
    }
  }

  // 🎧 设置播放器监听器
  private setupPlayerListeners() {
    if (!this.avPlayer) {
      return;
    }
    const self = this;

    this.avPlayer.on('stateChange', async (state: string) => {
      switch (state) {
        case 'initialized':
          await self.avPlayer?.prepare();
          break;
        case 'prepared':
          await self.avPlayer?.play();
          break;
        case 'completed':
          self.isPlaying = false;
          self.playProgress = 0;
          self.stopPlayAnimation();
          await self.avPlayer?.stop();
          break;
        case 'stopped':
          self.isPlaying = false;
          self.stopPlayAnimation();
          break;
        case 'error':
          logger.error('播放器报错');
          self.isPlaying = false;
          self.stopPlayAnimation();
          break;
      }
    });

    // 监听播放进度，用于做 UI 动画（如果需要）
    this.avPlayer.on('timeUpdate', (time: number) => {
      if (self.durationMs > 0) {
        self.playProgress = time / self.durationMs;
      }
    });
  }

  // 启动播放动画 (1 -> 2 -> 3 循环)
  startPlayAnimation() {
    this.waveIndex = 1;
    // 每 400ms 切换一帧，模拟声波向外扩散
    const self = this;
    this.animationInterval = setInterval(() => {
      self.waveIndex = (self.waveIndex % 3) + 1;
    }, 400);
  }

  // 停止播放动画，恢复满格静止状态
  stopPlayAnimation() {
    if (this.animationInterval !== -1) {
      clearInterval(this.animationInterval);
      this.animationInterval = -1;
    }
    this.waveIndex = 3; // 停止时恢复显示完整声波
  }

  // 组件销毁时释放播放器
  aboutToDisappear() {
    if (this.avPlayer) {
      this.avPlayer.release();
    }
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
            ToastUtils.show('图片: ' + this.message.getMessageBody());
          })
          .gesture(
            LongPressGesture()
              .onAction(() => {
                this.onLongPress(this.message);
              })
          );
      } else if (this.message.content && this.message.content['msgtype'] === 'm.audio') {
        // ✅ 微信同款语音气泡
        Row() {
          // 发送方的排版：时长在左，波形在右
          if (this.isOutgoing) {
            Text(this.getVoiceDurationText())
              .fontSize(14).fontColor($r('sys.color.white')).opacity(0.8).margin({ right: 8 })
          }

          // 🌀 纯代码手绘的三段式声波 (模拟微信效果)
          Row({ space: 3 }) { // 接收方声波朝右
            // 第一点 (永远亮)
            Circle({ width: 4, height: 4 })

            // 第二条弧线 (根据波形索引决定是否显示)
            Text(')')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isOutgoing ? '#ffffff' : this.getThemeColors().primary)
              .opacity(this.waveIndex >= 2 ? 1 : 0) // 隐藏时用透明度，保持占位

            // 第三条弧线
            Text(')')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isOutgoing ? '#ffffff' : this.getThemeColors().primary)
              .opacity(this.waveIndex >= 3 ? 1 : 0)
              .margin({ left: -6 }) // 紧凑一点
          }
          .width(24) // 锁定图标区域宽度
          // 如果是自己发出去的，让声波朝左
          .rotate({ angle: this.isOutgoing ? 180 : 0, centerX: '50%', centerY: '50%' })

          // 接收方的排版：波形在左，时长在右
          if (!this.isOutgoing) {
            Text(this.getVoiceDurationText())
              .fontSize(14).fontColor(this.getThemeColors().text).opacity(0.8).margin({ left: 8 })
          }
        }
        .backgroundColor(this.isOutgoing ? this.getThemeColors().outgoingBg : this.getThemeColors().messageBg)
        .borderRadius(18)
        .padding({
          left: 16,
          right: 16,
          top: 10,
          bottom: 10
        })
        .width(this.getVoiceBubbleWidth())
        .justifyContent(this.isOutgoing ? FlexAlign.End : FlexAlign.Start)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.togglePlayVoice();
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