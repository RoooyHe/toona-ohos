import { DeviceManager } from '../DeviceManager';
import { PushManager } from '../PushManager';
import { ScanManager } from '../ScanManager';
import { CryptoService } from '../CryptoService';
import { VerificationService } from '../VerificationService';
import { DeviceSecurityManager } from '../DeviceSecurityManager';
import { ServiceCollaborationManager } from '../ServiceCollaborationManager';
import { UserAuthManager } from '../UserAuthManager';
import { IAuthManager } from '../AuthManager';
import { ServiceLocator } from '../ServiceLocator';

export class DeviceContext {
  private deviceManager: DeviceManager = ServiceLocator.getDeviceManager();
  private pushManager: PushManager = ServiceLocator.getPushManager();
  private scanManager: ScanManager = ServiceLocator.getScanManager();
  private cryptoService: CryptoService = ServiceLocator.getCryptoService();
  private verificationService: VerificationService = ServiceLocator.getVerificationService();
  private deviceSecurityManager: DeviceSecurityManager = ServiceLocator.getDeviceSecurityManager();
  private serviceCollaborationManager: ServiceCollaborationManager = ServiceLocator.getServiceCollaborationManager();
  private userAuthManager: UserAuthManager = ServiceLocator.getUserAuthManager();
  private authManager: IAuthManager = ServiceLocator.getAuthManager();

  getDeviceManager(): DeviceManager {
    return this.deviceManager;
  }

  getPushManager(): PushManager {
    return this.pushManager;
  }

  getScanManager(): ScanManager {
    return this.scanManager;
  }

  getCryptoService(): CryptoService {
    return this.cryptoService;
  }

  getVerificationService(): VerificationService {
    return this.verificationService;
  }

  getDeviceSecurityManager(): DeviceSecurityManager {
    return this.deviceSecurityManager;
  }

  getServiceCollaborationManager(): ServiceCollaborationManager {
    return this.serviceCollaborationManager;
  }

  getUserAuthManager(): UserAuthManager {
    return this.userAuthManager;
  }

  getAuthManager(): IAuthManager {
    return this.authManager;
  }
}
