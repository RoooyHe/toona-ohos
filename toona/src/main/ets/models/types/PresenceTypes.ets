export type PresenceState = 'online' | 'offline' | 'unavailable';

export interface PresenceContent {
  presence?: string;
  status_msg?: string;
  last_active_ago?: number;
  currently_active?: boolean;
  os?: string;
  avatar_url?: string;
  displayname?: string;
}

export interface GetPresenceResponse extends PresenceContent {
  presence: PresenceState;
}

export interface SetPresenceRequest {
  presence: PresenceState;
  status_msg?: string;
}

export interface PresenceListRequest {
  nodes: string[];
}

interface GeneratedTypeLiteralInterface_1 {
  user_id: string;
  presence: PresenceState;
  last_active_ago?: number;
  status_msg?: string;
}

export interface PresenceListResponse {
  aggregated_users: Array<GeneratedTypeLiteralInterface_1>;
}