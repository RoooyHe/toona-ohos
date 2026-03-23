import { MatrixHttpClient, MatrixConfig } from '../network/MatrixHttpClient';
import { 
  LoginRequest, 
  LoginResponse, 
  RegisterRequest, 
  RegisterResponse,
  WhoAmIResponse,
  VersionsResponse 
} from '../models/MatrixTypes';
import { Session } from '../models/DataModels';
import { SecureStorage } from '../storage/SecureStorage';
import { Context } from '@kit.AbilityKit';

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
      const response = await this.httpClient.get<VersionsResponse>('/versions');
      return response.versions && response.versions.includes('r0.0.0');
    } catch (error) {
      console.error('Failed to check homeserver version:', error);
      return false;
    }
  }

  async login(userId: string, password: string, deviceName?: string): Promise<Session> {
    if (!this.httpClient) {
      throw new Error('Homeserver not set');
    }

    const loginRequest: LoginRequest = {
      identifier: {
        type: 'm.id.user',
        user: userId
      },
      password: password,
      device_id: this.generateDeviceId(),
      initial_device_display_name: deviceName || 'Toona鸿蒙客户端'
    };

    try {
      const response = await this.httpClient.post<LoginResponse>('/login', loginRequest);
      
      this.session = Session.fromLoginResponse(response, response.access_token);
      this.session.isGuest = false;
      
      this.httpClient.setAccessToken(response.access_token);
      
      await this.saveSession();
      
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

    const registerRequest: RegisterRequest = {
      username: username,
      password: password,
      device_id: this.generateDeviceId(),
      initial_device_display_name: deviceName || 'Toona鸿蒙客户端'
    };

    try {
      const response = await this.httpClient.post<RegisterResponse>('/register', registerRequest);
      
      this.session = Session.fromLoginResponse(response, response.access_token);
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
      await this.httpClient.post('/logout');
    } catch (error) {
      console.error('Logout request failed:', error);
    } finally {
      this.clearSession();
    }
  }

  async restoreSession(): Promise<Session | null> {
    if (!this.secureStorage) {
      return null;
    }

    try {
      const sessionJson = await this.secureStorage.loadSession();
      if (!sessionJson) {
        return null;
      }

      const sessionData = JSON.parse(sessionJson);
      this.session = Session.fromJSON(sessionData);
      
      MatrixConfig.getInstance().setHomeserver(this.session.homeServer);
      this.httpClient = MatrixConfig.getInstance().getHttpClient();
      this.httpClient.setAccessToken(this.session.accessToken);
      
      const isValid = await this.validateToken();
      if (!isValid) {
        await this.clearSession();
        return null;
      }
      
      return this.session;
    } catch (error) {
      console.error('Failed to restore session:', error);
      return null;
    }
  }

  async validateToken(): Promise<boolean> {
    if (!this.httpClient) {
      return false;
    }

    try {
      const response = await this.httpClient.get<WhoAmIResponse>('/account/whoami');
      return response.user_id === this.session?.userId;
    } catch (error) {
      console.error('Token validation failed:', error);
      return false;
    }
  }

  private async saveSession(): Promise<void> {
    if (!this.session) {
      return;
    }
    const sessionJson = JSON.stringify(this.session.toJSON());
    await this.secureStorage.saveSession(sessionJson);
  }

  private clearSession(): void {
    this.session = null;
    this.httpClient?.setAccessToken(null);
    MatrixConfig.getInstance().clear();
    this.secureStorage.clearSession();
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
