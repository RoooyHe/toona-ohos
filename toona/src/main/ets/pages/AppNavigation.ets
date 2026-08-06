import { AuthManager } from '../services/AuthManager';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { ServiceRegistry } from '../services/ServiceRegistry';
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
import { RoomHttpClient } from '../network/clients/RoomHttpClient';
import { MessageHttpClient } from '../network/clients/MessageHttpClient';
import { UserHttpClient } from '../network/clients/UserHttpClient';
import { DeviceHttpClient } from '../network/clients/DeviceHttpClient';
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
    const roomClient = new RoomHttpClient(config);
    const messageClient = new MessageHttpClient(config);
    const userClient = new UserHttpClient(config);
    const deviceClient = new DeviceHttpClient(config);
    const mediaClient = new MediaHttpClient(config);

    const authManager = new AuthManager(config, baseClient);
    const localDatabase = new LocalDatabase();
    const cryptoDao = CryptoDao.getInstance();
    const deviceKeysStorage = DeviceKeysStorage.getInstance();
    const verificationService = new VerificationService(authManager, deviceKeysStorage);
    const cryptoService = new CryptoService(authManager, deviceClient, verificationService, cryptoDao, deviceKeysStorage);
    const eventProcessor = new EventProcessor(localDatabase, cryptoService);
    const syncManager = new SyncManager(authManager, localDatabase, eventProcessor, cryptoService, baseClient);
    const roomManager = new RoomManager(authManager, localDatabase, roomClient);
    const messageManager = new MessageManager(authManager, localDatabase, messageClient);
    const deviceManager = new DeviceManager(authManager, deviceClient);
    const mediaManager = new MediaManager(mediaClient);
    const pushManager = new PushManager(userClient);
    const roomTagManager = new RoomTagManager(authManager, localDatabase, userClient);
    const userManager = new UserManager(authManager, userClient);
    const userAuthManager = new UserAuthManager();
    const deviceSecurityManager = new DeviceSecurityManager();
    const scanManager = new ScanManager();
    const shareManager = new ShareManager();
    const serviceCollaborationManager = new ServiceCollaborationManager();

    const registry = new ServiceRegistry();
    registry.registerConnectionConfig(config);
    registry.registerAuthManager(authManager);
    registry.registerLocalDatabase(localDatabase);
    registry.registerSyncManager(syncManager);
    registry.registerRoomManager(roomManager);
    registry.registerMessageManager(messageManager);
    registry.registerCryptoService(cryptoService);
    registry.registerVerificationService(verificationService);
    registry.registerDeviceManager(deviceManager);
    registry.registerMediaManager(mediaManager);
    registry.registerPushManager(pushManager);
    registry.registerRoomTagManager(roomTagManager);
    registry.registerUserManager(userManager);
    registry.registerEventProcessor(eventProcessor);
    registry.registerUserAuthManager(userAuthManager);
    registry.registerDeviceSecurityManager(deviceSecurityManager);
    registry.registerScanManager(scanManager);
    registry.registerShareManager(shareManager);
    registry.registerServiceCollaborationManager(serviceCollaborationManager);
    ServiceRegistry.init(registry);
  }

  onPageShow() {
    if (this.hasNavigated) {
      return;
    }
    this.hasNavigated = true;
    const session = ServiceRegistry.getCurrent().getAuthManager().getSession();
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
