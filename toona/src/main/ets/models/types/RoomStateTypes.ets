export interface RoomAvatarContentInfo {
  mimetype?: string;
  size?: number;
  width?: number;
  height?: number;
}

export interface RoomAvatarContent {
  url: string;
  info?: RoomAvatarContentInfo;
}

export interface CanonicalAliasContent {
  alias: string;
}

export interface RoomAliasesContent {
  aliases: string[];
}

export interface RoomDirectoryResponse {
  room_id: string;
  room_alias?: string;
  servers?: string[];
}

export interface PublicRoomsResponse {
  chunk: PublicRoom[];
  next_batch?: string;
  prev_batch?: string;
  total_room_count_estimate?: number;
}

export interface PublicRoom {
  room_id: string;
  name?: string;
  topic?: string;
  avatar_url?: string;
  join_rule?: string;
  guest_access?: string;
  world_readable?: boolean;
  num_joined_members?: number;
}

interface GeneratedTypeLiteralInterface_2 {
  room_id: string;
  user_id: string;
  display_name?: string;
  avatar_url?: string;
}

export interface RoomMembersResponse {
  members: Array<GeneratedTypeLiteralInterface_2>;
  start: string;
  end: string;
}

export interface SetReadMarkersRequest {
  unread_notifications?: Record<string, string | object>;
  fully_read?: string;
  highlighted?: string;
}
