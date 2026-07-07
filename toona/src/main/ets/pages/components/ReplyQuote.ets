import { getThemeColors } from '../../utils/ThemeManager';

interface ReplyQuoteData {
  eventId: string;
  sender: string;
  body: string;
}

interface ReplyQuoteThemeColors {
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
export struct ReplyQuote {
  @Prop replyQuote: ReplyQuoteData | null = null;
  onCancel: () => void = () => {};

  getThemeColors(): ReplyQuoteThemeColors {
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