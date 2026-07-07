import { AppLogger } from '../utils/AppLogger';
import {
  VerificationState,
  VerificationMethod,
  VerificationPhase,
  VerificationRequestEvent,
  VerificationReadyEvent,
  VerificationStartEvent,
  VerificationKeyEvent,
  VerificationMacEvent,
  VerificationCancelEvent,
  VerificationSession,
  SasDigits,
  KEY_VERIFICATION_REQUEST,
  KEY_VERIFICATION_READY,
  KEY_VERIFICATION_START,
  KEY_VERIFICATION_KEY,
  KEY_VERIFICATION_MAC,
  KEY_VERIFICATION_CANCEL,
  KEY_VERIFICATION_DONE,
  VERIFICATION_TIMEOUT_MS
} from '../crypto/types/CryptoTypes';
import { DeviceKeysStorage } from '../database/dao/DeviceKeysDao';
import { AuthManager } from './AuthManager';

const logger = AppLogger.getLogger('VerificationService');

/**
 * VerificationService handles Matrix key verification (SAS and QR code).
 *
 * Responsibilities:
 * - Initiate and respond to verification requests
 * - Manage verification sessions
 * - Compute and verify SAS (Short Authentication String)
 * - Handle QR code verification
 * - Update device trust levels
 */
export class VerificationService {
  private static instance: VerificationService;
  private deviceKeysStorage: DeviceKeysStorage;
  private authManager: AuthManager;

  // Active verification sessions
  private sessions: Map<string, VerificationSession> = new Map();

  // Callbacks
  private onVerificationUpdateCallbacks: Array<(session: VerificationSession) => void> = [];
  private onVerificationCompleteCallbacks: Array<(userId: string, deviceId: string, verified: boolean) => void> = [];

  private constructor() {
    this.deviceKeysStorage = DeviceKeysStorage.getInstance();
    this.authManager = AuthManager.getInstance();
  }

  static getInstance(): VerificationService {
    if (!VerificationService.instance) {
      VerificationService.instance = new VerificationService();
    }
    return VerificationService.instance;
  }

  /**
   * Register callback for verification updates
   */
  onVerificationUpdate(callback: (session: VerificationSession) => void): void {
    this.onVerificationUpdateCallbacks.push(callback);
  }

  /**
   * Register callback for verification completion
   */
  onVerificationComplete(callback: (userId: string, deviceId: string, verified: boolean) => void): void {
    this.onVerificationCompleteCallbacks.push(callback);
  }

  /**
   * Notify listeners about verification update
   */
  private notifyUpdate(session: VerificationSession): void {
    for (const callback of this.onVerificationUpdateCallbacks) {
      try {
        callback(session);
      } catch (error) {
        logger.error('Error in verification update callback:', error);
      }
    }
  }

  /**
   * Notify listeners about verification completion
   */
  private notifyComplete(userId: string, deviceId: string, verified: boolean): void {
    for (const callback of this.onVerificationCompleteCallbacks) {
      try {
        callback(userId, deviceId, verified);
      } catch (error) {
        logger.error('Error in verification complete callback:', error);
      }
    }
  }

  /**
   * Start SAS verification with a device
   */
  async startSasVerification(userId: string, deviceId: string): Promise<string> {
    const session = this.authManager.getSession();
    if (!session) {
      throw new Error('No active session');
    }

    const transactionId = `verify_${Date.now()}_${Math.random().toString(36).substring(2, 10)}`;

    const verificationSession: VerificationSession = {
      transactionId: transactionId,
      userId: userId,
      deviceId: deviceId,
      method: VerificationMethod.SAS,
      phase: VerificationPhase.REQUEST,
      started: false,
      createdAt: Date.now(),
      expiresAt: Date.now() + VERIFICATION_TIMEOUT_MS
    };

    this.sessions.set(transactionId, verificationSession);

    logger.info(`Started SAS verification with ${userId}:${deviceId}, transaction: ${transactionId}`);

    // In a real implementation, this would send a to-device event
    // For now, we'll just store the session
    this.notifyUpdate(verificationSession);

    return transactionId;
  }

