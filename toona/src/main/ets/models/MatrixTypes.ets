export interface MatrixError {
  errcode: string;
  error: string;
  retry_after_ms?: number;
  soft_logout?: boolean;
}

export interface MatrixResponse {
  errcode?: string;
  error?: string;
}

interface GeneratedTypeLiteralInterface_1 {
  type: string;
  user?: string;
  medium?: string;
  address?: string;
}

export interface LoginRequest {
  identifier: GeneratedTypeLiteralInterface_1;
  password: string;
  device_id?: string;
  initial_device_display_name?: string;
}

interface GeneratedTypeLiteralInterface_3 {
  base_url: string;
}

interface GeneratedTypeLiteralInterface_2 {
  'm.homeserver'?: GeneratedTypeLiteralInterface_3;
}

export interface LoginResponse {
  user_id: string;
  access_token: string;
  home_server: string;
  device_id: string;
  well_known?: GeneratedTypeLiteralInterface_2;
}

interface GeneratedTypeLiteralInterface_4 {
  session?: string;
  flows?: AuthenticationFlow[];
}

export interface RegisterRequest {
  username: string;
  password: string;
  device_id?: string;
  initial_device_display_name?: string;
  auth?: GeneratedTypeLiteralInterface_4;
}

export interface RegisterResponse {
  user_id: string;
  access_token: string;
  device_id: string;
  home_server: string;
  session?: string;
}

export interface AuthenticationFlow {
  stages: string[];
}

export interface WhoAmIResponse {
  user_id: string;
  device_id: string;
  is_guest: boolean;
  rooms: Map<string, number>;
  successors: string[];
}

export interface ProfileInfo {
  displayname?: string;
  avatar_url?: string;
}

export interface SyncRequest {
  filter?: string;
  since?: string;
  timeout?: number;
  full_state?: boolean;
  set_presence?: string;
  room_event_certificate?: string;
}

interface GeneratedTypeLiteralInterface_5 {
  join?: Record<string, RoomState>;
  invite?: Record<string, InvitedRoom>;
  leave?: Record<string, LeftRoom>;
}

interface GeneratedTypeLiteralInterface_6 {
  events: PresEvent[];
}

interface GeneratedTypeLiteralInterface_7 {
  events: Event[];
}

interface GeneratedTypeLiteralInterface_8 {
  events: Event[];
}

interface GeneratedTypeLiteralInterface_9 {
  changed: string[];
  left: string[];
}

export interface SyncResponse {
  next_batch: string;
  rooms?: GeneratedTypeLiteralInterface_5;
  presence?: GeneratedTypeLiteralInterface_6;
  account_data?: GeneratedTypeLiteralInterface_7;
  to_device?: GeneratedTypeLiteralInterface_8;
  device_lists?: GeneratedTypeLiteralInterface_9;
  device_one_time_keys_count?: Record<string, number>;
  device_unused_fallback_key_types?: string[];
  rate_limited?: boolean;
  required_user_agent?: string;
}

interface GeneratedTypeLiteralInterface_10 {
  events: Event[];
}

interface GeneratedTypeLiteralInterface_11 {
  events: Event[];
  limited?: boolean;
  prev_batch?: string;
}

interface GeneratedTypeLiteralInterface_12 {
  events: Event[];
}

interface GeneratedTypeLiteralInterface_13 {
  events: Event[];
}

export interface RoomState {
  state: GeneratedTypeLiteralInterface_10;
  timeline: GeneratedTypeLiteralInterface_11;
  ephemeral?: GeneratedTypeLiteralInterface_12;
  account_data?: GeneratedTypeLiteralInterface_13;
  unread_notifications?: UnreadNotifications;
  summary?: RoomSummary;
}

interface GeneratedTypeLiteralInterface_14 {
  events: Event[];
}

export interface InvitedRoom {
  invite_state: GeneratedTypeLiteralInterface_14;
}

interface GeneratedTypeLiteralInterface_15 {
  events: Event[];
}

interface GeneratedTypeLiteralInterface_16 {
  events: Event[];
}

export interface LeftRoom {
  state: GeneratedTypeLiteralInterface_15;
  timeline: GeneratedTypeLiteralInterface_16;
}

export interface UnreadNotifications {
  highlight_count?: number;
  notification_count?: number;
  full_screen_notification_types?: string[];
}

interface GeneratedTypeLiteralInterface_17 {
  custom?: Record<string, number>;
}

export interface RoomSummary {
  heroes?: string[];
  invited_member_count?: number;
  joined_member_count?: number;
  metadata?: GeneratedTypeLiteralInterface_17;
}

interface GeneratedTypeLiteralInterface_18 {
  age?: number;
  redact_reason?: string;
  transaction_id?: string;
  prev_content?: Record<string, string | object>;
}

interface GeneratedTypeLiteralInterface_19 {
  sha256: string;
}

export interface Event {
  type: string;
  event_id?: string;
  sender?: string;
  origin_server_ts?: number;
  state_key?: string;
  content: Record<string, string | object>;
  unsigned?: GeneratedTypeLiteralInterface_18;
  room_id?: string;
  membership?: string;
  prev_events?: [string, Event][];
  auth_events?: [string, Event][];
  depth?: number;
  hashes?: GeneratedTypeLiteralInterface_19;
  signatures?: Record<string, Record<string, string>>;
  destination?: string;
  origin?: string;
  moves?: EventMove[];
}

