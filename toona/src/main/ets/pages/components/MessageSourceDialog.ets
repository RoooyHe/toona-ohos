import { getThemeColors } from '../../utils/ThemeManager';
import { Message } from '../../models/DataModels';
import { ToastUtils } from '../../utils/ToastUtils';
import pasteboard from '@ohos.pasteboard';

/**
 * Message Source Dialog
 * Shows raw JSON event data for debugging
 */
@Component
export struct MessageSourceDialog {
  @Prop isVisible: boolean = false;
  @Prop message: Message | null = null;
  onClose: () => void = () => {};

  build() {
    if (!this.isVisible || !this.message) {
      return;
    }

    Stack() {
      // Background overlay
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .onClick(() => {
          this.onClose();
        });

      // Source card
      Column() {
        // Header
        Row() {
          Text('Message Source')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(getThemeColors().text)
            .layoutWeight(1);

          Button('Copy')
            .fontSize(14)
            .backgroundColor(getThemeColors().primary)
            .fontColor(getThemeColors().onPrimary)
            .borderRadius(6)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .onClick(() => {
              this.copyToClipboard();
            });

          Button('✕')
            .fontSize(16)
            .backgroundColor('transparent')
            .fontColor(getThemeColors().textSecondary)
            .width(32)
            .height(32)
            .margin({ left: 8 })
            .onClick(() => {
              this.onClose();
            });
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 20, bottom: 10 });

        // JSON content
        Scroll() {
          Text(this.getJsonSource())
            .fontSize(12)
            .fontFamily('monospace')
            .fontColor(getThemeColors().text)
            .padding(16)
            .backgroundColor(getThemeColors().surfaceNight)
            .borderRadius(8)
            .margin({ left: 20, right: 20, bottom: 20 });
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto);
      }
      .width('90%')
      .height('80%')
      .backgroundColor(getThemeColors().surface)
      .borderRadius(16)
      .shadow({
        radius: 20,
        color: 'rgba(0, 0, 0, 0.15)',
        offsetX: 0,
        offsetY: 4
      });
    }
    .width('100%')
    .height('100%');
  }

  private getJsonSource(): string {
    if (!this.message) {
      return '{}';
    }

    const source = {
      event_id: this.message.eventId,
      room_id: this.message.roomId,
      sender: this.message.sender,
      type: this.message.type,
      content: this.message.content,
      origin_server_ts: this.message.timestamp,
      status: this.message.status
    };

    return JSON.stringify(source, null, 2);
  }

  private copyToClipboard() {
    try {
      const pasteboard = pasteboard.getSystemPasteboard();
      const pasteData = pasteboard.createData(this.getJsonSource());
      pasteboard.setData(pasteData);
      ToastUtils.show('JSON copied to clipboard');
    } catch (error) {
      ToastUtils.show('Failed to copy');
    }
  }
}
