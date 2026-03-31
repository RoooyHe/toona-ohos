import data_preferences from '@ohos.data.preferences';
import { Context } from '@kit.AbilityKit';

const SECURITY_KEY = 'toona_secure_key';
const SESSION_KEY = 'matrix_session';
const PREFS_NAME = 'toona_prefs';

function bytesToHex(bytes: Uint8Array): string {
  const hexChars = '0123456789ABCDEF';
  let result = '';
  for (let i = 0; i < bytes.length; i++) {
    const byte = bytes[i];
    result += hexChars.charAt((byte >> 4) & 0x0F);
    result += hexChars.charAt(byte & 0x0F);
  }
  return result;
}

function hexToBytes(hex: string): Uint8Array {
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < hex.length; i += 2) {
    bytes[i / 2] = parseInt(hex.substring(i, i + 2), 16);
  }
  return bytes;
}

function base64Encode(str: string): string {
  const bytes: Uint8Array = new Uint8Array(str.length);
  for (let i = 0; i < str.length; i++) {
    bytes[i] = str.charCodeAt(i);
  }
  return bytesToHex(bytes);
}

function base64Decode(str: string): Uint8Array {
  return hexToBytes(str);
}

export class SecureStorage {
  private static instance: SecureStorage;
  private preferences: data_preferences.Preferences | null = null;
  private cryptoKey: string = '';

  private constructor() {
  }

  static getInstance(): SecureStorage {
    if (!SecureStorage.instance) {
      SecureStorage.instance = new SecureStorage();
    }
    return SecureStorage.instance;
  }

