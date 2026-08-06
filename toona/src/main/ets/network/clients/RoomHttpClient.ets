import {
  RoomAvatarContent,
  RoomMembersResponse,
  SetReadMarkersRequest,
  ReceiptContent,
  RoomDirectoryResponse,
  PublicRoomsResponse,
  PublicRoom,
  CanonicalAliasContent,
  RoomAliasesContent
} from '../../models/MatrixTypes';
import { BaseHttpClient } from './BaseHttpClient';

export class RoomHttpClient extends BaseHttpClient {
  async setRoomAvatar(roomId: string, avatar: RoomAvatarContent): Promise<void> {
    const encodedRoomId = this.encodePath(roomId);
    const body: Record<string, string | object> = { 'url': avatar.url };
    if (avatar.info) {
      if (avatar.info.mimetype) {
        body['mimetype'] = avatar.info.mimetype;
      }
      if (avatar.info.size !== undefined) {
        body['size'] = String(avatar.info.size);
      }
      if (avatar.info.width !== undefined) {
        body['width'] = String(avatar.info.width);
      }
      if (avatar.info.height !== undefined) {
        body['height'] = String(avatar.info.height);
      }
    }
    await this.put<void>(`/rooms/${encodedRoomId}/state/m.room.avatar`, body);
  }

  async getCanonicalAlias(roomId: string): Promise<CanonicalAliasContent | null> {
    const encodedRoomId = this.encodePath(roomId);
    try {
      return await this.get<CanonicalAliasContent>(
        `/rooms/${encodedRoomId}/state/m.room.canonical_alias`
      );
    } catch (error) {
      if (error.message.includes('404')) {
        return null;
      }
      throw new Error(error.message);
    }
  }

  async setCanonicalAlias(roomId: string, alias: string): Promise<void> {
    const encodedRoomId = this.encodePath(roomId);
    const body: Record<string, string | object> = { 'alias': alias };
    await this.put<void>(`/rooms/${encodedRoomId}/state/m.room.canonical_alias`, body);
  }

  async getRoomAliases(roomId: string): Promise<RoomAliasesContent | null> {
    const encodedRoomId = this.encodePath(roomId);
    try {
      return await this.get<RoomAliasesContent>(
        `/rooms/${encodedRoomId}/state/m.room.aliases`
      );
    } catch (error) {
      if (error.message.includes('404')) {
        return null;
      }
      throw new Error(error.message);
    }
  }

  async setRoomAliases(roomId: string, aliases: string[]): Promise<void> {
    const encodedRoomId = this.encodePath(roomId);
    const body: Record<string, string | object> = { 'aliases': aliases };
    await this.put<void>(`/rooms/${encodedRoomId}/state/m.room.aliases`, body);
  }

  async getRoomMembers(roomId: string, start?: string, end?: string, sess?: string): Promise<RoomMembersResponse> {
    const encodedRoomId = this.encodePath(roomId);
    const queryParams = this.buildQueryParams({
      'start': start,
      'end': end,
      'sess': sess
    });
    return await this.get<RoomMembersResponse>(
      `/rooms/${encodedRoomId}/members`,
      queryParams
    );
  }

  async setReadMarkers(roomId: string, request: SetReadMarkersRequest): Promise<void> {
    const encodedRoomId = this.encodePath(roomId);
    const body: Record<string, string | object> = {};
    if (request.fully_read !== undefined) {
      body['fully_read'] = request.fully_read;
    }
    if (request.highlighted !== undefined) {
      body['highlighted'] = request.highlighted;
    }
    if (request.unread_notifications !== undefined) {
      body['unread_notifications'] = request.unread_notifications;
    }
    await this.post<void>(`/rooms/${encodedRoomId}/read_markers`, body);
  }

  async getReceipt(roomId: string, receiptType: string, eventId: string): Promise<ReceiptContent> {
    const encodedRoomId = this.encodePath(roomId);
    const encodedEventId = this.encodePath(eventId);
    return await this.get<ReceiptContent>(
      `/rooms/${encodedRoomId}/receipt/${receiptType}/${encodedEventId}`
    );
  }

  async postReceipt(roomId: string, receiptType: string, eventId: string, threadId?: string): Promise<void> {
    const encodedRoomId = this.encodePath(roomId);
    const encodedEventId = this.encodePath(eventId);
    const body: Record<string, string | object> = {};
    if (threadId !== undefined) {
      body['thread_id'] = threadId;
    }
    await this.post<void>(`/rooms/${encodedRoomId}/receipt/${receiptType}/${encodedEventId}`, body);
  }

  async createRoomAlias(roomAlias: string, roomId: string, servers: string[]): Promise<void> {
    const encodedRoomAlias = this.encodePath(roomAlias);
    const body: Record<string, string | object> = { 'room_id': roomId, 'servers': servers };
    await this.put<void>(`/directory/room/${encodedRoomAlias}`, body);
  }

  async deleteRoomAlias(roomAlias: string): Promise<void> {
    const encodedRoomAlias = this.encodePath(roomAlias);
    await this.delete<void>(`/directory/room/${encodedRoomAlias}`);
  }

  async resolveRoomAlias(roomAlias: string): Promise<RoomDirectoryResponse> {
    const encodedRoomAlias = this.encodePath(roomAlias);
    return await this.get<RoomDirectoryResponse>(`/directory/room/${encodedRoomAlias}`);
  }

  async getPublicRooms(server?: string, limit?: number, since?: string): Promise<PublicRoomsResponse> {
    const queryParams = this.buildQueryParams({
      'server': server,
      'limit': limit,
      'since': since
    });
    return await this.get<PublicRoomsResponse>('/publicRooms', queryParams);
  }

  async postPublicRooms(room: Partial<PublicRoom>): Promise<PublicRoomsResponse> {
    const body: Record<string, string | object> = {};
    if (room.room_id !== undefined) {
      body['room_id'] = room.room_id;
    }
    if (room.name !== undefined) {
      body['name'] = room.name;
    }
    if (room.topic !== undefined) {
      body['topic'] = room.topic;
    }
    if (room.avatar_url !== undefined) {
      body['avatar_url'] = room.avatar_url;
    }
    if (room.join_rule !== undefined) {
      body['join_rule'] = room.join_rule;
    }
    if (room.guest_access !== undefined) {
      body['guest_access'] = room.guest_access;
    }
    if (room.world_readable !== undefined) {
      body['world_readable'] = room.world_readable ? 'true' : 'false';
    }
    if (room.num_joined_members !== undefined) {
      body['num_joined_members'] = String(room.num_joined_members);
    }
    return await this.post<PublicRoomsResponse>('/publicRooms', body);
  }

  async putTyping(roomId: string, userId: string, typing: boolean, timeout?: number): Promise<void> {
    const encodedRoomId = this.encodePath(roomId);
    const encodedUserId = this.encodePath(userId);
    const body: Record<string, string | object> = { 'typing': typing ? 'true' : 'false' };
    if (timeout !== undefined) {
      body['timeout'] = String(timeout);
    }
    await this.put<void>(
      `/rooms/${encodedRoomId}/typing/${encodedUserId}`,
      body
    );
  }

  async getTypingUsers(roomId: string, userId: string): Promise<string[]> {
    const encodedRoomId = this.encodePath(roomId);
    const encodedUserId = this.encodePath(userId);
    interface TypingUsersResponse {
      user_ids: string[];
    }
    const response = await this.get<TypingUsersResponse>(
      `/rooms/${encodedRoomId}/typing/${encodedUserId}`
    );
    return response.user_ids || [];
  }
}
