import http from '@ohos.net.http';

import {
  LoginResponse, RegisterResponse, WhoAmIResponse, VersionsResponse
} from '../models/MatrixTypes';
import { Session } from '../models/DataModels';
import { SPHelper, RandomUtil } from '@wondertek/wdkitlib';
import { Context } from '@kit.AbilityKit';

import { ConnectionConfig } from '../network/ConnectionConfig';
import { BaseHttpClient } from '../network/clients/BaseHttpClient';
import { AppLogger } from '../utils/AppLogger';

enum TokenValidationResult {
  VALID = 'valid',
  INVALID = 'invalid',
  NETWORK_ERROR = 'network_error'
}

export interface SavedCredentials {
  homeserver: string;
  userId: string;
  rememberMe: boolean;
}

export interface IAuthManager {
  init(context: Context): Promise<void>;
  setHomeserver(homeserverUrl: string): Promise<void>;
  getHomeserver(): string;
  discoverHomeserverUrl(domain: string): Promise<string | null>;
  checkHomeserverVersion(): Promise<boolean>;
  login(userId: string, password: string, deviceName?: string): Promise<Session>;
  register(username: string, password: string, deviceName?: string): Promise<Session>;
  logout(): Promise<void>;
  restoreSession(): Promise<Session | null>;
  getSession(): Session | null;
  getUserId(): string;
  isLoggedIn(): boolean;
  updateNextBatch(nextBatch: string): Promise<void>;
  loadSavedCredentials(): Promise<SavedCredentials | null>;
  saveCredentials(homeserver: string, userId: string, rememberMe: boolean): Promise<void>;
  clearSavedCredentials(): Promise<void>;
}

export class AuthManager implements IAuthManager {
  private static logger = AppLogger.getLogger(AuthManager);
  private config: ConnectionConfig;
  private httpClient: BaseHttpClient;
  private session: Session | null = null;
  private isInitialized: boolean = false;

  constructor(config: ConnectionConfig, httpClient: BaseHttpClient) {
    this.config = config;
    this.httpClient = httpClient;
  }

  async init(context: Context): Promise<void> {
    if (this.isInitialized) {
      return;
    }
    this.isInitialized = true;
  }

  async setHomeserver(homeserverUrl: string): Promise<void> {
    this.config.setHomeserver(homeserverUrl);
  }

  getHomeserver(): string {
    return this.config.getHomeserver();
  }

  async discoverHomeserverUrl(domain: string): Promise<string | null> {
    const cleanDomain = domain.trim().toLowerCase();
    let serverUrl = cleanDomain;
    if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
      serverUrl = 'https://' + serverUrl;
    }
    serverUrl = serverUrl.replace(/\/$/, '');

