import { AppLogger } from '../utils/AppLogger';
import { RoomTags, TagContent } from '../models/MatrixTypes';
import { AuthManager, IAuthManager } from './AuthManager';
import { LocalDatabase } from '../database/LocalDatabase';
import { UserHttpClient } from '../network/clients/UserHttpClient';

export interface IRoomTagManager {
  isFavorite(roomId: string): Promise<boolean>;
  addFavorite(roomId: string, order?: number): Promise<void>;
  removeFavorite(roomId: string): Promise<void>;
  isLowPriority(roomId: string): Promise<boolean>;
  addLowPriority(roomId: string, order?: number): Promise<void>;
  removeLowPriority(roomId: string): Promise<void>;
}

export class RoomTagManager implements IRoomTagManager {
  private logger = AppLogger.getLogger(RoomTagManager);
  private userHttpClient: UserHttpClient;
  private authManager: IAuthManager;
  private localDatabase: LocalDatabase;

  constructor(
    authManager: IAuthManager,
    localDatabase: LocalDatabase,
    userHttpClient: UserHttpClient
  ) {
    this.authManager = authManager;
    this.localDatabase = localDatabase;
    this.userHttpClient = userHttpClient;
  }

  async getRoomTags(roomId: string): Promise<RoomTags> {
    try {
      const room = await this.localDatabase.getRoom(roomId);
      if (room && room.tags) {
        return { tags: room.tags as Record<string, TagContent> };
      }
      return { tags: {} };
    } catch (error) {
      this.logger.error('Failed to get room tags from local database:', error);
      return { tags: {} };
    }
  }

  async addTag(roomId: string, tag: string, order?: number): Promise<void> {
    const userId: string = this.authManager.getUserId();
    if (!userId) {
      throw new Error('Not logged in');
    }
    try {
      await this.userHttpClient.addRoomTag(userId, roomId, tag, order);
    } catch (error) {
      this.logger.error('Failed to add room tag:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to add room tag: ${errMsg}`);
    }
  }

  async removeTag(roomId: string, tag: string): Promise<void> {
    const userId: string = this.authManager.getUserId();
    if (!userId) {
      throw new Error('Not logged in');
    }
    try {
      await this.userHttpClient.removeRoomTag(userId, roomId, tag);
    } catch (error) {
      this.logger.error('Failed to remove room tag:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to remove room tag: ${errMsg}`);
    }
  }

  async addFavorite(roomId: string, order?: number): Promise<void> {
    await this.addTag(roomId, 'm.favourite', order);
  }

  async removeFavorite(roomId: string): Promise<void> {
    await this.removeTag(roomId, 'm.favourite');
  }

  async addLowPriority(roomId: string, order?: number): Promise<void> {
    await this.addTag(roomId, 'm.lowpriority', order);
  }

  async removeLowPriority(roomId: string): Promise<void> {
    await this.removeTag(roomId, 'm.lowpriority');
  }

  async isFavorite(roomId: string): Promise<boolean> {
    const tags = await this.getRoomTags(roomId);
    if (!tags.tags) {
      return false;
    }
    const tagKeys: string[] = Object.keys(tags.tags);
    return tagKeys.includes('m.favourite');
  }

  async isLowPriority(roomId: string): Promise<boolean> {
    const tags = await this.getRoomTags(roomId);
    if (!tags.tags) {
      return false;
    }
    const tagKeys: string[] = Object.keys(tags.tags);
    return tagKeys.includes('m.lowpriority');
  }
}
