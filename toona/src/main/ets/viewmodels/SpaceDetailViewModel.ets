import { Room } from '../models/DataModels';
import { SpaceChild } from '../services/RoomManager';
import { IRoomManager } from '../services/RoomManager';
import { AppLogger } from '../utils/AppLogger';

const logger = AppLogger.getLogger('SpaceDetailViewModel');

export interface SpaceDetailState {
  spaceName: string;
  spaceId: string;
  childRooms: Room[];
  isLoading: boolean;
}

export type SpaceDetailStateCallback = (state: SpaceDetailState) => void;
export type NavigateToRoomCallback = (roomId: string, roomName: string) => void;

export class SpaceDetailViewModel {
  private roomManager: IRoomManager;
  private state: SpaceDetailState;
  private onStateChanged: SpaceDetailStateCallback | null = null;
  private onNavigateToRoom: NavigateToRoomCallback | null = null;

  constructor(spaceId: string, spaceName: string, roomManager: IRoomManager) {
    this.roomManager = roomManager;
    this.state = {
      spaceName: spaceName,
      spaceId: spaceId,
      childRooms: [],
      isLoading: true
    };
  }

  setOnStateChanged(callback: SpaceDetailStateCallback): void {
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

  getState(): SpaceDetailState {
    return this.state;
  }

  async loadSpaceDetails(): Promise<void> {
    this.state.isLoading = true;
    this.notifyStateChanged();
    try {
      const space: Room | null = await this.roomManager.getRoom(this.state.spaceId);
      if (space) {
        this.state.spaceName = space.getDisplayName();
      }

      const children: SpaceChild[] = await this.roomManager.getSpaceChildren(this.state.spaceId);
      const rooms: Room[] = [];
      for (let i: number = 0; i < children.length; i++) {
        const child: SpaceChild = children[i];
        const room: Room | null = await this.roomManager.getRoom(child.room_id);
        if (room) {
          rooms.push(room);
        }
      }
      this.state.childRooms = rooms;
    } catch (error) {
      logger.error('Failed to load space details:', error);
    } finally {
      this.state.isLoading = false;
      this.notifyStateChanged();
    }
  }

  navigateToRoom(room: Room): void {
    if (this.onNavigateToRoom) {
      this.onNavigateToRoom(room.id, room.getDisplayName());
    }
  }
}
