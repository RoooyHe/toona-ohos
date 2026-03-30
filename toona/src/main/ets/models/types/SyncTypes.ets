import { Event } from './CoreTypes';
import { RoomSummary, UnreadNotifications } from './RoomTypes';
import { PresenceContent } from './PresenceTypes';

export { Event, RoomSummary, UnreadNotifications, PresenceContent };

export interface SyncRequest {
  filter?: string;
  since?: string;
  timeout?: number;
  full_state?: boolean;
  set_presence?: string;
  room_event_certificate?: string;
}

export interface SyncResponse {
  next_batch: string;
  rooms?: SyncRooms;
  presence?: PresenceEvents;
  account_data?: AccountDataEvents;
  to_device?: ToDeviceEvents;
  device_lists?: DeviceListChanges;
  device_one_time_keys_count?: Record<string, number>;
  device_unused_fallback_key_types?: string[];
  rate_limited?: boolean;
  required_user_agent?: string;
}

export interface RoomStateEvents {
  events: Event[];
}

export interface TimelineEvents {
  events: Event[];
  limited?: boolean;
  prev_batch?: string;
}

export interface EphemeralEvents {
  events: Event[];
}

export interface AccountDataEvents {
  events: Event[];
}

export interface SyncRooms {
  join?: Record<string, RoomState>;
  invite?: Record<string, InvitedRoom>;
  leave?: Record<string, LeftRoom>;
}

export interface InviteState {
  events: Event[];
}

export interface InvitedRoom {
  invite_state: InviteState;
}

export interface LeftRoomState {
  events: Event[];
}

export interface LeftRoomTimeline {
  events: Event[];
}

export interface LeftRoom {
  state: LeftRoomState;
  timeline: LeftRoomTimeline;
}

export interface PresenceEvents {
  events: PresEvent[];
}

export interface ToDeviceEvents {
  events: Event[];
}

export interface DeviceListChanges {
  changed: string[];
  left: string[];
}

export interface PresEvent {
  type: string;
  sender: string;
  content: PresenceContent;
}

export interface RoomState {
  state: RoomStateEvents;
  timeline: TimelineEvents;
  ephemeral?: EphemeralEvents;
  account_data?: AccountDataEvents;
  unread_notifications?: UnreadNotifications;
  summary?: RoomSummary;
}