import { AppLogger } from '../utils/AppLogger';
import {
  PushRules,
  PushRule,
  PushRuleAction,
  PushRuleKind,
  PushRuleScope,
  NotificationsResponse,
  SetNotificationMarkerRequest
} from '../models/MatrixTypes';
import { BaseHttpClient } from '../network/clients/BaseHttpClient';

export interface IPushManager {
  getPushRules(): Promise<PushRules>;
}

export class PushManager implements IPushManager {
  private baseClient: BaseHttpClient;
  private logger = AppLogger.getLogger(PushManager);

  constructor(baseClient: BaseHttpClient) {
    this.baseClient = baseClient;
  }

  async getPushRules(): Promise<PushRules> {
    try {
      return await this.baseClient.get<PushRules>('/pushrules');
    } catch (error) {
      this.logger.error('Failed to get push rules:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get push rules: ${errMsg}`);
    }
  }

  async getPushRule(scope: PushRuleScope, kind: PushRuleKind, ruleId: string): Promise<PushRule> {
    try {
      const encoded = this.baseClient.encodePath(scope, kind, ruleId);
      return await this.baseClient.get<PushRule>(`/pushrules/${encoded}`);
    } catch (error) {
      this.logger.error('Failed to get push rule:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get push rule: ${errMsg}`);
    }
  }

  async addPushRule(
    scope: PushRuleScope,
    kind: PushRuleKind,
    ruleId: string,
    rule: Partial<PushRule>
  ): Promise<void> {
    try {
      const encoded = this.baseClient.encodePath(scope, kind, ruleId);
      await this.baseClient.put<void>(
        `/pushrules/${encoded}`,
        rule as Record<string, string | object>
      );
    } catch (error) {
      this.logger.error('Failed to add push rule:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to add push rule: ${errMsg}`);
    }
  }

  async updatePushRule(
    scope: PushRuleScope,
    kind: PushRuleKind,
    ruleId: string,
    rule: Partial<PushRule>
  ): Promise<void> {
    try {
      const encoded = this.baseClient.encodePath(scope, kind, ruleId);
      await this.baseClient.put<void>(
        `/pushrules/${encoded}`,
        rule as Record<string, string | object>
      );
    } catch (error) {
      this.logger.error('Failed to update push rule:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to update push rule: ${errMsg}`);
    }
  }

  async deletePushRule(scope: PushRuleScope, kind: PushRuleKind, ruleId: string): Promise<void> {
    try {
      const encoded = this.baseClient.encodePath(scope, kind, ruleId);
      await this.baseClient.delete<void>(`/pushrules/${encoded}`);
    } catch (error) {
      this.logger.error('Failed to delete push rule:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to delete push rule: ${errMsg}`);
    }
  }

  async setPushRuleActions(
    scope: PushRuleScope,
    kind: PushRuleKind,
    ruleId: string,
    actions: PushRuleAction[]
  ): Promise<void> {
    try {
      const encoded = this.baseClient.encodePath(scope, kind, ruleId);
      await this.baseClient.post<void>(
        `/pushrules/${encoded}/actions`,
        { "actions": actions }
      );
    } catch (error) {
      this.logger.error('Failed to set push rule actions:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to set push rule actions: ${errMsg}`);
    }
  }

  async getNotifications(limit?: number, since?: string): Promise<NotificationsResponse> {
    try {
      const queryParams = this.baseClient.buildQueryParams({
        'limit': limit,
        'since': since
      });
      return await this.baseClient.get<NotificationsResponse>('/notifications', queryParams);
    } catch (error) {
      this.logger.error('Failed to get notifications:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get notifications: ${errMsg}`);
    }
  }

  async setNotificationMarker(notificationKey: string): Promise<void> {
    try {
      const request: SetNotificationMarkerRequest = { notification_key: notificationKey };
      await this.baseClient.post<void>('/notifications', request as Record<string, string | object>);
    } catch (error) {
      this.logger.error('Failed to set notification marker:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to set notification marker: ${errMsg}`);
    }
  }

  async addContentRule(
    scope: PushRuleScope,
    ruleId: string,
    pattern: string,
    actions: PushRuleAction[],
    enabled: boolean = true
  ): Promise<void> {
    const rule: Partial<PushRule> = {
      pattern: pattern,
      actions: actions,
      enabled: enabled
    };
    await this.addPushRule(scope, 'content', ruleId, rule);
  }

  async addSenderRule(
    scope: PushRuleScope,
    ruleId: string,
    sender: string,
    actions: PushRuleAction[],
    enabled: boolean = true
  ): Promise<void> {
    const rule: Partial<PushRule> = {
      conditions: [{ kind: 'sender_notification_permission', key: sender }],
      actions: actions,
      enabled: enabled
    };
    await this.addPushRule(scope, 'sender', ruleId, rule);
  }

  async addRoomRule(
    scope: PushRuleScope,
    ruleId: string,
    roomId: string,
    actions: PushRuleAction[],
    enabled: boolean = true
  ): Promise<void> {
    const rule: Partial<PushRule> = {
      conditions: [{ kind: 'room_member_count', is: roomId }],
      actions: actions,
      enabled: enabled
    };
    await this.addPushRule(scope, 'room', ruleId, rule);
  }

  async disablePushRule(scope: PushRuleScope, kind: PushRuleKind, ruleId: string): Promise<void> {
    await this.updatePushRule(scope, kind, ruleId, { enabled: false });
  }

  async enablePushRule(scope: PushRuleScope, kind: PushRuleKind, ruleId: string): Promise<void> {
    await this.updatePushRule(scope, kind, ruleId, { enabled: true });
  }

  async muteRoom(roomId: string): Promise<void> {
    await this.updatePushRule('global', 'room', roomId, { actions: ['dont_notify'] });
  }

  async unmuteRoom(roomId: string): Promise<void> {
    await this.updatePushRule('global', 'room', roomId, { actions: ['notify'] });
  }
}
