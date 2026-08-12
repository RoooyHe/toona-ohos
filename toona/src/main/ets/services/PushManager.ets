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
import { PushHttpClient } from '../network/clients/PushHttpClient';

export class PushManager {
  private pushHttpClient: PushHttpClient;
  private logger = AppLogger.getLogger(PushManager);

  constructor(pushHttpClient: PushHttpClient) {
    this.pushHttpClient = pushHttpClient;
  }

  async getPushRules(): Promise<PushRules> {
    try {
      return await this.pushHttpClient.getPushRules();
    } catch (error) {
      this.logger.error('Failed to get push rules:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get push rules: ${errMsg}`);
    }
  }

  async getPushRule(scope: PushRuleScope, kind: PushRuleKind, ruleId: string): Promise<PushRule> {
    try {
      return await this.pushHttpClient.getPushRule(scope, kind, ruleId);
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
      await this.pushHttpClient.setPushRule(scope, kind, ruleId, rule);
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
      await this.pushHttpClient.setPushRule(scope, kind, ruleId, rule);
    } catch (error) {
      this.logger.error('Failed to update push rule:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to update push rule: ${errMsg}`);
    }
  }

  async deletePushRule(scope: PushRuleScope, kind: PushRuleKind, ruleId: string): Promise<void> {
    try {
      await this.pushHttpClient.deletePushRule(scope, kind, ruleId);
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
      await this.pushHttpClient.setPushRuleActions(scope, kind, ruleId, actions);
    } catch (error) {
      this.logger.error('Failed to set push rule actions:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to set push rule actions: ${errMsg}`);
    }
  }

  async getNotifications(limit?: number, since?: string): Promise<NotificationsResponse> {
    try {
      return await this.pushHttpClient.getNotifications(limit, since);
    } catch (error) {
      this.logger.error('Failed to get notifications:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get notifications: ${errMsg}`);
    }
  }

  async setNotificationMarker(notificationKey: string): Promise<void> {
    try {
      const request: SetNotificationMarkerRequest = { notification_key: notificationKey };
      await this.pushHttpClient.setNotificationMarker(request);
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
