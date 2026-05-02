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
  onVoiceClick: () => void = () => {
  };
  onInputChange: (text: string) => void = () => {
  };
  onSendMessage: () => void = () => {
  };
  onPickImage: () => void = () => {
  };


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
        .onClick(() => {
          this.onVoiceClick();
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