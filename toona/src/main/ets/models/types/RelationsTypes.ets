import {
  Event,
  RoomState,
  RoomStateEvents,
  TimelineEvents,
  EphemeralEvents,
  AccountDataEvents,
  PresenceEvents,
  PresenceContent,
  PresEvent
} from './SyncTypes';
import { RoomSummary, UnreadNotifications } from './RoomTypes';

export { Event,
  RoomState,
  RoomStateEvents,
  TimelineEvents,
  EphemeralEvents,
  AccountDataEvents,
  PresenceEvents,
  PresenceContent,
  PresEvent,
  RoomSummary,
  UnreadNotifications };

export interface RelationsResponse {
  chunk: Event[];
  next_batch?: string;
  prev_batch?: string;
}

export interface RelationTypeFilter {
  rel_type?: string;
  event_type?: string;
  room_id?: string;
  limit?: number;
  direction?: 'f' | 'b';
}

export interface InitialSyncResponse {
  end: string;
  rooms?: RoomState[];
  presence?: PresenceEvents;
  account_data?: AccountDataEvents;
}

export interface ConInitialSyncResponse {
  end: string;
  room: RoomState;
  presence?: PresenceEvents;
  account_data?: AccountDataEvents;
}