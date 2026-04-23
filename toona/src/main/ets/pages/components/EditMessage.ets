import { Message } from '../../models/DataModels';
import { getThemeColors } from '../../utils/ThemeManager';

interface EditMessageThemeColors {
  bg: string;
  text: string;
  textSecondary: string;
  inputBg: string;
  primary: string;
}

@Component
export struct EditMessage {
  @ObjectLink editingMessage: Message;
  @State editText: string = '';
  onCancel: () => void = () => {};
  onSave: (text: string) => void = () => {};

  getThemeColors(): EditMessageThemeColors {
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
    if (this.editingMessage) {
      Row() {
        Column() {
          Row() {
            Text('编辑消息')
              .fontSize(12)
              .fontColor(this.getThemeColors().primary);
            Text(': ')
              .fontSize(12)
              .fontColor(this.getThemeColors().textSecondary);
            Text(this.editingMessage.getMessageBody())
              .fontSize(12)
              .fontColor(this.getThemeColors().textSecondary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1);
          }

          TextInput({ text: this.editText, placeholder: '输入修改后的消息' })
            .fontSize(14)
            .backgroundColor(this.getThemeColors().bg)
            .borderRadius(8)
            .height(36)
            .margin({ top: 4 })
            .onChange((value: string) => {
              this.editText = value;
            });
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1);

        Column() {
          Button('✕')
            .fontSize(12)
            .backgroundColor('transparent')
            .fontColor(this.getThemeColors().textSecondary)
            .width(24)
            .height(24)
            .onClick(() => {
              this.onCancel();
            });

          Button('保存')
            .fontSize(12)
            .backgroundColor(this.getThemeColors().primary)
            .fontColor('#ffffff')
            .width(48)
            .height(28)
            .borderRadius(6)
            .margin({ top: 4 })
            .enabled(this.editText.trim().length > 0)
            .onClick(() => {
              this.onSave(this.editText);
            });
        }
        .alignItems(HorizontalAlign.Center);
      }
      .width('100%')
      .padding({
        left: 15,
        right: 10,
        top: 8,
        bottom: 8
      })
      .backgroundColor(this.getThemeColors().inputBg);
    }
  }
}