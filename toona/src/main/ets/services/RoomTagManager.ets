import { AppLogger } from '../utils/AppLogger';
import { RoomTags } from '../models/MatrixTypes';
import { AuthManager } from './AuthManager';
import { LocalDatabase } from '../database/LocalDatabase';
import { MatrixConfig, MatrixHttpClient } from '../network/MatrixHttpClient';

interface GeneratedTypeLiteralInterface_1 {
  order?: number;
}

export class RoomTagManager {
  private logger = AppLogger.getLogger(RoomTagManager);
  private static instance: RoomTagManager;
  private httpClient: MatrixHttpClient | null = null;
  private localDatabase: LocalDatabase;

  private constructor() {
    this.localDatabase = LocalDatabase.getInstance();
  }

  static getInstance(): RoomTagManager {
    if (!RoomTagManager.instance) {
      RoomTagManager.instance = new RoomTagManager();
    }
    return RoomTagManager.instance;
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

  async getRoomTags(roomId: string): Promise<RoomTags> {
    try {
      const room = await this.localDatabase.getRoom(roomId);
      if (room && room.tags) {
        return { tags: room.tags as Record<string, GeneratedTypeLiteralInterface_1> };
      }
      return { tags: {} };
    } catch (error) {
      this.logger.error('Failed to get room tags from local database:', error);
      return { tags: {} };
    }
  }

  async addTag(roomId: string, tag: string, order?: number): Promise<void> {
    const userId: string = AuthManager.getInstance().getUserId();
    if (!userId) {
      throw new Error('Not logged in');
    }
    try {
      await this.ensureHttpClient().addRoomTag(userId, roomId, tag, order);
    } catch (error) {
      this.logger.error('Failed to add room tag:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to add room tag: ${errMsg}`);
    }
  }

  async removeTag(roomId: string, tag: string): Promise<void> {
    const userId: string = AuthManager.getInstance().getUserId();
    if (!userId) {
      throw new Error('Not logged in');
    }
    try {
      await this.ensureHttpClient().removeRoomTag(userId, roomId, tag);
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