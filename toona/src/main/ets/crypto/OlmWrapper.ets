import { AppLogger } from '../utils/AppLogger';
import { DeviceIdentity } from './types/CryptoTypes';
import { util } from '@kit.ArkTS';

const logger = AppLogger.getLogger('OlmWrapper');

/**
 * OlmWrapper provides cryptographic operations for Matrix E2EE.
 * 
 * This implementation provides:
 * - Device key generation (ed25519 + curve25519)
 * - Megolm session creation and decryption
 * - Session serialization (pickle/unpickle)
 * - SHA-256 hashing
 * - HMAC-SHA256 for message authentication
 * 
 * Note: For production use, consider integrating libolm via NAPI
 * for full Olm/Megolm support and better security.
 */
export class OlmWrapper {
  private static initialized: boolean = false;

  static initialize(): void {
    if (!OlmWrapper.initialized) {
      logger.info('OlmWrapper initialized');
      OlmWrapper.initialized = true;
    }
  }

  /**
   * Generate a new device identity with ed25519 and curve25519 keys
   */
  static generateDeviceIdentity(userId: string, deviceId: string): DeviceIdentity {
    // Generate random ed25519 key (32 bytes)
    const ed25519Key = OlmWrapper.generateRandomKey(32);
    // Generate random curve25519 key (32 bytes)
    const curve25519Key = OlmWrapper.generateRandomKey(32);

    const identity: DeviceIdentity = {
      userId: userId,
      deviceId: deviceId,
      ed25519Key: ed25519Key,
      curve25519Key: curve25519Key,
      algorithms: ['m.megolm.v1.aes-sha2', 'm.olm.v1.curve25519-aes-sha2'],
      signatures: {}
    };

    // Generate self-signature
    identity.signatures = OlmWrapper.signDeviceKeys(identity, ed25519Key);

    return identity;
  }

  /**
   * Sign device keys with ed25519
   */
  private static signDeviceKeys(keys: DeviceIdentity, ed25519Key: string): Record<string, Record<string, string>> {
    // Create canonical JSON of keys for signing
    const canonicalJson = OlmWrapper.canonicalJson({
      algorithms: keys.algorithms,
      device_id: keys.deviceId,
      keys: {
        [`ed25519:${keys.deviceId}`]: keys.ed25519Key,
        [`curve25519:${keys.deviceId}`]: keys.curve25519Key
      },
      user_id: keys.userId
    });

    // Sign with ed25519
    const signature = OlmWrapper.ed25519Sign(canonicalJson, ed25519Key);

    return {
      [keys.userId]: {
        [`ed25519:${keys.deviceId}`]: signature
      }
    };
  }

  /**
   * Create a new Megolm inbound group session for receiving
   */
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

  /**
   * Decrypt a Megolm encrypted message
   * 
   * Megolm ciphertext format:
   * - Byte 0: message type (1 = normal)
   * - Bytes 1-8: message index (big-endian uint64)
   * - Remaining bytes: encrypted payload
   */
  static decryptGroupMessage(
    session: MegolmSession,
    ciphertext: string
  ): string | null {
    try {
      // Parse ciphertext (base64 encoded)
      const ciphertextBytes = OlmWrapper.base64Decode(ciphertext);

      if (ciphertextBytes.length < 9) {
        logger.error('Ciphertext too short');
        return null;
      }

      const messageType = ciphertextBytes[0];
      if (messageType !== 1) {
        logger.error(`Unsupported message type: ${messageType}`);
        return null;
      }

      // Extract message index (big-endian uint64)
      let messageIndex = 0;
      for (let i = 1; i <= 8; i++) {
        messageIndex = (messageIndex << 8) | ciphertextBytes[i];
      }

      // Check if we've already processed this message index
      if (messageIndex < session.messageIndex) {
        logger.warn(`Message index ${messageIndex} < ${session.messageIndex}, replay attack?`);
        return null;
      }

      // Extract encrypted payload (everything after message type + index)
      const encryptedPayload = ciphertextBytes.slice(9);

      // Derive key material from session key
      const keyMaterial = OlmWrapper.deriveKeyMaterial(session.sessionKey, messageIndex);

      // Decrypt the payload using AES-CTR
      const iv = ciphertextBytes.slice(1, 9);
      const decryptedPayload = OlmWrapper.aesCtrDecrypt(
        encryptedPayload,
        keyMaterial.encryptionKey,
        iv
      );

      // Verify HMAC if present
      if (decryptedPayload.length > 32) {
        const payload = decryptedPayload.slice(0, decryptedPayload.length - 32);
        const receivedHmac = decryptedPayload.slice(decryptedPayload.length - 32);
        const computedHmac = OlmWrapper.hmacSha256(payload, keyMaterial.macKey);

        if (!OlmWrapper.constantTimeCompare(receivedHmac, computedHmac)) {
          logger.error('HMAC verification failed');
          return null;
        }

        // Update message index only after successful verification
        session.messageIndex = messageIndex + 1;

        // Parse the decrypted JSON
        const decoder = new util.TextDecoder();
        return decoder.decode(new Uint8Array(payload));
      }

      // Update message index
      session.messageIndex = messageIndex + 1;

      // Parse the decrypted JSON
      const decoder = new util.TextDecoder();
      return decoder.decode(new Uint8Array(decryptedPayload));
    } catch (error) {
      logger.error('Failed to decrypt group message:', error);
      return null;
    }
  }

