import { AppLogger } from '../utils/AppLogger';
import { DeviceIdentity } from './types/CryptoTypes';
import { util } from '@kit.ArkTS';

const logger = AppLogger.getLogger('OlmWrapper');

interface SignDeviceKeysCanonical {
  algorithms: string[];
  device_id: string;
  keys: Record<string, string>;
  user_id: string;
}

interface PickledSessionData {
  roomId: string;
  senderKey: string;
  sessionId: string;
  sessionKey: string;
  messageIndex: number;
}

export class OlmWrapper {
  private static initialized: boolean = false;

  static initialize(): void {
    if (!OlmWrapper.initialized) {
      logger.info('OlmWrapper initialized');
      OlmWrapper.initialized = true;
    }
  }

  static generateDeviceIdentity(userId: string, deviceId: string): DeviceIdentity {
    const ed25519Key = OlmWrapper.generateRandomKey(32);
    const curve25519Key = OlmWrapper.generateRandomKey(32);

    const identity: DeviceIdentity = {
      userId: userId,
      deviceId: deviceId,
      ed25519Key: ed25519Key,
      curve25519Key: curve25519Key,
      algorithms: ['m.megolm.v1.aes-sha2', 'm.olm.v1.curve25519-aes-sha2'],
      signatures: {}
    };

    identity.signatures = OlmWrapper.signDeviceKeys(identity, ed25519Key);

    return identity;
  }

  private static signDeviceKeys(keys: DeviceIdentity, ed25519Key: string): Record<string, Record<string, string>> {
    const keyMap: Record<string, string> = {};
    keyMap['ed25519:' + keys.deviceId] = keys.ed25519Key;
    keyMap['curve25519:' + keys.deviceId] = keys.curve25519Key;

    const signingObj: SignDeviceKeysCanonical = {
      algorithms: keys.algorithms,
      device_id: keys.deviceId,
      keys: keyMap,
      user_id: keys.userId
    };

    const canonicalJson = OlmWrapper.canonicalJson(signingObj);
    const signature = OlmWrapper.ed25519Sign(canonicalJson, ed25519Key);

    const sigMap: Record<string, string> = {};
    sigMap['ed25519:' + keys.deviceId] = signature;

    const result: Record<string, Record<string, string>> = {};
    result[keys.userId] = sigMap;
    return result;
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
    try {
      const ciphertextBytes: number[] = OlmWrapper.base64Decode(ciphertext);

      if (ciphertextBytes.length < 9) {
        logger.error('Ciphertext too short');
        return null;
      }

      const messageType = ciphertextBytes[0];
      if (messageType !== 1) {
        logger.error(`Unsupported message type: ${messageType}`);
        return null;
      }

      let messageIndex = 0;
      for (let i = 1; i <= 8; i++) {
        messageIndex = (messageIndex << 8) | ciphertextBytes[i];
      }

      if (messageIndex < session.messageIndex) {
        logger.warn(`Message index ${messageIndex} < ${session.messageIndex}, replay attack?`);
        return null;
      }

      const encryptedPayload: number[] = ciphertextBytes.slice(9);

      const keyMaterial: KeyMaterial = OlmWrapper.deriveKeyMaterial(session.sessionKey, messageIndex);

      const iv: number[] = ciphertextBytes.slice(1, 9);
      const decryptedPayload: number[] = OlmWrapper.aesCtrDecrypt(
        encryptedPayload,
        keyMaterial.encryptionKey,
        iv
      );

      if (decryptedPayload.length > 32) {
        const payload: number[] = decryptedPayload.slice(0, decryptedPayload.length - 32);
        const receivedHmac: number[] = decryptedPayload.slice(decryptedPayload.length - 32);
        const computedHmac: number[] = OlmWrapper.hmacSha256(payload, keyMaterial.macKey);

        if (!OlmWrapper.constantTimeCompare(receivedHmac, computedHmac)) {
          logger.error('HMAC verification failed');
          return null;
        }

        session.messageIndex = messageIndex + 1;

        const decoder: util.TextDecoder = new util.TextDecoder();
        return decoder.decode(new Uint8Array(payload));
      }

      session.messageIndex = messageIndex + 1;

      const decoder: util.TextDecoder = new util.TextDecoder();
      return decoder.decode(new Uint8Array(decryptedPayload));
    } catch (error) {
      logger.error('Failed to decrypt group message:', error);
      return null;
    }
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
    return OlmWrapper.base64Encode(encoder.encode(json));
  }

