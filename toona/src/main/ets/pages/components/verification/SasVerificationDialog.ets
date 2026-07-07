import { getThemeColors } from '../../../utils/ThemeManager';
import { VerificationService } from '../../../services/VerificationService';
import { VerificationSession, VerificationPhase } from '../../../crypto/types/CryptoTypes';
import { ToastUtils } from '../../../utils/ToastUtils';

/**
 * SAS Verification Dialog
 * Shows 7-digit SAS code for user comparison
 */
@Component
export struct SasVerificationDialog {
  @Prop sessionId: string = '';
  @Prop isVisible: boolean = false;
  @Prop userId: string = '';
  @Prop deviceId: string = '';
  onCancel: () => void = () => {};
  onConfirm: () => void = () => {};

  private verificationService: VerificationService = VerificationService.getInstance();
  @State sasDigits: string = '';
  @State sasEmojis: string[] = [];
  @State phase: VerificationPhase = VerificationPhase.REQUEST;

  aboutToAppear() {
    this.loadSession();
  }

  loadSession() {
    if (!this.sessionId) {
      return;
    }

    const session = this.verificationService.getSession(this.sessionId);
    if (session) {
      this.phase = session.phase;

      // Generate SAS digits
      if (session.sasBytes && session.sasBytes.length > 0) {
        const digits = this.verificationService.getSasDigits(session.sasBytes);
        this.sasDigits = digits.decimal;
        this.sasEmojis = digits.emoji;
      }
    }
  }

  build() {
    if (!this.isVisible) {
      return;
    }

    Column() {
      // Header
      Row() {
        Text('Verify Device')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(getThemeColors().text);

        Blank();

        Button('✕')
          .fontSize(16)
          .backgroundColor('transparent')
          .fontColor(getThemeColors().textSecondary)
          .width(32)
          .height(32)
          .onClick(() => {
            this.onCancel();
          });
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 10 });

      // Device info
      Column() {
        Text('Verifying device:')
          .fontSize(14)
          .fontColor(getThemeColors().textSecondary);
        Text(`${this.userId.split(':')[0]}:${this.deviceId}`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(getThemeColors().text)
          .margin({ top: 4 });
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 20 });

      // SAS Code display
      Column() {
        Text('Compare these digits:')
          .fontSize(14)
          .fontColor(getThemeColors().textSecondary)
          .margin({ bottom: 12 });

        // Large SAS digits
        Text(this.sasDigits || '------')
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor(getThemeColors().primary)
          .letterSpacing(8);

        // Emoji representation
        if (this.sasEmojis.length > 0) {
          Row() {
            ForEach(this.sasEmojis, (emoji: string) => {
              Text(emoji)
                .fontSize(32)
                .margin({ left: 4, right: 4 });
            });
          }
          .margin({ top: 12 });
        }
      }
      .width('100%')
      .padding(20)
      .backgroundColor(getThemeColors().bgSoft)
      .borderRadius(12)
      .margin({ left: 20, right: 20 });

      // Instructions
      Text('Both devices should show the same code.\nIf they match, tap "They Match" to verify.')
        .fontSize(14)
        .fontColor(getThemeColors().textSecondary)
        .textAlign(TextAlign.Center)
        .margin({ top: 20, left: 20, right: 20 });

      // Buttons
      Row() {
        Button('Cancel')
          .fontSize(16)
          .backgroundColor(getThemeColors().bg)
          .fontColor(getThemeColors().text)
          .borderWidth(1)
          .borderColor(getThemeColors().dividerStrong)
          .borderRadius(6)
          .width('45%')
          .height(44)
          .onClick(() => {
            this.onCancel();
          });

        Button('They Match')
          .fontSize(16)
          .backgroundColor(getThemeColors().primary)
          .fontColor(getThemeColors().onPrimary)
          .borderRadius(6)
          .width('45%')
          .height(44)
          .onClick(() => {
            this.confirmVerification();
          });
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 20, right: 20, top: 20, bottom: 20 });
    }
    .width('100%')
    .backgroundColor(getThemeColors().surface)
    .borderRadius(16)
    .shadow({
      radius: 20,
      color: 'rgba(0, 0, 0, 0.15)',
      offsetX: 0,
      offsetY: 4
    });
  }

  async confirmVerification() {
    try {
      await this.verificationService.confirmVerification(this.sessionId);
      ToastUtils.show('Device verified successfully');
      this.onConfirm();
    } catch (error) {
      ToastUtils.show('Verification failed');
      this.onCancel();
    }
  }
}