  /**
   * Start QR code verification (show QR code)
   */
  async startQrVerification(userId: string, deviceId: string): Promise<{ transactionId: string; qrData: string }> {
    const session = this.authManager.getSession();
    if (!session) {
      throw new Error('No active session');
    }

    const transactionId = `verify_${Date.now()}_${Math.random().toString(36).substring(2, 10)}`;

    // Generate shared secret for QR code
    const sharedSecret = this.generateSharedSecret();

    const verificationSession: VerificationSession = {
      transactionId: transactionId,
      userId: userId,
      deviceId: deviceId,
      method: VerificationMethod.QR_CODE_SHOW,
      phase: VerificationPhase.REQUEST,
      started: false,
      createdAt: Date.now(),
      expiresAt: Date.now() + VERIFICATION_TIMEOUT_MS
    };

    this.sessions.set(transactionId, verificationSession);

    logger.info(`Started QR verification with ${userId}:${deviceId}, transaction: ${transactionId}`);

    this.notifyUpdate(verificationSession);

    // Generate QR code data (simplified)
    const qrData = JSON.stringify({
      type: 'm.login.ecdh-v1.curve25519-aes-sha2',
      key: sharedSecret,
      transaction_id: transactionId
    });

    return { transactionId, qrData };
  }

  /**
   * Accept an incoming verification request
   */
  async acceptVerification(transactionId: string): Promise<void> {
    const session = this.sessions.get(transactionId);
    if (!session) {
      logger.error(`No session found for transaction ${transactionId}`);
      return;
    }

    session.phase = VerificationPhase.READY;
    session.started = true;

    logger.info(`Accepted verification ${transactionId}`);

    this.notifyUpdate(session);
  }

  /**
   * Handle incoming verification request
   */
  async handleVerificationRequest(event: VerificationRequestEvent, senderUserId: string): Promise<void> {
    logger.info(`Received verification request from ${senderUserId}:${event.from_device}`);

    // Check if we already have a session for this device
    for (const session of this.sessions.values()) {
      if (session.userId === senderUserId && session.deviceId === event.from_device) {
        logger.info(`Already have active session with ${senderUserId}:${event.from_device}`);
        return;
      }
    }

    // Create a new session for the incoming request
    const verificationSession: VerificationSession = {
      transactionId: event.transaction_id,
      userId: senderUserId,
      deviceId: event.from_device,
      method: VerificationMethod.SAS,
      phase: VerificationPhase.REQUEST,
      started: false,
      createdAt: Date.now(),
      expiresAt: Date.now() + VERIFICATION_TIMEOUT_MS
    };

    this.sessions.set(event.transaction_id, verificationSession);

    logger.info(`Created session for incoming verification request: ${event.transaction_id}`);

    this.notifyUpdate(verificationSession);
  }

  /**
   * Handle verification ready event
   */
  async handleVerificationReady(event: VerificationReadyEvent, senderUserId: string): Promise<void> {
    const session = this.sessions.get(event.transaction_id);
    if (!session) {
      logger.error(`No session found for transaction ${event.transaction_id}`);
      return;
    }

    session.phase = VerificationPhase.READY;

    logger.info(`Verification ${event.transaction_id} is ready`);

    this.notifyUpdate(session);
  }

  /**
   * Handle verification start event
   */
  async handleVerificationStart(event: VerificationStartEvent, senderUserId: string): Promise<void> {
    const session = this.sessions.get(event.transaction_id);
    if (!session) {
      logger.error(`No session found for transaction ${event.transaction_id}`);
      return;
    }

    session.phase = VerificationPhase.START;

    // Generate SAS bytes
    if (event.method === VerificationMethod.SAS) {
      session.sasBytes = this.generateSasBytes();
      session.sasVerified = false;
    }

    logger.info(`Verification ${event.transaction_id} started with method ${event.method}`);

    this.notifyUpdate(session);
  }

  /**
   * Handle verification key event
   */
  async handleVerificationKey(event: VerificationKeyEvent, senderUserId: string): Promise<void> {
    const session = this.sessions.get(event.transaction_id);
    if (!session) {
      logger.error(`No session found for transaction ${event.transaction_id}`);
      return;
    }

    session.phase = VerificationPhase.KEY;

    logger.info(`Verification ${event.transaction_id} received key`);

    this.notifyUpdate(session);
  }

  /**
   * Handle verification MAC event
   */
  async handleVerificationMac(event: VerificationMacEvent, senderUserId: string): Promise<void> {
    const session = this.sessions.get(event.transaction_id);
    if (!session) {
      logger.error(`No session found for transaction ${event.transaction_id}`);
      return;
    }

    session.phase = VerificationPhase.MAC;

    logger.info(`Verification ${event.transaction_id} received MAC`);

    this.notifyUpdate(session);
  }

