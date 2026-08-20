import { Room } from '../models/DataModels';
import { IRoomManager } from '../services/RoomManager';
import { AppLogger } from '../utils/AppLogger';

const logger = AppLogger.getLogger('SpaceViewModel');

export interface SpaceItem {
  room: Room;
  children: SpaceItem[];
  isExpanded: boolean;
  level: number;
}

export interface SpaceState {
  spaceItems: SpaceItem[];
  isLoading: boolean;
}

export type SpaceStateCallback = (state: SpaceState) => void;
export type NavigateToSpaceCallback = (spaceId: string, spaceName: string) => void;
export type NavigateToRoomCallback = (roomId: string, roomName: string) => void;
export type NavigateToJoinSpaceCallback = () => void;

export class SpaceViewModel {
  private roomManager: IRoomManager;
  private state: SpaceState;
  private expandedSpaces: Set<string> = new Set();
  private onStateChanged: SpaceStateCallback | null = null;
  private onNavigateToSpace: NavigateToSpaceCallback | null = null;
  private onNavigateToRoom: NavigateToRoomCallback | null = null;
  private onNavigateToJoinSpace: NavigateToJoinSpaceCallback | null = null;

  constructor(roomManager: IRoomManager) {
    this.roomManager = roomManager;
    this.state = {
      spaceItems: [],
      isLoading: true
    };
  }

  setOnStateChanged(callback: SpaceStateCallback): void {
    this.onStateChanged = callback;
  }

  setOnNavigateToSpace(callback: NavigateToSpaceCallback): void {
    this.onNavigateToSpace = callback;
  }

  setOnNavigateToRoom(callback: NavigateToRoomCallback): void {
    this.onNavigateToRoom = callback;
  }

  setOnNavigateToJoinSpace(callback: NavigateToJoinSpaceCallback): void {
    this.onNavigateToJoinSpace = callback;
  }

  private notifyStateChanged(): void {
    if (this.onStateChanged) {
      this.onStateChanged(this.state);
    }
  }

  getState(): SpaceState {
    return this.state;
  }

  async loadSpaces(): Promise<void> {
    this.state.isLoading = true;
    this.notifyStateChanged();
    try {
      const rooms: Room[] = await this.roomManager.getRooms();
      this.state.spaceItems = this.buildSpaceTree(rooms);
    } catch (error) {
      logger.error('Failed to load spaces:', error);
    } finally {
      this.state.isLoading = false;
      this.notifyStateChanged();
    }
  }

  private buildSpaceTree(rooms: Room[]): SpaceItem[] {
    const spaceMap: Map<string, SpaceItem> = new Map();
    const rootItems: SpaceItem[] = [];

    const spaceRooms: Room[] = rooms.filter((room: Room): boolean => room.isSpace === true);
    for (const room of spaceRooms) {
      spaceMap.set(room.id, {
        room: room,
        children: [],
        isExpanded: this.expandedSpaces.has(room.id),
        level: 0
      });
    }

    const spaceMapValues: SpaceItem[] = [];
    spaceMap.forEach((item: SpaceItem) => {
      spaceMapValues.push(item);
    });

    for (const item of spaceMapValues) {
      const content: Record<string, string | object> | undefined = item.room.lastEvent?.content as Record<string, string | object> | undefined;
      const parentRoomId: string | undefined = content !== undefined ? content['parent'] as string | undefined : undefined;

      if (parentRoomId && spaceMap.has(parentRoomId)) {
        const parent: SpaceItem | undefined = spaceMap.get(parentRoomId);
        if (parent) {
          item.level = parent.level + 1;
          parent.children.push(item);
        }
      } else {
        rootItems.push(item);
      }
    }

    for (const room of rooms) {
      if (!room.isSpace && !this.isChildOfAnySpace(room, spaceRooms)) {
        rootItems.push({
          room: room,
          children: [],
          isExpanded: false,
          level: 0
        });
      }
    }

    return rootItems;
  }

  private isChildOfAnySpace(room: Room, spaces: Room[]): boolean {
    const content: Record<string, string | object> | undefined = room.lastEvent?.content as Record<string, string | object> | undefined;
    return content !== undefined && content['parent'] !== undefined;
  }

  toggleSpace(roomId: string): void {
    if (this.expandedSpaces.has(roomId)) {
      this.expandedSpaces.delete(roomId);
    } else {
      this.expandedSpaces.add(roomId);
    }
    this.refreshTree();
  }

  private async refreshTree(): Promise<void> {
    const rooms: Room[] = await this.roomManager.getRooms();
    this.state.spaceItems = this.buildSpaceTree(rooms);
    this.notifyStateChanged();
  }

  navigateToSpace(space: Room): void {
    if (this.onNavigateToSpace) {
      this.onNavigateToSpace(space.id, space.getDisplayName());
    }
  }

  navigateToRoom(room: Room): void {
    if (this.onNavigateToRoom) {
      this.onNavigateToRoom(room.id, room.getDisplayName());
    }
  }

  navigateToJoinSpace(): void {
    if (this.onNavigateToJoinSpace) {
      this.onNavigateToJoinSpace();
    }
  }
}
