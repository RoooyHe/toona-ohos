import { UserHttpClient } from '../network/clients/UserHttpClient';
import { AppLogger } from '../utils/AppLogger';
import { AuthManager, IAuthManager } from './AuthManager';

interface GeneratedTypeLiteralInterface_1 {
  displayName: string | null;
  avatarUrl: string | null;
}

export class UserManager {
  private userClient: UserHttpClient;
  private logger = AppLogger.getLogger(UserManager);
  private authManager: IAuthManager;

  constructor(authManager: IAuthManager, userClient: UserHttpClient) {
    this.authManager = authManager;
    this.userClient = userClient;
  }

  async getDisplayName(userId?: string): Promise<string | null> {
    const targetUserId: string = userId ?? this.authManager.getUserId();
    if (!targetUserId) {
      throw new Error('Not logged in');
    }
    try {
      return await this.userClient.getDisplayName(targetUserId);
    } catch (error) {
      this.logger.error('Failed to get display name:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get display name: ${errMsg}`);
    }
  }

  async setDisplayName(displayName: string): Promise<void> {
    const userId: string = this.authManager.getUserId();
    if (!userId) {
      throw new Error('Not logged in');
    }
    try {
      await this.userClient.setDisplayName(userId, displayName);
    } catch (error) {
      this.logger.error('Failed to set display name:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to set display name: ${errMsg}`);
    }
  }

  async getAvatarUrl(userId?: string): Promise<string | null> {
    const targetUserId: string = userId ?? this.authManager.getUserId();
    if (!targetUserId) {
      throw new Error('Not logged in');
    }
    try {
      return await this.userClient.getAvatarUrl(targetUserId);
    } catch (error) {
      this.logger.error('Failed to get avatar URL:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get avatar URL: ${errMsg}`);
    }
  }

  async setAvatarUrl(avatarUrl: string): Promise<void> {
    const userId: string = this.authManager.getUserId();
    if (!userId) {
      throw new Error('Not logged in');
    }
    try {
      await this.userClient.setAvatarUrl(userId, avatarUrl);
    } catch (error) {
      this.logger.error('Failed to set avatar URL:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to set avatar URL: ${errMsg}`);
    }
  }

  async getUserProfile(userId?: string): Promise<GeneratedTypeLiteralInterface_1> {
    const results: Array<string | null> = await Promise.all([
      this.getDisplayName(userId),
      this.getAvatarUrl(userId)
    ]);
    const displayName = results[0];
    const avatarUrl = results[1];
    return {
      displayName: displayName,
      avatarUrl: avatarUrl
    };
  }
}