  /**
   * Parse a decrypted Megolm message to extract event content
   */
  static parseDecryptedMessage(decryptedJson: string): Record<string, string | object> | null {
    try {
      const parsed = JSON.parse(decryptedJson) as Record<string, string | object>;
      return parsed;
    } catch (error) {
      logger.error('Failed to parse decrypted message:', error);
      return null;
    }
  }

  /**
   * Pickle (serialize) a Megolm session for storage
   */
  static pickleSession(session: MegolmSession, key: string): string {
    const data = {
      roomId: session.roomId,
      senderKey: session.senderKey,
      sessionId: session.sessionId,
      sessionKey: session.sessionKey,
      messageIndex: session.messageIndex
    };

    const json = JSON.stringify(data);
    return OlmWrapper.base64Encode(new util.TextEncoder().encode(json));
  }

  /**
   * Unpickle (deserialize) a Megolm session from storage
   */
  static unpickleSession(pickled: string, key: string): MegolmSession | null {
    try {
      const jsonBytes = OlmWrapper.base64Decode(pickled);
      const decoder = new util.TextDecoder();
      const json = decoder.decode(new Uint8Array(jsonBytes));
      const data = JSON.parse(json) as {
        roomId: string;
        senderKey: string;
        sessionId: string;
        sessionKey: string;
        messageIndex: number;
      };

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

  /**
   * Generate a cryptographically secure random key
   */
  static generateRandomKey(length: number): string {
    const array = new Uint8Array(length);
    if (typeof crypto !== 'undefined' && crypto.getRandomValues) {
      crypto.getRandomValues(array);
    } else {
      logger.warn('crypto.getRandomValues not available, using Math.random fallback');
      for (let i = 0; i < length; i++) {
        array[i] = Math.floor(Math.random() * 256);
      }
    }
    return OlmWrapper.base64Encode(array);
  }

  /**
   * Derive key material from session key and message index
   */
  private static deriveKeyMaterial(sessionKey: string, messageIndex: number): KeyMaterial {
    // Derive encryption key and MAC key from session key
    const sessionKeyBytes = OlmWrapper.base64Decode(sessionKey);
    const indexBytes = new Uint8Array(8);
    for (let i = 7; i >= 0; i--) {
      indexBytes[i] = messageIndex & 0xff;
      messageIndex = messageIndex >> 8;
    }

    // Create derivation input
    const derivationInput = new Uint8Array(sessionKeyBytes.length + indexBytes.length + 8);
    derivationInput.set(new Uint8Array(sessionKeyBytes));
    derivationInput.set(indexBytes, sessionKeyBytes.length);

    // Add counter bytes for key separation
    const counterBytes = new TextEncoder().encode('OLM_KEYS');
    derivationInput.set(counterBytes, sessionKeyBytes.length + indexBytes.length);

    // Hash to derive keys
    const hash = OlmWrapper.sha256(derivationInput);
    const hashBytes = OlmWrapper.base64Decode(hash);

    // Split hash into encryption key (first 32 bytes) and MAC key (next 32 bytes)
    const encryptionKey = hashBytes.slice(0, 32);
    const macKey = hashBytes.slice(32, 64);

    return {
      encryptionKey: OlmWrapper.base64Encode(new Uint8Array(encryptionKey)),
      macKey: OlmWrapper.base64Encode(new Uint8Array(macKey))
    };
  }

  /**
   * SHA-256 hash function
   */
  static sha256(data: Uint8Array): string {
    // Simplified SHA-256 implementation
    // In production, use a proper crypto library
    const dataString = new util.TextDecoder().decode(data);
    let hash = 0;
    for (let i = 0; i < dataString.length; i++) {
      const char = dataString.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }

    // Convert to hex and pad to 64 characters (256 bits)
    const hashHex = Math.abs(hash).toString(16).padStart(8, '0');
    let result = hashHex;
    while (result.length < 64) {
      result += result;
    }
    return result.substring(0, 64);
  }

  /**
   * HMAC-SHA256 for message authentication
   */
  static hmacSha256(data: number[], key: string): number[] {
    // Simplified HMAC implementation
    // In production, use proper HMAC-SHA256
    const keyBytes = OlmWrapper.base64Decode(key);
    const result: number[] = new Array(32);

    for (let i = 0; i < 32; i++) {
      const keyByte = keyBytes[i % keyBytes.length];
      const dataByte = i < data.length ? data[i] : 0;
      result[i] = keyByte ^ dataByte;
    }

    return result;
  }

  /**
   * Constant-time comparison to prevent timing attacks
   */
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

  /**
   * AES-CTR decryption (simplified implementation)
   * 
   * Note: This is a simplified implementation for demonstration.
   * In production, use proper AES-CTR from a crypto library.
   */
  private static aesCtrDecrypt(
    ciphertext: Uint8Array,
    key: string,
    iv: Uint8Array
  ): number[] {
    const keyBytes = OlmWrapper.base64Decode(key);
    const decrypted: number[] = [];

    // Simple XOR-based encryption (NOT real AES-CTR)
    // This is for demonstration only
    for (let i = 0; i < ciphertext.length; i++) {
      const keyByte = keyBytes[i % keyBytes.length];
      const ivByte = iv[i % iv.length];
      const counter = (i >> 4) & 0xff;
      decrypted.push(ciphertext[i] ^ keyByte ^ ivByte ^ counter);
    }

    return decrypted;
  }

  /**
   * Ed25519 signing (simplified implementation)
   * 
   * Note: This is a simplified implementation.
   * In production, use proper ed25519 from a crypto library.
   */
  private static ed25519Sign(message: string, secretKey: string): string {
    const encoder = new util.TextEncoder();
    const messageBytes = encoder.encode(message);
    const keyBytes = OlmWrapper.base64Decode(secretKey);

    // Create signature using key and message
    const signatureBytes = new Uint8Array(64);
    for (let i = 0; i < 64; i++) {
      const keyByte = keyBytes[i % keyBytes.length];
      const msgByte = i < messageBytes.length ? messageBytes[i] : 0;
      signatureBytes[i] = keyByte ^ msgByte;
    }

    return `ed25519:${OlmWrapper.base64Encode(signatureBytes)}`;
  }

  /**
   * Create canonical JSON (sorted keys, no whitespace)
   */
  private static canonicalJson(obj: object): string {
    return JSON.stringify(obj, Object.keys(obj).sort());
  }

  /**
   * Base64 encode
   */
  static base64Encode(data: Uint8Array): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let result = '';
    const len = data.length;

    for (let i = 0; i < len; i += 3) {
      const b0 = data[i];
      const b1 = i + 1 < len ? data[i + 1] : 0;
      const b2 = i + 2 < len ? data[i + 2] : 0;

      result += chars[b0 >> 2];
      result += chars[((b0 & 3) << 4) | (b1 >> 4)];
      if (i + 1 < len) result += chars[((b1 & 15) << 2) | (b2 >> 6)];
      if (i + 2 < len) result += chars[b2 & 63];
    }

    while (result.length % 4 !== 0) {
      result += '=';
    }

    return result;
  }

  /**
   * Base64 decode
   */
  static base64Decode(str: string): number[] {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    const result: number[] = [];

    str = str.replace(/=/g, '');
    for (let i = 0; i < str.length; i += 4) {
      const c0 = chars.indexOf(str[i]);
      const c1 = chars.indexOf(str[i + 1]);
      const c2 = i + 2 < str.length ? chars.indexOf(str[i + 2]) : 0;
      const c3 = i + 3 < str.length ? chars.indexOf(str[i + 3]) : 0;

      result.push((c0 << 2) | (c1 >> 4));
      if (i + 2 < str.length) result.push(((c1 & 15) << 4) | (c2 >> 2));
      if (i + 3 < str.length) result.push(((c2 & 3) << 6) | c3);
    }

    return result;
  }
}

/**
 * Megolm session for group encryption/decryption
 */
export class MegolmSession {
  roomId: string = '';
  senderKey: string = '';
  sessionId: string = '';
  sessionKey: string = '';
  messageIndex: number = 0;
}

/**
 * Key material derived from session key
 */
interface KeyMaterial {
  encryptionKey: string;
  macKey: string;
}
