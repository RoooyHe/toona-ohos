import { AppLogger } from '../utils/AppLogger';
import { CryptoStub, MegolmSession } from '../crypto/CryptoStub';
import {
  DeviceIdentity,
  RoomKeyEvent,
  EncryptedEventContent,
  DecryptedEvent,
  VerificationRequestEvent,
  VerificationReadyEvent,
  VerificationStartEvent,
  VerificationKeyEvent,
  VerificationMacEvent,
  VerificationCancelEvent,
  MEGOLM_ALGORITHM,
  ONE_TIME_KEY_TARGET,
  KEY_VERIFICATION_REQUEST,
  KEY_VERIFICATION_READY,
  KEY_VERIFICATION_START,
  KEY_VERIFICATION_KEY,
  KEY_VERIFICATION_MAC,
  KEY_VERIFICATION_CANCEL,
  KEY_VERIFICATION_DONE
} from '../crypto/types/CryptoTypes';
import { CryptoDao } from '../database/dao/CryptoDao';
import { DeviceKeysStorage } from '../database/dao/DeviceKeysDao';
import { InboundGroupSessionEntity } from '../database/entities/InboundGroupSessionEntity';
import { AuthManager, IAuthManager } from './AuthManager';
import { VerificationService } from './VerificationService';

const logger = AppLogger.getLogger('CryptoService');

interface ToDeviceEventInternal {
  type: string;
  sender: string;
  content: Record<string, string | object>;
}

export interface EncryptedMatrixEvent {
  event_id: string;
  room_id: string;
  sender: string;
  type: string;
  content: Record<string, string | object>;
  origin_server_ts: number;
}

interface DecryptedErrorContent {
  body: string;
  msgtype: string;
}

interface KeyRequestBody {
  algorithm: string;
  room_id: string;
  session_id: string;
  sender_key: string;
}

interface KeyRequestContent {
  action: string;
  requesting_user_id: string;
  requesting_device_id: string;
  request_id: string;
  body: KeyRequestBody;
}

interface KeyRequestEvent {
  type: string;
  content: KeyRequestContent;
}

export class CryptoService {
  private initialized: boolean = false;
  private cryptoDao: CryptoDao;
  private deviceKeysStorage: DeviceKeysStorage;
  private authManager: IAuthManager;
  private verificationService: VerificationService;

  private deviceId: string = '';
  private deviceIdentity: DeviceIdentity | null = null;

  private inboundGroupSessions: Map<string, MegolmSession> = new Map();
  private pendingRoomKeys: Map<string, RoomKeyEvent[]> = new Map();

  private decryptionCallbacks: Array<(roomId: string, eventId: string) => void> = [];

  constructor(
    authManager: IAuthManager,
    verificationService: VerificationService,
    cryptoDao: CryptoDao,
    deviceKeysStorage: DeviceKeysStorage
  ) {
    this.authManager = authManager;
    this.verificationService = verificationService;
    this.cryptoDao = cryptoDao;
    this.deviceKeysStorage = deviceKeysStorage;
  }