export interface EventMove {
  event_id: string;
  ts: number;
  new_room_id: string;
}

interface GeneratedTypeLiteralInterface_20 {
  presence?: string;
  status_msg?: string;
  last_active_ago?: number;
  currently_active?: boolean;
  os?: string;
  avatar_url?: string;
  displayname?: string;
}

export interface PresEvent {
  type: string;
  sender: string;
  content: GeneratedTypeLiteralInterface_20;
}

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
  unreadCount?: number;
  highlightCount?: number;
  lastEvent?: Event;
  lastEventTime?: number;
}

interface GeneratedTypeLiteralInterface_21 {
  type: string;
  state_key?: string;
  content: Record<string, string | object>;
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
  initial_state?: GeneratedTypeLiteralInterface_21[];
  power_level_content_override?: Record<string, string | object>;
}

export interface Invite3pid {
  id_server: string;
  id_access_token?: string;
  medium: string;
  address: string;
}

export interface MessageEventContent {
  msgtype?: string;
  body: string;
  format?: string;
  formatted_body?: string;
  geo_uri?: string;
  info?: MessageInfo;
  url?: string;
  file?: EncryptedFile;
  keys?: EncryptionKeys;
  caption?: string;
  mentions?: Mentions;
}

export interface MessageInfo {
  mimetype?: string;
  size?: number;
  duration?: number;
  width?: number;
  height?: number;
  thumbnail_url?: string;
  thumbnail_file?: EncryptedFile;
  thumbnail_info?: MessageInfo;
  orientation?: number;
  'xyz.amorgan.blurhash'?: string;
}

interface GeneratedTypeLiteralInterface_22 {
  alg: string;
  key: string;
  key_id: string;
  v?: string;
}

export interface EncryptedFile {
  url?: string;
  key?: GeneratedTypeLiteralInterface_22;
  iv?: string;
  hashes?: Record<string, string>;
  file?: string;
}

export interface EncryptionKeys {
  k: string;
  key: string;
}

export interface Mentions {
  user_ids?: string[];
  room_id?: string;
}

export interface TextMessageContent extends MessageEventContent {
  msgtype: 'm.text';
  body: string;
  format?: string;
  formatted_body?: string;
  mentions?: Mentions;
}

export interface EmoteMessageContent extends MessageEventContent {
  msgtype: 'm.emote';
  body: string;
}

export interface NoticeMessageContent extends MessageEventContent {
  msgtype: 'm.notice';
  body: string;
}

export interface ImageMessageContent extends MessageEventContent {
  msgtype: 'm.image';
  url?: string;
  file?: EncryptedFile;
  info?: MessageInfo;
  body: string;
}

export interface AudioMessageContent extends MessageEventContent {
  msgtype: 'm.audio';
  url?: string;
  file?: EncryptedFile;
  info?: MessageInfo;
  body: string;
}

export interface VideoMessageContent extends MessageEventContent {
  msgtype: 'm.video';
  url?: string;
  file?: EncryptedFile;
  info?: MessageInfo;
  body: string;
}

export interface LocationMessageContent extends MessageEventContent {
  msgtype: 'm.location';
  geo_uri: string;
  info?: MessageInfo;
  body: string;
}

export interface FileMessageContent extends MessageEventContent {
  msgtype: 'm.file';
  url?: string;
  file?: EncryptedFile;
  info?: MessageInfo;
  body: string;
}

export interface RoomMemberContent {
  displayname?: string;
  avatar_url?: string;
  membership?: string;
  is_direct?: boolean;
  reason?: string;
}

export interface User {
  userId: string;
  displayName?: string;
  avatarUrl?: string;
  presence?: string;
  lastActiveAgo?: number;
  currentlyActive?: boolean;
  statusMsg?: string;
}

export interface Message {
  eventId: string;
  roomId: string;
  sender: string;
  type: string;
  content: MessageEventContent;
  timestamp: number;
  isOutgoing: boolean;
  status: MessageStatus;
  replyEventId?: string;
  editedEventId?: string;
}

export enum MessageStatus {
  SENDING = 'sending',
  SENT = 'sent',
  FAILED = 'failed',
  DECRYPTING = 'decrypting',
  PLACEHOLDER = 'placeholder'
}

export interface SendMessageResult {
  event_id: string;
  wire_event_id?: string;
}

export interface RoomMessagesResponse {
  chunk: Event[];
  start: string;
  end?: string;
  state?: Event[];
}

interface GeneratedTypeLiteralInterface_23 {
  user_id: string;
  display_name?: string;
  avatar_url?: string;
}

export interface JoinedMembersResponse {
  joined_members: GeneratedTypeLiteralInterface_23[];
}

export interface RoomCreateResponse {
  room_id: string;
  room_alias?: string;
}

export interface JoinedRoomsResponse {
  joined_rooms: string[];
}

export interface DirectoryRoomResponse {
  room_id: string;
  servers: string[];
}

export interface TurnServerResponse {
  uris: string[];
  username?: string;
  password?: string;
  ttl?: number;
}

export interface VersionsResponse {
  versions: string[];
  unstable_features?: Record<string, boolean>;
}
