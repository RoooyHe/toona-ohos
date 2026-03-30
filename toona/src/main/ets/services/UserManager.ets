import { MatrixHttpClient, MatrixConfig } from '../network/MatrixHttpClient';
import { AuthManager } from './AuthManager';

interface GeneratedTypeLiteralInterface_1 {
  displayName: string | null;
  avatarUrl: string | null;
}

export class UserManager {
  private static instance: UserManager;
  private httpClient: MatrixHttpClient | null = null;

  private constructor() {
  }

  static getInstance(): UserManager {
    if (!UserManager.instance) {
      UserManager.instance = new UserManager();
    }
    return UserManager.instance;
  }

  setHomeserver(homeserverUrl: string): void {
    MatrixConfig.getInstance().setHomeserver(homeserverUrl);
    this.httpClient = MatrixConfig.getInstance().getHttpClient();
  }

  private ensureHttpClient(): MatrixHttpClient {
    if (!this.httpClient) {
      this.httpClient = MatrixConfig.getInstance().getHttpClient();
    }
    return this.httpClient;
  }

  async getDisplayName(userId?: string): Promise<string | null> {
    const targetUserId: string = userId ?? AuthManager.getInstance().getUserId();
    if (!targetUserId) {
      throw new Error('Not logged in');
    }
    try {
      return await this.ensureHttpClient().getDisplayName(targetUserId);
    } catch (error) {
      console.error('Failed to get display name:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get display name: ${errMsg}`);
    }
  }

  async setDisplayName(displayName: string): Promise<void> {
    const userId: string = AuthManager.getInstance().getUserId();
    if (!userId) {
      throw new Error('Not logged in');
    }
    try {
      await this.ensureHttpClient().setDisplayName(userId, displayName);
    } catch (error) {
      console.error('Failed to set display name:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to set display name: ${errMsg}`);
    }
  }

  async getAvatarUrl(userId?: string): Promise<string | null> {
    const targetUserId: string = userId ?? AuthManager.getInstance().getUserId();
    if (!targetUserId) {
      throw new Error('Not logged in');
    }
    try {
      return await this.ensureHttpClient().getAvatarUrl(targetUserId);
    } catch (error) {
      console.error('Failed to get avatar URL:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get avatar URL: ${errMsg}`);
    }
  }

  async setAvatarUrl(avatarUrl: string): Promise<void> {
    const userId: string = AuthManager.getInstance().getUserId();
    if (!userId) {
      throw new Error('Not logged in');
    }
    try {
      await this.ensureHttpClient().setAvatarUrl(userId, avatarUrl);
    } catch (error) {
      console.error('Failed to set avatar URL:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to set avatar URL: ${errMsg}`);
    }
  }

  async getUserProfile(userId?: string): Promise<GeneratedTypeLiteralInterface_1> {
    const GeneratedDestructArray_1 = await Promise.all([
      this.getDisplayName(userId),
      this.getAvatarUrl(userId)
    ]);
    const displayName = GeneratedDestructArray_1[0];
    const avatarUrl = GeneratedDestructArray_1[1];
    return {
      displayName: displayName,
      avatarUrl: avatarUrl
    };
  }
}