import { userAuth } from '@kit.UserAuthenticationKit';
import { promptAction } from '@ohos.promptAction';
import { BusinessError } from '@kit.BasicServicesKit';

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

  async checkBiometricSupport(): Promise<{ isSupported: boolean; faceAvailable: boolean; fingerprintAvailable: boolean }> {
    try {
      const result = userAuth.getInstance().getAvailableStatus(
        userAuth.UserAuthType.FACE,
        userAuth.AuthTrustLevel.ATL3
      );
      
      const faceAvailable = result === 0;
      
      const fingerprintResult = userAuth.getInstance().getAvailableStatus(
        userAuth.UserAuthType.FINGERPRINT,
        userAuth.AuthTrustLevel.ATL3
      );
      
      const fingerprintAvailable = fingerprintResult === 0;
      
      this.isDeviceSupported = faceAvailable || fingerprintAvailable;
      
      return {
        isSupported: this.isDeviceSupported,
        faceAvailable,
        fingerprintAvailable
      };
    } catch (error) {
      console.error('Failed to check biometric support: %{public}s', JSON.stringify(error));
      return {
        isSupported: false,
        faceAvailable: false,
        fingerprintAvailable: false
      };
    }
  }

  async authenticate(reason: string): Promise<boolean> {
    try {
      const supportResult = await this.checkBiometricSupport();
      if (!supportResult.isSupported) {
        promptAction.showToast({ message: '当前设备不支持生物识别' });
        return false;
      }

      const challenge = this.generateChallenge();
      
      const authParams: userAuth.AuthParams = {
        challenge: challenge,
        authType: [userAuth.UserAuthType.FACE, userAuth.UserAuthType.FINGERPRINT],
        trustLevel: userAuth.AuthTrustLevel.ATL3,
        context: getContext()
      };

      const result = await userAuth.getInstance().auth(
        getContext(),
        authParams,
        {
          onResult: (resultCode: number, result: userAuth.AuthResult) => {
            console.info('Auth result: %{public}d', resultCode);
            if (resultCode === 0) {
              this.isBiometricEnabled = true;
            }
          }
        }
      );

      return result?.result === 0;
    } catch (error) {
      console.error('Authentication failed: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  async authenticateWithFace(): Promise<boolean> {
    try {
      const support = await this.checkBiometricSupport();
      if (!support.faceAvailable) {
        promptAction.showToast({ message: '面部识别不可用' });
        return false;
      }

      const challenge = this.generateChallenge();
      
      const authParams: userAuth.AuthParams = {
        challenge: challenge,
        authType: [userAuth.UserAuthType.FACE],
        trustLevel: userAuth.AuthTrustLevel.ATL3,
        context: getContext()
      };

      return new Promise<boolean>((resolve) => {
        userAuth.getInstance().auth(
          getContext(),
          authParams,
          {
            onResult: (resultCode: number, result: userAuth.AuthResult) => {
              console.info('Face auth result: %{public}d', resultCode);
              if (resultCode === 0) {
                promptAction.showToast({ message: '面部识别成功' });
                this.isBiometricEnabled = true;
                resolve(true);
              } else {
                promptAction.showToast({ message: '面部识别失败' });
                resolve(false);
              }
            }
          }
        );
      });
    } catch (error) {
      console.error('Face authentication failed: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  async authenticateWithFingerprint(): Promise<boolean> {
    try {
      const support = await this.checkBiometricSupport();
      if (!support.fingerprintAvailable) {
        promptAction.showToast({ message: '指纹识别不可用' });
        return false;
      }

      const challenge = this.generateChallenge();
      
      const authParams: userAuth.AuthParams = {
        challenge: challenge,
        authType: [userAuth.UserAuthType.FINGERPRINT],
        trustLevel: userAuth.AuthTrustLevel.ATL3,
        context: getContext()
      };

      return new Promise<boolean>((resolve) => {
        userAuth.getInstance().auth(
          getContext(),
          authParams,
          {
            onResult: (resultCode: number, result: userAuth.AuthResult) => {
              console.info('Fingerprint auth result: %{public}d', resultCode);
              if (resultCode === 0) {
                promptAction.showToast({ message: '指纹识别成功' });
                this.isBiometricEnabled = true;
                resolve(true);
              } else {
                promptAction.showToast({ message: '指纹识别失败' });
                resolve(false);
              }
            }
          }
        );
      });
    } catch (error) {
      console.error('Fingerprint authentication failed: %{public}s', JSON.stringify(error));
      return false;
    }
  }

  private generateChallenge(): Uint8Array {
    const challenge = new Uint8Array(16);
    for (let i = 0; i < challenge.length; i++) {
      challenge[i] = Math.floor(Math.random() * 256);
    }
    return challenge;
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