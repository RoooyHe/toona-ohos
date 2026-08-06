import { MatrixEndpoints } from '../network/clients/MatrixEndpoints';
import { AppLogger } from '../utils/AppLogger';
import { AuthManager, IAuthManager } from './AuthManager';
import { GetPresenceResponse, PresenceState, SetPresenceRequest } from '../models/MatrixTypes';

interface GeneratedTypeLiteralInterface_1 {
  displayName: string | null;
  avatarUrl: string | null;
}

export class UserManager {
  private matrixEndpoints: MatrixEndpoints;
  private logger = AppLogger.getLogger(UserManager);
  private authManager: IAuthManager;

  constructor(authManager: IAuthManager, matrixEndpoints: MatrixEndpoints) {
    this.authManager = authManager;
    this.matrixEndpoints = matrixEndpoints;
  }

  async getDisplayName(userId?: string): Promise<string | null> {
    const targetUserId: string = userId ?? this.authManager.getUserId();
    if (!targetUserId) {
      throw new Error('Not logged in');
    }
    try {
      return await this.matrixEndpoints.getDisplayName(targetUserId);
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
      await this.matrixEndpoints.setDisplayName(userId, displayName);
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
      return await this.matrixEndpoints.getAvatarUrl(targetUserId);
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
      await this.matrixEndpoints.setAvatarUrl(userId, avatarUrl);
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

  async getPresence(userId: string): Promise<GetPresenceResponse> {
    try {
      return await this.matrixEndpoints.getPresence(userId);
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
      await this.matrixEndpoints.setPresence(userId, request);
    } catch (error) {
      this.logger.error('Failed to set presence:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to set presence: ${errMsg}`);
    }
  }
}
