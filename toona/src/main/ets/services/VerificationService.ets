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
import { AuthManager, IAuthManager } from './AuthManager';

const logger = AppLogger.getLogger('VerificationService');

export class VerificationService {
  private deviceKeysStorage: DeviceKeysStorage;
  private authManager: IAuthManager;

  private sessions: Map<string, VerificationSession> = new Map();

  private onVerificationUpdateCallbacks: Array<(session: VerificationSession) => void> = [];
  private onVerificationCompleteCallbacks: Array<(userId: string, deviceId: string, verified: boolean) => void> = [];

  constructor(
    authManager: IAuthManager,
    deviceKeysStorage: DeviceKeysStorage
  ) {
    this.authManager = authManager;
    this.deviceKeysStorage = deviceKeysStorage;
  }

  onVerificationUpdate(callback: (session: VerificationSession) => void): void {
    this.onVerificationUpdateCallbacks.push(callback);
  }

  onVerificationComplete(callback: (userId: string, deviceId: string, verified: boolean) => void): void {
    this.onVerificationCompleteCallbacks.push(callback);
  }

  private notifyUpdate(session: VerificationSession): void {
    for (const callback of this.onVerificationUpdateCallbacks) {
      try {
        callback(session);
      } catch (error) {
        logger.error('Error in verification update callback:', error);
      }
    }
  }

  private notifyComplete(userId: string, deviceId: string, verified: boolean): void {
    for (const callback of this.onVerificationCompleteCallbacks) {
      try {
        callback(userId, deviceId, verified);
      } catch (error) {
        logger.error('Error in verification complete callback:', error);
      }
    }
  }

  async startSasVerification(userId: string, deviceId: string): Promise<string> {
    throw new Error('Device verification not available — E2EE not implemented');
  }

  async startQrVerification(userId: string, deviceId: string): Promise<void> {
    throw new Error('QR verification not available — E2EE not implemented');
  }

  async acceptVerification(transactionId: string): Promise<void> {
    logger.info(`Verification not available — acceptVerification called for ${transactionId} (E2EE not implemented)`);
  }

  async handleVerificationRequest(event: VerificationRequestEvent, senderUserId: string): Promise<void> {
    logger.info(`Received verification request from ${senderUserId}:${event.from_device} — verification not available (E2EE not implemented)`);

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
    this.notifyUpdate(verificationSession);
  }

  async handleVerificationReady(event: VerificationReadyEvent, senderUserId: string): Promise<void> {
    logger.info(`Verification ${event.transaction_id} ready received — verification not available (E2EE not implemented)`);
    const session = this.sessions.get(event.transaction_id);
    if (session) {
      this.notifyUpdate(session);
    }
  }

  async handleVerificationStart(event: VerificationStartEvent, senderUserId: string): Promise<void> {
    logger.info(`Verification ${event.transaction_id} start received — verification not available (E2EE not implemented)`);
    const session = this.sessions.get(event.transaction_id);
    if (session) {
      this.notifyUpdate(session);
    }
  }

  async handleVerificationKey(event: VerificationKeyEvent, senderUserId: string): Promise<void> {
    logger.info(`Verification ${event.transaction_id} key received — verification not available (E2EE not implemented)`);
    const session = this.sessions.get(event.transaction_id);
    if (session) {
      this.notifyUpdate(session);
    }
  }

  async handleVerificationMac(event: VerificationMacEvent, senderUserId: string): Promise<void> {
    logger.info(`Verification ${event.transaction_id} MAC received — verification not available (E2EE not implemented)`);
    const session = this.sessions.get(event.transaction_id);
    if (session) {
      this.notifyUpdate(session);
    }
  }

  async handleVerificationCancel(event: VerificationCancelEvent, senderUserId: string): Promise<void> {
    logger.info(`Verification ${event.transaction_id} cancelled: ${event.reason}`);
    const session = this.sessions.get(event.transaction_id);
    if (session) {
      this.sessions.delete(event.transaction_id);
      this.notifyUpdate(session);
    }
  }

  async handleVerificationDone(transactionId: string, senderUserId: string): Promise<void> {
    logger.info(`Verification ${transactionId} done received — not marking verified (E2EE not implemented)`);
    const session = this.sessions.get(transactionId);
    if (session) {
      this.sessions.delete(transactionId);
    }
  }

  async confirmVerification(transactionId: string): Promise<void> {
    throw new Error('Device verification not available — E2EE not implemented');
  }

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

  async getDeviceTrustLevel(userId: string, deviceId: string): Promise<VerificationState> {
    return await this.deviceKeysStorage.getTrustLevel(userId, deviceId);
  }

  async setDeviceTrustLevel(userId: string, deviceId: string, level: VerificationState): Promise<void> {
    await this.deviceKeysStorage.setTrustLevel(userId, deviceId, level);
  }

  getSession(transactionId: string): VerificationSession | null {
    return this.sessions.get(transactionId) || null;
  }

  getActiveSessions(): VerificationSession[] {
    return Array.from(this.sessions.values());
  }

  getSessionForDevice(userId: string, deviceId: string): VerificationSession | null {
    for (const session of this.sessions.values()) {
      if (session.userId === userId && session.deviceId === deviceId) {
        return session;
      }
    }
    return null;
  }

  getSasDigits(sasBytes: number[]): SasDigits {
    return {
      decimal: 'N/A',
      emoji: ['⚠️']
    };
  }
}
