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
import { ServiceLocator } from './ServiceLocator';

/**
 * @deprecated Use ServiceLocator and facade classes instead.
 * This class is kept for backward compatibility and delegates all operations to ServiceLocator.
 */
export class ServiceRegistry {
  static init(registry: ServiceRegistry): void {
    ServiceLocator.setConnectionConfig(registry.getConnectionConfig());
    ServiceLocator.setAuthManager(registry.getAuthManager() as AuthManager);
    ServiceLocator.setLocalDatabase(registry.getLocalDatabase());
    ServiceLocator.setSyncManager(registry.getSyncManager() as SyncManager);
    ServiceLocator.setRoomManager(registry.getRoomManager() as RoomManager);
    ServiceLocator.setMessageManager(registry.getMessageManager());
    ServiceLocator.setCryptoService(registry.getCryptoService());
    ServiceLocator.setVerificationService(registry.getVerificationService());
    ServiceLocator.setDeviceManager(registry.getDeviceManager());
    ServiceLocator.setMediaManager(registry.getMediaManager());
    ServiceLocator.setPushManager(registry.getPushManager());
    ServiceLocator.setRoomTagManager(registry.getRoomTagManager());
    ServiceLocator.setUserManager(registry.getUserManager());
    ServiceLocator.setEventProcessor(registry.getEventProcessor());
    ServiceLocator.setUserAuthManager(registry.getUserAuthManager());
    ServiceLocator.setDeviceSecurityManager(registry.getDeviceSecurityManager());
    ServiceLocator.setScanManager(registry.getScanManager());
    ServiceLocator.setShareManager(registry.getShareManager());
    ServiceLocator.setServiceCollaborationManager(registry.getServiceCollaborationManager());
  }

  static getCurrent(): ServiceRegistry {
    return new ServiceRegistry();
  }

  registerConnectionConfig(config: ConnectionConfig): void {
    ServiceLocator.setConnectionConfig(config);
  }

  getConnectionConfig(): ConnectionConfig {
    return ServiceLocator.getConnectionConfig();
  }

  registerAuthManager(manager: AuthManager): void {
    ServiceLocator.setAuthManager(manager);
  }

  getAuthManager(): IAuthManager {
    return ServiceLocator.getAuthManager();
  }

  registerSyncManager(manager: SyncManager): void {
    ServiceLocator.setSyncManager(manager);
  }

  getSyncManager(): SyncManager {
    return ServiceLocator.getSyncManager() as SyncManager;
  }

  registerRoomManager(manager: RoomManager): void {
    ServiceLocator.setRoomManager(manager);
  }

  getRoomManager(): IRoomManager {
    return ServiceLocator.getRoomManager();
  }

  registerMessageManager(manager: MessageManager): void {
    ServiceLocator.setMessageManager(manager);
  }

  getMessageManager(): MessageManager {
    return ServiceLocator.getMessageManager();
  }

  registerDeviceManager(manager: DeviceManager): void {
    ServiceLocator.setDeviceManager(manager);
  }

  getDeviceManager(): DeviceManager {
    return ServiceLocator.getDeviceManager();
  }

  registerMediaManager(manager: MediaManager): void {
    ServiceLocator.setMediaManager(manager);
  }

  getMediaManager(): MediaManager {
    return ServiceLocator.getMediaManager();
  }

  registerPushManager(manager: PushManager): void {
    ServiceLocator.setPushManager(manager);
  }

  getPushManager(): PushManager {
    return ServiceLocator.getPushManager();
  }

  registerRoomTagManager(manager: RoomTagManager): void {
    ServiceLocator.setRoomTagManager(manager);
  }

  getRoomTagManager(): RoomTagManager {
    return ServiceLocator.getRoomTagManager();
  }

  registerUserManager(manager: UserManager): void {
    ServiceLocator.setUserManager(manager);
  }

  getUserManager(): UserManager {
    return ServiceLocator.getUserManager();
  }

  registerLocalDatabase(database: LocalDatabase): void {
    ServiceLocator.setLocalDatabase(database);
  }

  getLocalDatabase(): LocalDatabase {
    return ServiceLocator.getLocalDatabase();
  }

  registerCryptoService(service: CryptoService): void {
    ServiceLocator.setCryptoService(service);
  }

  getCryptoService(): CryptoService {
    return ServiceLocator.getCryptoService();
  }

  registerVerificationService(service: VerificationService): void {
    ServiceLocator.setVerificationService(service);
  }

  getVerificationService(): VerificationService {
    return ServiceLocator.getVerificationService();
  }

  registerEventProcessor(processor: EventProcessor): void {
    ServiceLocator.setEventProcessor(processor);
  }

  getEventProcessor(): EventProcessor {
    return ServiceLocator.getEventProcessor();
  }

  registerUserAuthManager(manager: UserAuthManager): void {
    ServiceLocator.setUserAuthManager(manager);
  }

  getUserAuthManager(): UserAuthManager {
    return ServiceLocator.getUserAuthManager();
  }

  registerDeviceSecurityManager(manager: DeviceSecurityManager): void {
    ServiceLocator.setDeviceSecurityManager(manager);
  }

  getDeviceSecurityManager(): DeviceSecurityManager {
    return ServiceLocator.getDeviceSecurityManager();
  }

  registerScanManager(manager: ScanManager): void {
    ServiceLocator.setScanManager(manager);
  }

  getScanManager(): ScanManager {
    return ServiceLocator.getScanManager();
  }

  registerShareManager(manager: ShareManager): void {
    ServiceLocator.setShareManager(manager);
  }

  getShareManager(): ShareManager {
    return ServiceLocator.getShareManager();
  }

  registerServiceCollaborationManager(manager: ServiceCollaborationManager): void {
    ServiceLocator.setServiceCollaborationManager(manager);
  }

  getServiceCollaborationManager(): ServiceCollaborationManager {
    return ServiceLocator.getServiceCollaborationManager();
  }

  reset(): void {
    ServiceLocator.reset();
  }
}
