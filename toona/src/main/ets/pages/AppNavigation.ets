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
import { MessageSender } from '../services/MessageSender';
import { DeviceManager } from '../services/DeviceManager';
import { MediaManager } from '../services/MediaManager';
import { PushManager } from '../services/PushManager';
import { RoomTagManager } from '../services/RoomTagManager';
import { UserManager } from '../services/UserManager';
import { DeviceSecurityManager } from '../services/DeviceSecurityManager';
import { ScanManager } from '../services/ScanManager';
import { ShareManager } from '../services/ShareManager';
import { HarmonyFilePicker } from '../platform/adapters/HarmonyFilePicker';
import { HarmonyClipboard } from '../platform/adapters/HarmonyClipboard';
import { HarmonyAudioRecorder } from '../platform/adapters/HarmonyAudioRecorder';
import { IFilePicker } from '../platform/adapters/IFilePicker';
import { IClipboard } from '../platform/adapters/IClipboard';
import { IAudioRecorder } from '../platform/adapters/IAudioRecorder';
import { ConnectionConfig } from '../network/ConnectionConfig';
import { BaseHttpClient } from '../network/clients/BaseHttpClient';

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

    const authManager = new AuthManager(config, baseClient);
    const localDatabase = new LocalDatabase();
    const cryptoDao = CryptoDao.getInstance();
    const deviceKeysStorage = DeviceKeysStorage.getInstance();
    const verificationService = new VerificationService(authManager, deviceKeysStorage);
    const cryptoService = new CryptoService(authManager, verificationService, cryptoDao, deviceKeysStorage);
    const eventProcessor = new EventProcessor(localDatabase, cryptoService);
    const syncManager = new SyncManager(authManager, localDatabase, eventProcessor, cryptoService, baseClient);
    const roomManager = new RoomManager(authManager, localDatabase, baseClient);
    const messageManager = new MessageManager(localDatabase, baseClient);
    const messageSender = new MessageSender(baseClient);
    const deviceManager = new DeviceManager(authManager, baseClient);
    const mediaManager = new MediaManager(baseClient);
    const pushManager = new PushManager(baseClient);
    const roomTagManager = new RoomTagManager(authManager, localDatabase, baseClient);
    const userManager = new UserManager(authManager, baseClient);
    const deviceSecurityManager = new DeviceSecurityManager();
    const scanManager = new ScanManager();
    const shareManager = new ShareManager();

    ServiceLocator.setConnectionConfig(config);
    ServiceLocator.setAuthManager(authManager);
    ServiceLocator.setLocalDatabase(localDatabase);
    ServiceLocator.setSyncManager(syncManager);
    ServiceLocator.setRoomManager(roomManager);
    ServiceLocator.setMessageManager(messageManager);
    ServiceLocator.setMessageSender(messageSender);
    ServiceLocator.setCryptoService(cryptoService);
    ServiceLocator.setVerificationService(verificationService);
    ServiceLocator.setDeviceManager(deviceManager);
    ServiceLocator.setMediaManager(mediaManager);
    ServiceLocator.setPushManager(pushManager);
    ServiceLocator.setRoomTagManager(roomTagManager);
    ServiceLocator.setUserManager(userManager);
    ServiceLocator.setEventProcessor(eventProcessor);
    ServiceLocator.setDeviceSecurityManager(deviceSecurityManager);
    ServiceLocator.setScanManager(scanManager);
    ServiceLocator.setShareManager(shareManager);
    const filePicker: IFilePicker = new HarmonyFilePicker();
    const clipboard: IClipboard = new HarmonyClipboard();
    const audioRecorder: IAudioRecorder = new HarmonyAudioRecorder();

    ServiceLocator.setFilePicker(filePicker);
    ServiceLocator.setClipboard(clipboard);
    ServiceLocator.setAudioRecorder(audioRecorder);
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
