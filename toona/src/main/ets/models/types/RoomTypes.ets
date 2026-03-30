import { Event, InitialStateEvent } from './CoreTypes';

export { Event, InitialStateEvent };

export interface Room {
  id: string;
  name?: string;
  displayName?: string;
  topic?: string;
  avatarUrl?: string;
  memberCount?: number;
  joinedMembers?: string[];
  myMembership?: string;
  isDirect?: boolean;
  isSpace?: boolean;
  unreadCount?: number;
  highlightCount?: number;
  lastEvent?: Event;
  lastEventTime?: number;
}

export interface RoomMetadata {
  custom?: Record<string, number>;
}

export interface RoomSummary {
  heroes?: string[];
  invited_member_count?: number;
  joined_member_count?: number;
  metadata?: RoomMetadata;
}

export interface UnreadNotifications {
  notification_count?: number;
  highlight_count?: number;
  unread_count?: number;
}

export interface RoomMemberContent {
  displayname?: string;
  avatar_url?: string;
  membership?: string;
  is_direct?: boolean;
  reason?: string;
}

export interface RoomCreateContent {
  creator?: string;
  room_version?: string;
  federate?: boolean;
  is_direct?: boolean;
  preset?: string;
  name?: string;
  topic?: string;
  invite?: string[];
  invite_3pid?: Invite3pid[];
  room_alias_name?: string;
  initial_state?: InitialStateEvent[];
  power_level_content_override?: Record<string, string | object>;
}

export interface Invite3pid {
  id_server: string;
  id_access_token?: string;
  medium: string;
  address: string;
}

export interface ParsedRoomState {
  roomId: string;
  name?: string;
  topic?: string;
  avatarUrl?: string;
  canonicalAlias?: string;
  joinRule?: string;
  historyVisibility?: string;
  createTime?: number;
  creator?: string;
  isSpace?: boolean;
  memberCount?: number;
}

export interface RoomMessagesResponse {
  chunk: Event[];
  start: string;
  end?: string;
  state?: Event[];
}

export interface RoomMemberInfo {
  user_id: string;
  display_name?: string;
  avatar_url?: string;
}

export interface JoinedMembersResponse {
  joined_members: RoomMemberInfo[];
}

export interface RoomCreateResponse {
  events: Event[];
  room_id: string;
  room_alias?: string;
}

export interface JoinedRoomsResponse {
  joined_rooms: string[];
}

export interface TypingContent {
  typing: boolean;
  timeout?: number;
}

export interface ReceiptContent {
  thread_id?: string;
}

export interface TypingUsersResponse {
  user_ids: string[];
}