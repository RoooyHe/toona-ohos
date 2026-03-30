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

export interface VersionsResponse {
  versions: string[];
  unstable_features?: Record<string, boolean>;
}

export interface WellKnownInfo {
  'm.homeserver'?: HomeServerInfo;
}

export interface HomeServerInfo {
  base_url: string;
}

export interface EventUnsigned {
  age?: number;
  redact_reason?: string;
  transaction_id?: string;
  prev_content?: Record<string, string | object>;
}

export interface EventHashes {
  sha256: string;
}

export interface EventMove {
  event_id: string;
  ts: number;
  new_room_id: string;
}

export interface Event {
  type: string;
  event_id?: string;
  sender?: string;
  origin_server_ts?: number;
  state_key?: string;
  content: Record<string, string | object>;
  unsigned?: EventUnsigned;
  room_id?: string;
  membership?: string;
  prev_events?: [string, Event][];
  auth_events?: [string, Event][];
  depth?: number;
  hashes?: EventHashes;
  signatures?: Record<string, Record<string, string>>;
  destination?: string;
  origin?: string;
  moves?: EventMove[];
  redacts?: string;
}

export interface InitialStateEvent {
  type: string;
  state_key?: string;
  content: Record<string, string | object>;
}

export interface SendMessageResult {
  event_id: string;
  wire_event_id?: string;
}