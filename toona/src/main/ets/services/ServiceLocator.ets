import { AuthManager, IAuthManager } from './AuthManager';
import { SyncManager, ISyncManager } from './SyncManager';
import { RoomManager, IRoomManager } from './RoomManager';
import { MessageManager, IMessageManager } from './MessageManager';
import { MessageSender, IMessageSender } from './MessageSender';
import { CryptoService } from './CryptoService';
import { VerificationService, IVerificationService } from './VerificationService';
import { DeviceManager, IDeviceManager } from './DeviceManager';
import { MediaManager, IMediaManager } from './MediaManager';
import { PushManager, IPushManager } from './PushManager';
import { RoomTagManager, IRoomTagManager } from './RoomTagManager';
import { UserManager, IUserManager } from './UserManager';
import { DeviceSecurityManager, IDeviceSecurityManager } from './DeviceSecurityManager';
import { ScanManager, IScanManager } from './ScanManager';
import { ShareManager, IShareManager } from './ShareManager';
import { EventProcessor } from './EventProcessor';
import { LocalDatabase } from '../database/LocalDatabase';
import { ConnectionConfig } from '../network/ConnectionConfig';
import { IFilePicker } from '../platform/adapters/IFilePicker';
import { IClipboard } from '../platform/adapters/IClipboard';
import { IAudioRecorder } from '../platform/adapters/IAudioRecorder';
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
  private static readonly DEVICE_SECURITY_KEY: string = 'svc_deviceSecurityManager';
  private static readonly SCAN_KEY: string = 'svc_scanManager';
  private static readonly SHARE_KEY: string = 'svc_shareManager';
  private static readonly EVENT_PROCESSOR_KEY: string = 'svc_eventProcessor';
  private static readonly CONNECTION_CONFIG_KEY: string = 'svc_connectionConfig';
  private static readonly MESSAGE_SENDER_KEY: string = 'svc_messageSender';
  private static readonly FILE_PICKER_KEY: string = 'svc_filePicker';
  private static readonly CLIPBOARD_KEY: string = 'svc_clipboard';
  private static readonly AUDIO_RECORDER_KEY: string = 'svc_audioRecorder';

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

  static getMessageManager(): IMessageManager {
    const mgr: MessageManager | undefined = AppStorage.get<MessageManager>(ServiceLocator.MESSAGE_KEY);
    if (!mgr) {
      throw new Error('MessageManager not initialized');
    }
    return mgr;
  }

  static setMessageSender(sender: MessageSender): void {
    AppStorage.setOrCreate<MessageSender>(ServiceLocator.MESSAGE_SENDER_KEY, sender);
    logger.info('MessageSender registered');
  }

  static getMessageSender(): IMessageSender {
    const sender: MessageSender | undefined = AppStorage.get<MessageSender>(ServiceLocator.MESSAGE_SENDER_KEY);
    if (!sender) {
      throw new Error('MessageSender not initialized');
    }
    return sender;
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

  static getVerificationService(): IVerificationService {
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

  static getDeviceManager(): IDeviceManager {
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

  static getMediaManager(): IMediaManager {
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

  static getPushManager(): IPushManager {
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

  static getRoomTagManager(): IRoomTagManager {
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

  static getUserManager(): IUserManager {
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

  static setDeviceSecurityManager(mgr: DeviceSecurityManager): void {
    AppStorage.setOrCreate<DeviceSecurityManager>(ServiceLocator.DEVICE_SECURITY_KEY, mgr);
    logger.info('DeviceSecurityManager registered');
  }

  static getDeviceSecurityManager(): IDeviceSecurityManager {
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

  static getScanManager(): IScanManager {
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

  static getShareManager(): IShareManager {
    const mgr: ShareManager | undefined = AppStorage.get<ShareManager>(ServiceLocator.SHARE_KEY);
    if (!mgr) {
      throw new Error('ShareManager not initialized');
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

  static setFilePicker(picker: IFilePicker): void {
    AppStorage.setOrCreate<Object>(ServiceLocator.FILE_PICKER_KEY, picker);
    logger.info('FilePicker registered');
  }

  static getFilePicker(): IFilePicker {
    const picker: Object | undefined = AppStorage.get<Object>(ServiceLocator.FILE_PICKER_KEY);
    if (!picker) {
      throw new Error('FilePicker not initialized');
    }
    return picker as IFilePicker;
  }

  static setClipboard(clipboard: IClipboard): void {
    AppStorage.setOrCreate<Object>(ServiceLocator.CLIPBOARD_KEY, clipboard);
    logger.info('Clipboard registered');
  }

  static getClipboard(): IClipboard {
    const clipboard: Object | undefined = AppStorage.get<Object>(ServiceLocator.CLIPBOARD_KEY);
    if (!clipboard) {
      throw new Error('Clipboard not initialized');
    }
    return clipboard as IClipboard;
  }

  static setAudioRecorder(recorder: IAudioRecorder): void {
    AppStorage.setOrCreate<Object>(ServiceLocator.AUDIO_RECORDER_KEY, recorder);
    logger.info('AudioRecorder registered');
  }

  static getAudioRecorder(): IAudioRecorder {
    const recorder: Object | undefined = AppStorage.get<Object>(ServiceLocator.AUDIO_RECORDER_KEY);
    if (!recorder) {
      throw new Error('AudioRecorder not initialized');
    }
    return recorder as IAudioRecorder;
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
    AppStorage.set<DeviceSecurityManager | undefined>(ServiceLocator.DEVICE_SECURITY_KEY, undefined);
    AppStorage.set<ScanManager | undefined>(ServiceLocator.SCAN_KEY, undefined);
    AppStorage.set<ShareManager | undefined>(ServiceLocator.SHARE_KEY, undefined);
    AppStorage.set<EventProcessor | undefined>(ServiceLocator.EVENT_PROCESSOR_KEY, undefined);
    AppStorage.set<ConnectionConfig | undefined>(ServiceLocator.CONNECTION_CONFIG_KEY, undefined);
    AppStorage.set<MessageSender | undefined>(ServiceLocator.MESSAGE_SENDER_KEY, undefined);
    AppStorage.set<Object | undefined>(ServiceLocator.FILE_PICKER_KEY, undefined);
    AppStorage.set<Object | undefined>(ServiceLocator.CLIPBOARD_KEY, undefined);
    AppStorage.set<Object | undefined>(ServiceLocator.AUDIO_RECORDER_KEY, undefined);
    logger.info('ServiceLocator reset');
  }
}
