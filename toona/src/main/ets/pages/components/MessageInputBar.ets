import { Message } from '../../models/DataModels';
import { getThemeColors } from '../../utils/ThemeManager';
// 引入鸿蒙原生相册选择器和文件系统模块

interface InputBarThemeColors {
  bg: string;
  bgSoft: string;
  text: string;
  textSecondary: string;
  textMute: string;
  textMute2: string;
  textFaint: string;
  inputBg: string;
  primary: string;
  primaryDeep: string;
  primarySoft: string;
  onPrimary: string;
  error: string;
  success: string;
  warning: string;
  divider: string;
  dividerStrong: string;
  dividerCool: string;
  surface: string;
  surfaceNight: string;
  surfaceNightSoft: string;
  tabBg: string;
}

@Component
export struct MessageInputBar {
  @Prop inputText: string = '';
  @Prop editingMessage: Message | null = null;

  // 顺手补全默认空函数的参数，防止严格模式下再次报类型警告
  onVoiceClick: (event: TouchEvent) => void = (event: TouchEvent) => {};
  onInputChange: (text: string) => void = (text: string) => {};
  onSendMessage: () => void = () => {};
  onPickImage: () => void = () => {};

  getThemeColors(): InputBarThemeColors {
    const base = getThemeColors();
    return {
      bg: base.bg,
      bgSoft: base.bgSoft,
      text: base.text,
      textSecondary: base.textSecondary,
      textMute: base.textMute,
      textMute2: base.textMute2,
      textFaint: base.textFaint,
      inputBg: base.inputBg,
      primary: base.primary,
      primaryDeep: base.primaryDeep,
      primarySoft: base.primarySoft,
      onPrimary: base.onPrimary,
      error: base.error,
      success: base.success,
      warning: base.warning,
      divider: base.divider,
      dividerStrong: base.dividerStrong,
      dividerCool: base.dividerCool,
      surface: base.surface,
      surfaceNight: base.surfaceNight,
      surfaceNightSoft: base.surfaceNightSoft,
      tabBg: base.tabBg
    };
  }

  build() {
    Row() {
      Image($r('app.media.phone'))
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
        .fillColor(getThemeColors().textSecondary)
        // ✅ 修复：接收系统传来的 event 参数，并转交给 onVoiceClick
        .onTouch((event: TouchEvent) => {
          this.onVoiceClick(event);
        });

      if (!this.editingMessage) {
        TextInput({ placeholder: '输入消息...', text: this.inputText })
          .fontSize(16)
          .backgroundColor(this.getThemeColors().inputBg)
          .borderRadius(20)
          .height(40)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.onInputChange(value);
          })
          .onSubmit(() => {
            this.onSendMessage();
          });
      }

      Row() {
        Image($r('app.media.pic'))
          .width(24)
          .height(24)
          .objectFit(ImageFit.Contain)
          .fillColor(getThemeColors().textSecondary)
          .margin({ left: 5 })
          .onClick(() => {
            this.onPickImage();
          });
      }
    }
    .width('100%')
    .padding({
      left: 15,
      right: 15,
      top: 10,
      bottom: 10
    })
    .backgroundColor(this.getThemeColors().bg);
  }
}