import { AppLogger } from '../utils/AppLogger';
import { DeviceIdentity } from './types/CryptoTypes';
import { util } from '@kit.ArkTS';

const logger = AppLogger.getLogger('CryptoStub');

interface PickledSessionData {
  roomId: string;
  senderKey: string;
  sessionId: string;
  sessionKey: string;
  messageIndex: number;
}

export class CryptoStub {
  private static initialized: boolean = false;

  static initialize(): void {
    if (!CryptoStub.initialized) {
      logger.info('CryptoStub initialized (E2EE not available — encryption stubs active)');
      CryptoStub.initialized = true;
    }
  }

  static generateDeviceIdentity(userId: string, deviceId: string): DeviceIdentity {
    throw new Error('E2EE not available — device identity generation requires real Olm library');
  }

  static createInboundGroupSession(
    roomId: string,
    senderKey: string,
    sessionId: string,
    sessionKey: string
  ): MegolmSession {
    const session = new MegolmSession();
    session.roomId = roomId;
    session.senderKey = senderKey;
    session.sessionId = sessionId;
    session.sessionKey = sessionKey;
    session.messageIndex = 0;
    return session;
  }

  static decryptGroupMessage(
    session: MegolmSession,
    ciphertext: string
  ): string | null {
    logger.error('Decryption not available — E2EE not implemented');
    return null;
  }

  static parseDecryptedMessage(decryptedJson: string): Record<string, string | object> | null {
    try {
      const parsed: Record<string, string | object> = JSON.parse(decryptedJson) as Record<string, string | object>;
      return parsed;
    } catch (error) {
      logger.error('Failed to parse decrypted message:', error);
      return null;
    }
  }

  static pickleSession(session: MegolmSession, key: string): string {
    const data: PickledSessionData = {
      roomId: session.roomId,
      senderKey: session.senderKey,
      sessionId: session.sessionId,
      sessionKey: session.sessionKey,
      messageIndex: session.messageIndex
    };

    const json: string = JSON.stringify(data);
    const encoder: util.TextEncoder = new util.TextEncoder();
    return CryptoStub.base64Encode(encoder.encode(json));
  }

  static unpickleSession(pickled: string, key: string): MegolmSession | null {
    try {
      const jsonBytes: number[] = CryptoStub.base64Decode(pickled);
      const decoder: util.TextDecoder = new util.TextDecoder();
      const json: string = decoder.decode(new Uint8Array(jsonBytes));
      const data: PickledSessionData = JSON.parse(json) as PickledSessionData;

      const session = new MegolmSession();
      session.roomId = data.roomId;
      session.senderKey = data.senderKey;
      session.sessionId = data.sessionId;
      session.sessionKey = data.sessionKey;
      session.messageIndex = data.messageIndex;
      return session;
    } catch (error) {
      logger.error('Failed to unpickle session:', error);
      return null;
    }
  }

  static generateRandomKey(length: number): string {
    throw new Error('E2EE not available — cryptographic random generation requires real Olm library');
  }

  static sha256(data: Uint8Array): string {
    throw new Error('E2EE not available — SHA-256 requires real Olm library');
  }

  static hmacSha256(data: number[], key: string): number[] {
    throw new Error('E2EE not available — HMAC-SHA-256 requires real Olm library');
  }

  static aesCtrDecrypt(
    ciphertext: number[],
    key: string,
    iv: number[]
  ): number[] {
    throw new Error('E2EE not available — AES-CTR decryption requires real Olm library');
  }

  static ed25519Sign(message: string, secretKey: string): string {
    throw new Error('E2EE not available — Ed25519 signing requires real Olm library');
  }

  private static deriveKeyMaterial(sessionKey: string, messageIndex: number): never {
    throw new Error('E2EE not available — key derivation requires real Olm library');
  }

  private static constantTimeCompare(a: number[], b: number[]): boolean {
    if (a.length !== b.length) {
      return false;
    }

    let result = 0;
    for (let i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }

    return result === 0;
  }

  private static canonicalJson(obj: object): string {
    return JSON.stringify(obj, Object.keys(obj).sort());
  }

  static base64Encode(data: Uint8Array): string {
    const chars: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let result: string = '';
    const len: number = data.length;

    for (let i = 0; i < len; i += 3) {
      const b0: number = data[i];
      const b1: number = i + 1 < len ? data[i + 1] : 0;
      const b2: number = i + 2 < len ? data[i + 2] : 0;

      result += chars.charAt(b0 >> 2);
      result += chars.charAt(((b0 & 3) << 4) | (b1 >> 4));
      if (i + 1 < len) result += chars.charAt(((b1 & 15) << 2) | (b2 >> 6));
      if (i + 2 < len) result += chars.charAt(b2 & 63);
    }

    while (result.length % 4 !== 0) {
      result += '=';
    }

    return result;
  }

  static base64Decode(str: string): number[] {
    const chars: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    const result: number[] = [];

    const cleaned: string = str.replace(/=/g, '');
    for (let i = 0; i < cleaned.length; i += 4) {
      const c0: number = chars.indexOf(cleaned.charAt(i));
      const c1: number = chars.indexOf(cleaned.charAt(i + 1));
      const c2: number = i + 2 < cleaned.length ? chars.indexOf(cleaned.charAt(i + 2)) : 0;
      const c3: number = i + 3 < cleaned.length ? chars.indexOf(cleaned.charAt(i + 3)) : 0;

      result.push((c0 << 2) | (c1 >> 4));
      if (i + 2 < cleaned.length) result.push(((c1 & 15) << 4) | (c2 >> 2));
      if (i + 3 < cleaned.length) result.push(((c2 & 3) << 6) | c3);
    }

    return result;
  }
}

export class MegolmSession {
  roomId: string = '';
  senderKey: string = '';
  sessionId: string = '';
  sessionKey: string = '';
  messageIndex: number = 0;
}
