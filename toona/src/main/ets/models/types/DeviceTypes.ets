export interface Device {
  device_id: string;
  display_name?: string;
  last_seen_ip?: string;
  last_seen_ts?: number;
  session_id?: string;
}

export interface DevicesResponse {
  devices: Device[];
}

export interface UpdateDeviceRequest {
  display_name?: string;
}

export interface DeviceKeyInfo {
  user_id: string;
  device_id: string;
  algorithms?: string[];
  keys?: Record<string, string>;
  signatures?: Record<string, Record<string, string>>;
}

export interface QueryKeysRequest {
  device_keys?: Record<string, string[]>;
  timeout?: number;
}

export interface QueryKeysResponse {
  device_keys?: Record<string, Record<string, DeviceKeyInfo>>;
  failures?: Record<string, string>;
}

export interface UploadKeysRequest {
  device_keys?: DeviceKeyInfo;
  one_time_keys?: Record<string, string>;
  fallback_keys?: Record<string, string>;
}

export interface UploadKeysResponse {
  one_time_key_counts?: Record<string, number>;
  fallback_key_counts?: Record<string, number>;
}

export interface ClaimKeysRequest {
  one_time_keys?: Record<string, Record<string, string>>;
  timeout?: number;
}

export interface ClaimKeysResponse {
  one_time_keys?: Record<string, Record<string, Record<string, string>>>;
  failures?: Record<string, string>;
}

export interface RoomKeyInfo {
  session_id: string;
  room_id: string;
  algorithm: string;
  sender_key?: string;
  forwarding_curve25519_key_chain?: string[];
  sender_claimed_keys?: Record<string, string>;
  shared?: boolean;
  room_key?: Record<string, string | object>;
}

export interface QueryRoomKeysRequest {
  rooms?: string[];
  session_ids?: string[];
}

export interface QueryRoomKeysResponse {
  rooms?: Record<string, Record<string, RoomKeyInfo>>;
}

export interface UploadRoomKeysRequest {
  rooms?: Record<string, RoomKeyInfo[]>;
}

export type UploadRoomKeysRoomsData = Record<string, RoomKeyInfo[]>;

export interface UploadRoomKeysResponse {
  count?: number;
}

export interface KeyBackupVersion {
  version: string;
  algorithm?: string;
  auth_data?: Record<string, string | object>;
}

export interface KeyBackupSessionData {
  first_message_index?: number;
  forwarded_count?: number;
  is_verified?: boolean;
  room_id?: string;
  session_id?: string;
  data?: Record<string, string | object>;
}

export interface SignatureRequest {
  device_keys?: DeviceKeyInfo;
  tx_hash?: string;
}

export interface SignatureResponse {
  signatures?: Record<string, Record<string, string>>;
  failures?: Record<string, string>;
}