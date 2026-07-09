import { getThemeColors } from '../../utils/ThemeManager';
import { Message } from '../../models/DataModels';
import { ToastUtils } from '../../utils/ToastUtils';

/**
 * Message Report Dialog
 * Allows users to report abusive messages
 */
@Component
export struct MessageReportDialog {
  @Prop isVisible: boolean = false;
  @Prop message: Message | null = null;
  onReport: (reason: string) => void = () => {};
  onClose: () => void = () => {};

  @State selectedReason: string = '';
  @State customReason: string = '';

  private reasons: string[] = [
    'Spam',
    'Harassment',
    'Hate speech',
    'Violence',
    'Nudity',
    'Self-harm',
    'Other'
  ];

  build() {
    Stack() {
      if (this.isVisible && this.message) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.onClose();
          });

        Column() {
          Row() {
            Text('Report Message')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(getThemeColors().text)
              .layoutWeight(1);

            Button('✕')
              .fontSize(16)
              .backgroundColor('transparent')
              .fontColor(getThemeColors().textSecondary)
              .width(32)
              .height(32)
              .onClick(() => {
                this.onClose();
              });
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 20, bottom: 10 });

          Column() {
            Text(this.message!.getMessageBody())
              .fontSize(14)
              .fontColor(getThemeColors().textSecondary)
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 16 });

          Text('Select a reason:')
            .fontSize(14)
            .fontColor(getThemeColors().text)
            .padding({ left: 20, right: 20, bottom: 8 });

          ForEach(this.reasons, (reason: string) => {
            Row() {
              Circle()
                .width(16)
                .height(16)
                .fill(this.selectedReason === reason ? getThemeColors().primary : 'transparent')
                .stroke(getThemeColors().dividerStrong)
                .strokeWidth(1);

              Text(reason)
                .fontSize(14)
                .fontColor(getThemeColors().text)
                .margin({ left: 12 });
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 8, bottom: 8 })
            .onClick(() => {
              this.selectedReason = reason;
            });
          });

          if (this.selectedReason === 'Other') {
            TextInput({ placeholder: 'Please describe the issue...' })
              .fontSize(14)
              .backgroundColor(getThemeColors().inputBg)
              .borderRadius(6)
              .height(80)
              .margin({ left: 20, right: 20, top: 12 })
              .onChange((value: string) => {
                this.customReason = value;
              });
          }

          Row() {
            Button('Cancel')
              .fontSize(14)
              .backgroundColor(getThemeColors().bg)
              .fontColor(getThemeColors().text)
              .borderWidth(1)
              .borderColor(getThemeColors().dividerStrong)
              .borderRadius(6)
              .layoutWeight(1)
              .height(40)
              .margin({ left: 20, right: 10, top: 20, bottom: 20 })
              .onClick(() => {
                this.onClose();
              });

            Button('Report')
              .fontSize(14)
              .backgroundColor(getThemeColors().error)
              .fontColor(Color.White)
              .borderRadius(6)
              .layoutWeight(1)
              .height(40)
              .margin({ left: 10, right: 20, top: 20, bottom: 20 })
              .enabled(this.selectedReason.length > 0)
              .onClick(() => {
                const reason = this.selectedReason === 'Other' ? this.customReason : this.selectedReason;
                this.onReport(reason);
                this.onClose();
              });
          }
          .width('100%');
        }
        .width('90%')
        .backgroundColor(getThemeColors().surface)
        .borderRadius(16)
        .shadow({
          radius: 20,
          color: 'rgba(0, 0, 0, 0.15)',
          offsetX: 0,
          offsetY: 4
        });
      }
    }
    .width('100%')
    .height('100%');
  }
}
