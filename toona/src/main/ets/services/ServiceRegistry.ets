import { AuthManager, IAuthManager } from './AuthManager';
import { SyncManager } from './SyncManager';
import { RoomManager, IRoomManager } from './RoomManager';
import { MessageManager } from './MessageManager';
import { CryptoService } from './CryptoService';
import { VerificationService } from './VerificationService';
import { DeviceManager } from './DeviceManager';
import { MediaManager } from './MediaManager';
import { PushManager } from './PushManager';
import { RoomTagManager } from './RoomTagManager';
import { UserManager } from './UserManager';
import { UserAuthManager } from './UserAuthManager';
import { DeviceSecurityManager } from './DeviceSecurityManager';
import { ScanManager } from './ScanManager';
import { ShareManager } from './ShareManager';
import { ServiceCollaborationManager } from './ServiceCollaborationManager';
import { EventProcessor } from './EventProcessor';
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
  private cryptoService: CryptoService | null = null;
  private verificationService: VerificationService | null = null;
  private deviceManager: DeviceManager | null = null;
  private mediaManager: MediaManager | null = null;
  private pushManager: PushManager | null = null;
  private roomTagManager: RoomTagManager | null = null;
  private userManager: UserManager | null = null;
  private localDatabase: LocalDatabase | null = null;
  private userAuthManager: UserAuthManager | null = null;
  private deviceSecurityManager: DeviceSecurityManager | null = null;
  private scanManager: ScanManager | null = null;
  private shareManager: ShareManager | null = null;
  private serviceCollaborationManager: ServiceCollaborationManager | null = null;
  private eventProcessor: EventProcessor | null = null;

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

  registerEventProcessor(processor: EventProcessor): void {
    this.eventProcessor = processor;
    logger.info('EventProcessor registered');
  }

  getEventProcessor(): EventProcessor {
    if (!this.eventProcessor) {
      throw new Error('EventProcessor not initialized');
    }
    return this.eventProcessor;
  }

  registerUserAuthManager(manager: UserAuthManager): void {
    this.userAuthManager = manager;
    logger.info('UserAuthManager registered');
  }

  getUserAuthManager(): UserAuthManager {
    if (!this.userAuthManager) {
      throw new Error('UserAuthManager not initialized');
    }
    return this.userAuthManager;
  }

  registerDeviceSecurityManager(manager: DeviceSecurityManager): void {
    this.deviceSecurityManager = manager;
    logger.info('DeviceSecurityManager registered');
  }

  getDeviceSecurityManager(): DeviceSecurityManager {
    if (!this.deviceSecurityManager) {
      throw new Error('DeviceSecurityManager not initialized');
    }
    return this.deviceSecurityManager;
  }

  registerScanManager(manager: ScanManager): void {
    this.scanManager = manager;
    logger.info('ScanManager registered');
  }

  getScanManager(): ScanManager {
    if (!this.scanManager) {
      throw new Error('ScanManager not initialized');
    }
    return this.scanManager;
  }

  registerShareManager(manager: ShareManager): void {
    this.shareManager = manager;
    logger.info('ShareManager registered');
  }

  getShareManager(): ShareManager {
    if (!this.shareManager) {
      throw new Error('ShareManager not initialized');
    }
    return this.shareManager;
  }

  registerServiceCollaborationManager(manager: ServiceCollaborationManager): void {
    this.serviceCollaborationManager = manager;
    logger.info('ServiceCollaborationManager registered');
  }

  getServiceCollaborationManager(): ServiceCollaborationManager {
    if (!this.serviceCollaborationManager) {
      throw new Error('ServiceCollaborationManager not initialized');
    }
    return this.serviceCollaborationManager;
  }

  reset(): void {
    this.connectionConfig = null;
    this.authManager = null;
    this.syncManager = null;
    this.roomManager = null;
    this.messageManager = null;
    this.cryptoService = null;
    this.verificationService = null;
    this.deviceManager = null;
    this.mediaManager = null;
    this.pushManager = null;
    this.roomTagManager = null;
    this.userManager = null;
    this.localDatabase = null;
    this.userAuthManager = null;
    this.deviceSecurityManager = null;
    this.scanManager = null;
    this.shareManager = null;
    this.serviceCollaborationManager = null;
    this.eventProcessor = null;
    AppStorage.set<ServiceRegistry>(REGISTRY_KEY, this as ServiceRegistry);
    logger.info('ServiceRegistry reset');
  }
}
