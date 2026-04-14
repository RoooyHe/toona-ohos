import promptAction from '@ohos.promptAction';

interface BiometricSupportResult {
  isSupported: boolean;
  faceAvailable: boolean;
  fingerprintAvailable: boolean;
}

export class UserAuthManager {
  private static instance: UserAuthManager;
  private isBiometricEnabled: boolean = false;
  private isDeviceSupported: boolean = false;

  static getInstance(): UserAuthManager {
    if (!UserAuthManager.instance) {
      UserAuthManager.instance = new UserAuthManager();
    }
    return UserAuthManager.instance;
  }

  async checkBiometricSupport(): Promise<BiometricSupportResult> {
    // Stub implementation - biometric API compatibility varies by SDK version
    // Return as unsupported to use password authentication instead
    return {
      isSupported: false,
      faceAvailable: false,
      fingerprintAvailable: false
    };
  }

  async authenticate(reason: string): Promise<boolean> {
    // Stub - biometric auth not available
    promptAction.showToast({ message: '生物识别功能暂不可用' });
    return false;
  }

  async authenticateWithFace(): Promise<boolean> {
    // Stub - biometric auth not available
    promptAction.showToast({ message: '面部识别功能暂不可用' });
    return false;
  }

  async authenticateWithFingerprint(): Promise<boolean> {
    // Stub - biometric auth not available
    promptAction.showToast({ message: '指纹识别功能暂不可用' });
    return false;
  }

  setBiometricEnabled(enabled: boolean): void {
    this.isBiometricEnabled = enabled;
  }

  isEnabled(): boolean {
    return this.isBiometricEnabled;
  }

  getBiometricType(): string {
    if (!this.isDeviceSupported) {
      return 'none';
    }
    return 'available';
  }

  async verifyIdentity(): Promise<boolean> {
    return this.authenticate('验证身份');
  }
}
