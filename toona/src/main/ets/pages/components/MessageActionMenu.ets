import { Message } from '../../models/DataModels';
import { getThemeColors } from '../../utils/ThemeManager';

interface ActionMenuThemeColors {
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
export struct MessageActionMenu {
  @Prop showReplyMenu: boolean = false;
  @ObjectLink selectedMessage: Message;
  onReply: (message: Message) => void = () => {};
  onCopy: (message: Message) => void = () => {};
  onDelete: (message: Message) => void = () => {};
  onEdit: (message: Message) => void = () => {};
  onSecurityCheck: (message: Message) => void = () => {};
  onShare: (message: Message) => void = () => {};
  onReact: (message: Message) => void = () => {};
  onForward: (message: Message) => void = () => {};
  onPin: (message: Message) => void = () => {};
  onViewSource: (message: Message) => void = () => {};
  onReport: (message: Message) => void = () => {};
  onClose: () => void = () => {};

  getThemeColors(): ActionMenuThemeColors {
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
    if (this.showReplyMenu && this.selectedMessage) {
      Column() {
        Column() {
          Text('回复')
            .fontSize(14)
            .fontColor(this.getThemeColors().text)
            .width('100%')
            .padding({ left: 15, top: 12, bottom: 12 })
            .onClick(() => {
              this.onReply(this.selectedMessage);
            });

          Divider().color(this.getThemeColors().divider);

          Text('复制')
            .fontSize(14)
            .fontColor(this.getThemeColors().text)
            .width('100%')
            .padding({ left: 15, top: 12, bottom: 12 })
            .onClick(() => {
              this.onCopy(this.selectedMessage);
            });

          Divider().color(this.getThemeColors().divider);

          Text('回复')
            .fontSize(14)
            .fontColor(this.getThemeColors().text)
            .width('100%')
            .padding({ left: 15, top: 12, bottom: 12 })
            .onClick(() => {
              this.onReact(this.selectedMessage);
            });

          if (this.selectedMessage.isOutgoing) {
            Divider().color(this.getThemeColors().divider);

            Text('删除')
              .fontSize(14)
              .fontColor(this.getThemeColors().error)
              .width('100%')
              .padding({ left: 15, top: 12, bottom: 12 })
              .onClick(() => {
                this.onDelete(this.selectedMessage);
              });

            Divider().color(this.getThemeColors().divider);

            Text('编辑')
              .fontSize(14)
              .fontColor(this.getThemeColors().primary)
              .width('100%')
              .padding({ left: 15, top: 12, bottom: 12 })
              .onClick(() => {
                this.onEdit(this.selectedMessage);
              });
          }

          Divider().color(this.getThemeColors().divider);

          Text('安全检测')
            .fontSize(14)
            .fontColor(this.getThemeColors().warning)
            .width('100%')
            .padding({ left: 15, top: 12, bottom: 12 })
            .onClick(() => {
              this.onSecurityCheck(this.selectedMessage);
            });

          Divider().color(this.getThemeColors().divider);

          Text('分享')
            .fontSize(14)
            .fontColor(this.getThemeColors().primary)
            .width('100%')
            .padding({ left: 15, top: 12, bottom: 12 })
            .onClick(() => {
              this.onShare(this.selectedMessage);
            });

          Divider().color(this.getThemeColors().divider);

          Text('转发')
            .fontSize(14)
            .fontColor(this.getThemeColors().primary)
            .width('100%')
            .padding({ left: 15, top: 12, bottom: 12 })
            .onClick(() => {
              this.onForward(this.selectedMessage);
            });

          Divider().color(this.getThemeColors().divider);

          Text('置顶')
            .fontSize(14)
            .fontColor(this.getThemeColors().primary)
            .width('100%')
            .padding({ left: 15, top: 12, bottom: 12 })
            .onClick(() => {
              this.onPin(this.selectedMessage);
            });

          Divider().color(this.getThemeColors().divider);

          Text('查看源码')
            .fontSize(14)
            .fontColor(this.getThemeColors().textSecondary)
            .width('100%')
            .padding({ left: 15, top: 12, bottom: 12 })
            .onClick(() => {
              this.onViewSource(this.selectedMessage);
            });

          Divider().color(this.getThemeColors().divider);

          Text('举报')
            .fontSize(14)
            .fontColor(this.getThemeColors().error)
            .width('100%')
            .padding({ left: 15, top: 12, bottom: 12 })
            .onClick(() => {
              this.onReport(this.selectedMessage);
            });

          Divider().color(this.getThemeColors().divider);

          Text('取消')
            .fontSize(14)
            .fontColor(this.getThemeColors().textSecondary)
            .width('100%')
            .padding({ left: 15, top: 12, bottom: 12 })
            .onClick(() => {
              this.onClose();
            });
        }
        .width(160)
        .backgroundColor(this.getThemeColors().bg)
        .borderRadius(8)
        .shadow({
          radius: 10,
          color: 'rgba(0, 0, 0, 0.15)',
          offsetX: 0,
          offsetY: 2
        });
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('rgba(0, 0, 0, 0.3)')
      .onClick(() => {
        this.onClose();
      });
    }
  }
}