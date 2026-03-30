import { Event } from './CoreTypes';

export { Event };

export type PushRuleKind = 'container' | 'room' | 'sender' | 'content' | 'underride';

export type PushRuleScope = 'global' | 'device';

export type PushRuleAction = 'notify' | 'dont_notify' | 'coalesce' | 'set_default' | 'unset_default';

export interface PushRuleCondition {
  kind: 'device_used' | 'device_is_specific' | 'room_member_count' | 'sender_notification_permission' | 'contains_display_name';
  key?: string;
  pattern?: string;
  is?: string;
  min_member_count?: number;
}

export interface PushRule {
  rule_id: string;
  priority: number;
  conditions?: PushRuleCondition[];
  actions: PushRuleAction[];
  pattern?: string;
  reactive?: boolean;
  default?: boolean;
  enabled: boolean;
}

export interface PushRules {
  global?: PushRuleset;
  device?: PushRuleset;
}

export interface PushRuleset {
  container?: PushRule[];
  override?: PushRule[];
  room?: PushRule[];
  sender?: PushRule[];
  content?: PushRule[];
  underride?: PushRule[];
}

export interface NotificationData {
  room_id: string;
  event_id: string;
  type: string;
  sender: string;
  sender_display_name?: string;
  room_name?: string;
  room_alias?: string;
  prio: 'low' | 'medium' | 'high';
  readout_count?: number;
  ts: number;
  event: Event;
}

export interface NotificationsResponse {
  notifications: NotificationData[];
  next_token?: string;
}

export interface TagContent {
  order?: number;
}

export interface RoomTags {
  tags: Record<string, TagContent>;
}

export interface RoomTag {
  tag: string;
  content: TagContent;
}

export interface SetNotificationMarkerRequest {
  notification_key?: string;
  room_id?: string;
  event_id?: string;
}