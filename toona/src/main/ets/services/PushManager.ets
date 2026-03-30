import { MatrixHttpClient, MatrixConfig } from '../network/MatrixHttpClient';
import {
  PushRules,
  PushRule,
  PushRuleAction,
  PushRuleKind,
  PushRuleScope,
  NotificationsResponse,
  SetNotificationMarkerRequest
} from '../models/MatrixTypes';

export class PushManager {
  private static instance: PushManager;
  private httpClient: MatrixHttpClient | null = null;

  private constructor() {
  }

  static getInstance(): PushManager {
    if (!PushManager.instance) {
      PushManager.instance = new PushManager();
    }
    return PushManager.instance;
  }

  setHomeserver(homeserverUrl: string): void {
    MatrixConfig.getInstance().setHomeserver(homeserverUrl);
    this.httpClient = MatrixConfig.getInstance().getHttpClient();
  }

  private ensureHttpClient(): MatrixHttpClient {
    if (!this.httpClient) {
      throw new Error('PushManager not initialized. Call setHomeserver first.');
    }
    return this.httpClient;
  }

  async getPushRules(): Promise<PushRules> {
    try {
      return await this.ensureHttpClient().getPushRules();
    } catch (error) {
      console.error('Failed to get push rules:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get push rules: ${errMsg}`);
    }
  }

  async getPushRule(scope: PushRuleScope, kind: PushRuleKind, ruleId: string): Promise<PushRule> {
    try {
      return await this.ensureHttpClient().getPushRule(scope, kind, ruleId);
    } catch (error) {
      console.error('Failed to get push rule:', error);
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
      await this.ensureHttpClient().setPushRule(scope, kind, ruleId, rule);
    } catch (error) {
      console.error('Failed to add push rule:', error);
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
      await this.ensureHttpClient().setPushRule(scope, kind, ruleId, rule);
    } catch (error) {
      console.error('Failed to update push rule:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to update push rule: ${errMsg}`);
    }
  }

  async deletePushRule(scope: PushRuleScope, kind: PushRuleKind, ruleId: string): Promise<void> {
    try {
      await this.ensureHttpClient().deletePushRule(scope, kind, ruleId);
    } catch (error) {
      console.error('Failed to delete push rule:', error);
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
      await this.ensureHttpClient().setPushRuleActions(scope, kind, ruleId, actions);
    } catch (error) {
      console.error('Failed to set push rule actions:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to set push rule actions: ${errMsg}`);
    }
  }

  async getNotifications(limit?: number, since?: string): Promise<NotificationsResponse> {
    try {
      return await this.ensureHttpClient().getNotifications(limit, since);
    } catch (error) {
      console.error('Failed to get notifications:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get notifications: ${errMsg}`);
    }
  }

  async setNotificationMarker(notificationKey: string): Promise<void> {
    try {
      const request: SetNotificationMarkerRequest = { notification_key: notificationKey };
      await this.ensureHttpClient().setNotificationMarker(request);
    } catch (error) {
      console.error('Failed to set notification marker:', error);
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