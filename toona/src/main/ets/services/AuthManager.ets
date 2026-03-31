import { MatrixHttpClient, MatrixConfig } from '../network/MatrixHttpClient';
import {
  LoginResponse, RegisterResponse, WhoAmIResponse, VersionsResponse
} from '../models/MatrixTypes';
import { Session } from '../models/DataModels';
import { SecureStorage } from '../storage/SecureStorage';
import { Context } from '@kit.AbilityKit';

enum TokenValidationResult {
  VALID = 'valid',
  INVALID = 'invalid',
  NETWORK_ERROR = 'network_error'
}

export class AuthManager {
  private static instance: AuthManager;
  private httpClient: MatrixHttpClient | null = null;
  private session: Session | null = null;
  private secureStorage: SecureStorage;
  private isInitialized: boolean = false;

  private constructor() {
    this.secureStorage = SecureStorage.getInstance();
  }

  static getInstance(): AuthManager {
    if (!AuthManager.instance) {
      AuthManager.instance = new AuthManager();
    }
    return AuthManager.instance;
  }

  async init(context: Context): Promise<void> {
    if (this.isInitialized) {
      return;
    }
    await this.secureStorage.init(context);
    this.isInitialized = true;
  }

  async setHomeserver(homeserverUrl: string): Promise<void> {
    MatrixConfig.getInstance().setHomeserver(homeserverUrl);
    this.httpClient = MatrixConfig.getInstance().getHttpClient();
  }

  getHomeserver(): string {
    return MatrixConfig.getInstance().getHomeserver();
  }

  async checkHomeserverVersion(): Promise<boolean> {
    if (!this.httpClient) {
      throw new Error('Homeserver not set');
    }

    try {
      const response = await this.httpClient.getWithoutVersionPrefix<VersionsResponse>('/versions');
      if (response.versions) {
        return response.versions.includes('v1.1') ||
        response.versions.includes('v1.2') ||
        response.versions.includes('v1.3');
      }
      return false;
    } catch (error) {
      console.error('Failed to check homeserver version:', error);
      return false;
    }
  }