  async init(context: Context): Promise<void> {
    try {
      this.preferences = await data_preferences.getPreferences(context, PREFS_NAME);
      await this.ensureCryptoKey();
    } catch (error) {
      console.error('Failed to initialize SecureStorage:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to initialize SecureStorage: ${errMsg}`);
    }
  }

  private async ensureCryptoKey(): Promise<void> {
    try {
      const keyData = await this.preferences?.get(SECURITY_KEY, '');
      if (!keyData || keyData === '') {
        this.cryptoKey = this.generateRandomKey();
        await this.preferences?.put(SECURITY_KEY, this.cryptoKey);
        await this.preferences?.flush();
      } else {
        this.cryptoKey = keyData as string;
      }
      console.info('SecureStorage: CryptoKey initialized, length: ' + this.cryptoKey.length);
    } catch (error) {
      console.error('SecureStorage: Failed to ensure cryptoKey:', error);
      this.cryptoKey = this.generateRandomKey();
    }
  }

  private generateRandomKey(): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result = '';
    for (let i = 0; i < 32; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }

  private simpleEncrypt(data: string): string {
    if (!this.cryptoKey) {
      return data;
    }
    let result = '';
    for (let i = 0; i < data.length; i++) {
      const charCode = data.charCodeAt(i) ^ this.cryptoKey.charCodeAt(i % this.cryptoKey.length);
      result += String.fromCharCode(charCode);
    }
    return base64Encode(result);
  }

  private simpleDecrypt(encryptedData: string): string {
    if (!this.cryptoKey) {
      return encryptedData;
    }
    try {
      const decoded: Uint8Array = base64Decode(encryptedData);
      let result = '';
      for (let i = 0; i < decoded.length; i++) {
        const charCode = decoded[i] ^ this.cryptoKey.charCodeAt(i % this.cryptoKey.length);
        result += String.fromCharCode(charCode);
      }
      return result;
    } catch {
      return encryptedData;
    }
  }

  async saveSession(sessionJson: string): Promise<void> {
    if (!this.preferences) {
      console.error('SecureStorage: preferences not initialized');
      throw new Error('SecureStorage not initialized');
    }
    if (!this.cryptoKey) {
      console.error('SecureStorage: cryptoKey not available');
      throw new Error('Crypto key not available');
    }
    const encrypted = this.simpleEncrypt(sessionJson);
    try {
      await this.preferences.put(SESSION_KEY, encrypted);
      await this.preferences.flush();
      console.info('SecureStorage: Session saved, encrypted length: ' + encrypted.length);
      
      const verified = this.simpleDecrypt(encrypted);
      if (verified !== sessionJson) {
        console.error('SecureStorage: Save verification failed! Data mismatch.');
        console.error('SecureStorage: Original length: ' + sessionJson.length + ', Verified length: ' + verified.length);
        throw new Error('Session save verification failed');
      }
      console.info('SecureStorage: Session save verified successfully');
    } catch (error) {
      console.error('SecureStorage: Failed to save session', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to save session: ${errMsg}`);
    }
  }

  async loadSession(): Promise<string | null> {
    if (!this.preferences) {
      console.error('SecureStorage: preferences not initialized');
      throw new Error('SecureStorage not initialized');
    }
    try {
      const encryptedVal = await this.preferences.get(SESSION_KEY, '');
      const encrypted: string = typeof encryptedVal === 'string' ? encryptedVal : String(encryptedVal);
      if (!encrypted || encrypted === '') {
        console.info('SecureStorage: No session found');
        return null;
      }
      console.info('SecureStorage: Session loaded, encrypted length: ' + encrypted.length);
      return this.simpleDecrypt(encrypted);
    } catch (error) {
      console.error('SecureStorage: Failed to load session', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to load session: ${errMsg}`);
    }
  }

  async clearSession(): Promise<void> {
    if (!this.preferences) {
      console.warn('SecureStorage: preferences not initialized in clearSession');
      return;
    }
    try {
      await this.preferences.delete(SESSION_KEY);
      await this.preferences.flush();
      console.info('SecureStorage: Session cleared');
    } catch (error) {
      console.error('SecureStorage: Failed to clear session', error);
    }
  }

  async hasSession(): Promise<boolean> {
    if (!this.preferences) {
      return false;
    }
    try {
      const session = await this.preferences.get(SESSION_KEY, '');
      return session !== '';
    } catch {
      return false;
    }
  }

  async saveString(key: string, value: string): Promise<void> {
    if (!this.preferences) {
      throw new Error('SecureStorage not initialized');
    }
    const encrypted = this.simpleEncrypt(value);
    await this.preferences.put(key, encrypted);
    await this.preferences.flush();
  }

  async loadString(key: string): Promise<string | null> {
    if (!this.preferences) {
      throw new Error('SecureStorage not initialized');
    }
    const encrypted = await this.preferences.get(key, '');
    if (!encrypted || encrypted === '') {
      return null;
    }
    return this.simpleDecrypt(encrypted as string);
  }

  async saveBoolean(key: string, value: boolean): Promise<void> {
    if (!this.preferences) {
      throw new Error('SecureStorage not initialized');
    }
    await this.preferences.put(key, value.toString());
    await this.preferences.flush();
  }

  async loadBoolean(key: string, defaultValue: boolean = false): Promise<boolean> {
    if (!this.preferences) {
      return defaultValue;
    }
    const value = await this.preferences.get(key, defaultValue.toString());
    return value === 'true';
  }

  async saveNumber(key: string, value: number): Promise<void> {
    if (!this.preferences) {
      throw new Error('SecureStorage not initialized');
    }
    await this.preferences.put(key, value.toString());
    await this.preferences.flush();
  }

  async loadNumber(key: string, defaultValue: number = 0): Promise<number> {
    if (!this.preferences) {
      return defaultValue;
    }
    const value = await this.preferences.get(key, defaultValue.toString());
    const parsed = parseFloat(value as string);
    return isNaN(parsed) ? defaultValue : parsed;
  }

  async remove(key: string): Promise<void> {
    if (!this.preferences) {
      throw new Error('SecureStorage not initialized');
    }
    await this.preferences.delete(key);
    await this.preferences.flush();
  }

  async clearAll(): Promise<void> {
    if (!this.preferences) {
      throw new Error('SecureStorage not initialized');
    }
    await this.preferences.clear();
    await this.preferences.flush();
  }
}