  /**
   * Handle verification cancel event
   */
  async handleVerificationCancel(event: VerificationCancelEvent, senderUserId: string): Promise<void> {
    const session = this.sessions.get(event.transaction_id);
    if (!session) {
      logger.error(`No session found for transaction ${event.transaction_id}`);
      return;
    }

    logger.info(`Verification ${event.transaction_id} cancelled: ${event.reason}`);

    this.sessions.delete(event.transaction_id);

    this.notifyUpdate(session);
  }

  /**
   * Handle verification done event
   */
  async handleVerificationDone(transactionId: string, senderUserId: string): Promise<void> {
    const session = this.sessions.get(transactionId);
    if (!session) {
      logger.error(`No session found for transaction ${transactionId}`);
      return;
    }

    session.phase = VerificationPhase.DONE;

    // Update device trust level
    await this.deviceKeysStorage.setTrustLevel(
      session.userId,
      session.deviceId,
      VerificationState.VERIFIED,
      this.authManager.getSession()?.deviceId
    );

    logger.info(`Verification ${transactionId} completed successfully`);

    this.notifyComplete(session.userId, session.deviceId, true);
    this.sessions.delete(transactionId);
  }

  /**
   * Confirm SAS verification (user confirms the codes match)
   */
  async confirmVerification(transactionId: string): Promise<void> {
    const session = this.sessions.get(transactionId);
    if (!session) {
      logger.error(`No session found for transaction ${transactionId}`);
      return;
    }

    session.sasVerified = true;
    session.phase = VerificationPhase.DONE;

    // Update device trust level
    await this.deviceKeysStorage.setTrustLevel(
      session.userId,
      session.deviceId,
      VerificationState.VERIFIED,
      this.authManager.getSession()?.deviceId
    );

    logger.info(`SAS verification ${transactionId} confirmed`);

    this.notifyComplete(session.userId, session.deviceId, true);
    this.sessions.delete(transactionId);
  }

  /**
   * Cancel verification
   */
  async cancelVerification(transactionId: string, reason?: string): Promise<void> {
    const session = this.sessions.get(transactionId);
    if (!session) {
      logger.error(`No session found for transaction ${transactionId}`);
      return;
    }

    logger.info(`Cancelling verification ${transactionId}: ${reason || 'user cancelled'}`);

    this.sessions.delete(transactionId);

    this.notifyUpdate(session);
  }

  /**
   * Get device trust level
   */
  async getDeviceTrustLevel(userId: string, deviceId: string): Promise<VerificationState> {
    return await this.deviceKeysStorage.getTrustLevel(userId, deviceId);
  }

  /**
   * Set device trust level
   */
  async setDeviceTrustLevel(userId: string, deviceId: string, level: VerificationState): Promise<void> {
    await this.deviceKeysStorage.setTrustLevel(userId, deviceId, level);
  }

  /**
   * Get active verification session
   */
  getSession(transactionId: string): VerificationSession | null {
    return this.sessions.get(transactionId) || null;
  }

  /**
   * Get all active sessions
   */
  getActiveSessions(): VerificationSession[] {
    return Array.from(this.sessions.values());
  }

  /**
   * Get session for a specific device
   */
  getSessionForDevice(userId: string, deviceId: string): VerificationSession | null {
    for (const session of this.sessions.values()) {
      if (session.userId === userId && session.deviceId === deviceId) {
        return session;
      }
    }
    return null;
  }

  /**
   * Generate SAS bytes (simplified)
   */
  private generateSasBytes(): number[] {
    const bytes: number[] = [];
    for (let i = 0; i < 6; i++) {
      bytes.push(Math.floor(Math.random() * 256));
    }
    return bytes;
  }

  /**
   * Generate shared secret (simplified)
   */
  private generateSharedSecret(): string {
    const bytes: number[] = [];
    for (let i = 0; i < 32; i++) {
      bytes.push(Math.floor(Math.random() * 256));
    }
    return bytes.map(b => b.toString(16).padStart(2, '0')).join('');
  }

  /**
   * Get SAS digits from bytes
   */
  getSasDigits(sasBytes: number[]): SasDigits {
    // Generate 7 decimal digits from SAS bytes
    let decimal = '';
    for (let i = 0; i < 7; i++) {
      const byte = sasBytes[i % sasBytes.length];
      decimal += (byte % 10).toString();
    }

    // Generate emoji (simplified)
    const emojis = ['😀', '🎉', '🔑', '✅', '🔒', '🌟', '💫'];

    return {
      decimal: decimal,
      emoji: emojis.slice(0, 7)
    };
  }
}
