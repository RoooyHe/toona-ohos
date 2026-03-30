import {
  PushRules,
  PushRule,
  PushRuleAction,
  NotificationsResponse,
  RoomTags,
  SetNotificationMarkerRequest
} from '../../models/MatrixTypes';
import { BaseHttpClient } from './BaseHttpClient';

interface GeneratedTypeLiteralInterface_1 {
  displayname?: string;
}

interface GeneratedTypeLiteralInterface_2 {
  avatar_url?: string;
}

export class UserHttpClient extends BaseHttpClient {
  async getDisplayName(userId: string): Promise<string | null> {
    const encodedUserId = encodeURIComponent(userId);
    const response = await this.get<GeneratedTypeLiteralInterface_1>(
      `/profile/${encodedUserId}/displayname`
    );
    return response.displayname ?? null;
  }

  async setDisplayName(userId: string, displayName: string): Promise<void> {
    const encodedUserId = encodeURIComponent(userId);
    await this.put<void>(
      `/profile/${encodedUserId}/displayname`,
      { "displayname": displayName }
    );
  }

  async getAvatarUrl(userId: string): Promise<string | null> {
    const encodedUserId = encodeURIComponent(userId);
    const response = await this.get<GeneratedTypeLiteralInterface_2>(
      `/profile/${encodedUserId}/avatar_url`
    );
    return response.avatar_url ?? null;
  }

  async setAvatarUrl(userId: string, avatarUrl: string): Promise<void> {
    const encodedUserId = encodeURIComponent(userId);
    await this.put<void>(
      `/profile/${encodedUserId}/avatar_url`,
      { "avatar_url": avatarUrl }
    );
  }

  async getPushRules(): Promise<PushRules> {
    return await this.get<PushRules>('/pushrules');
  }

  async getPushRule(scope: string, kind: string, ruleId: string): Promise<PushRule> {
    const encodedScope = encodeURIComponent(scope);
    const encodedKind = encodeURIComponent(kind);
    const encodedRuleId = encodeURIComponent(ruleId);
    return await this.get<PushRule>(
      `/pushrules/${encodedScope}/${encodedKind}/${encodedRuleId}`
    );
  }

  async setPushRule(
    scope: string,
    kind: string,
    ruleId: string,
    rule: Partial<PushRule>
  ): Promise<void> {
    const encodedScope = encodeURIComponent(scope);
    const encodedKind = encodeURIComponent(kind);
    const encodedRuleId = encodeURIComponent(ruleId);
    await this.put<void>(
      `/pushrules/${encodedScope}/${encodedKind}/${encodedRuleId}`,
      rule as Record<string, string | object>
    );
  }

  async deletePushRule(scope: string, kind: string, ruleId: string): Promise<void> {
    const encodedScope = encodeURIComponent(scope);
    const encodedKind = encodeURIComponent(kind);
    const encodedRuleId = encodeURIComponent(ruleId);
    await this.delete<void>(
      `/pushrules/${encodedScope}/${encodedKind}/${encodedRuleId}`
    );
  }

  async setPushRuleActions(
    scope: string,
    kind: string,
    ruleId: string,
    actions: PushRuleAction[]
  ): Promise<void> {
    const encodedScope = encodeURIComponent(scope);
    const encodedKind = encodeURIComponent(kind);
    const encodedRuleId = encodeURIComponent(ruleId);
    await this.post<void>(
      `/pushrules/${encodedScope}/${encodedKind}/${encodedRuleId}/actions`,
      { "actions": actions }
    );
  }

  async getNotifications(limit?: number, since?: string, only?: string): Promise<NotificationsResponse> {
    const queryParams: Record<string, string | number> = {};
    if (limit !== undefined) {
      queryParams['limit'] = limit;
    }
    if (since !== undefined) {
      queryParams['since'] = since;
    }
    if (only !== undefined) {
      queryParams['only'] = only;
    }
    return await this.get<NotificationsResponse>('/notifications', queryParams);
  }

  async setNotificationMarker(request: SetNotificationMarkerRequest): Promise<void> {
    await this.post<void>('/notifications', request as Record<string, string | object>);
  }

  async getRoomTags(userId: string, roomId: string): Promise<RoomTags> {
    const encodedUserId = encodeURIComponent(userId);
    const encodedRoomId = encodeURIComponent(roomId);
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
    const encodedUserId = encodeURIComponent(userId);
    const encodedRoomId = encodeURIComponent(roomId);
    const encodedTag = encodeURIComponent(tag);
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
    const encodedUserId = encodeURIComponent(userId);
    const encodedRoomId = encodeURIComponent(roomId);
    const encodedTag = encodeURIComponent(tag);
    await this.delete<void>(
      `/user/${encodedUserId}/rooms/${encodedRoomId}/tags/${encodedTag}`
    );
  }
}