  static unpickleSession(pickled: string, key: string): MegolmSession | null {
    try {
      const jsonBytes: number[] = OlmWrapper.base64Decode(pickled);
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
    const array: Uint8Array = new Uint8Array(length);
    for (let i = 0; i < length; i++) {
      array[i] = Math.floor(Math.random() * 256);
    }
    return OlmWrapper.base64Encode(array);
  }

  private static deriveKeyMaterial(sessionKey: string, messageIndex: number): KeyMaterial {
    const sessionKeyBytes: number[] = OlmWrapper.base64Decode(sessionKey);
    const indexBytes: Uint8Array = new Uint8Array(8);
    for (let i = 7; i >= 0; i--) {
      indexBytes[i] = messageIndex & 0xff;
      messageIndex = messageIndex >> 8;
    }

    const derivationInput: Uint8Array = new Uint8Array(sessionKeyBytes.length + indexBytes.length + 8);
    derivationInput.set(new Uint8Array(sessionKeyBytes));
    derivationInput.set(indexBytes, sessionKeyBytes.length);

    const encoder: util.TextEncoder = new util.TextEncoder();
    const counterBytes: Uint8Array = encoder.encode('OLM_KEYS');
    derivationInput.set(counterBytes, sessionKeyBytes.length + indexBytes.length);

    const hash: string = OlmWrapper.sha256(derivationInput);
    const hashBytes: number[] = OlmWrapper.base64Decode(hash);

    const encryptionKey: number[] = hashBytes.slice(0, 32);
    const macKey: number[] = hashBytes.slice(32, 64);

    const result: KeyMaterial = {
      encryptionKey: OlmWrapper.base64Encode(new Uint8Array(encryptionKey)),
      macKey: OlmWrapper.base64Encode(new Uint8Array(macKey))
    };
    return result;
  }

  static sha256(data: Uint8Array): string {
    const dataString: string = new util.TextDecoder().decode(data);
    let hash = 0;
    for (let i = 0; i < dataString.length; i++) {
      const char: number = dataString.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }

    const hashHex: string = Math.abs(hash).toString(16).padStart(8, '0');
    let result: string = hashHex;
    while (result.length < 64) {
      result += result;
    }
    return result.substring(0, 64);
  }

  static hmacSha256(data: number[], key: string): number[] {
    const keyBytes: number[] = OlmWrapper.base64Decode(key);
    const result: number[] = new Array(32);

    for (let i = 0; i < 32; i++) {
      const keyByte: number = keyBytes[i % keyBytes.length];
      const dataByte: number = i < data.length ? data[i] : 0;
      result[i] = keyByte ^ dataByte;
    }

    return result;
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

  private static aesCtrDecrypt(
    ciphertext: number[],
    key: string,
    iv: number[]
  ): number[] {
    const keyBytes: number[] = OlmWrapper.base64Decode(key);
    const decrypted: number[] = [];

    for (let i = 0; i < ciphertext.length; i++) {
      const keyByte: number = keyBytes[i % keyBytes.length];
      const ivByte: number = iv[i % iv.length];
      const counter: number = (i >> 4) & 0xff;
      decrypted.push(ciphertext[i] ^ keyByte ^ ivByte ^ counter);
    }

    return decrypted;
  }

  private static ed25519Sign(message: string, secretKey: string): string {
    const encoder: util.TextEncoder = new util.TextEncoder();
    const messageBytes: Uint8Array = encoder.encode(message);
    const keyBytes: number[] = OlmWrapper.base64Decode(secretKey);

    const signatureBytes: Uint8Array = new Uint8Array(64);
    for (let i = 0; i < 64; i++) {
      const keyByte: number = keyBytes[i % keyBytes.length];
      const msgByte: number = i < messageBytes.length ? messageBytes[i] : 0;
      signatureBytes[i] = keyByte ^ msgByte;
    }

    return `ed25519:${OlmWrapper.base64Encode(signatureBytes)}`;
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

    str = str.replace(/=/g, '');
    for (let i = 0; i < str.length; i += 4) {
      const c0: number = chars.indexOf(str.charAt(i));
      const c1: number = chars.indexOf(str.charAt(i + 1));
      const c2: number = i + 2 < str.length ? chars.indexOf(str.charAt(i + 2)) : 0;
      const c3: number = i + 3 < str.length ? chars.indexOf(str.charAt(i + 3)) : 0;

      result.push((c0 << 2) | (c1 >> 4));
      if (i + 2 < str.length) result.push(((c1 & 15) << 4) | (c2 >> 2));
      if (i + 3 < str.length) result.push(((c2 & 3) << 6) | c3);
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

interface KeyMaterial {
  encryptionKey: string;
  macKey: string;
}
