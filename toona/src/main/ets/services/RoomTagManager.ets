import { MatrixHttpClient, MatrixConfig } from '../network/MatrixHttpClient';
import { RoomTags } from '../models/MatrixTypes';
import { AuthManager } from './AuthManager';

export class RoomTagManager {
  private static instance: RoomTagManager;
  private httpClient: MatrixHttpClient | null = null;

  private constructor() {
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
    const userId: string = AuthManager.getInstance().getUserId();
    if (!userId) {
      throw new Error('Not logged in');
    }
    try {
      return await this.ensureHttpClient().getRoomTags(userId, roomId);
    } catch (error) {
      console.error('Failed to get room tags:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get room tags: ${errMsg}`);
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
      console.error('Failed to add room tag:', error);
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
      console.error('Failed to remove room tag:', error);
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