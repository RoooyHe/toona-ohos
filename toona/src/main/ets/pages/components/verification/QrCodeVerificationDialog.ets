import { getThemeColors } from '../../../utils/ThemeManager';
import { VerificationService } from '../../../services/VerificationService';
import { VerificationSession, VerificationPhase } from '../../../crypto/types/CryptoTypes';
import { ToastUtils } from '../../../utils/ToastUtils';

/**
 * QR Code Verification Dialog
 * Display QR code for scanning or scan QR code
 */
@Component
export struct QrCodeVerificationDialog {
  @Prop sessionId: string = '';
  @Prop isVisible: boolean = false;
  @Prop userId: string = '';
  @Prop deviceId: string = '';
  @Prop showQrCode: boolean = true; // true = show QR, false = scan QR
  onCancel: () => void = () => {};
  onConfirm: () => void = () => {};

  verificationService: VerificationService | null = null;
  @State qrData: string = '';
  @State phase: VerificationPhase = VerificationPhase.REQUEST;

  aboutToAppear() {
    this.loadSession();
  }

  loadSession() {
    if (!this.sessionId || !this.verificationService) {
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
        Text(this.showQrCode ? 'Show QR Code' : 'Scan QR Code')
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
        Text(this.showQrCode ? 'Scan this code with the other device:' : 'Point camera at QR code:')
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

      // QR Code placeholder
      Column() {
        if (this.showQrCode) {
          // Show QR code
          Column() {
            Text('QR Code')
              .fontSize(24)
              .fontColor(getThemeColors().textSecondary);
            Text('Will be generated here')
              .fontSize(12)
              .fontColor(getThemeColors().textMute2)
              .margin({ top: 8 });
          }
          .width(200)
          .height(200)
          .backgroundColor(getThemeColors().bg)
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center);
        } else {
          // Scan QR code
          Column() {
            Text('Camera')
              .fontSize(24)
              .fontColor(getThemeColors().textSecondary);
            Text('Camera view will appear here')
              .fontSize(12)
              .fontColor(getThemeColors().textMute2)
              .margin({ top: 8 });
          }
          .width(200)
          .height(200)
          .backgroundColor(getThemeColors().surfaceNight)
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center);
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding(20);

      // Instructions
      Text(this.showQrCode
        ? 'Show this QR code to the other device for scanning.'
        : 'Scan the QR code displayed on the other device.')
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

        Button(this.showQrCode ? 'Done' : 'Scan')
          .fontSize(16)
          .backgroundColor(getThemeColors().primary)
          .fontColor(getThemeColors().onPrimary)
          .borderRadius(6)
          .width('45%')
          .height(44)
          .onClick(() => {
            this.handleAction();
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

  handleAction() {
    if (this.showQrCode) {
      // Done showing QR code
      ToastUtils.show('QR code shown to other device');
      this.onConfirm();
    } else {
      // Start scanning
      ToastUtils.show('Camera scanning started');
      // In a real implementation, this would open the camera
    }
  }
}
