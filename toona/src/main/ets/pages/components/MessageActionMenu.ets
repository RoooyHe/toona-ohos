import { Message } from '../../models/DataModels';
import { getThemeColors } from '../../utils/ThemeManager';

interface ActionMenuThemeColors {
  bg: string;
  text: string;
  textSecondary: string;
  primary: string;
  error: string;
  divider: string;
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
  onClose: () => void = () => {};

  getThemeColors(): ActionMenuThemeColors {
    const base = getThemeColors();
    return {
      bg: base.bg,
      text: base.text,
      textSecondary: base.textSecondary,
      primary: base.primary,
      error: '#e53935',
      divider: base.divider
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
            .fontColor('#FF9800')
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