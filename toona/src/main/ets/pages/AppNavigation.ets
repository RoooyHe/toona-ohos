import { AuthManager } from '../services/AuthManager';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { ServiceLocator } from '../services/ServiceLocator';
import { LocalDatabase } from '../database/LocalDatabase';
import { EventProcessor } from '../services/EventProcessor';
import { CryptoService } from '../services/CryptoService';
import { VerificationService } from '../services/VerificationService';
import { CryptoDao } from '../database/dao/CryptoDao';
import { DeviceKeysStorage } from '../database/dao/DeviceKeysDao';
import { SyncManager } from '../services/SyncManager';
import { RoomManager } from '../services/RoomManager';
import { MessageManager } from '../services/MessageManager';
import { DeviceManager } from '../services/DeviceManager';
import { MediaManager } from '../services/MediaManager';
import { PushManager } from '../services/PushManager';
import { RoomTagManager } from '../services/RoomTagManager';
import { UserManager } from '../services/UserManager';
import { UserAuthManager } from '../services/UserAuthManager';
import { DeviceSecurityManager } from '../services/DeviceSecurityManager';
import { ScanManager } from '../services/ScanManager';
import { ShareManager } from '../services/ShareManager';
import { ServiceCollaborationManager } from '../services/ServiceCollaborationManager';
import { ConnectionConfig } from '../network/ConnectionConfig';
import { BaseHttpClient } from '../network/clients/BaseHttpClient';
import { MatrixEndpoints } from '../network/clients/MatrixEndpoints';
import { RoomHttpClient } from '../network/clients/RoomHttpClient';
import { MediaHttpClient } from '../network/clients/MediaHttpClient';

@Builder
export function AppNavigationBuilder(name: string, param: Object) {
  AppNavigation()
}

@Entry
@Component
struct AppNavigation {
  @StorageLink('colorMode') colorMode: number = 0;
  pathStack: NavPathStack = new NavPathStack();
  private hasNavigated: boolean = false;

  aboutToAppear() {
    this.initializeServices();
    AppStorage.setOrCreate('colorMode', ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    this.colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  }

  private initializeServices(): void {
    const config = new ConnectionConfig();

    const baseClient = new BaseHttpClient(config);
    const matrixEndpoints = new MatrixEndpoints(config);
    const roomClient = new RoomHttpClient(config);
    const mediaClient = new MediaHttpClient(config);

    const authManager = new AuthManager(config, baseClient);
    const localDatabase = new LocalDatabase();
    const cryptoDao = CryptoDao.getInstance();
    const deviceKeysStorage = DeviceKeysStorage.getInstance();
    const verificationService = new VerificationService(authManager, deviceKeysStorage);
    const cryptoService = new CryptoService(authManager, matrixEndpoints, verificationService, cryptoDao, deviceKeysStorage);
    const eventProcessor = new EventProcessor(localDatabase, cryptoService);
    const syncManager = new SyncManager(authManager, localDatabase, eventProcessor, cryptoService, baseClient);
    const roomManager = new RoomManager(authManager, localDatabase, roomClient);
    const messageManager = new MessageManager(authManager, localDatabase, matrixEndpoints);
    const deviceManager = new DeviceManager(authManager, matrixEndpoints);
    const mediaManager = new MediaManager(mediaClient);
    const pushManager = new PushManager(matrixEndpoints);
    const roomTagManager = new RoomTagManager(authManager, localDatabase, matrixEndpoints);
    const userManager = new UserManager(authManager, matrixEndpoints);
    const userAuthManager = new UserAuthManager();
    const deviceSecurityManager = new DeviceSecurityManager();
    const scanManager = new ScanManager();
    const shareManager = new ShareManager();
    const serviceCollaborationManager = new ServiceCollaborationManager();

    ServiceLocator.setConnectionConfig(config);
    ServiceLocator.setAuthManager(authManager);
    ServiceLocator.setLocalDatabase(localDatabase);
    ServiceLocator.setSyncManager(syncManager);
    ServiceLocator.setRoomManager(roomManager);
    ServiceLocator.setMessageManager(messageManager);
    ServiceLocator.setCryptoService(cryptoService);
    ServiceLocator.setVerificationService(verificationService);
    ServiceLocator.setDeviceManager(deviceManager);
    ServiceLocator.setMediaManager(mediaManager);
    ServiceLocator.setPushManager(pushManager);
    ServiceLocator.setRoomTagManager(roomTagManager);
    ServiceLocator.setUserManager(userManager);
    ServiceLocator.setEventProcessor(eventProcessor);
    ServiceLocator.setUserAuthManager(userAuthManager);
    ServiceLocator.setDeviceSecurityManager(deviceSecurityManager);
    ServiceLocator.setScanManager(scanManager);
    ServiceLocator.setShareManager(shareManager);
    ServiceLocator.setServiceCollaborationManager(serviceCollaborationManager);
  }

  onPageShow() {
    if (this.hasNavigated) {
      return;
    }
    this.hasNavigated = true;
    const session = ServiceLocator.getAuthManager().getSession();
    if (session !== null) {
      this.pathStack.clear();
      const param: Record<string, Object> = {};
      this.pathStack.pushPathByName('MainPage', param);
    } else {
      this.pathStack.clear();
      const param: Record<string, Object> = {};
      this.pathStack.pushPathByName('LoginPage', param);
    }
  }

  build() {
    Navigation(this.pathStack) {
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
  }
}
