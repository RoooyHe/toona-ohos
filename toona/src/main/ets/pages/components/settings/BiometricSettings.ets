import promptAction from '@ohos.promptAction';
import { getThemeColors } from '../../../utils/ThemeManager';

@Component
export struct BiometricSettings {
  onToggleBiometric: (enable: boolean) => void = () => {};
  onVerifyBiometric: () => void = () => {};

  build() {
    Column() {
      Row() {
        Text('登录安全')
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
            Text('生物识别登录')
              .fontSize(14)
              .fontColor(getThemeColors().text);
            Text('使用指纹或面部识别快速登录')
              .fontSize(11)
              .fontColor(getThemeColors().textSecondary)
              .margin({ top: 2 });
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1);

          Toggle({ type: ToggleType.Switch, isOn: false })
            .selectedColor(getThemeColors().primary)
            .onChange((isOn: boolean) => {
              this.onToggleBiometric(isOn);
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
            Text('验证生物识别')
              .fontSize(14)
              .fontColor(getThemeColors().text);
            Text('测试指纹或面部识别是否可用')
              .fontSize(11)
              .fontColor(getThemeColors().textSecondary)
              .margin({ top: 2 });
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1);

          Button('验证')
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
              this.onVerifyBiometric();
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