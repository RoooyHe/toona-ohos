import { RoomManager } from '../services/RoomManager';
import { Room } from '../models/DataModels';
import { getThemeColors } from '../utils/ThemeManager';
import { AppLogger } from '../utils/AppLogger';

const logger = AppLogger.getLogger('SpacePage');

// 空间项数据结构
interface SpaceItem {
  room: Room;
  children: SpaceItem[];
  isExpanded: boolean;
  level: number;
}

@Builder
export function SpacePageBuilder(name: string, param: Object) {
  SpacePage({
    pathStack: param ? (((param as Record<string, Object>)['pathStack'] as NavPathStack)) : new NavPathStack()
  })
}

/**
 * 内部组件：空间列表项
 */
@Component
struct SpaceListItem {
  @Prop item: SpaceItem;
  pathStack?: NavPathStack;
  onToggle?: (roomId: string) => void;
  onNavigateToSpace?: (space: Room) => void;
  onNavigateToRoom?: (room: Room) => void;

  build() {
    Column() {
      Row() {
        Row().width(this.item.level * 20)

        if (this.item.children.length > 0) {
          Text(this.item.isExpanded ? '▼' : '▶')
            .fontSize(12)
            .fontColor(getThemeColors().textSecondary)
            .margin({ right: 8 })
            .onClick((e) => {
              if (this.onToggle) {
                this.onToggle(this.item.room.id);
              }
            })
        } else {
          Row().width(20)
        }

        Text(this.item.room.getDisplayName()
          .charAt(0)
          .toUpperCase())
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(getThemeColors().onPrimary)
          .width(32)
          .height(32)
          .borderRadius(16)
          .backgroundColor(this.item.room.isSpace ? getThemeColors().primary : getThemeColors().textSecondary)
          .textAlign(TextAlign.Center)
          .margin({ right: 12 });

        Text(this.item.room.getDisplayName())
          .fontSize(16)
          .fontColor(getThemeColors().text)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });

        if (this.item.room.isSpace) {
          Text('详情')
            .fontSize(12)
            .fontColor(getThemeColors().primary)
            .padding(8)
            .onClick(() => {
              if (this.onNavigateToSpace) {
                this.onNavigateToSpace(this.item.room);
              }
            })
        }
      }
      .width('100%')
      .padding({
        left: 16,
        right: 16,
        top: 12,
        bottom: 12
      })
      .backgroundColor(getThemeColors().bg)
      .onClick(() => {
        if (this.item.room.isSpace) {
          if (this.onToggle) {
            this.onToggle(this.item.room.id);
          }
        } else {
          if (this.onNavigateToRoom) {
            this.onNavigateToRoom(this.item.room);
          }
        }
      });

      if (this.item.isExpanded && this.item.children.length > 0) {
        ForEach(this.item.children, (child: SpaceItem) => {
          SpaceListItem({
            item: child,
            pathStack: this.pathStack,
            onToggle: this.onToggle,
            onNavigateToSpace: this.onNavigateToSpace,
            onNavigateToRoom: this.onNavigateToRoom
          })
        })
      }
    }
  }
}

@Component
export struct SpacePage {
  @State spaceItems: SpaceItem[] = [];
  @State isLoading: boolean = true;
  // 依赖 MainPage 传进来的 pathStack 即可
  pathStack: NavPathStack = new NavPathStack();
  private roomManager: RoomManager = RoomManager.getInstance();
  private expandedSpaces: Set<string> = new Set();

  aboutToAppear() {
    this.loadSpaces();
  }

  async loadSpaces() {
    this.isLoading = true;
    try {
      const rooms = await this.roomManager.getRooms();
      this.spaceItems = this.buildSpaceTree(rooms);
    } catch (error) {
logger.error('Failed to load spaces:', error);
    } finally {
      this.isLoading = false;
    }
  }

  buildSpaceTree(rooms: Room[]): SpaceItem[] {
    const spaceMap: Map<string, SpaceItem> = new Map();
    const rootItems: SpaceItem[] = [];

    const spaceRooms = rooms.filter(room => room.isSpace === true);
    for (const room of spaceRooms) {
      spaceMap.set(room.id, {
        room: room,
        children: [],
        isExpanded: this.expandedSpaces.has(room.id),
        level: 0
      });
    }

    for (const item of spaceMap.values()) {
      const content = item.room.lastEvent?.content as Record<string, string | object>;
      const parentRoomId = content?.parent as string;

      if (parentRoomId && spaceMap.has(parentRoomId)) {
        const parent = spaceMap.get(parentRoomId)!;
        item.level = parent.level + 1;
        parent.children.push(item);
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
    const content = room.lastEvent?.content as Record<string, string | object>;
    return !!(content?.parent);
  }

  onToggleSpace(roomId: string) {
    if (this.expandedSpaces.has(roomId)) {
      this.expandedSpaces.delete(roomId);
    } else {
      this.expandedSpaces.add(roomId);
    }
    this.refreshTree();
  }

  async refreshTree() {
    const rooms = await this.roomManager.getRooms();
    this.spaceItems = this.buildSpaceTree(rooms);
  }

  // 移除了多余的安全校验，直接使用 MainPage 传递进来的 pathStack 进行跳转
  navigateToSpaceDetail(space: Room) {
    if (!this.pathStack) {
      return;
    }
    const param: Record<string, Object> = {
      "spaceId": space.id,
      "spaceName": space.getDisplayName()
    };
    this.pathStack.pushPathByName('SpaceDetailPage', param);
  }

  navigateToRoom(room: Room) {
    if (!this.pathStack) {
      return;
    }
    const param: Record<string, Object> = {
      "roomId": room.id,
      "roomName": room.getDisplayName()
    };
    this.pathStack.pushPathByName('RoomDetailPage', param);
  }

  navigateToJoinSpace() {
    if (!this.pathStack) {
      return;
    }
    const param: Record<string, Object> = {};
    this.pathStack.pushPathByName('JoinSpacePage', param);
  }

  build() {
    // 🎯 这里移除了导致闪退的 NavDestination
    Stack() {
      Column() {
        if (this.isLoading) {
          Column() {
            LoadingProgress().width(40).height(40);
            Text('加载中...').margin({ top: 10 }).fontColor(getThemeColors().textSecondary);
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center);
        } else if (this.spaceItems.length === 0) {
          Column() {
            Text('暂无空间').fontSize(16).fontColor(getThemeColors().textSecondary);
            Text('点击下方创建空间').fontSize(14).opacity(0.7).margin({ top: 5 });
          }
          .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center);
        } else {
          List() {
            ForEach(this.spaceItems, (item: SpaceItem) => {
              ListItem() {
                SpaceListItem({
                  item: item,
                  pathStack: this.pathStack,
                  onToggle: (id): void => this.onToggleSpace(id),
                  onNavigateToSpace: (s): void => this.navigateToSpaceDetail(s),
                  onNavigateToRoom: (r): void => this.navigateToRoom(r)
                });
              }
            });
          }
          .width('100%')
          .layoutWeight(1)
          .divider({ strokeWidth: 1, color: getThemeColors().divider });
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(getThemeColors().bg);
    }
    .width('100%')
    .height('100%');
  }
}