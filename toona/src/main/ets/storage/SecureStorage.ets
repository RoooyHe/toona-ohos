import data_preferences from '@ohos.data.preferences';
import promptAction from '@ohos.promptAction';
import { Context } from '@kit.AbilityKit';

const SECURITY_KEY = 'toona_secure_key';
const SESSION_KEY = 'matrix_session';
const PREFS_NAME = 'toona_prefs';

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
    return Buffer.from(result, 'binary').toString('base64');
  }

  private simpleDecrypt(encryptedData: string): string {
    if (!this.cryptoKey) {
      return encryptedData;
    }
    try {
      const decoded = Buffer.from(encryptedData, 'base64').toString('binary');
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
      throw new Error('SecureStorage not initialized');
    }
    const encrypted = this.simpleEncrypt(sessionJson);
    try {
      await this.preferences.put(SESSION_KEY, encrypted);
    } catch (error) {
      // TODO: Implement error handling.
    }
    try {
      await this.preferences.flush();
    } catch (error) {
      // TODO: Implement error handling.
    }
  }

  async loadSession(): Promise<string | null> {
    if (!this.preferences) {
      throw new Error('SecureStorage not initialized');
    }
    const encrypted = await this.preferences.get(SESSION_KEY, '');
    if (!encrypted || encrypted === '') {
      return null;
    }
    return this.simpleDecrypt(encrypted as string);
  }

  async clearSession(): Promise<void> {
    if (!this.preferences) {
      throw new Error('SecureStorage not initialized');
    }
    await this.preferences.delete(SESSION_KEY);
    await this.preferences.flush();
  }

  async hasSession(): Promise<boolean> {
    if (!this.preferences) {
      return false;
    }
    const session = await this.preferences.get(SESSION_KEY, '');
    return session !== '';
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

function promptActionShowToast(message: string): void {
  try {
    promptAction.showToast({
      message: message,
      duration: 2000
    });
  } catch {
    console.info(message);
  }
}
