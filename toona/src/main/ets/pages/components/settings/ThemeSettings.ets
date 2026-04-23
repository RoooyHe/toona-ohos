import promptAction from '@ohos.promptAction';
import { ColorModeType, getThemeColors } from '../../../utils/ThemeManager';

@Component
export struct ThemeSettings {
  @Prop colorModeType: ColorModeType = 'light';
  onSetColorMode: (mode: ColorModeType) => void = () => {};

  setColorMode(mode: ColorModeType) {
    this.onSetColorMode(mode);
  }

  build() {
    Column() {
      Row() {
        Text('外观设置')
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
        this.ColorModeOptionBuilder('日间', 'light');
        Divider().color(getThemeColors().divider);
        this.ColorModeOptionBuilder('夜间', 'dark');
        Divider().color(getThemeColors().divider);
        this.ColorModeOptionBuilder('跟随系统', 'system');
      }
      .width('100%')
      .backgroundColor(getThemeColors().surface);
    }
    .width('100%')
    .margin({ top: 10 });
  }

  @Builder
  ColorModeOptionBuilder(label: string, mode: ColorModeType) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(getThemeColors().text);

      Blank();

      if (this.colorModeType === mode) {
        Image($r('app.media.check'))
          .width(20)
          .height(20)
          .fillColor(getThemeColors().primary);
      }
    }
    .width('100%')
    .padding({
      left: 20,
      right: 20,
      top: 14,
      bottom: 14
    })
    .onClick(() => {
      this.setColorMode(mode);
    });
  }
}