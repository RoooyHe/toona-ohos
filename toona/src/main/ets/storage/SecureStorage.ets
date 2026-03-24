import data_preferences from '@ohos.data.preferences';
import { Context } from '@kit.AbilityKit';

const SECURITY_KEY = 'toona_secure_key';
const SESSION_KEY = 'matrix_session';
const PREFS_NAME = 'toona_prefs';

function base64CharAt(index: number): string {
  if (index < 26) {
    return String.fromCharCode(65 + index);
  }
  if (index < 52) {
    return String.fromCharCode(97 + index - 26);
  }
  if (index < 62) {
    return String.fromCharCode(48 + index - 52);
  }
  if (index === 62) {
    return '+';
  }
  return '/';
}

function base64IndexOf(ch: string): number {
  if (ch >= 'A' && ch <= 'Z') {
    return ch.charCodeAt(0) - 65;
  }
  if (ch >= 'a' && ch <= 'z') {
    return ch.charCodeAt(0) - 97 + 26;
  }
  if (ch >= '0' && ch <= '9') {
    return ch.charCodeAt(0) - 48 + 52;
  }
  if (ch === '+') {
    return 62;
  }
  if (ch === '/') {
    return 63;
  }
  return -1;
}

function base64Encode(str: string): string {
  let result = '';
  let i = 0;
  while (i < str.length) {
    const a = str.charCodeAt(i++);
    const b = i < str.length ? str.charCodeAt(i++) : 0;
    const c = i < str.length ? str.charCodeAt(i++) : 0;
    const triplet = (a << 16) | (b << 8) | c;
    result += base64CharAt((triplet >> 18) & 0x3F);
    result += base64CharAt((triplet >> 12) & 0x3F);
    result += i > str.length + 1 ? '=' : base64CharAt((triplet >> 6) & 0x3F);
    result += i > str.length ? '=' : base64CharAt(triplet & 0x3F);
  }
  return result;
}

function base64Decode(str: string): string {
  let result = '';
  let i = 0;
  const cleanedStr = str.replace(/[^A-Za-z0-9+/=]/g, '');
  while (i < cleanedStr.length) {
    const a = base64IndexOf(cleanedStr.charAt(i++));
    const b = base64IndexOf(cleanedStr.charAt(i++));
    const c = base64IndexOf(cleanedStr.charAt(i++));
    const d = base64IndexOf(cleanedStr.charAt(i++));
    const triplet = (a << 18) | (b << 12) | (c !== -1 ? c << 6 : 0) | (d !== -1 ? d : 0);
    result += String.fromCharCode((triplet >> 16) & 0xFF);
    if (c !== -1) {
      result += String.fromCharCode((triplet >> 8) & 0xFF);
    }
    if (d !== -1) {
      result += String.fromCharCode(triplet & 0xFF);
    }
  }
  return result;
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
    } catch (error) {
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
      const decoded = base64Decode(encryptedData);
      let result = '';
      for (let i = 0; i < decoded.length; i++) {
        const charCode = decoded.charCodeAt(i) ^ this.cryptoKey.charCodeAt(i % this.cryptoKey.length);
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
    const encrypted = this.simpleEncrypt(sessionJson);
    try {
      await this.preferences.put(SESSION_KEY, encrypted);
      await this.preferences.flush();
      console.info('SecureStorage: Session saved successfully');
    } catch (error) {
      console.error('SecureStorage: Failed to save session', error);
      throw error;
    }
  }

  async loadSession(): Promise<string | null> {
    if (!this.preferences) {
      console.error('SecureStorage: preferences not initialized');
      throw new Error('SecureStorage not initialized');
    }
    try {
      const encrypted = await this.preferences.get(SESSION_KEY, '');
      if (!encrypted || encrypted === '') {
        console.info('SecureStorage: No session found');
        return null;
      }
      console.info('SecureStorage: Session loaded, encrypted length: ' + encrypted.length);
      return this.simpleDecrypt(encrypted as string);
    } catch (error) {
      console.error('SecureStorage: Failed to load session', error);
      throw error;
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