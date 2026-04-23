import promptAction from '@ohos.promptAction';
import { getThemeColors } from '../../../utils/ThemeManager';

@Component
export struct QRScannerSettings {
  onScanQRCode: () => void = () => {};

  build() {
    Column() {
      Row() {
        Text('扫码')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(getThemeColors().text);
      }
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        top: 15,
        bottom: 10
      });

      Column() {
        Row() {
          Column() {
            Text('扫描二维码加入房间')
              .fontSize(14)
              .fontColor(getThemeColors().text);
            Text('扫描好友分享的房间链接')
              .fontSize(11)
              .fontColor(getThemeColors().textSecondary)
              .margin({ top: 2 });
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1);

          Button('扫码')
            .fontSize(12)
            .backgroundColor(getThemeColors().primary)
            .fontColor('#ffffff')
            .padding({
              left: 16,
              right: 16,
              top: 8,
              bottom: 8
            })
            .borderRadius(16)
            .onClick(() => {
              this.onScanQRCode();
            });
        }
        .width('100%')
        .padding({
          left: 20,
          right: 20,
          top: 12,
          bottom: 12
        });
      }
      .width('100%')
      .backgroundColor(getThemeColors().surface);
    }
    .width('100%')
    .margin({ top: 10 });
  }
}