  async login(userId: string, password: string, deviceName?: string): Promise<Session> {
    if (!this.httpClient) {
      throw new Error('Homeserver not set');
    }

    const deviceId: string = this.generateDeviceId();
    const displayName: string = deviceName || 'Toona鸿蒙客户端';
    const identifier: Record<string, string | object> = {
      "type": 'm.id.user',
      "user": userId
    };
    const loginBody: Record<string, string | object> = {
      "identifier": identifier,
      "password": password,
      "device_id": deviceId,
      "initial_device_display_name": displayName,
      "type": 'm.login.password'
    };

    try {
      const response = await this.httpClient.post<LoginResponse>('/login', loginBody);

      const homeServer = MatrixConfig.getInstance().getHomeserver();
      console.info('AuthManager: Login success, homeServer: ' + homeServer);
      this.session =
        Session.fromLoginResponse(response.user_id, response.access_token, homeServer, response.device_id);
      this.session.isGuest = false;

      this.httpClient.setAccessToken(response.access_token);

      await this.saveSession();
      console.info('AuthManager: Session saved with homeServer: ' + this.session.homeServer);

      return this.session;
    } catch (error) {
      console.error('Login failed:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Login failed: ${errMsg}`);
    }
  }

  async register(username: string, password: string, deviceName?: string): Promise<Session> {
    if (!this.httpClient) {
      throw new Error('Homeserver not set');
    }

    const deviceId: string = this.generateDeviceId();
    const displayName: string = deviceName || 'Toona鸿蒙客户端';
    const registerBody: Record<string, string | object> = {
      "username": username,
      "password": password,
      "device_id": deviceId,
      "initial_device_display_name": displayName
    };

    try {
      const response = await this.httpClient.post<RegisterResponse>('/register', registerBody);

      const homeServer = MatrixConfig.getInstance().getHomeserver();
      this.session =
        Session.fromLoginResponse(response.user_id, response.access_token, homeServer, response.device_id);
      this.session.isGuest = false;

      this.httpClient.setAccessToken(response.access_token);

      await this.saveSession();

      return this.session;
    } catch (error) {
      console.error('Registration failed:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Registration failed: ${errMsg}`);
    }
  }

  async logout(): Promise<void> {
    if (!this.httpClient || !this.session) {
      return;
    }

    try {
      await this.httpClient.post<object>('/logout');
    } catch (error) {
      console.error('Logout request failed:', error);
    } finally {
      await this.clearSession();
    }
  }

  async restoreSession(): Promise<Session | null> {
    console.info('AuthManager: Starting session restore');
    
    if (!this.secureStorage) {
      console.error('AuthManager: secureStorage not available');
      return null;
    }

    try {
      const sessionJson = await this.secureStorage.loadSession();
      if (!sessionJson) {
        console.info('AuthManager: No session found in storage');
        return null;
      }

      console.info('AuthManager: Session data loaded, parsing...');
      const sessionData: Record<string, string> = JSON.parse(sessionJson) as Record<string, string>;
      this.session = Session.fromJSON(sessionData);
      console.info('AuthManager: Session parsed, userId: ' + this.session.userId + ', homeServer: ' + this.session.homeServer);

      MatrixConfig.getInstance().setHomeserver(this.session.homeServer);
      console.info('AuthManager: setHomeserver called with: ' + this.session.homeServer);
      this.httpClient = MatrixConfig.getInstance().getHttpClient();
      this.httpClient.setAccessToken(this.session.accessToken);
      console.info('AuthManager: HTTP client configured with token');

      console.info('AuthManager: Validating token...');
      const validationResult = await this.validateToken();
      
      if (validationResult === TokenValidationResult.VALID) {
        console.info('AuthManager: Session restored successfully');
        return this.session;
      }
      
      if (validationResult === TokenValidationResult.INVALID) {
        console.warn('AuthManager: Token is invalid (server rejected it), clearing session');
        await this.clearSession();
        return null;
      }
      
      if (validationResult === TokenValidationResult.NETWORK_ERROR) {
        console.warn('AuthManager: Token validation failed due to network error, keeping session for retry');
        return this.session;
      }

      return this.session;
    } catch (error) {
      console.error('AuthManager: Failed to restore session:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      if (errMsg.includes('JSON parse') || errMsg.includes('SyntaxError')) {
        console.error('AuthManager: Session data is corrupted, clearing session');
        await this.clearSession();
      }
      return null;
    }
  }

  async validateToken(): Promise<TokenValidationResult> {
    if (!this.httpClient) {
      return TokenValidationResult.INVALID;
    }

    try {
      const response = await this.httpClient.get<WhoAmIResponse>('/account/whoami');
      if (response.user_id === this.session?.userId) {
        return TokenValidationResult.VALID;
      }
      return TokenValidationResult.INVALID;
    } catch (error) {
      console.error('Token validation error:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      if (errMsg.includes('401') || errMsg.includes('403') || errMsg.includes('Forbidden') || errMsg.includes('Unauthorized')) {
        return TokenValidationResult.INVALID;
      }
      return TokenValidationResult.NETWORK_ERROR;
    }
  }

  private async saveSession(): Promise<void> {
    if (!this.session) {
      console.warn('AuthManager: No session to save');
      return;
    }
    const sessionJson = JSON.stringify(this.session.toJSON());
    console.info('AuthManager: Saving session...');
    try {
      await this.secureStorage.saveSession(sessionJson);
      console.info('AuthManager: Session saved successfully');
    } catch (error) {
      console.error('AuthManager: Failed to save session:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to save session: ${errMsg}`);
    }
  }

  private async clearSession(): Promise<void> {
    this.session = null;
    this.httpClient?.setAccessToken(null);
    MatrixConfig.getInstance().clear();
    try {
      await this.secureStorage.clearSession();
    } catch (error) {
      console.error('AuthManager: Failed to clear session from storage:', error);
    }
  }

  getSession(): Session | null {
    return this.session;
  }

  getHttpClient(): MatrixHttpClient {
    if (!this.httpClient) {
      throw new Error('HttpClient not initialized');
    }
    return this.httpClient;
  }

  getUserId(): string {
    return this.session?.userId || '';
  }

  isLoggedIn(): boolean {
    return this.session !== null && this.session.accessToken !== '';
  }

  private generateDeviceId(): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result = 'TOONA';
    for (let i = 0; i < 10; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }

  async updateNextBatch(nextBatch: string): Promise<void> {
    if (this.session) {
      this.session.nextBatch = nextBatch;
      await this.saveSession();
    }
  }

  reset(): void {
    this.session = null;
    this.httpClient = null;
    this.isInitialized = false;
  }
}
