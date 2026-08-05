import { AuthManager } from '../services/AuthManager';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { ServiceRegistry } from '../services/ServiceRegistry';
import { LocalDatabase } from '../database/LocalDatabase';
import { EventProcessor } from '../services/EventProcessor';
import { CryptoService } from '../services/CryptoService';
import { CryptoManager } from '../services/CryptoManager';
import { VerificationService } from '../services/VerificationService';
import { CryptoDao } from '../database/dao/CryptoDao';
import { DeviceKeysStorage } from '../database/dao/DeviceKeysDao';
import { SyncManager } from '../services/SyncManager';
import { RoomManager } from '../services/RoomManager';
import { MessageManager } from '../services/MessageManager';
import { DeviceManager } from '../services/DeviceManager';
import { FilterManager } from '../services/FilterManager';
import { MediaManager } from '../services/MediaManager';
import { OpenIdManager } from '../services/OpenIdManager';
import { PresenceManager } from '../services/PresenceManager';
import { PushManager } from '../services/PushManager';
import { RoomStateManager } from '../services/RoomStateManager';
import { RoomTagManager } from '../services/RoomTagManager';
import { ThirdpartyManager } from '../services/ThirdpartyManager';
import { UserManager } from '../services/UserManager';
import { VoIPManager } from '../services/VoIPManager';
import { ConnectionConfig } from '../network/ConnectionConfig';
import { BaseHttpClient } from '../network/clients/BaseHttpClient';
import { RoomHttpClient } from '../network/clients/RoomHttpClient';
import { MessageHttpClient } from '../network/clients/MessageHttpClient';
import { UserHttpClient } from '../network/clients/UserHttpClient';
import { DeviceHttpClient } from '../network/clients/DeviceHttpClient';
import { PresenceHttpClient } from '../network/clients/PresenceHttpClient';
import { OpenIdHttpClient } from '../network/clients/OpenIdHttpClient';
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
    const presenceClient = new PresenceHttpClient(config);
    const openIdClient = new OpenIdHttpClient(config);
    const mediaClient = new MediaHttpClient(config);

    const authManager = new AuthManager(config, baseClient);
    const localDatabase = new LocalDatabase();
    const cryptoManager = new CryptoManager(deviceClient);
    const cryptoDao = CryptoDao.getInstance();
    const deviceKeysStorage = DeviceKeysStorage.getInstance();
    const verificationService = new VerificationService(authManager, deviceKeysStorage);
    const cryptoService = new CryptoService(authManager, cryptoManager, verificationService, cryptoDao, deviceKeysStorage);
    const eventProcessor = new EventProcessor(localDatabase, cryptoService);
    const syncManager = new SyncManager(authManager, localDatabase, eventProcessor, cryptoService, baseClient);
    const roomManager = new RoomManager(authManager, localDatabase, roomClient);
    const messageManager = new MessageManager(authManager, localDatabase, messageClient);
    const deviceManager = new DeviceManager(authManager, deviceClient);
    const filterManager = new FilterManager(baseClient);
    const mediaManager = new MediaManager(mediaClient);
    const openIdManager = new OpenIdManager(openIdClient);
    const presenceManager = new PresenceManager(presenceClient);
    const pushManager = new PushManager(userClient);
    const roomStateManager = new RoomStateManager(roomClient);
    const roomTagManager = new RoomTagManager(authManager, localDatabase, userClient);
    const thirdpartyManager = new ThirdpartyManager(baseClient);
    const userManager = new UserManager(authManager, userClient);
    const voipManager = new VoIPManager(baseClient);

    const registry = new ServiceRegistry();
    registry.registerConnectionConfig(config);
    registry.registerAuthManager(authManager);
    registry.registerLocalDatabase(localDatabase);
    registry.registerSyncManager(syncManager);
    registry.registerRoomManager(roomManager);
    registry.registerMessageManager(messageManager);
    registry.registerCryptoManager(cryptoManager);
    registry.registerCryptoService(cryptoService);
    registry.registerVerificationService(verificationService);
    registry.registerDeviceManager(deviceManager);
    registry.registerFilterManager(filterManager);
    registry.registerMediaManager(mediaManager);
    registry.registerOpenIdManager(openIdManager);
    registry.registerPresenceManager(presenceManager);
    registry.registerPushManager(pushManager);
    registry.registerRoomStateManager(roomStateManager);
    registry.registerRoomTagManager(roomTagManager);
    registry.registerThirdpartyManager(thirdpartyManager);
    registry.registerUserManager(userManager);
    registry.registerVoipManager(voipManager);
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
