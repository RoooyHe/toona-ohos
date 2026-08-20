import { IAuthManager, SavedCredentials } from '../services/AuthManager';
import { AppLogger } from '../utils/AppLogger';
import { ToastUtils } from '../utils/ToastUtils';

const logger = AppLogger.getLogger('LoginViewModel');

export interface LoginState {
  homeserver: string;
  userId: string;
  password: string;
  isLoading: boolean;
  isDiscovering: boolean;
  errorMessage: string;
  rememberMe: boolean;
}

export type LoginStateCallback = (state: LoginState) => void;
export type LoginSuccessCallback = () => void;
export type NavigateToRegisterCallback = () => void;

export class LoginViewModel {
  private authManager: IAuthManager;
  private state: LoginState;
  private onStateChanged: LoginStateCallback | null = null;
  private onLoginSuccess: LoginSuccessCallback | null = null;
  private onNavigateToRegister: NavigateToRegisterCallback | null = null;

  constructor(authManager: IAuthManager) {
    this.authManager = authManager;
    this.state = {
      homeserver: '',
      userId: '',
      password: '',
      isLoading: false,
      isDiscovering: false,
      errorMessage: '',
      rememberMe: true
    };
  }

  setOnStateChanged(callback: LoginStateCallback): void {
    this.onStateChanged = callback;
  }

  setOnLoginSuccess(callback: LoginSuccessCallback): void {
    this.onLoginSuccess = callback;
  }

  setOnNavigateToRegister(callback: NavigateToRegisterCallback): void {
    this.onNavigateToRegister = callback;
  }

  private notifyStateChanged(): void {
    if (this.onStateChanged) {
      this.onStateChanged(this.state);
    }
  }

  getState(): LoginState {
    return this.state;
  }

  async loadSavedCredentials(): Promise<void> {
    try {
      const creds: SavedCredentials | null = await this.authManager.loadSavedCredentials();
      if (creds && creds.rememberMe) {
        this.state.homeserver = creds.homeserver;
        this.state.userId = creds.userId;
        this.state.rememberMe = true;
        this.notifyStateChanged();
      }
    } catch (error) {
      logger.error('Failed to load saved credentials:', error);
    }
  }

  setHomeserver(value: string): void {
    this.state.homeserver = value;
    this.notifyStateChanged();
  }

  setUserId(value: string): void {
    this.state.userId = value;
    this.notifyStateChanged();
  }

  setPassword(value: string): void {
    this.state.password = value;
    this.notifyStateChanged();
  }

  setRememberMe(value: boolean): void {
    this.state.rememberMe = value;
    this.notifyStateChanged();
  }

  async login(): Promise<void> {
    if (!this.state.homeserver || !this.state.userId || !this.state.password) {
      this.state.errorMessage = '请填写所有字段';
      this.notifyStateChanged();
      return;
    }

    this.state.isDiscovering = true;
    this.state.errorMessage = '';
    this.state.isLoading = true;
    this.notifyStateChanged();

    try {
      let serverUrl: string;
      if (this.state.homeserver.includes('.')) {
        const discovered: string | null = await this.authManager.discoverHomeserverUrl(this.state.homeserver);
        serverUrl = discovered || this.state.homeserver;
      } else {
        serverUrl = this.state.homeserver.trim();
        if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
          serverUrl = 'https://' + serverUrl;
        }
        serverUrl = serverUrl.replace(/\/$/, '');
      }

      await this.authManager.setHomeserver(serverUrl);

      const isValidServer: boolean = await this.authManager.checkHomeserverVersion();
      if (!isValidServer) {
        this.state.errorMessage = '无法连接到服务器';
        this.state.isLoading = false;
        this.state.isDiscovering = false;
        this.notifyStateChanged();
        return;
      }

      await this.authManager.login(this.state.userId, this.state.password);
      await this.authManager.saveCredentials(this.state.homeserver, this.state.userId, this.state.rememberMe);

      ToastUtils.show('登录成功', 2000);

      if (this.onLoginSuccess) {
        this.onLoginSuccess();
      }
    } catch (error) {
      logger.error('Login failed:', error);
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      if (errorMsg.includes('M_FORBIDDEN')) {
        this.state.errorMessage = '用户名或密码错误';
      } else if (errorMsg.includes('M_USER_IN_USE')) {
        this.state.errorMessage = '用户已存在';
      } else if (errorMsg.includes(':')) {
        const parts: string[] = errorMsg.split(':');
        this.state.errorMessage = parts[1] ? parts[1].trim() : errorMsg;
      } else {
        this.state.errorMessage = '登录失败，请检查服务器地址';
      }
    } finally {
      this.state.isLoading = false;
      this.state.isDiscovering = false;
      this.notifyStateChanged();
    }
  }

  handleSSOLogin(): void {
    ToastUtils.show('SSO登录需要配置身份提供商', 2000);
  }

  navigateToRegister(): void {
    if (this.onNavigateToRegister) {
      this.onNavigateToRegister();
    }
  }
}
