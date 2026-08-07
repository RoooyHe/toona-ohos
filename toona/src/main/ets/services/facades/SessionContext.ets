import { IAuthManager } from '../AuthManager';
import { UserAuthManager } from '../UserAuthManager';
import { ServiceLocator } from '../ServiceLocator';
import { Session } from '../../models/DataModels';

export class SessionContext {
  private authManager: IAuthManager = ServiceLocator.getAuthManager();
  private userAuthManager: UserAuthManager = ServiceLocator.getUserAuthManager();

  getAuthManager(): IAuthManager {
    return this.authManager;
  }

  getUserAuthManager(): UserAuthManager {
    return this.userAuthManager;
  }

  getSession(): Session | null {
    return this.authManager.getSession();
  }

  getHomeserver(): string {
    return this.authManager.getHomeserver();
  }

  async setHomeserver(url: string): Promise<void> {
    await this.authManager.setHomeserver(url);
  }

  async checkHomeserverVersion(): Promise<boolean> {
    return await this.authManager.checkHomeserverVersion();
  }

  async login(userId: string, password: string): Promise<Session> {
    return await this.authManager.login(userId, password);
  }

  async register(username: string, password: string): Promise<void> {
    await this.authManager.register(username, password);
  }

  async logout(): Promise<void> {
    await this.authManager.logout();
  }

  async authenticateWithFace(): Promise<boolean> {
    return await this.userAuthManager.authenticateWithFace();
  }
}
