import { getThemeColors } from '../../utils/ThemeManager';

interface ReplyQuoteData {
  eventId: string;
  sender: string;
  body: string;
}

interface ReplyQuoteThemeColors {
  bg: string;
  text: string;
  textSecondary: string;
  inputBg: string;
  primary: string;
}

@Component
export struct ReplyQuote {
  @Prop replyQuote: ReplyQuoteData | null = null;
  onCancel: () => void = () => {};

  getThemeColors(): ReplyQuoteThemeColors {
    const base = getThemeColors();
    return {
      bg: base.bg,
      text: base.text,
      textSecondary: base.textSecondary,
      inputBg: base.inputBg,
      primary: base.primary
    };
  }

  getReplySenderName(sender: string): string {
    const colonIndex = sender.indexOf(':');
    return colonIndex > 0 ? sender.substring(1, colonIndex) : sender;
  }

  build() {
    if (this.replyQuote) {
      Row() {
        Column() {
          Row() {
            Text('回复: ')
              .fontSize(12)
              .fontColor(this.getThemeColors().primary);
            Text(this.getReplySenderName(this.replyQuote.sender))
              .fontSize(12)
              .fontColor(this.getThemeColors().textSecondary);
          }

          Text(this.replyQuote.body)
            .fontSize(12)
            .fontColor(this.getThemeColors().textSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1);

        Button('✕')
          .fontSize(12)
          .backgroundColor('transparent')
          .fontColor(this.getThemeColors().textSecondary)
          .width(24)
          .height(24)
          .onClick(() => {
            this.onCancel();
          });
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