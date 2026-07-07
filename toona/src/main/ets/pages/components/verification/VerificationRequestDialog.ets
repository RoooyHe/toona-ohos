import { getThemeColors } from '../../../utils/ThemeManager';
import { VerificationService } from '../../../services/VerificationService';
import { VerificationSession, VerificationPhase } from '../../../crypto/types/CryptoTypes';
import { ToastUtils } from '../../../utils/ToastUtils';

/**
 * Verification Request Dialog
 * Shows incoming verification request for user to accept/decline
 */
@Component
export struct VerificationRequestDialog {
  @Prop sessionId: string = '';
  @Prop isVisible: boolean = false;
  @Prop userId: string = '';
  @Prop deviceId: string = '';
  onAccept: () => void = () => {};
  onDecline: () => void = () => {};

  private verificationService: VerificationService = VerificationService.getInstance();
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
    }
  }

  build() {
    if (!this.isVisible) {
      return;
    }

    Column() {
      // Header
      Row() {
        Text('Verification Request')
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
            this.onDecline();
          });
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 10 });

      // Requester info
      Column() {
        Text('Device requesting verification:')
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

      // Icon
      Column() {
        Text('🔐')
          .fontSize(48);
      }
      .width('100%')
      .padding(20)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center);

      // Instructions
      Text('Another device wants to verify your identity.\nAccept to start the verification process.')
        .fontSize(14)
        .fontColor(getThemeColors().textSecondary)
        .textAlign(TextAlign.Center)
        .margin({ top: 20, left: 20, right: 20 });

      // Buttons
      Row() {
        Button('Decline')
          .fontSize(16)
          .backgroundColor(getThemeColors().bg)
          .fontColor(getThemeColors().error)
          .borderWidth(1)
          .borderColor(getThemeColors().error)
          .borderRadius(6)
          .width('45%')
          .height(44)
          .onClick(() => {
            this.onDecline();
          });

        Button('Accept')
          .fontSize(16)
          .backgroundColor(getThemeColors().primary)
          .fontColor(getThemeColors().onPrimary)
          .borderRadius(6)
          .width('45%')
          .height(44)
          .onClick(() => {
            this.acceptVerification();
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

  async acceptVerification() {
    try {
      await this.verificationService.acceptVerification(this.sessionId);
      ToastUtils.show('Verification accepted');
      this.onAccept();
    } catch (error) {
      ToastUtils.show('Failed to accept verification');
      this.onDecline();
    }
  }
}
