import promptAction from '@ohos.promptAction';
import { getThemeColors } from '../../../utils/ThemeManager';

@Component
export struct SecuritySettings {
  onCheckDeviceSecurity: () => void = () => {};

  build() {
    Column() {
      Row() {
        Text('安全与防诈')
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
            Text('AI安全检测')
              .fontSize(14)
              .fontColor(getThemeColors().text);
            Text('自动检测可疑消息和链接')
              .fontSize(11)
              .fontColor(getThemeColors().textSecondary)
              .margin({ top: 2 });
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1);

          Button('检测')
            .fontSize(12)
            .backgroundColor('#FF9800')
            .fontColor('#ffffff')
            .padding({
              left: 12,
              right: 12,
              top: 6,
              bottom: 6
            })
            .borderRadius(16)
            .onClick(() => {
              this.onCheckDeviceSecurity();
            });
        }
        .width('100%')
        .padding({
          left: 20,
          right: 20,
          top: 12,
          bottom: 12
        });

        Divider().color(getThemeColors().divider);

        Row() {
          Column() {
            Text('诈骗风险提示')
              .fontSize(14)
              .fontColor(getThemeColors().text);
            Text('长按消息进行安全检测')
              .fontSize(11)
              .fontColor(getThemeColors().textSecondary)
              .margin({ top: 2 });
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1);

          Image($r('app.media.message'))
            .width(24)
            .height(24)
            .opacity(0.5);
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