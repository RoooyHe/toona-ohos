import { getThemeColors } from '../../../utils/ThemeManager';

@Component
export struct LogoutButton {
  onLogout: () => void = () => {};

  build() {
    Column() {
      Button('退出登录')
        .fontSize(16)
        .fontColor('#e53935')
        .backgroundColor($r('sys.color.white'))
        .width('100%')
        .height(48)
        .borderRadius(8)
        .margin({
          top: 20,
          left: 20,
          right: 20,
          bottom: 30
        })
        .onClick(() => {
          this.onLogout();
        });
    }
    .width('100%')
    .backgroundColor($r('sys.color.white'))
    .margin({ top: 10 });
  }
}