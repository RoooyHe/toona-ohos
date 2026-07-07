import { AppLogger } from '../utils/AppLogger';
import { OlmWrapper, MegolmSession } from '../crypto/OlmWrapper';
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
import { CryptoManager } from './CryptoManager';
import { AuthManager } from './AuthManager';
import { VerificationService } from './VerificationService';

const logger = AppLogger.getLogger('CryptoService');

/**
 * CryptoService handles all E2EE operations for the Matrix client.
 * 
 * Responsibilities:
 * - Device key generation and upload
 * - Megolm session management
 * - Message decryption
 * - To-device event processing
 * - One-time key management
 * - Key request/response handling
 */
export class CryptoService {
  private static instance: CryptoService;
  private initialized: boolean = false;
  private cryptoDao: CryptoDao;
  private deviceKeysStorage: DeviceKeysStorage;
  private cryptoManager: CryptoManager;
  private authManager: AuthManager;
  private verificationService: VerificationService;

  // Device identity
  private deviceId: string = '';
  private ed25519Key: string = '';
  private curve25519Key: string = '';
  private deviceIdentity: DeviceIdentity | null = null;

  // Session caches
  private inboundGroupSessions: Map<string, MegolmSession> = new Map();
  private pendingRoomKeys: Map<string, RoomKeyEvent[]> = new Map();

  // Callbacks
  private decryptionCallbacks: Array<(roomId: string, eventId: string) => void> = [];

  private constructor() {
    this.cryptoDao = CryptoDao.getInstance();
    this.deviceKeysStorage = DeviceKeysStorage.getInstance();
    this.cryptoManager = CryptoManager.getInstance();
    this.authManager = AuthManager.getInstance();
    this.verificationService = VerificationService.getInstance();
  }

  static getInstance(): CryptoService {
    if (!CryptoService.instance) {
      CryptoService.instance = new CryptoService();
    }
    return CryptoService.instance;
  }