  async initialize(): Promise<void> {
    if (this.initialized) {
      logger.info('CryptoService already initialized');
      return;
    }

    try {
      logger.info('Initializing CryptoService (E2EE not available — encryption stubs active)');

      CryptoStub.initialize();

      this.deviceId = await this.getOrCreateDeviceId();

      await this.loadDeviceKeysIfAvailable();

      await this.loadCachedSessions();

      logger.info('CryptoService initialized (encryption stubs active — no key upload)');

      this.initialized = true;
    } catch (error) {
      logger.error('Failed to initialize CryptoService:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`CryptoService initialization failed: ${errMsg}`);
    }
  }

  onDecrypted(callback: (roomId: string, eventId: string) => void): void {
    this.decryptionCallbacks.push(callback);
  }

  private notifyDecrypted(roomId: string, eventId: string): void {
    for (const callback of this.decryptionCallbacks) {
      try {
        callback(roomId, eventId);
      } catch (error) {
        logger.error('Error in decryption callback:', error);
      }
    }
  }

  private async getOrCreateDeviceId(): Promise<string> {
    const session = this.authManager.getSession();
    if (!session) {
      throw new Error('No active session');
    }

    const existingKeys = await this.deviceKeysStorage.getDeviceKeys(session.userId);
    if (existingKeys && existingKeys.device_id) {
      logger.info(`Loaded existing device ID: ${existingKeys.device_id}`);
      return existingKeys.device_id;
    }

    const devicePrefix = 'TOONA_';
    const randomPart: string = Date.now().toString(36).toUpperCase();
    const newDeviceId: string = `${devicePrefix}${randomPart}`;
    logger.info(`Generated device ID (no crypto keys): ${newDeviceId}`);
    return newDeviceId;
  }

  private async loadDeviceKeysIfAvailable(): Promise<void> {
    const session = this.authManager.getSession();
    if (!session) {
      return;
    }

    const existingKeys = await this.deviceKeysStorage.getDeviceKeys(session.userId);
    if (existingKeys && existingKeys.ed25519_key && existingKeys.curve25519_key) {
      this.deviceIdentity = {
        userId: session.userId,
        deviceId: existingKeys.device_id,
        ed25519Key: existingKeys.ed25519_key,
        curve25519Key: existingKeys.curve25519_key,
        algorithms: JSON.parse(existingKeys.algorithms),
        signatures: JSON.parse(existingKeys.signatures)
      };
      logger.info(`Loaded existing device keys for ${existingKeys.device_id}`);
    } else {
      logger.info('No device keys available — E2EE not implemented');
      this.deviceIdentity = null;
    }
  }

  private async loadCachedSessions(): Promise<void> {
    try {
      const sessions = await this.cryptoDao.getAllInboundGroupSessions();
      for (const entity of sessions) {
        const session = CryptoStub.unpickleSession(entity.session_data, '');
        if (session) {
          const cacheKey = `${entity.room_id}:${entity.megolm_session_id}`;
          this.inboundGroupSessions.set(cacheKey, session);
        }
      }
      logger.info(`Loaded ${sessions.length} cached Megolm sessions`);
    } catch (error) {
      logger.error('Failed to load cached sessions:', error);
    }
  }

  async processToDeviceEvent(event: ToDeviceEventInternal): Promise<void> {
    if (!this.initialized) {
      logger.warn('CryptoService not initialized, queuing event');
      return;
    }

    try {
      const content: Record<string, string | object> = event.content;
      switch (event.type) {
        case 'm.room_key':
          await this.handleRoomKeyEvent(this.contentToRoomKeyEvent(content));
          break;
        case 'm.room_key_request':
          await this.handleRoomKeyRequest(content);
          break;
        case 'm.forwarded_room_key':
          await this.handleForwardedRoomKeyEvent(this.contentToRoomKeyEvent(content));
          break;
        case 'm.room_key_request.cancellation':
          await this.handleRoomKeyRequestCancellation(content);
          break;
        case KEY_VERIFICATION_REQUEST:
          await this.handleVerificationRequest(this.contentToVerificationRequestEvent(content));
          break;
        case KEY_VERIFICATION_READY:
          await this.handleVerificationReady(this.contentToVerificationReadyEvent(content));
          break;
        case KEY_VERIFICATION_START:
          await this.handleVerificationStart(this.contentToVerificationStartEvent(content));
          break;
        case KEY_VERIFICATION_KEY:
          await this.handleVerificationKey(this.contentToVerificationKeyEvent(content));
          break;
        case KEY_VERIFICATION_MAC:
          await this.handleVerificationMac(this.contentToVerificationMacEvent(content));
          break;
        case KEY_VERIFICATION_CANCEL:
          await this.handleVerificationCancel(this.contentToVerificationCancelEvent(content));
          break;
        case KEY_VERIFICATION_DONE:
          await this.handleVerificationDone(content);
          break;
        default:
          logger.info(`Unhandled to-device event type: ${event.type}`);
      }
    } catch (error) {
      logger.error(`Failed to process to-device event ${event.type}:`, error);
    }
  }

  private contentToRoomKeyEvent(content: Record<string, string | object>): RoomKeyEvent {
    const evt: RoomKeyEvent = {
      type: content['type'] as string,
      algorithm: content['algorithm'] as string,
      room_id: content['room_id'] as string,
      session_id: content['session_id'] as string,
      session_key: content['session_key'] as string,
      sender_key: content['sender_key'] as string
    };
    return evt;
  }

  private contentToVerificationRequestEvent(content: Record<string, string | object>): VerificationRequestEvent {
    const methods: string[] = content['methods'] as string[];
    const evt: VerificationRequestEvent = {
      from_device: content['from_device'] as string,
      methods: methods,
      timestamp: Number(content['timestamp']),
      transaction_id: content['transaction_id'] as string
    };
    return evt;
  }

  private contentToVerificationReadyEvent(content: Record<string, string | object>): VerificationReadyEvent {
    const methods: string[] = content['methods'] as string[];
    const evt: VerificationReadyEvent = {
      methods: methods,
      transaction_id: content['transaction_id'] as string
    };
    return evt;
  }

  private contentToVerificationStartEvent(content: Record<string, string | object>): VerificationStartEvent {
    const evt: VerificationStartEvent = {
      method: content['method'] as string,
      short_authentication_string: content['short_authentication_string'] as string[],
      transaction_id: content['transaction_id'] as string,
      key_agreement_protocols: content['key_agreement_protocols'] as string[],
      hashes: content['hashes'] as string[],
      authentication_codes: content['authentication_codes'] as string[]
    };
    return evt;
  }

  private contentToVerificationKeyEvent(content: Record<string, string | object>): VerificationKeyEvent {
    const evt: VerificationKeyEvent = {
      key: content['key'] as string,
      transaction_id: content['transaction_id'] as string
    };
    return evt;
  }

  private contentToVerificationMacEvent(content: Record<string, string | object>): VerificationMacEvent {
    const evt: VerificationMacEvent = {
      keys: content['keys'] as string,
      mac: content['mac'] as Record<string, string>,
      transaction_id: content['transaction_id'] as string
    };
    return evt;
  }

  private contentToVerificationCancelEvent(content: Record<string, string | object>): VerificationCancelEvent {
    const evt: VerificationCancelEvent = {
      code: content['code'] as string,
      reason: content['reason'] as string,
      transaction_id: content['transaction_id'] as string
    };
    return evt;
  }

  private async handleRoomKeyEvent(event: RoomKeyEvent): Promise<void> {
    logger.info(`Received room key for room ${event.room_id}`);

    if (!event.room_id || !event.session_id || !event.session_key) {
      logger.error('Invalid room key event: missing required fields');
      return;
    }

    const session = CryptoStub.createInboundGroupSession(
      event.room_id,
      event.sender_key || '',
      event.session_id,
      event.session_key
    );

    const cacheKey = `${event.room_id}:${event.session_id}`;
    this.inboundGroupSessions.set(cacheKey, session);

    const entity = new InboundGroupSessionEntity();
    entity.sessionId = cacheKey;
    entity.room_id = event.room_id;
    entity.sender_key = event.sender_key || '';
    entity.megolm_session_id = event.session_id;
    entity.session_data = CryptoStub.pickleSession(session, '');
    entity.forwarding_chain = JSON.stringify(event.forwarding_curve25519_key_chain || []);
    entity.created_at = Date.now();

    await this.cryptoDao.saveInboundGroupSession(entity);

    logger.info(`Stored Megolm session ${event.session_id} for room ${event.room_id} (decryption not available)`);
  }

  private async handleRoomKeyRequest(content: Record<string, string | object>): Promise<void> {
    const requestingUserId = content['requesting_user_id'] as string;
    const requestingDevice = content['requesting_device_id'] as string;
    const sessionId = content['session_id'] as string;

    logger.info(`Received key request from ${requestingUserId}:${requestingDevice} for session ${sessionId} — key sharing not available (E2EE not implemented)`);
  }

  private async sendKeyShareResponse(
    requestingUserId: string,
    requestingDevice: string,
    session: MegolmSession
  ): Promise<void> {
    logger.info(`Key sharing not available — would send key for session ${session.sessionId} to ${requestingUserId}:${requestingDevice} (E2EE not implemented)`);
  }

  private async handleForwardedRoomKeyEvent(event: RoomKeyEvent): Promise<void> {
    logger.info(`Received forwarded room key for room ${event.room_id}`);

    if (!event.room_id || !event.session_id || !event.session_key) {
      logger.error('Invalid forwarded room key event: missing required fields');
      return;
    }

    const session = CryptoStub.createInboundGroupSession(
      event.room_id,
      event.sender_key || '',
      event.session_id,
      event.session_key
    );

    const cacheKey = `${event.room_id}:${event.session_id}`;
    this.inboundGroupSessions.set(cacheKey, session);

    const entity = new InboundGroupSessionEntity();
    entity.sessionId = cacheKey;
    entity.room_id = event.room_id;
    entity.sender_key = event.sender_key || '';
    entity.megolm_session_id = event.session_id;
    entity.session_data = CryptoStub.pickleSession(session, '');
    entity.forwarding_chain = JSON.stringify(event.forwarding_curve25519_key_chain || []);
    entity.created_at = Date.now();

    await this.cryptoDao.saveInboundGroupSession(entity);

    logger.info(`Stored forwarded Megolm session ${event.session_id} for room ${event.room_id} (decryption not available)`);
  }

  private async handleRoomKeyRequestCancellation(content: Record<string, string | object>): Promise<void> {
    const requestId = content['request_id'] as string;
    logger.info(`Received key request cancellation for request ${requestId}`);
  }

  private async handleVerificationRequest(event: VerificationRequestEvent): Promise<void> {
    logger.info(`Received verification request from device ${event.from_device}`);
    await this.verificationService.handleVerificationRequest(event, event.from_device);
  }

  private async handleVerificationReady(event: VerificationReadyEvent): Promise<void> {
    logger.info(`Verification ${event.transaction_id} is ready`);
    await this.verificationService.handleVerificationReady(event, '');
  }

  private async handleVerificationStart(event: VerificationStartEvent): Promise<void> {
    logger.info(`Verification ${event.transaction_id} started with method ${event.method}`);
    await this.verificationService.handleVerificationStart(event, '');
  }

  private async handleVerificationKey(event: VerificationKeyEvent): Promise<void> {
    logger.info(`Verification ${event.transaction_id} received key`);
    await this.verificationService.handleVerificationKey(event, '');
  }

  private async handleVerificationMac(event: VerificationMacEvent): Promise<void> {
    logger.info(`Verification ${event.transaction_id} received MAC`);
    await this.verificationService.handleVerificationMac(event, '');
  }

  private async handleVerificationCancel(event: VerificationCancelEvent): Promise<void> {
    logger.info(`Verification ${event.transaction_id} cancelled: ${event.reason}`);
    await this.verificationService.handleVerificationCancel(event, '');
  }

  private async handleVerificationDone(content: Record<string, string | object>): Promise<void> {
    const transactionId = content['transaction_id'] as string;
    logger.info(`Verification ${transactionId} completed`);
    await this.verificationService.handleVerificationDone(transactionId, '');
  }

  async decryptEvent(event: EncryptedMatrixEvent): Promise<DecryptedEvent> {
    if (!this.initialized) {
      return this.createDecryptionError(event, 'CryptoService not initialized');
    }

    const contentAlgo: string = (event.content['algorithm'] as string) || '';
    const contentSessionId: string = (event.content['session_id'] as string) || '';
    const contentCiphertext: string = (event.content['ciphertext'] as string) || '';
    const contentSenderId: string = (event.content['sender_key'] as string) || '';

    if (contentAlgo !== MEGOLM_ALGORITHM) {
      return this.createDecryptionError(event, `Unsupported algorithm: ${contentAlgo}`);
    }

    if (!contentSessionId || !contentCiphertext) {
      return this.createDecryptionError(event, 'Missing required fields');
    }

    const cacheKey = `${event.room_id}:${contentSessionId}`;
    let session: MegolmSession | undefined = this.inboundGroupSessions.get(cacheKey);

    if (!session) {
      const entity = await this.cryptoDao.getInboundGroupSession(cacheKey);
      if (entity) {
        const loaded = CryptoStub.unpickleSession(entity.session_data, '');
        if (loaded) {
          this.inboundGroupSessions.set(cacheKey, loaded);
          session = loaded;
        }
      }
    }

    if (!session) {
      const pendingEvent: RoomKeyEvent = {
        type: 'm.room_key',
        algorithm: contentAlgo,
        room_id: event.room_id,
        session_id: contentSessionId,
        session_key: '',
        sender_key: contentSenderId
      };
      const pending = this.pendingRoomKeys.get(event.room_id) || [];
      pending.push(pendingEvent);
      this.pendingRoomKeys.set(event.room_id, pending);

      return this.createDecryptionError(event, 'No session available for decryption');
    }

    const decryptedJson = CryptoStub.decryptGroupMessage(session, contentCiphertext);
    if (!decryptedJson) {
      return this.createDecryptionError(event, 'E2EE not available — decryption requires real Olm library');
    }

    const parsed = CryptoStub.parseDecryptedMessage(decryptedJson);
    if (!parsed) {
      return this.createDecryptionError(event, 'Failed to parse decrypted message');
    }

    const entity = new InboundGroupSessionEntity();
    entity.sessionId = cacheKey;
    entity.room_id = event.room_id;
    entity.sender_key = contentSenderId;
    entity.megolm_session_id = contentSessionId;
    entity.session_data = CryptoStub.pickleSession(session, '');
    entity.forwarding_chain = '[]';
    entity.created_at = Date.now();
    await this.cryptoDao.saveInboundGroupSession(entity);

    this.notifyDecrypted(event.room_id, event.event_id);

    const parsedType: string = (parsed as Record<string, string | object>)['type'] as string || 'm.room.message';
    const parsedContent: Record<string, string | object> = (parsed as Record<string, string | object>)['content'] as Record<string, string | object> || parsed;
    const decryptedResult: DecryptedEvent = {
      eventId: event.event_id,
      roomId: event.room_id,
      sender: event.sender,
      type: parsedType,
      content: parsedContent,
      timestamp: event.origin_server_ts
    };
    return decryptedResult;
  }

  private createDecryptionError(event: EncryptedMatrixEvent, error: string): DecryptedEvent {
    const errorContent: DecryptedErrorContent = {
      body: `[Unable to decrypt: ${error}]`,
      msgtype: 'm.text'
    };
    const result: DecryptedEvent = {
      eventId: event.event_id,
      roomId: event.room_id,
      sender: event.sender,
      type: event.type,
      content: errorContent as Object as Record<string, string | object>,
      timestamp: event.origin_server_ts,
      decryptionError: error
    };
    return result;
  }

  async uploadDeviceKeys(deviceKeys: Record<string, string | object>): Promise<void> {
    logger.info('Device key upload not available — E2EE not implemented');
  }

  async uploadOneTimeKeys(oneTimeKeys: Record<string, string>): Promise<void> {
    logger.info('One-time key upload not available — E2EE not implemented');
  }

  async requestRoomKeys(roomId: string, sessionId: string): Promise<void> {
    logger.info(`Key requests not available — would request keys for room ${roomId}, session ${sessionId} (E2EE not implemented)`);
  }

  getDeviceIdentity(): DeviceIdentity | null {
    return this.deviceIdentity;
  }

  getDeviceId(): string {
    return this.deviceId;
  }

  isInitialized(): boolean {
    return this.initialized;
  }

  getSessionCount(): number {
    return this.inboundGroupSessions.size;
  }

  getPendingEventCount(): number {
    let count = 0;
    for (const pending of this.pendingRoomKeys.values()) {
      count += pending.length;
    }
    return count;
  }
}
