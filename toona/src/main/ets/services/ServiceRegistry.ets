import { AuthManager, IAuthManager } from './AuthManager';
import { SyncManager } from './SyncManager';
import { RoomManager, IRoomManager } from './RoomManager';
import { MessageManager } from './MessageManager';
import { CryptoManager } from './CryptoManager';
import { CryptoService } from './CryptoService';
import { VerificationService } from './VerificationService';
import { DeviceManager } from './DeviceManager';
import { FilterManager } from './FilterManager';
import { MediaManager } from './MediaManager';
import { OpenIdManager } from './OpenIdManager';
import { PresenceManager } from './PresenceManager';
import { PushManager } from './PushManager';
import { RoomStateManager } from './RoomStateManager';
import { RoomTagManager } from './RoomTagManager';
import { ThirdpartyManager } from './ThirdpartyManager';
import { UserManager } from './UserManager';
import { VoIPManager } from './VoIPManager';
import { LocalDatabase } from '../database/LocalDatabase';
import { ConnectionConfig } from '../network/ConnectionConfig';
import { AppLogger } from '../utils/AppLogger';

const logger = AppLogger.getLogger('ServiceRegistry');

const REGISTRY_KEY: string = 'serviceRegistry';

export class ServiceRegistry {
  private connectionConfig: ConnectionConfig | null = null;
  private authManager: AuthManager | null = null;
  private syncManager: SyncManager | null = null;
  private roomManager: RoomManager | null = null;
  private messageManager: MessageManager | null = null;
  private cryptoManager: CryptoManager | null = null;
  private cryptoService: CryptoService | null = null;
  private verificationService: VerificationService | null = null;
  private deviceManager: DeviceManager | null = null;
  private filterManager: FilterManager | null = null;
  private mediaManager: MediaManager | null = null;
  private openIdManager: OpenIdManager | null = null;
  private presenceManager: PresenceManager | null = null;
  private pushManager: PushManager | null = null;
  private roomStateManager: RoomStateManager | null = null;
  private roomTagManager: RoomTagManager | null = null;
  private thirdpartyManager: ThirdpartyManager | null = null;
  private userManager: UserManager | null = null;
  private voipManager: VoIPManager | null = null;
  private localDatabase: LocalDatabase | null = null;

  static init(registry: ServiceRegistry): void {
    AppStorage.setOrCreate<ServiceRegistry>(REGISTRY_KEY, registry);
    logger.info('ServiceRegistry initialized via AppStorage');
  }

  static getCurrent(): ServiceRegistry {
    const registry: ServiceRegistry | undefined = AppStorage.get<ServiceRegistry>(REGISTRY_KEY);
    if (!registry) {
      throw new Error('ServiceRegistry not initialized — call ServiceRegistry.init() first');
    }
    return registry;
  }

  registerConnectionConfig(config: ConnectionConfig): void {
    this.connectionConfig = config;
    logger.info('ConnectionConfig registered');
  }

  getConnectionConfig(): ConnectionConfig {
    if (!this.connectionConfig) {
      throw new Error('ConnectionConfig not initialized');
    }
    return this.connectionConfig;
  }

  registerAuthManager(manager: AuthManager): void {
    this.authManager = manager;
    logger.info('AuthManager registered');
  }

  getAuthManager(): IAuthManager {
    if (!this.authManager) {
      throw new Error('AuthManager not initialized');
    }
    return this.authManager;
  }

  registerSyncManager(manager: SyncManager): void {
    this.syncManager = manager;
    logger.info('SyncManager registered');
  }

  getSyncManager(): SyncManager {
    if (!this.syncManager) {
      throw new Error('SyncManager not initialized');
    }
    return this.syncManager;
  }

  registerRoomManager(manager: RoomManager): void {
    this.roomManager = manager;
    logger.info('RoomManager registered');
  }

  getRoomManager(): IRoomManager {
    if (!this.roomManager) {
      throw new Error('RoomManager not initialized');
    }
    return this.roomManager;
  }

  registerMessageManager(manager: MessageManager): void {
    this.messageManager = manager;
    logger.info('MessageManager registered');
  }

  getMessageManager(): MessageManager {
    if (!this.messageManager) {
      throw new Error('MessageManager not initialized');
    }
    return this.messageManager;
  }

  registerCryptoManager(manager: CryptoManager): void {
    this.cryptoManager = manager;
    logger.info('CryptoManager registered');
  }

  getCryptoManager(): CryptoManager {
    if (!this.cryptoManager) {
      throw new Error('CryptoManager not initialized');
    }
    return this.cryptoManager;
  }

  registerDeviceManager(manager: DeviceManager): void {
    this.deviceManager = manager;
    logger.info('DeviceManager registered');
  }

  getDeviceManager(): DeviceManager {
    if (!this.deviceManager) {
      throw new Error('DeviceManager not initialized');
    }
    return this.deviceManager;
  }

