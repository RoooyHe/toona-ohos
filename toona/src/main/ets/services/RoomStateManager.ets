import { AppLogger } from '../utils/AppLogger';
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
import { RoomHttpClient } from '../network/clients/RoomHttpClient';

export class RoomStateManager {
  private roomClient: RoomHttpClient;
  private logger = AppLogger.getLogger(RoomStateManager);

  constructor(roomClient: RoomHttpClient) {
    this.roomClient = roomClient;
  }

  async setRoomAvatar(roomId: string, avatarUrl: string, info?: RoomAvatarContentInfo): Promise<void> {
    try {
      const avatar: RoomAvatarContent = { url: avatarUrl };
      if (info) {
        avatar.info = info;
      }
      await this.roomClient.setRoomAvatar(roomId, avatar);
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      this.logger.error(`Failed to set room avatar: ${errMsg}`);
      throw new Error(`Failed to set room avatar: ${errMsg}`);
    }
  }

  async getCanonicalAlias(roomId: string): Promise<string | null> {
    try {
      const result = await this.roomClient.getCanonicalAlias(roomId);
      return result?.alias ?? null;
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      this.logger.error(`Failed to get canonical alias: ${errMsg}`);
      throw new Error(`Failed to get canonical alias: ${errMsg}`);
    }
  }

  async setCanonicalAlias(roomId: string, alias: string): Promise<void> {
    try {
      await this.roomClient.setCanonicalAlias(roomId, alias);
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      this.logger.error(`Failed to set canonical alias: ${errMsg}`);
      throw new Error(`Failed to set canonical alias: ${errMsg}`);
    }
  }

  async getRoomAliases(roomId: string): Promise<string[]> {
    try {
      const result = await this.roomClient.getRoomAliases(roomId);
      return result?.aliases ?? [];
    } catch (error) {
      this.logger.error('Failed to get room aliases:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get room aliases: ${errMsg}`);
    }
  }

  async setRoomAliases(roomId: string, aliases: string[]): Promise<void> {
    try {
      await this.roomClient.setRoomAliases(roomId, aliases);
    } catch (error) {
      this.logger.error('Failed to set room aliases:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to set room aliases: ${errMsg}`);
    }
  }

  async getRoomMembers(roomId: string, start?: string, end?: string): Promise<RoomMembersResponse> {
    try {
      return await this.roomClient.getRoomMembers(roomId, start, end);
    } catch (error) {
      this.logger.error('Failed to get room members:', error);
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
      await this.roomClient.setReadMarkers(roomId, request);
    } catch (error) {
      this.logger.error('Failed to set read markers:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to set read markers: ${errMsg}`);
    }
  }

  async markRoomAsRead(roomId: string, fullyReadEventId: string): Promise<void> {
    await this.setReadMarkers(roomId, fullyReadEventId);
  }

  async getReceipt(roomId: string, receiptType: string, eventId: string): Promise<ReceiptContent> {
    try {
      return await this.roomClient.getReceipt(roomId, receiptType, eventId);
    } catch (error) {
      this.logger.error('Failed to get receipt:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get receipt: ${errMsg}`);
    }
  }

  async createRoomAlias(roomAlias: string, roomId: string, servers: string[]): Promise<void> {
    try {
      await this.roomClient.createRoomAlias(roomAlias, roomId, servers);
    } catch (error) {
      this.logger.error('Failed to create room alias:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to create room alias: ${errMsg}`);
    }
  }

  async deleteRoomAlias(roomAlias: string): Promise<void> {
    try {
      await this.roomClient.deleteRoomAlias(roomAlias);
    } catch (error) {
      this.logger.error('Failed to delete room alias:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to delete room alias: ${errMsg}`);
    }
  }

  async resolveRoomAlias(roomAlias: string): Promise<RoomDirectoryResponse> {
    try {
      return await this.roomClient.resolveRoomAlias(roomAlias);
    } catch (error) {
      this.logger.error('Failed to resolve room alias:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to resolve room alias: ${errMsg}`);
    }
  }

  async getPublicRooms(server?: string, limit?: number, since?: string): Promise<PublicRoomsResponse> {
    try {
      return await this.roomClient.getPublicRooms(server, limit, since);
    } catch (error) {
      this.logger.error('Failed to get public rooms:', error);
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
      return await this.roomClient.postPublicRooms(room);
    } catch (error) {
      this.logger.error('Failed to search public rooms:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to search public rooms: ${errMsg}`);
    }
  }
}
