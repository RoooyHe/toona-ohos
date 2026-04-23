import promptAction from '@ohos.promptAction';
import { getThemeColors } from '../../../utils/ThemeManager';

@Component
export struct CollaborationSettings {
  onFindCollaborativeDevices: () => void = () => {};

  build() {
    Column() {
      Row() {
        Text('跨设备协作')
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
            Text('设备接续')
              .fontSize(14)
              .fontColor(getThemeColors().text);
            Text('将当前会话切换到其他设备')
              .fontSize(11)
              .fontColor(getThemeColors().textSecondary)
              .margin({ top: 2 });
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1);

          Button('查找设备')
            .fontSize(12)
            .backgroundColor(getThemeColors().primary)
            .fontColor('#ffffff')
            .padding({
              left: 12,
              right: 12,
              top: 6,
              bottom: 6
            })
            .borderRadius(16)
            .onClick(() => {
              this.onFindCollaborativeDevices();
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