    try {
      const wellKnownUrl = serverUrl + '/.well-known/matrix/client';
      const httpClient = http.createHttp();
      const response = await httpClient.request(wellKnownUrl, {
        method: http.RequestMethod.GET,
        header: {
          'Accept': 'application/json'
        }
      });

      if (response.responseCode === 200) {
        const responseData = response.result as string;
        const regex = new RegExp('"m\\.homeserver"\\s*:\\s*\\{\\s*"base_url"\\s*:\\s*"([^"]+)"');
        const match = regex.exec(responseData);
        if (match !== null && match[1] !== undefined) {
          httpClient.destroy();
          return match[1].replace(/\/$/, '');
        }
      }
      httpClient.destroy();
    } catch (error) {
      AuthManager.logger.warn('Well-known discovery failed, using direct connection:', error);
    }
    return serverUrl;
  }

  async checkHomeserverVersion(): Promise<boolean> {
    try {
      const response = await this.httpClient.get<VersionsResponse>('/versions', undefined, '');
      if (response.versions) {
        return response.versions.includes('v1.1') ||
        response.versions.includes('v1.2') ||
        response.versions.includes('v1.3');
      }
      return false;
    } catch (error) {
      AuthManager.logger.error('Failed to check homeserver version:', error);
      return false;
    }
  }

  async login(userId: string, password: string, deviceName?: string): Promise<Session> {
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

      const homeServer = this.config.getHomeserver();
      AuthManager.logger.info('AuthManager: Login success, homeServer: ' + homeServer);
      this.session =
        Session.fromLoginResponse(response.user_id, response.access_token, homeServer, response.device_id);
      this.session.isGuest = false;

      this.config.setAccessToken(response.access_token);

      await this.saveSession();
      AuthManager.logger.info('AuthManager: Session saved with homeServer: ' + this.session.homeServer);

      return this.session;
    } catch (error) {
      AuthManager.logger.error('Login failed:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Login failed: ${errMsg}`);
    }
  }

  async register(username: string, password: string, deviceName?: string): Promise<Session> {
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

      const homeServer = this.config.getHomeserver();
      this.session =
        Session.fromLoginResponse(response.user_id, response.access_token, homeServer, response.device_id);
      this.session.isGuest = false;

      this.config.setAccessToken(response.access_token);

      await this.saveSession();

      return this.session;
    } catch (error) {
      AuthManager.logger.error('Registration failed:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Registration failed: ${errMsg}`);
    }
  }

  async logout(): Promise<void> {
    if (!this.session) {
      return;
    }

    try {
      await this.httpClient.post<object>('/logout');
    } catch (error) {
      AuthManager.logger.error('Logout request failed:', error);
    } finally {
      await this.clearSession();
    }
  }

  async restoreSession(): Promise<Session | null> {
    AuthManager.logger.info('AuthManager: Starting session restore');
    
    try {
      const sessionJson = await SPHelper.default.get('matrix_session', '') as string;
      if (!sessionJson) {
        AuthManager.logger.info('AuthManager: No session found in storage');
        return null;
      }

      AuthManager.logger.info('AuthManager: Session data loaded, parsing...');
      const sessionData: Record<string, string> = JSON.parse(sessionJson) as Record<string, string>;
      this.session = Session.fromJSON(sessionData);
      AuthManager.logger.info('AuthManager: Session parsed, userId: ' + this.session.userId + ', homeServer: ' + this.session.homeServer);

      this.config.setHomeserver(this.session.homeServer);
      AuthManager.logger.info('AuthManager: setHomeserver called with: ' + this.session.homeServer);
      this.config.setAccessToken(this.session.accessToken);
      AuthManager.logger.info('AuthManager: HTTP client configured with token');

      AuthManager.logger.info('AuthManager: Validating token...');
      const validationResult = await this.validateToken();
      
      if (validationResult === TokenValidationResult.VALID) {
        AuthManager.logger.info('AuthManager: Session restored successfully');
        return this.session;
      }
      
      if (validationResult === TokenValidationResult.INVALID) {
        AuthManager.logger.warn('AuthManager: Token is invalid (server rejected it), clearing session');
        await this.clearSession();
        return null;
      }
      
      if (validationResult === TokenValidationResult.NETWORK_ERROR) {
        AuthManager.logger.warn('AuthManager: Token validation failed due to network error, keeping session for retry');
        return this.session;
      }

      return this.session;
    } catch (error) {
      AuthManager.logger.error('AuthManager: Failed to restore session:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      if (errMsg.includes('JSON parse') || errMsg.includes('SyntaxError')) {
        AuthManager.logger.error('AuthManager: Session data is corrupted, clearing session');
        await this.clearSession();
      }
      return null;
    }
  }

  async validateToken(): Promise<TokenValidationResult> {
    try {
      const response = await this.httpClient.get<WhoAmIResponse>('/account/whoami');
      if (response.user_id === this.session?.userId) {
        return TokenValidationResult.VALID;
      }
      return TokenValidationResult.INVALID;
    } catch (error) {
      AuthManager.logger.error('Token validation error:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      if (errMsg.includes('401') || errMsg.includes('403') || errMsg.includes('Forbidden') || errMsg.includes('Unauthorized')) {
        return TokenValidationResult.INVALID;
      }
      return TokenValidationResult.NETWORK_ERROR;
    }
  }

  private async saveSession(): Promise<void> {
    if (!this.session) {
      AuthManager.logger.warn('AuthManager: No session to save');
      return;
    }
    const sessionJson = JSON.stringify(this.session.toJSON());
    AuthManager.logger.info('AuthManager: Saving session...');
    try {
      await SPHelper.default.saveAndFlush('matrix_session', sessionJson);
      AuthManager.logger.info('AuthManager: Session saved successfully');
    } catch (error) {
      AuthManager.logger.error('AuthManager: Failed to save session:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to save session: ${errMsg}`);
    }
  }

  private async clearSession(): Promise<void> {
    this.session = null;
    this.config.setAccessToken(null);
    this.config.clear();
    try {
      await SPHelper.default.delete('matrix_session');
    } catch (error) {
      AuthManager.logger.error('AuthManager: Failed to clear session from storage:', error);
    }
  }

  getSession(): Session | null {
    return this.session;
  }

  getUserId(): string {
    return this.session?.userId || '';
  }

  isLoggedIn(): boolean {
    return this.session !== null && this.session.accessToken !== '';
  }

  private generateDeviceId(): string {
    const randomPart = RandomUtil.generateUUIDRandom().replace(/-/g, '').substring(0, 10);
    return 'TOONA' + randomPart;
  }

  async updateNextBatch(nextBatch: string): Promise<void> {
    if (this.session) {
      this.session.nextBatch = nextBatch;
      await this.saveSession();
    }
  }

  reset(): void {
    this.session = null;
    this.isInitialized = false;
  }

  async loadSavedCredentials(): Promise<SavedCredentials | null> {
    try {
      const savedHomeserver = await SPHelper.default.get('saved_homeserver', '') as string;
      const savedUserId = await SPHelper.default.get('saved_user_id', '') as string;
      const savedRemember = await SPHelper.default.get('remember_me', 'false') as string;

      if (savedRemember === 'true' && savedHomeserver) {
        const creds: SavedCredentials = {
          homeserver: savedHomeserver,
          userId: savedUserId,
          rememberMe: true
        };
        return creds;
      }
      return null;
    } catch (error) {
      AuthManager.logger.error('Failed to load saved credentials:', error);
      return null;
    }
  }

  async saveCredentials(homeserver: string, userId: string, rememberMe: boolean): Promise<void> {
    if (rememberMe) {
      await SPHelper.default.saveAndFlush('saved_homeserver', homeserver);
      await SPHelper.default.saveAndFlush('saved_user_id', userId);
      await SPHelper.default.saveAndFlush('remember_me', 'true');
    } else {
      await SPHelper.default.delete('saved_homeserver');
      await SPHelper.default.delete('saved_user_id');
      await SPHelper.default.saveAndFlush('remember_me', 'false');
    }
  }

  async clearSavedCredentials(): Promise<void> {
    try {
      await SPHelper.default.delete('saved_homeserver');
      await SPHelper.default.delete('saved_user_id');
      await SPHelper.default.delete('remember_me');
    } catch (error) {
      AuthManager.logger.error('Failed to clear saved credentials:', error);
    }
  }
}
