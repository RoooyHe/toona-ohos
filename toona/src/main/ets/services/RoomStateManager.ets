import { MatrixHttpClient, MatrixConfig } from '../network/MatrixHttpClient';
import {
  RoomAvatarContent,
  RoomAvatarContentInfo,
  RoomDirectoryResponse,
  PublicRoomsResponse,
  PublicRoom,
  RoomMembersResponse,
  SetReadMarkersRequest,
  ReceiptContent
} from '../models/MatrixTypes';

export class RoomStateManager {
  private static instance: RoomStateManager;
  private httpClient: MatrixHttpClient | null = null;

  private constructor() {
  }

  static getInstance(): RoomStateManager {
    if (!RoomStateManager.instance) {
      RoomStateManager.instance = new RoomStateManager();
    }
    return RoomStateManager.instance;
  }

  setHomeserver(homeserverUrl: string): void {
    MatrixConfig.getInstance().setHomeserver(homeserverUrl);
    this.httpClient = MatrixConfig.getInstance().getHttpClient();
  }

  private ensureHttpClient(): MatrixHttpClient {
    if (!this.httpClient) {
      throw new Error('RoomStateManager not initialized. Call setHomeserver first.');
    }
    return this.httpClient;
  }

  async setRoomAvatar(roomId: string, avatarUrl: string, info?: RoomAvatarContentInfo): Promise<void> {
    try {
      const avatar: RoomAvatarContent = { url: avatarUrl };
      if (info) {
        avatar.info = info;
      }
      await this.ensureHttpClient().setRoomAvatar(roomId, avatar);
    } catch (error) {
      console.error('Failed to set room avatar:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to set room avatar: ${errMsg}`);
    }
  }

  async getCanonicalAlias(roomId: string): Promise<string | null> {
    try {
      const result = await this.ensureHttpClient().getCanonicalAlias(roomId);
      return result?.alias ?? null;
    } catch (error) {
      console.error('Failed to get canonical alias:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get canonical alias: ${errMsg}`);
    }
  }

  async setCanonicalAlias(roomId: string, alias: string): Promise<void> {
    try {
      await this.ensureHttpClient().setCanonicalAlias(roomId, alias);
    } catch (error) {
      console.error('Failed to set canonical alias:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to set canonical alias: ${errMsg}`);
    }
  }

  async getRoomAliases(roomId: string): Promise<string[]> {
    try {
      const result = await this.ensureHttpClient().getRoomAliases(roomId);
      return result?.aliases ?? [];
    } catch (error) {
      console.error('Failed to get room aliases:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get room aliases: ${errMsg}`);
    }
  }

  async setRoomAliases(roomId: string, aliases: string[]): Promise<void> {
    try {
      await this.ensureHttpClient().setRoomAliases(roomId, aliases);
    } catch (error) {
      console.error('Failed to set room aliases:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to set room aliases: ${errMsg}`);
    }
  }

  async getRoomMembers(roomId: string, start?: string, end?: string): Promise<RoomMembersResponse> {
    try {
      return await this.ensureHttpClient().getRoomMembers(roomId, start, end);
    } catch (error) {
      console.error('Failed to get room members:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get room members: ${errMsg}`);
    }
  }

  async setReadMarkers(roomId: string, fullyReadEventId: string, unreadNotificationKey?: string): Promise<void> {
    try {
      const request: SetReadMarkersRequest = { fully_read: fullyReadEventId };
      if (unreadNotificationKey) {
        const notifications: Record<string, string | object> = {};
        notifications[unreadNotificationKey] = 'highlighted';
        request.unread_notifications = notifications;
      }
      await this.ensureHttpClient().setReadMarkers(roomId, request);
    } catch (error) {
      console.error('Failed to set read markers:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to set read markers: ${errMsg}`);
    }
  }

  async markRoomAsRead(roomId: string, fullyReadEventId: string): Promise<void> {
    await this.setReadMarkers(roomId, fullyReadEventId);
  }

  async getReceipt(roomId: string, receiptType: string, eventId: string): Promise<ReceiptContent> {
    try {
      return await this.ensureHttpClient().getReceipt(roomId, receiptType, eventId);
    } catch (error) {
      console.error('Failed to get receipt:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get receipt: ${errMsg}`);
    }
  }

  async createRoomAlias(roomAlias: string, roomId: string, servers: string[]): Promise<void> {
    try {
      await this.ensureHttpClient().createRoomAlias(roomAlias, roomId, servers);
    } catch (error) {
      console.error('Failed to create room alias:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to create room alias: ${errMsg}`);
    }
  }

  async deleteRoomAlias(roomAlias: string): Promise<void> {
    try {
      await this.ensureHttpClient().deleteRoomAlias(roomAlias);
    } catch (error) {
      console.error('Failed to delete room alias:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to delete room alias: ${errMsg}`);
    }
  }

  async resolveRoomAlias(roomAlias: string): Promise<RoomDirectoryResponse> {
    try {
      return await this.ensureHttpClient().resolveRoomAlias(roomAlias);
    } catch (error) {
      console.error('Failed to resolve room alias:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to resolve room alias: ${errMsg}`);
    }
  }

  async getPublicRooms(server?: string, limit?: number, since?: string): Promise<PublicRoomsResponse> {
    try {
      return await this.ensureHttpClient().getPublicRooms(server, limit, since);
    } catch (error) {
      console.error('Failed to get public rooms:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get public rooms: ${errMsg}`);
    }
  }

  async searchPublicRooms(
    server: string,
    query?: string,
    limit?: number,
    since?: string
  ): Promise<PublicRoomsResponse> {
    try {
      const room: Partial<PublicRoom> = {};
      if (query) {
        room.name = query;
      }
      return await this.ensureHttpClient().postPublicRooms(room);
    } catch (error) {
      console.error('Failed to search public rooms:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to search public rooms: ${errMsg}`);
    }
  }
}