  registerFilterManager(manager: FilterManager): void {
    this.filterManager = manager;
    logger.info('FilterManager registered');
  }

  getFilterManager(): FilterManager {
    if (!this.filterManager) {
      throw new Error('FilterManager not initialized');
    }
    return this.filterManager;
  }

  registerMediaManager(manager: MediaManager): void {
    this.mediaManager = manager;
    logger.info('MediaManager registered');
  }

  getMediaManager(): MediaManager {
    if (!this.mediaManager) {
      throw new Error('MediaManager not initialized');
    }
    return this.mediaManager;
  }

  registerOpenIdManager(manager: OpenIdManager): void {
    this.openIdManager = manager;
    logger.info('OpenIdManager registered');
  }

  getOpenIdManager(): OpenIdManager {
    if (!this.openIdManager) {
      throw new Error('OpenIdManager not initialized');
    }
    return this.openIdManager;
  }

  registerPresenceManager(manager: PresenceManager): void {
    this.presenceManager = manager;
    logger.info('PresenceManager registered');
  }

  getPresenceManager(): PresenceManager {
    if (!this.presenceManager) {
      throw new Error('PresenceManager not initialized');
    }
    return this.presenceManager;
  }

  registerPushManager(manager: PushManager): void {
    this.pushManager = manager;
    logger.info('PushManager registered');
  }

  getPushManager(): PushManager {
    if (!this.pushManager) {
      throw new Error('PushManager not initialized');
    }
    return this.pushManager;
  }

  registerRoomStateManager(manager: RoomStateManager): void {
    this.roomStateManager = manager;
    logger.info('RoomStateManager registered');
  }

  getRoomStateManager(): RoomStateManager {
    if (!this.roomStateManager) {
      throw new Error('RoomStateManager not initialized');
    }
    return this.roomStateManager;
  }

  registerRoomTagManager(manager: RoomTagManager): void {
    this.roomTagManager = manager;
    logger.info('RoomTagManager registered');
  }

  getRoomTagManager(): RoomTagManager {
    if (!this.roomTagManager) {
      throw new Error('RoomTagManager not initialized');
    }
    return this.roomTagManager;
  }

  registerThirdpartyManager(manager: ThirdpartyManager): void {
    this.thirdpartyManager = manager;
    logger.info('ThirdpartyManager registered');
  }

  getThirdpartyManager(): ThirdpartyManager {
    if (!this.thirdpartyManager) {
      throw new Error('ThirdpartyManager not initialized');
    }
    return this.thirdpartyManager;
  }

  registerUserManager(manager: UserManager): void {
    this.userManager = manager;
    logger.info('UserManager registered');
  }

  getUserManager(): UserManager {
    if (!this.userManager) {
      throw new Error('UserManager not initialized');
    }
    return this.userManager;
  }

  registerVoipManager(manager: VoIPManager): void {
    this.voipManager = manager;
    logger.info('VoIPManager registered');
  }

  getVoipManager(): VoIPManager {
    if (!this.voipManager) {
      throw new Error('VoIPManager not initialized');
    }
    return this.voipManager;
  }

  registerLocalDatabase(database: LocalDatabase): void {
    this.localDatabase = database;
    logger.info('LocalDatabase registered');
  }

  getLocalDatabase(): LocalDatabase {
    if (!this.localDatabase) {
      throw new Error('LocalDatabase not initialized');
    }
    return this.localDatabase;
  }

  registerCryptoService(service: CryptoService): void {
    this.cryptoService = service;
    logger.info('CryptoService registered');
  }

  getCryptoService(): CryptoService {
    if (!this.cryptoService) {
      throw new Error('CryptoService not initialized');
    }
    return this.cryptoService;
  }

  registerVerificationService(service: VerificationService): void {
    this.verificationService = service;
    logger.info('VerificationService registered');
  }

  getVerificationService(): VerificationService {
    if (!this.verificationService) {
      throw new Error('VerificationService not initialized');
    }
    return this.verificationService;
  }

  reset(): void {
    this.connectionConfig = null;
    this.authManager = null;
    this.syncManager = null;
    this.roomManager = null;
    this.messageManager = null;
    this.cryptoManager = null;
    this.cryptoService = null;
    this.verificationService = null;
    this.deviceManager = null;
    this.filterManager = null;
    this.mediaManager = null;
    this.openIdManager = null;
    this.presenceManager = null;
    this.pushManager = null;
    this.roomStateManager = null;
    this.roomTagManager = null;
    this.thirdpartyManager = null;
    this.userManager = null;
    this.voipManager = null;
    this.localDatabase = null;
    AppStorage.set<ServiceRegistry>(REGISTRY_KEY, this as ServiceRegistry);
    logger.info('ServiceRegistry reset');
  }
}
