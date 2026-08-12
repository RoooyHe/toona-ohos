import {
  PushRules,
  PushRule,
  PushRuleAction,
  NotificationsResponse,
  SetNotificationMarkerRequest
} from '../../models/MatrixTypes';
import { BaseHttpClient } from './BaseHttpClient';

export class PushHttpClient extends BaseHttpClient {
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
}
