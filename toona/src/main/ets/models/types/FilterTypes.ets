export type FilterFormat = 'event' | 'event_id_only' | 'compact';

export interface RoomFilter {
  limit?: number;
  unread_notifications?: string;
  rooms?: string[];
  not_rooms?: string[];
  types?: string[];
  not_types?: string[];
  senders?: string[];
  not_senders?: string[];
  contains_url?: boolean;
  "org.matrix.nick"?: string;
}

export interface RoomEventFilter extends RoomFilter {
  rooms?: string[];
  not_rooms?: string[];
  types?: string[];
  not_types?: string[];
  senders?: string[];
  not_senders?: string[];
  contains_url?: boolean;
  "org.matrix.nick"?: string;
}

export interface StateFilter extends RoomFilter {
  lazy_load_members?: boolean;
  include_redundant_members?: boolean;
  unread_thread_notifications?: boolean;
}

export interface TimelineFilter extends RoomFilter {
  lazy_load_members?: boolean;
  include_redundant_members?: boolean;
  unread_thread_notifications?: boolean;
}

export interface RoomEventFilterResult {
  state?: StateFilter;
  timeline?: TimelineFilter;
  ephemeral?: RoomFilter;
  account_data?: RoomFilter;
  to_device?: RoomFilter;
  lists?: Record<string, RoomFilter>;
}

export interface FilterFields {
  event_fields?: string[];
  event_format?: FilterFormat;
  presence?: RoomFilter;
  room?: RoomEventFilterResult;
}

export interface Filter {
  filter_id?: string;
  user_id?: string;
  filter?: FilterFields;
  room?: RoomEventFilterResult;
  presence?: RoomFilter;
}

export interface CreateFilterResponse {
  filter_id: string;
}

export interface GetFilterResponse {
  filter_id: string;
  user_id?: string;
  filter?: FilterFields;
  room?: RoomEventFilterResult;
  presence?: RoomFilter;
}

export type PresenceFilter = RoomFilter;
export type RoomFilterPart = RoomEventFilterResult;