import { getThemeColors } from '../../../utils/ThemeManager';

@Component
export struct SettingsHeader {
  build() {
    Column() {
      Row() {
        Text('设置')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1);
      }
      .width('100%')
      .padding({ left: 10, right: 10 })
      .backgroundColor(getThemeColors().bg);

      Divider().color('#f0f0f0');
    }
  }
}