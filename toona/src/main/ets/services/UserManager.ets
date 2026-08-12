import { UserHttpClient } from '../network/clients/UserHttpClient';
import { AppLogger } from '../utils/AppLogger';
import { AuthManager, IAuthManager } from './AuthManager';
import { GetPresenceResponse, PresenceState, SetPresenceRequest } from '../models/MatrixTypes';
import { UserProfile } from '../models/DataModels';

export class UserManager {
  private userHttpClient: UserHttpClient;
  private logger = AppLogger.getLogger(UserManager);
  private authManager: IAuthManager;

  constructor(authManager: IAuthManager, userHttpClient: UserHttpClient) {
    this.authManager = authManager;
    this.userHttpClient = userHttpClient;
  }

  async getDisplayName(userId?: string): Promise<string | null> {
    const targetUserId: string = userId ?? this.authManager.getUserId();
    if (!targetUserId) {
      throw new Error('Not logged in');
    }
    try {
      return await this.userHttpClient.getDisplayName(targetUserId);
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
      await this.userHttpClient.setDisplayName(userId, displayName);
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
      return await this.userHttpClient.getAvatarUrl(targetUserId);
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
      await this.userHttpClient.setAvatarUrl(userId, avatarUrl);
    } catch (error) {
      this.logger.error('Failed to set avatar URL:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to set avatar URL: ${errMsg}`);
    }
  }

  async getUserProfile(userId?: string): Promise<UserProfile> {
    const results: Array<string | null> = await Promise.all([
      this.getDisplayName(userId),
      this.getAvatarUrl(userId)
    ]);
    const displayName = results[0];
    const avatarUrl = results[1];
    const profile: UserProfile = {
      displayName: displayName,
      avatarUrl: avatarUrl
    };
    return profile;
  }

  async getPresence(userId: string): Promise<GetPresenceResponse> {
    try {
      return await this.userHttpClient.getPresence(userId);
    } catch (error) {
      this.logger.error('Failed to get presence:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get presence: ${errMsg}`);
    }
  }

  async setPresence(userId: string, presence: PresenceState, statusMsg?: string): Promise<void> {
    try {
      const request: SetPresenceRequest = { presence: presence };
      if (statusMsg !== undefined) {
        request.status_msg = statusMsg;
      }
      await this.userHttpClient.setPresence(userId, request);
    } catch (error) {
      this.logger.error('Failed to set presence:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to set presence: ${errMsg}`);
    }
  }
}
