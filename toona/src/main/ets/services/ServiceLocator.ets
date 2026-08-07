import { AuthManager, IAuthManager } from './AuthManager';
import { SyncManager, ISyncManager } from './SyncManager';
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

const logger = AppLogger.getLogger('ServiceLocator');

export class ServiceLocator {
  private static readonly AUTH_KEY: string = 'svc_authManager';
  private static readonly SYNC_KEY: string = 'svc_syncManager';
  private static readonly ROOM_KEY: string = 'svc_roomManager';
  private static readonly MESSAGE_KEY: string = 'svc_messageManager';
  private static readonly CRYPTO_KEY: string = 'svc_cryptoService';
  private static readonly VERIFICATION_KEY: string = 'svc_verificationService';
  private static readonly DEVICE_KEY: string = 'svc_deviceManager';
  private static readonly MEDIA_KEY: string = 'svc_mediaManager';
  private static readonly PUSH_KEY: string = 'svc_pushManager';
  private static readonly ROOM_TAG_KEY: string = 'svc_roomTagManager';
  private static readonly USER_KEY: string = 'svc_userManager';
  private static readonly LOCAL_DB_KEY: string = 'svc_localDatabase';
  private static readonly USER_AUTH_KEY: string = 'svc_userAuthManager';
  private static readonly DEVICE_SECURITY_KEY: string = 'svc_deviceSecurityManager';
  private static readonly SCAN_KEY: string = 'svc_scanManager';
  private static readonly SHARE_KEY: string = 'svc_shareManager';
  private static readonly COLLABORATION_KEY: string = 'svc_serviceCollaborationManager';
  private static readonly EVENT_PROCESSOR_KEY: string = 'svc_eventProcessor';
  private static readonly CONNECTION_CONFIG_KEY: string = 'svc_connectionConfig';

  static setAuthManager(mgr: AuthManager): void {
    AppStorage.setOrCreate<AuthManager>(ServiceLocator.AUTH_KEY, mgr);
    logger.info('AuthManager registered');
  }

  static getAuthManager(): IAuthManager {
    const mgr: AuthManager | undefined = AppStorage.get<AuthManager>(ServiceLocator.AUTH_KEY);
    if (!mgr) {
      throw new Error('AuthManager not initialized');
    }
    return mgr;
  }

  static setSyncManager(mgr: SyncManager): void {
    AppStorage.setOrCreate<SyncManager>(ServiceLocator.SYNC_KEY, mgr);
    logger.info('SyncManager registered');
  }

  static getSyncManager(): ISyncManager {
    const mgr: SyncManager | undefined = AppStorage.get<SyncManager>(ServiceLocator.SYNC_KEY);
    if (!mgr) {
      throw new Error('SyncManager not initialized');
    }
    return mgr;
  }

  static setRoomManager(mgr: RoomManager): void {
    AppStorage.setOrCreate<RoomManager>(ServiceLocator.ROOM_KEY, mgr);
    logger.info('RoomManager registered');
  }

  static getRoomManager(): IRoomManager {
    const mgr: RoomManager | undefined = AppStorage.get<RoomManager>(ServiceLocator.ROOM_KEY);
    if (!mgr) {
      throw new Error('RoomManager not initialized');
    }
    return mgr;
  }

  static setMessageManager(mgr: MessageManager): void {
    AppStorage.setOrCreate<MessageManager>(ServiceLocator.MESSAGE_KEY, mgr);
    logger.info('MessageManager registered');
  }

  static getMessageManager(): MessageManager {
    const mgr: MessageManager | undefined = AppStorage.get<MessageManager>(ServiceLocator.MESSAGE_KEY);
    if (!mgr) {
      throw new Error('MessageManager not initialized');
    }
    return mgr;
  }

  static setCryptoService(svc: CryptoService): void {
    AppStorage.setOrCreate<CryptoService>(ServiceLocator.CRYPTO_KEY, svc);
    logger.info('CryptoService registered');
  }

  static getCryptoService(): CryptoService {
    const svc: CryptoService | undefined = AppStorage.get<CryptoService>(ServiceLocator.CRYPTO_KEY);
    if (!svc) {
      throw new Error('CryptoService not initialized');
    }
    return svc;
  }

  static setVerificationService(svc: VerificationService): void {
    AppStorage.setOrCreate<VerificationService>(ServiceLocator.VERIFICATION_KEY, svc);
    logger.info('VerificationService registered');
  }

  static getVerificationService(): VerificationService {
    const svc: VerificationService | undefined = AppStorage.get<VerificationService>(ServiceLocator.VERIFICATION_KEY);
    if (!svc) {
      throw new Error('VerificationService not initialized');
    }
    return svc;
  }

