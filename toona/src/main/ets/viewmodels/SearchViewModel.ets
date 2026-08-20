import { Room } from '../models/DataModels';
import { IRoomManager } from '../services/RoomManager';
import { AppLogger } from '../utils/AppLogger';

const logger = AppLogger.getLogger('SearchViewModel');

export interface SearchState {
  searchQuery: string;
  searchResults: Room[];
  isSearching: boolean;
}

export type SearchStateCallback = (state: SearchState) => void;
export type NavigateToRoomCallback = (roomId: string, roomName: string) => void;

export class SearchViewModel {
  private roomManager: IRoomManager;
  private state: SearchState;
  private onStateChanged: SearchStateCallback | null = null;
  private onNavigateToRoom: NavigateToRoomCallback | null = null;

  constructor(roomManager: IRoomManager) {
    this.roomManager = roomManager;
    this.state = {
      searchQuery: '',
      searchResults: [],
      isSearching: false
    };
  }

  setOnStateChanged(callback: SearchStateCallback): void {
    this.onStateChanged = callback;
  }

  setOnNavigateToRoom(callback: NavigateToRoomCallback): void {
    this.onNavigateToRoom = callback;
  }

  private notifyStateChanged(): void {
    if (this.onStateChanged) {
      this.onStateChanged(this.state);
    }
  }

  getState(): SearchState {
    return this.state;
  }

  setSearchQuery(value: string): void {
    this.state.searchQuery = value;
    this.notifyStateChanged();
  }

  async search(): Promise<void> {
    if (!this.state.searchQuery.trim()) {
      return;
    }

    this.state.isSearching = true;
    this.notifyStateChanged();

    try {
      const roomId: string = await this.roomManager.resolveRoomAlias(this.state.searchQuery.trim());
      const room: Room | null = await this.roomManager.getRoom(roomId);
      if (room) {
        this.state.searchResults = [room];
      } else {
        this.state.searchResults = [];
      }
    } catch (error) {
      logger.error('Search failed:', error);
      this.state.searchResults = [];
    } finally {
      this.state.isSearching = false;
      this.notifyStateChanged();
    }
  }

  navigateToRoom(room: Room): void {
    if (this.onNavigateToRoom) {
      this.onNavigateToRoom(room.id, room.getDisplayName());
    }
  }
}