  /**
   * Initialize the crypto service
   * Must be called after authentication
   */
  async initialize(): Promise<void> {
    if (this.initialized) {
      logger.info('CryptoService already initialized');
      return;
    }

    try {
      logger.info('Initializing CryptoService');

      // Initialize OlmWrapper
      OlmWrapper.initialize();

      // Get or generate device ID
      this.deviceId = await this.getOrCreateDeviceId();

      // Get or generate device keys
      await this.getOrCreateDeviceKeys();

      // Load cached sessions from database
      await this.loadCachedSessions();

      // Upload device keys if needed
      await this.ensureKeysUploaded();

      // Upload one-time keys if needed
      await this.ensureOneTimeKeys();

      this.initialized = true;
      logger.info('CryptoService initialized successfully');
    } catch (error) {
      logger.error('Failed to initialize CryptoService:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`CryptoService initialization failed: ${errMsg}`);
    }
  }

  /**
   * Register a callback for when a message is decrypted
   */
  onDecrypted(callback: (roomId: string, eventId: string) => void): void {
    this.decryptionCallbacks.push(callback);
  }

  /**
   * Notify listeners about a decrypted message
   */
  private notifyDecrypted(roomId: string, eventId: string): void {
    for (const callback of this.decryptionCallbacks) {
      try {
        callback(roomId, eventId);
      } catch (error) {
        logger.error('Error in decryption callback:', error);
      }
    }
  }

  /**
   * Get or create device ID
   */
  private async getOrCreateDeviceId(): Promise<string> {
    const session = this.authManager.getSession();
    if (!session) {
      throw new Error('No active session');
    }

    // Try to load existing device keys from database
    const existingKeys = await this.deviceKeysStorage.getDeviceKeys(session.userId);
    if (existingKeys && existingKeys.device_id) {
      this.ed25519Key = existingKeys.ed25519_key;
      this.curve25519Key = existingKeys.curve25519_key;
      logger.info(`Loaded existing device keys for ${existingKeys.device_id}`);
      return existingKeys.device_id;
    }

    // Generate a new secure random device ID
    const devicePrefix = 'TOONA_';
    const randomKey = OlmWrapper.generateRandomKey(8);
    const randomPart = randomKey.replace(/[^a-zA-Z0-9]/g, '').substring(0, 8).toUpperCase();
    return `${devicePrefix}${randomPart}`;
  }

  /**
   * Get or generate device keys
   */
  private async getOrCreateDeviceKeys(): Promise<void> {
    const session = this.authManager.getSession();
    if (!session) {
      throw new Error('No active session');
    }

    // Check if we already have keys in memory
    if (this.ed25519Key && this.curve25519Key && this.deviceIdentity) {
      return;
    }

    // Try to load from database
    const existingKeys = await this.deviceKeysStorage.getDeviceKeys(session.userId);
    if (existingKeys && existingKeys.ed25519_key && existingKeys.curve25519_key) {
      this.ed25519Key = existingKeys.ed25519_key;
      this.curve25519Key = existingKeys.curve25519_key;

      // Reconstruct device identity
      this.deviceIdentity = {
        userId: session.userId,
        deviceId: existingKeys.device_id,
        ed25519Key: existingKeys.ed25519_key,
        curve25519Key: existingKeys.curve25519_key,
        algorithms: JSON.parse(existingKeys.algorithms),
        signatures: JSON.parse(existingKeys.signatures)
      };

      logger.info(`Loaded device keys from database for ${existingKeys.device_id}`);
      return;
    }

    // Generate new keys
    const identity = OlmWrapper.generateDeviceIdentity(session.userId, this.deviceId);
    this.deviceIdentity = identity;
    this.ed25519Key = identity.ed25519Key;
    this.curve25519Key = identity.curve25519Key;

    // Persist the new keys
    await this.deviceKeysStorage.saveDeviceKeys(
      session.userId,
      this.deviceId,
      identity.ed25519Key,
      identity.curve25519Key,
      identity.algorithms,
      identity.signatures
    );

    logger.info(`Generated and saved device keys for ${this.deviceId}`);
  }

  /**
   * Load cached sessions from database
   */
  private async loadCachedSessions(): Promise<void> {
    try {
      const sessions = await this.cryptoDao.getAllInboundGroupSessions();
      for (const entity of sessions) {
        const session = OlmWrapper.unpickleSession(entity.session_data, '');
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

  /**
   * Ensure device keys are uploaded to server
   */
  private async ensureKeysUploaded(): Promise<void> {
    if (!this.deviceIdentity) {
      logger.error('No device identity to upload');
      return;
    }

    try {
      await this.cryptoManager.uploadDeviceKeys(this.deviceIdentity as unknown as Record<string, string | object>);
      logger.info('Device keys uploaded');
    } catch (error) {
      logger.error('Failed to upload device keys:', error);
    }
  }

  /**
   * Ensure we have enough one-time keys
   */
  private async ensureOneTimeKeys(): Promise<void> {
    try {
      const oneTimeKeys: Record<string, string> = {};
      for (let i = 0; i < ONE_TIME_KEY_TARGET; i++) {
        const keyId = `signed_curve25519:${i}`;
        const key = OlmWrapper.generateRandomKey(32);
        oneTimeKeys[keyId] = key;
      }

      await this.cryptoManager.uploadOneTimeKeys(oneTimeKeys);
      logger.info(`Uploaded ${ONE_TIME_KEY_TARGET} one-time keys`);
    } catch (error) {
      logger.error('Failed to upload one-time keys:', error);
    }
  }

  /**
   * Process a to-device event
   */
  async processToDeviceEvent(event: {
    type: string;
    sender: string;
    content: Record<string, string | object>;
  }): Promise<void> {
    if (!this.initialized) {
      logger.warn('CryptoService not initialized, queuing event');
      return;
    }

    try {
      switch (event.type) {
        case 'm.room_key':
          await this.handleRoomKeyEvent(event as unknown as RoomKeyEvent);
          break;
        case 'm.room_key_request':
          await this.handleRoomKeyRequest(event);
          break;
        case 'm.forwarded_room_key':
          await this.handleForwardedRoomKeyEvent(event as unknown as RoomKeyEvent);
          break;
        case 'm.room_key_request.cancellation':
          await this.handleRoomKeyRequestCancellation(event);
          break;
        // Verification events
        case KEY_VERIFICATION_REQUEST:
          await this.handleVerificationRequest(event as unknown as VerificationRequestEvent);
          break;
        case KEY_VERIFICATION_READY:
          await this.handleVerificationReady(event as unknown as VerificationReadyEvent);
          break;
        case KEY_VERIFICATION_START:
          await this.handleVerificationStart(event as unknown as VerificationStartEvent);
          break;
        case KEY_VERIFICATION_KEY:
          await this.handleVerificationKey(event as unknown as VerificationKeyEvent);
          break;
        case KEY_VERIFICATION_MAC:
          await this.handleVerificationMac(event as unknown as VerificationMacEvent);
          break;
        case KEY_VERIFICATION_CANCEL:
          await this.handleVerificationCancel(event as unknown as VerificationCancelEvent);
          break;
        case KEY_VERIFICATION_DONE:
          await this.handleVerificationDone(event);
          break;
        default:
          logger.info(`Unhandled to-device event type: ${event.type}`);
      }
    } catch (error) {
      logger.error(`Failed to process to-device event ${event.type}:`, error);
    }
  }

  /**
   * Handle m.room_key to-device event
   */
  private async handleRoomKeyEvent(event: RoomKeyEvent): Promise<void> {
    logger.info(`Received room key for room ${event.room_id}`);

    // Validate required fields
    if (!event.room_id || !event.session_id || !event.session_key) {
      logger.error('Invalid room key event: missing required fields');
      return;
    }

    // Create inbound group session
    const session = OlmWrapper.createInboundGroupSession(
      event.room_id,
      event.sender_key || '',
      event.session_id,
      event.session_key
    );

    // Cache the session
    const cacheKey = `${event.room_id}:${event.session_id}`;
    this.inboundGroupSessions.set(cacheKey, session);

    // Store in database
    const entity = new InboundGroupSessionEntity();
    entity.sessionId = cacheKey;
    entity.room_id = event.room_id;
    entity.sender_key = event.sender_key || '';
    entity.megolm_session_id = event.session_id;
    entity.session_data = OlmWrapper.pickleSession(session, '');
    entity.forwarding_chain = JSON.stringify(event.forwarding_curve25519_key_chain || []);
    entity.created_at = Date.now();

    await this.cryptoDao.saveInboundGroupSession(entity);

    // Process any pending encrypted events for this room
    await this.processPendingEvents(event.room_id);

    logger.info(`Stored Megolm session ${event.session_id} for room ${event.room_id}`);
  }

  /**
   * Handle m.room_key_request to-device event
   */
  private async handleRoomKeyRequest(event: { content: Record<string, string | object> }): Promise<void> {
    const content = event.content;
    const requestingUserId = content['requesting_user_id'] as string;
    const requestingDevice = content['requesting_device_id'] as string;
    const roomId = content['room_id'] as string;
    const sessionId = content['session_id'] as string;

    logger.info(`Received key request from ${requestingUserId}:${requestingDevice} for session ${sessionId}`);

    // Check if we have the requested session
    const cacheKey = `${roomId}:${sessionId}`;
    const session = this.inboundGroupSessions.get(cacheKey);

    if (session) {
      logger.info(`We have the requested session, sending key share`);
      await this.sendKeyShareResponse(requestingUserId, requestingDevice, session);
    } else {
      logger.info(`We don't have the requested session, ignoring request`);
    }
  }

  /**
   * Send a key share response
   */
  private async sendKeyShareResponse(
    requestingUserId: string,
    requestingDevice: string,
    session: MegolmSession
  ): Promise<void> {
    try {
      // Create the forwarded room key event
      const forwardedKey: RoomKeyEvent = {
        type: 'm.forwarded_room_key',
        algorithm: MEGOLM_ALGORITHM,
        room_id: session.roomId,
        session_id: session.sessionId,
        session_key: session.sessionKey,
        sender_key: this.curve25519Key,
        forwarding_curve25519_key_chain: [this.curve25519Key]
      };

      // Send via to-device message
      // Note: This requires a to-device send API which may not be available
      logger.info(`Would send key share to ${requestingUserId}:${requestingDevice}`);
      logger.info(`Key share contains session ${session.sessionId} for room ${session.roomId}`);
    } catch (error) {
      logger.error('Failed to send key share response:', error);
    }
  }

  /**
   * Handle m.forwarded_room_key to-device event
   */
  private async handleForwardedRoomKeyEvent(event: RoomKeyEvent): Promise<void> {
    logger.info(`Received forwarded room key for room ${event.room_id}`);

    // Validate required fields
    if (!event.room_id || !event.session_id || !event.session_key) {
      logger.error('Invalid forwarded room key event: missing required fields');
      return;
    }

    // Create inbound group session from forwarded key
    const session = OlmWrapper.createInboundGroupSession(
      event.room_id,
      event.sender_key || '',
      event.session_id,
      event.session_key
    );

    // Cache the session
    const cacheKey = `${event.room_id}:${event.session_id}`;
    this.inboundGroupSessions.set(cacheKey, session);

    // Store in database
    const entity = new InboundGroupSessionEntity();
    entity.sessionId = cacheKey;
    entity.room_id = event.room_id;
    entity.sender_key = event.sender_key || '';
    entity.megolm_session_id = event.session_id;
    entity.session_data = OlmWrapper.pickleSession(session, '');
    entity.forwarding_chain = JSON.stringify(event.forwarding_curve25519_key_chain || []);
    entity.created_at = Date.now();

    await this.cryptoDao.saveInboundGroupSession(entity);

    // Process any pending encrypted events for this room
    await this.processPendingEvents(event.room_id);

    logger.info(`Stored forwarded Megolm session ${event.session_id} for room ${event.room_id}`);
  }

  /**
   * Handle m.room_key_request.cancellation to-device event
   */
  private async handleRoomKeyRequestCancellation(event: { content: Record<string, string | object> }): Promise<void> {
    const content = event.content;
    const requestId = content['request_id'] as string;
    logger.info(`Received key request cancellation for request ${requestId}`);
    // No action needed - we were going to share the key anyway
  }

  // ── Verification Event Handlers ──

  /**
   * Handle m.keyverification.request to-device event
   */
  private async handleVerificationRequest(event: VerificationRequestEvent): Promise<void> {
    logger.info(`Received verification request from device ${event.from_device}`);

    // Delegate to VerificationService
    await this.verificationService.handleVerificationRequest(event, event.from_device);
  }

  /**
   * Handle m.keyverification.ready to-device event
   */
  private async handleVerificationReady(event: VerificationReadyEvent): Promise<void> {
    logger.info(`Verification ${event.transaction_id} is ready`);

    // Delegate to VerificationService
    await this.verificationService.handleVerificationReady(event, '');
  }

  /**
   * Handle m.keyverification.start to-device event
   */
  private async handleVerificationStart(event: VerificationStartEvent): Promise<void> {
    logger.info(`Verification ${event.transaction_id} started with method ${event.method}`);

    // Delegate to VerificationService
    await this.verificationService.handleVerificationStart(event, '');
  }

  /**
   * Handle m.keyverification.key to-device event
   */
  private async handleVerificationKey(event: VerificationKeyEvent): Promise<void> {
    logger.info(`Verification ${event.transaction_id} received key`);

    // Delegate to VerificationService
    await this.verificationService.handleVerificationKey(event, '');
  }

  /**
   * Handle m.keyverification.mac to-device event
   */
  private async handleVerificationMac(event: VerificationMacEvent): Promise<void> {
    logger.info(`Verification ${event.transaction_id} received MAC`);

    // Delegate to VerificationService
    await this.verificationService.handleVerificationMac(event, '');
  }

  /**
   * Handle m.keyverification.cancel to-device event
   */
  private async handleVerificationCancel(event: VerificationCancelEvent): Promise<void> {
    logger.info(`Verification ${event.transaction_id} cancelled: ${event.reason}`);

    // Delegate to VerificationService
    await this.verificationService.handleVerificationCancel(event, '');
  }

  /**
   * Handle m.keyverification.done to-device event
   */
  private async handleVerificationDone(event: { content: Record<string, string | object> }): Promise<void> {
    const content = event.content;
    const transactionId = content['transaction_id'] as string;
    logger.info(`Verification ${transactionId} completed`);

    // Delegate to VerificationService
    await this.verificationService.handleVerificationDone(transactionId, '');
  }

  // ── End Verification Event Handlers ──

  /**
   * Process pending encrypted events for a room
   */
  private async processPendingEvents(roomId: string): Promise<void> {
    const pending = this.pendingRoomKeys.get(roomId);
    if (pending && pending.length > 0) {
      logger.info(`Processing ${pending.length} pending events for room ${roomId}`);
      // Clear the pending list
      this.pendingRoomKeys.delete(roomId);

      // Note: The actual decryption will be triggered by EventProcessor
      // when it processes the next sync with these events
    }
  }

  /**
   * Decrypt an encrypted event
   */
  async decryptEvent(event: {
    event_id: string;
    room_id: string;
    sender: string;
    type: string;
    content: Record<string, string | object>;
    origin_server_ts: number;
  }): Promise<DecryptedEvent> {
    if (!this.initialized) {
      return this.createDecryptionError(event, 'CryptoService not initialized');
    }

    const content = event.content as unknown as EncryptedEventContent;

    // Check algorithm
    if (content.algorithm !== MEGOLM_ALGORITHM) {
      return this.createDecryptionError(event, `Unsupported algorithm: ${content.algorithm}`);
    }

    // Validate required fields
    if (!content.session_id || !content.ciphertext) {
      return this.createDecryptionError(event, 'Missing required fields');
    }

    // Look up session
    const cacheKey = `${event.room_id}:${content.session_id}`;
    let session = this.inboundGroupSessions.get(cacheKey);

    if (!session) {
      // Try loading from database
      const entity = await this.cryptoDao.getInboundGroupSession(cacheKey);
      if (entity) {
        session = OlmWrapper.unpickleSession(entity.session_data, '');
        if (session) {
          this.inboundGroupSessions.set(cacheKey, session);
        }
      }
    }

    if (!session) {
      // Queue the event for later decryption
      const pending = this.pendingRoomKeys.get(event.room_id) || [];
      pending.push({
        type: 'm.room_key',
        algorithm: content.algorithm,
        room_id: event.room_id,
        session_id: content.session_id,
        session_key: '',
        sender_key: content.sender_key
      });
      this.pendingRoomKeys.set(event.room_id, pending);

      return this.createDecryptionError(event, 'No session available for decryption');
    }

    // Decrypt the message
    const decryptedJson = OlmWrapper.decryptGroupMessage(session, content.ciphertext);
    if (!decryptedJson) {
      return this.createDecryptionError(event, 'Decryption failed');
    }

    // Parse the decrypted message
    const parsed = OlmWrapper.parseDecryptedMessage(decryptedJson);
    if (!parsed) {
      return this.createDecryptionError(event, 'Failed to parse decrypted message');
    }

    // Update session in database
    const entity = new InboundGroupSessionEntity();
    entity.sessionId = cacheKey;
    entity.room_id = event.room_id;
    entity.sender_key = content.sender_key || '';
    entity.megolm_session_id = content.session_id;
    entity.session_data = OlmWrapper.pickleSession(session, '');
    entity.forwarding_chain = '[]';
    entity.created_at = Date.now();
    await this.cryptoDao.saveInboundGroupSession(entity);

    // Notify listeners about the decrypted message
    this.notifyDecrypted(event.room_id, event.event_id);

    // Return decrypted event
    return {
      eventId: event.event_id,
      roomId: event.room_id,
      sender: event.sender,
      type: parsed['type'] as string || 'm.room.message',
      content: parsed['content'] as Record<string, string | object> || parsed,
      timestamp: event.origin_server_ts
    };
  }

  private createDecryptionError(event: {
    event_id: string;
    room_id: string;
    sender: string;
    type: string;
    content: Record<string, string | object>;
    origin_server_ts: number;
  }, error: string): DecryptedEvent {
    return {
      eventId: event.event_id,
      roomId: event.room_id,
      sender: event.sender,
      type: event.type,
      content: {
        body: `[Unable to decrypt: ${error}]`,
        msgtype: 'm.text'
      },
      timestamp: event.origin_server_ts,
      decryptionError: error
    };
  }

  /**
   * Request keys for a specific room and session
   */
  async requestRoomKeys(roomId: string, sessionId: string): Promise<void> {
    try {
      logger.info(`Requesting keys for room ${roomId}, session ${sessionId}`);

      // Create key request event
      const keyRequest = {
        type: 'm.room_key_request',
        content: {
          action: 'request',
          requesting_user_id: this.authManager.getSession()?.userId || '',
          requesting_device_id: this.deviceId,
          request_id: `key_request_${Date.now()}`,
          body: {
            algorithm: MEGOLM_ALGORITHM,
            room_id: roomId,
            session_id: sessionId,
            sender_key: ''
          }
        }
      };

      logger.info(`Would send key request: ${JSON.stringify(keyRequest)}`);
    } catch (error) {
      logger.error('Failed to request room keys:', error);
    }
  }

  /**
   * Get device identity
   */
  getDeviceIdentity(): DeviceIdentity | null {
    return this.deviceIdentity;
  }

  /**
   * Get device ID
   */
  getDeviceId(): string {
    return this.deviceId;
  }

  /**
   * Check if initialized
   */
  isInitialized(): boolean {
    return this.initialized;
  }

  /**
   * Get the number of cached sessions
   */
  getSessionCount(): number {
    return this.inboundGroupSessions.size;
  }

  /**
   * Get the number of pending events
   */
  getPendingEventCount(): number {
    let count = 0;
    for (const pending of this.pendingRoomKeys.values()) {
      count += pending.length;
    }
    return count;
  }
}
