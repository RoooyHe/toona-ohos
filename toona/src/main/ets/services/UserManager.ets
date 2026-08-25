import { AppLogger } from '../utils/AppLogger';
import { AuthManager, IAuthManager } from './AuthManager';
import { GetPresenceResponse, PresenceState, SetPresenceRequest } from '../models/MatrixTypes';
import { UserProfile } from '../models/DataModels';
import { BaseHttpClient } from '../network/clients/BaseHttpClient';

interface DisplayNameResponse {
  displayname?: string;
}

interface AvatarUrlResponse {
  avatar_url?: string;
}

export interface IUserManager {
  getUserProfile(userId?: string): Promise<UserProfile>;
  setDisplayName(displayName: string): Promise<void>;
  setAvatarUrl(avatarUrl: string): Promise<void>;
  getPresence(userId: string): Promise<GetPresenceResponse>;
  setPresence(userId: string, presence: PresenceState, statusMsg?: string): Promise<void>;
  getDisplayName(userId?: string): Promise<string | null>;
  getAvatarUrl(userId?: string): Promise<string | null>;
}

export class UserManager implements IUserManager {
  private logger = AppLogger.getLogger(UserManager);
  private authManager: IAuthManager;
  private baseClient: BaseHttpClient;

  constructor(authManager: IAuthManager, baseClient: BaseHttpClient) {
    this.authManager = authManager;
    this.baseClient = baseClient;
  }

  async getDisplayName(userId?: string): Promise<string | null> {
    const targetUserId: string = userId ?? this.authManager.getUserId();
    if (!targetUserId) {
      throw new Error('Not logged in');
    }
    try {
      const encodedUserId = this.baseClient.encodePath(targetUserId);
      const response = await this.baseClient.get<DisplayNameResponse>(
        `/profile/${encodedUserId}/displayname`
      );
      return response.displayname ?? null;
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
      const encodedUserId = this.baseClient.encodePath(userId);
      await this.baseClient.put<void>(
        `/profile/${encodedUserId}/displayname`,
        { "displayname": displayName }
      );
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
      const encodedUserId = this.baseClient.encodePath(targetUserId);
      const response = await this.baseClient.get<AvatarUrlResponse>(
        `/profile/${encodedUserId}/avatar_url`
      );
      return response.avatar_url ?? null;
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
      const encodedUserId = this.baseClient.encodePath(userId);
      await this.baseClient.put<void>(
        `/profile/${encodedUserId}/avatar_url`,
        { "avatar_url": avatarUrl }
      );
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
      const encodedUserId = this.baseClient.encodePath(userId);
      return await this.baseClient.get<GetPresenceResponse>(`/presence/${encodedUserId}/status`);
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
      const encodedUserId = this.baseClient.encodePath(userId);
      const body: Record<string, string | object> = { 'presence': request.presence };
      if (request.status_msg !== undefined) {
        body['status_msg'] = request.status_msg;
      }
      await this.baseClient.put<void>(`/presence/${encodedUserId}/status`, body);
    } catch (error) {
      this.logger.error('Failed to set presence:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to set presence: ${errMsg}`);
    }
  }
}