  static setDeviceManager(mgr: DeviceManager): void {
    AppStorage.setOrCreate<DeviceManager>(ServiceLocator.DEVICE_KEY, mgr);
    logger.info('DeviceManager registered');
  }

  static getDeviceManager(): DeviceManager {
    const mgr: DeviceManager | undefined = AppStorage.get<DeviceManager>(ServiceLocator.DEVICE_KEY);
    if (!mgr) {
      throw new Error('DeviceManager not initialized');
    }
    return mgr;
  }

  static setMediaManager(mgr: MediaManager): void {
    AppStorage.setOrCreate<MediaManager>(ServiceLocator.MEDIA_KEY, mgr);
    logger.info('MediaManager registered');
  }

  static getMediaManager(): MediaManager {
    const mgr: MediaManager | undefined = AppStorage.get<MediaManager>(ServiceLocator.MEDIA_KEY);
    if (!mgr) {
      throw new Error('MediaManager not initialized');
    }
    return mgr;
  }

  static setPushManager(mgr: PushManager): void {
    AppStorage.setOrCreate<PushManager>(ServiceLocator.PUSH_KEY, mgr);
    logger.info('PushManager registered');
  }

  static getPushManager(): PushManager {
    const mgr: PushManager | undefined = AppStorage.get<PushManager>(ServiceLocator.PUSH_KEY);
    if (!mgr) {
      throw new Error('PushManager not initialized');
    }
    return mgr;
  }

  static setRoomTagManager(mgr: RoomTagManager): void {
    AppStorage.setOrCreate<RoomTagManager>(ServiceLocator.ROOM_TAG_KEY, mgr);
    logger.info('RoomTagManager registered');
  }

  static getRoomTagManager(): RoomTagManager {
    const mgr: RoomTagManager | undefined = AppStorage.get<RoomTagManager>(ServiceLocator.ROOM_TAG_KEY);
    if (!mgr) {
      throw new Error('RoomTagManager not initialized');
    }
    return mgr;
  }

  static setUserManager(mgr: UserManager): void {
    AppStorage.setOrCreate<UserManager>(ServiceLocator.USER_KEY, mgr);
    logger.info('UserManager registered');
  }

  static getUserManager(): UserManager {
    const mgr: UserManager | undefined = AppStorage.get<UserManager>(ServiceLocator.USER_KEY);
    if (!mgr) {
      throw new Error('UserManager not initialized');
    }
    return mgr;
  }

  static setLocalDatabase(db: LocalDatabase): void {
    AppStorage.setOrCreate<LocalDatabase>(ServiceLocator.LOCAL_DB_KEY, db);
    logger.info('LocalDatabase registered');
  }

  static getLocalDatabase(): LocalDatabase {
    const db: LocalDatabase | undefined = AppStorage.get<LocalDatabase>(ServiceLocator.LOCAL_DB_KEY);
    if (!db) {
      throw new Error('LocalDatabase not initialized');
    }
    return db;
  }

  static setUserAuthManager(mgr: UserAuthManager): void {
    AppStorage.setOrCreate<UserAuthManager>(ServiceLocator.USER_AUTH_KEY, mgr);
    logger.info('UserAuthManager registered');
  }

  static getUserAuthManager(): UserAuthManager {
    const mgr: UserAuthManager | undefined = AppStorage.get<UserAuthManager>(ServiceLocator.USER_AUTH_KEY);
    if (!mgr) {
      throw new Error('UserAuthManager not initialized');
    }
    return mgr;
  }

  static setDeviceSecurityManager(mgr: DeviceSecurityManager): void {
    AppStorage.setOrCreate<DeviceSecurityManager>(ServiceLocator.DEVICE_SECURITY_KEY, mgr);
    logger.info('DeviceSecurityManager registered');
  }

  static getDeviceSecurityManager(): DeviceSecurityManager {
    const mgr: DeviceSecurityManager | undefined = AppStorage.get<DeviceSecurityManager>(ServiceLocator.DEVICE_SECURITY_KEY);
    if (!mgr) {
      throw new Error('DeviceSecurityManager not initialized');
    }
    return mgr;
  }

  static setScanManager(mgr: ScanManager): void {
    AppStorage.setOrCreate<ScanManager>(ServiceLocator.SCAN_KEY, mgr);
    logger.info('ScanManager registered');
  }

