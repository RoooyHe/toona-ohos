export interface User {
  userId: string;
  displayName?: string;
  avatarUrl?: string;
  presence?: string;
  lastActiveAgo?: number;
  currentlyActive?: boolean;
  statusMsg?: string;
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