import { IAuthManager } from '../services/AuthManager';
import { AppLogger } from '../utils/AppLogger';
import { ToastUtils } from '../utils/ToastUtils';

const logger = AppLogger.getLogger('RegisterViewModel');

export interface RegisterState {
  homeserver: string;
  username: string;
  password: string;
  confirmPassword: string;
  isLoading: boolean;
  errorMessage: string;
}

export type RegisterStateCallback = (state: RegisterState) => void;
export type RegisterSuccessCallback = () => void;

export class RegisterViewModel {
  private authManager: IAuthManager;
  private state: RegisterState;
  private onStateChanged: RegisterStateCallback | null = null;
  private onRegisterSuccess: RegisterSuccessCallback | null = null;

  constructor(authManager: IAuthManager) {
    this.authManager = authManager;
    this.state = {
      homeserver: authManager.getHomeserver() || '',
      username: '',
      password: '',
      confirmPassword: '',
      isLoading: false,
      errorMessage: ''
    };
  }

  setOnStateChanged(callback: RegisterStateCallback): void {
    this.onStateChanged = callback;
  }

  setOnRegisterSuccess(callback: RegisterSuccessCallback): void {
    this.onRegisterSuccess = callback;
  }

  private notifyStateChanged(): void {
    if (this.onStateChanged) {
      this.onStateChanged(this.state);
    }
  }

  getState(): RegisterState {
    return this.state;
  }

  setHomeserver(value: string): void {
    this.state.homeserver = value;
    this.notifyStateChanged();
  }

  setUsername(value: string): void {
    this.state.username = value;
    this.notifyStateChanged();
  }

  setPassword(value: string): void {
    this.state.password = value;
    this.notifyStateChanged();
  }

  setConfirmPassword(value: string): void {
    this.state.confirmPassword = value;
    this.notifyStateChanged();
  }

  async register(): Promise<void> {
    if (!this.state.homeserver || !this.state.username || !this.state.password || !this.state.confirmPassword) {
      this.state.errorMessage = '请填写所有字段';
      this.notifyStateChanged();
      return;
    }

    if (this.state.password !== this.state.confirmPassword) {
      this.state.errorMessage = '两次密码输入不一致';
      this.notifyStateChanged();
      return;
    }

    if (this.state.password.length < 8) {
      this.state.errorMessage = '密码长度至少8位';
      this.notifyStateChanged();
      return;
    }

    let serverUrl: string = this.state.homeserver.trim();
    if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
      serverUrl = 'https://' + serverUrl;
    }
    serverUrl = serverUrl.replace(/\/$/, '');

    this.state.isLoading = true;
    this.state.errorMessage = '';
    this.notifyStateChanged();

    try {
      if (serverUrl !== this.authManager.getHomeserver()) {
        await this.authManager.setHomeserver(serverUrl);
      }

      const isValidServer: boolean = await this.authManager.checkHomeserverVersion();
      if (!isValidServer) {
        this.state.errorMessage = '无法连接到服务器';
        this.state.isLoading = false;
        this.notifyStateChanged();
        return;
      }

      await this.authManager.register(this.state.username, this.state.password);

      ToastUtils.show('注册成功', 2000);

      if (this.onRegisterSuccess) {
        this.onRegisterSuccess();
      }
    } catch (error) {
      logger.error('Registration failed:', error);
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      if (errorMsg.includes('M_USER_IN_USE')) {
        this.state.errorMessage = '用户名已被使用';
      } else if (errorMsg.includes('M_WEAK_PASSWORD')) {
        this.state.errorMessage = '密码强度不够';
      } else if (errorMsg.includes(':')) {
        const parts: string[] = errorMsg.split(':');
        this.state.errorMessage = parts[1] ? parts[1].trim() : errorMsg;
      } else {
        this.state.errorMessage = '注册失败，请检查服务器地址';
      }
    } finally {
      this.state.isLoading = false;
      this.notifyStateChanged();
    }
  }
}