  static getScanManager(): ScanManager {
    const mgr: ScanManager | undefined = AppStorage.get<ScanManager>(ServiceLocator.SCAN_KEY);
    if (!mgr) {
      throw new Error('ScanManager not initialized');
    }
    return mgr;
  }

  static setShareManager(mgr: ShareManager): void {
    AppStorage.setOrCreate<ShareManager>(ServiceLocator.SHARE_KEY, mgr);
    logger.info('ShareManager registered');
  }

  static getShareManager(): ShareManager {
    const mgr: ShareManager | undefined = AppStorage.get<ShareManager>(ServiceLocator.SHARE_KEY);
    if (!mgr) {
      throw new Error('ShareManager not initialized');
    }
    return mgr;
  }

  static setServiceCollaborationManager(mgr: ServiceCollaborationManager): void {
    AppStorage.setOrCreate<ServiceCollaborationManager>(ServiceLocator.COLLABORATION_KEY, mgr);
    logger.info('ServiceCollaborationManager registered');
  }

  static getServiceCollaborationManager(): ServiceCollaborationManager {
    const mgr: ServiceCollaborationManager | undefined = AppStorage.get<ServiceCollaborationManager>(ServiceLocator.COLLABORATION_KEY);
    if (!mgr) {
      throw new Error('ServiceCollaborationManager not initialized');
    }
    return mgr;
  }

  static setEventProcessor(proc: EventProcessor): void {
    AppStorage.setOrCreate<EventProcessor>(ServiceLocator.EVENT_PROCESSOR_KEY, proc);
    logger.info('EventProcessor registered');
  }

  static getEventProcessor(): EventProcessor {
    const proc: EventProcessor | undefined = AppStorage.get<EventProcessor>(ServiceLocator.EVENT_PROCESSOR_KEY);
    if (!proc) {
      throw new Error('EventProcessor not initialized');
    }
    return proc;
  }

  static setConnectionConfig(config: ConnectionConfig): void {
    AppStorage.setOrCreate<ConnectionConfig>(ServiceLocator.CONNECTION_CONFIG_KEY, config);
    logger.info('ConnectionConfig registered');
  }

  static getConnectionConfig(): ConnectionConfig {
    const config: ConnectionConfig | undefined = AppStorage.get<ConnectionConfig>(ServiceLocator.CONNECTION_CONFIG_KEY);
    if (!config) {
      throw new Error('ConnectionConfig not initialized');
    }
    return config;
  }

  static reset(): void {
    AppStorage.set<AuthManager | undefined>(ServiceLocator.AUTH_KEY, undefined);
    AppStorage.set<SyncManager | undefined>(ServiceLocator.SYNC_KEY, undefined);
    AppStorage.set<RoomManager | undefined>(ServiceLocator.ROOM_KEY, undefined);
    AppStorage.set<MessageManager | undefined>(ServiceLocator.MESSAGE_KEY, undefined);
    AppStorage.set<CryptoService | undefined>(ServiceLocator.CRYPTO_KEY, undefined);
    AppStorage.set<VerificationService | undefined>(ServiceLocator.VERIFICATION_KEY, undefined);
    AppStorage.set<DeviceManager | undefined>(ServiceLocator.DEVICE_KEY, undefined);
    AppStorage.set<MediaManager | undefined>(ServiceLocator.MEDIA_KEY, undefined);
    AppStorage.set<PushManager | undefined>(ServiceLocator.PUSH_KEY, undefined);
    AppStorage.set<RoomTagManager | undefined>(ServiceLocator.ROOM_TAG_KEY, undefined);
    AppStorage.set<UserManager | undefined>(ServiceLocator.USER_KEY, undefined);
    AppStorage.set<LocalDatabase | undefined>(ServiceLocator.LOCAL_DB_KEY, undefined);
    AppStorage.set<UserAuthManager | undefined>(ServiceLocator.USER_AUTH_KEY, undefined);
    AppStorage.set<DeviceSecurityManager | undefined>(ServiceLocator.DEVICE_SECURITY_KEY, undefined);
    AppStorage.set<ScanManager | undefined>(ServiceLocator.SCAN_KEY, undefined);
    AppStorage.set<ShareManager | undefined>(ServiceLocator.SHARE_KEY, undefined);
    AppStorage.set<ServiceCollaborationManager | undefined>(ServiceLocator.COLLABORATION_KEY, undefined);
    AppStorage.set<EventProcessor | undefined>(ServiceLocator.EVENT_PROCESSOR_KEY, undefined);
    AppStorage.set<ConnectionConfig | undefined>(ServiceLocator.CONNECTION_CONFIG_KEY, undefined);
    logger.info('ServiceLocator reset');
  }
}
