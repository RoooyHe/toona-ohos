import { RoomTags, GetPresenceResponse, SetPresenceRequest } from '../../models/MatrixTypes';
import { BaseHttpClient } from './BaseHttpClient';

interface DisplayNameResponse {
  displayname?: string;
}

interface AvatarUrlResponse {
  avatar_url?: string;
}

export class UserHttpClient extends BaseHttpClient {
  async getDisplayName(userId: string): Promise<string | null> {
    const encodedUserId = this.encodePath(userId);
    const response = await this.get<DisplayNameResponse>(
      `/profile/${encodedUserId}/displayname`
    );
    return response.displayname ?? null;
  }

  async setDisplayName(userId: string, displayName: string): Promise<void> {
    const encodedUserId = this.encodePath(userId);
    await this.put<void>(
      `/profile/${encodedUserId}/displayname`,
      { "displayname": displayName }
    );
  }

  async getAvatarUrl(userId: string): Promise<string | null> {
    const encodedUserId = this.encodePath(userId);
    const response = await this.get<AvatarUrlResponse>(
      `/profile/${encodedUserId}/avatar_url`
    );
    return response.avatar_url ?? null;
  }

  async setAvatarUrl(userId: string, avatarUrl: string): Promise<void> {
    const encodedUserId = this.encodePath(userId);
    await this.put<void>(
      `/profile/${encodedUserId}/avatar_url`,
      { "avatar_url": avatarUrl }
    );
  }

  async getPresence(userId: string): Promise<GetPresenceResponse> {
    const encodedUserId = this.encodePath(userId);
    return await this.get<GetPresenceResponse>(`/presence/${encodedUserId}/status`);
  }

  async setPresence(userId: string, request: SetPresenceRequest): Promise<void> {
    const encodedUserId = this.encodePath(userId);
    const body: Record<string, string | object> = { 'presence': request.presence };
    if (request.status_msg !== undefined) {
      body['status_msg'] = request.status_msg;
    }
    await this.put<void>(`/presence/${encodedUserId}/status`, body);
  }

  async getRoomTags(userId: string, roomId: string): Promise<RoomTags> {
    const encodedUserId = this.encodePath(userId);
    const encodedRoomId = this.encodePath(roomId);
    return await this.get<RoomTags>(
      `/user/${encodedUserId}/rooms/${encodedRoomId}/tags`
    );
  }

  async addRoomTag(
    userId: string,
    roomId: string,
    tag: string,
    order?: number
  ): Promise<void> {
    const encodedUserId = this.encodePath(userId);
    const encodedRoomId = this.encodePath(roomId);
    const encodedTag = this.encodePath(tag);
    const body: Record<string, string | number | undefined> = {};
    if (order !== undefined) {
      body['order'] = order;
    }
    await this.put<void>(
      `/user/${encodedUserId}/rooms/${encodedRoomId}/tags/${encodedTag}`,
      body as Record<string, string | object>
    );
  }

  async removeRoomTag(userId: string, roomId: string, tag: string): Promise<void> {
    const encodedUserId = this.encodePath(userId);
    const encodedRoomId = this.encodePath(roomId);
    const encodedTag = this.encodePath(tag);
    await this.delete<void>(
      `/user/${encodedUserId}/rooms/${encodedRoomId}/tags/${encodedTag}`
    );
  }
}
