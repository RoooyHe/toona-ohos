import {
  PushRules,
  PushRule,
  PushRuleAction,
  NotificationsResponse,
  RoomTags,
  SetNotificationMarkerRequest,
  GetPresenceResponse,
  SetPresenceRequest,
  RelationsResponse
} from '../../models/MatrixTypes';
import { Device, DevicesResponse, UpdateDeviceRequest } from '../../models/types/DeviceTypes';
import { BaseHttpClient } from './BaseHttpClient';

export interface DeviceAuthData {
  auth: Record<string, string | object>;
}

interface DisplayNameResponse {
  displayname?: string;
}

interface AvatarUrlResponse {
  avatar_url?: string;
}

export class MatrixEndpoints extends BaseHttpClient {
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

  async getPushRules(): Promise<PushRules> {
    return await this.get<PushRules>('/pushrules');
  }

  async getPushRule(scope: string, kind: string, ruleId: string): Promise<PushRule> {
    const encoded = this.encodePath(scope, kind, ruleId);
    return await this.get<PushRule>(`/pushrules/${encoded}`);
  }

  async setPushRule(
    scope: string,
    kind: string,
    ruleId: string,
    rule: Partial<PushRule>
  ): Promise<void> {
    const encoded = this.encodePath(scope, kind, ruleId);
    await this.put<void>(
      `/pushrules/${encoded}`,
      rule as Record<string, string | object>
    );
  }

  async deletePushRule(scope: string, kind: string, ruleId: string): Promise<void> {
    const encoded = this.encodePath(scope, kind, ruleId);
    await this.delete<void>(`/pushrules/${encoded}`);
  }

  async setPushRuleActions(
    scope: string,
    kind: string,
    ruleId: string,
    actions: PushRuleAction[]
  ): Promise<void> {
    const encoded = this.encodePath(scope, kind, ruleId);
    await this.post<void>(
      `/pushrules/${encoded}/actions`,
      { "actions": actions }
    );
  }

  async getNotifications(limit?: number, since?: string, only?: string): Promise<NotificationsResponse> {
    const queryParams = this.buildQueryParams({
      'limit': limit,
      'since': since,
      'only': only
    });
    return await this.get<NotificationsResponse>('/notifications', queryParams);
  }

  async setNotificationMarker(request: SetNotificationMarkerRequest): Promise<void> {
    await this.post<void>('/notifications', request as Record<string, string | object>);
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

  async getDevices(): Promise<DevicesResponse> {
    return await this.get<DevicesResponse>('/devices');
  }

  async getDevice(deviceId: string): Promise<Device> {
    const encodedDeviceId = this.encodePath(deviceId);
    return await this.get<Device>(`/devices/${encodedDeviceId}`);
  }

  async updateDevice(deviceId: string, request: UpdateDeviceRequest | Record<string, Object>): Promise<void> {
    const encodedDeviceId = this.encodePath(deviceId);
    await this.put<Record<string, Object>>(`/devices/${encodedDeviceId}`, request as Record<string, string | object>);
  }

  async deleteDevice(deviceId: string, authData?: DeviceAuthData): Promise<void> {
    const encodedDeviceId = this.encodePath(deviceId);
    let payload: Record<string, string | object> | undefined = undefined;
    if (authData) {
      payload = { "auth": authData.auth as object };
    }
    await this.delete<Record<string, Object>>(`/devices/${encodedDeviceId}`, payload);
  }

  async deleteDevices(deviceIds: string[], authData?: DeviceAuthData): Promise<void> {
    const payload: Record<string, string | object> = {
      "devices": deviceIds as Object
    };
    if (authData) {
      payload['auth'] = authData.auth as Object;
    }
    await this.post<Record<string, Object>>('/delete_devices', payload);
  }

  async queryKeys(request: Record<string, Object>): Promise<Record<string, Object>> {
    return await this.post<Record<string, Object>>('/keys/query', request as Record<string, string | object>);
  }

  async uploadKeys(request: Record<string, Object>): Promise<Record<string, Object>> {
    return await this.post<Record<string, Object>>('/keys/upload', request as Record<string, string | object>);
  }

  async claimKeys(request: Record<string, Object>): Promise<Record<string, Object>> {
    return await this.post<Record<string, Object>>('/keys/claim', request as Record<string, string | object>);
  }

  async queryRoomKeys(request: Record<string, Object>): Promise<Record<string, Object>> {
    return await this.post<Record<string, Object>>('/room_keys/query', request as Record<string, string | object>);
  }

  async uploadRoomKeys(request: Record<string, Object>): Promise<Record<string, Object>> {
    return await this.post<Record<string, Object>>('/room_keys/keys', request as Record<string, string | object>);
  }

  async getRoomKeys(version?: string): Promise<Record<string, Object>> {
    const url = version ? `/room_keys/keys?version=${version}` : '/room_keys/keys';
    return await this.get<Record<string, Object>>(url);
  }

  async putRoomKeys(version: string, request: Record<string, Object>): Promise<Record<string, Object>> {
    const encodedVersion = this.encodePath(version);
    return await this.put<Record<string, Object>>(`/room_keys/keys?version=${version}`, request as Record<string, string | object>);
  }

  async getKeyBackupVersion(): Promise<Record<string, Object>> {
    return await this.get<Record<string, Object>>('/room_keys/version');
  }

  async putKeyBackupVersion(version: string, request: Record<string, Object>): Promise<Record<string, Object>> {
    const encodedVersion = this.encodePath(version);
    return await this.put<Record<string, Object>>(`/room_keys/version/${encodedVersion}`, request as Record<string, string | object>);
  }

  async createKeyBackupVersion(request: Record<string, Object>): Promise<Record<string, Object>> {
    return await this.post<Record<string, Object>>('/room_keys/version', request as Record<string, string | object>);
  }

  async deleteKeyBackupVersion(version: string): Promise<Record<string, Object>> {
    const encodedVersion = this.encodePath(version);
    return await this.delete<Record<string, Object>>(`/room_keys/version/${encodedVersion}`);
  }

  async uploadSignatures(request: Record<string, Object>): Promise<Record<string, Object>> {
    return await this.post<Record<string, Object>>('/keys/signatures/upload', request as Record<string, string | object>);
  }

  async getRelations(
    roomId: string,
    eventId: string,
    relType?: string,
    eventType?: string,
    limit?: number,
    direction?: 'f' | 'b'
  ): Promise<RelationsResponse> {
    const encodedRoomId = this.encodePath(roomId);
    const encodedEventId = this.encodePath(eventId);
    const queryParams = this.buildQueryParams({
      'rel_type': relType,
      'event_type': eventType,
      'limit': limit,
      'direction': direction
    });
    let endpoint = `/rooms/${encodedRoomId}/relations/${encodedEventId}`;
    if (relType !== undefined && eventType !== undefined) {
      endpoint += `/${relType}/${eventType}`;
    }
    return await this.get<RelationsResponse>(endpoint, queryParams);
  }

  async addAnnotation(
    roomId: string,
    eventId: string,
    relType: string,
    key: string,
    type: string,
    content: Record<string, string | object>
  ): Promise<void> {
    const encodedRoomId = this.encodePath(roomId);
    const encodedEventId = this.encodePath(eventId);
    const body: Record<string, string | object> = { 'key': key };
    const contentKeys = Object.keys(content);
    for (let i = 0; i < contentKeys.length; i++) {
      const k = contentKeys[i];
      body[k] = content[k];
    }
    await this.put<void>(
      `/rooms/${encodedRoomId}/relations/${encodedEventId}/${relType}/${type}`,
      body
    );
  }
}
