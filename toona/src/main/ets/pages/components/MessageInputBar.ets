import { Message } from '../../models/DataModels';
import { getThemeColors } from '../../utils/ThemeManager';
// 引入鸿蒙原生相册选择器和文件系统模块

interface InputBarThemeColors {
  bg: string;
  text: string;
  textSecondary: string;
  inputBg: string;
  primary: string;
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
      text: base.text,
      textSecondary: base.textSecondary,
      inputBg: base.inputBg,
      primary: base.primary
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