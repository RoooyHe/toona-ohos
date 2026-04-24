import { RoomManager } from '../services/RoomManager';
import { Room } from '../models/DataModels';
import { getThemeColors } from '../utils/ThemeManager';

interface SpaceItem {
  room: Room;
  children: SpaceItem[];
  isExpanded: boolean;
  level: number;
}

@Builder
export function SpacePageBuilder(name: string, param: Object) {
  SpacePage({
    pathStack: ((param as Record<string, Object>)['pathStack'] as NavPathStack) || new NavPathStack()
  })
}

@Component
export struct SpacePage {
  @State spaceItems: SpaceItem[] = [];
  @State isLoading: boolean = true;
  @State navCtx: NavDestinationContext | null = null;
  @State pathStack: NavPathStack = new NavPathStack();
  private roomManager: RoomManager = RoomManager.getInstance();
  private expandedSpaces: Set<string> = new Set();

  aboutToAppear() {
    this.loadSpaces();
  }

  async loadSpaces() {
    this.isLoading = true;
    try {
      const rooms = await this.roomManager.getRooms();
      const spaces = this.buildSpaceTree(rooms);
      this.spaceItems = spaces;
    } catch (error) {
      console.error('Failed to load spaces:', error);
    } finally {
      this.isLoading = false;
    }
  }

  buildSpaceTree(rooms: Room[]): SpaceItem[] {
    const spaceMap: Map<string, SpaceItem> = new Map();
    const rootSpaces: SpaceItem[] = [];

    const spaceRooms = rooms.filter(room => room.isSpace === true);

    for (const room of spaceRooms) {
      const item: SpaceItem = {
        room: room,
        children: [],
        isExpanded: this.expandedSpaces.has(room.id),
        level: 0
      };
      spaceMap.set(room.id, item);
    }

    for (const room of spaceRooms) {
      const content = room.lastEvent?.content as Record<string, string | object>;
      const parentRoomId = content?.parent as string;

      if (parentRoomId && spaceMap.has(parentRoomId)) {
        const parent = spaceMap.get(parentRoomId)!;
        const childItem: SpaceItem = {
          room: room,
          children: [],
          isExpanded: this.expandedSpaces.has(room.id),
          level: parent.level + 1
        };
        parent.children.push(childItem);
        spaceMap.set(room.id, childItem);
      } else {
        const rootItem: SpaceItem = {
          room: room,
          children: [],
          isExpanded: this.expandedSpaces.has(room.id),
          level: 0
        };
        rootSpaces.push(rootItem);
      }
    }

    for (const room of rooms) {
      if (!spaceMap.has(room.id)) {
        rootSpaces.push({
          room: room,
          children: [],
          isExpanded: false,
          level: 0
        });
      }
    }

    return rootSpaces;
  }

  onToggleSpace(roomId: string) {
    if (this.expandedSpaces.has(roomId)) {
      this.expandedSpaces.delete(roomId);
    } else {
      this.expandedSpaces.add(roomId);
    }
    this.updateExpandedState(this.spaceItems);
  }

  updateExpandedState(items: SpaceItem[]) {
    for (let i = 0; i < items.length; i++) {
      items[i].isExpanded = this.expandedSpaces.has(items[i].room.id);
      if (items[i].children.length > 0) {
        this.updateExpandedState(items[i].children);
      }
    }
  }

  navigateToSpaceDetail(space: Room) {
    const stack = this.navCtx?.pathStack ?? this.pathStack;
    if (!stack) {
      console.error('navigateToSpaceDetail: no pathStack available');
      return;
    }
    const param: Record<string, Object> = {
      "spaceId": space.id,
      "spaceName": space.getDisplayName()
    };
    stack.pushPathByName('SpaceDetailPage', param);
  }

  navigateToRoom(room: Room) {
    const stack = this.navCtx?.pathStack ?? this.pathStack;
    if (!stack) {
      console.error('navigateToRoom: no pathStack available');
      return;
    }
    const param: Record<string, Object> = {
      "roomId": room.id,
      "roomName": room.getDisplayName(),
      "pathStack": stack
    };
    stack.pushPathByName('RoomDetailPage', param);
  }

  navigateToJoinSpace() {
    const stack = this.navCtx?.pathStack ?? this.pathStack;
    if (!stack) {
      console.error('navigateToJoinSpace: no pathStack available');
      return;
    }
    const param: Record<string, Object> = {
      "pathStack": stack
    };
    stack.pushPathByName('JoinSpacePage', param);
  }

  build() {
    Stack() {
      Column() {
        Divider().color(getThemeColors().divider);

          if (this.isLoading) {
            Column() {
              LoadingProgress()
                .width(40)
                .height(40);
              Text('加载中...')
                .fontSize(14)
                .fontColor(getThemeColors().textSecondary)
                .margin({ top: 10 });
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center);
          } else if (this.spaceItems.length === 0) {
            Column() {
              Text('暂无空间')
                .fontSize(16)
                .fontColor(getThemeColors().textSecondary);
              Text('点击下方创建空间')
                .fontSize(14)
                .fontColor(getThemeColors().textSecondary)
                .opacity(0.7)
                .margin({ top: 5 });
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center);
          } else {
            List() {
              ForEach(this.spaceItems, (item: SpaceItem) => {
                ListItem() {
                  SpaceListItem({
                    item: item,
                    onToggle: (roomId: string) => {
                      this.onToggleSpace(roomId);
                    },
                    onNavigateToSpace: (space: Room) => {
                      this.navigateToSpaceDetail(space);
                    },
                    onNavigateToRoom: (room: Room) => {
                      this.navigateToRoom(room);
                    }
                  });
                }
              });
            }
            .width('100%')
            .layoutWeight(1);
          }

          Row() {
            Text('创建空间')
              .fontSize(16)
              .fontColor(getThemeColors().primary)
              .onClick(() => {
                this.navigateToJoinSpace();
              });
          }
          .width('90%')
          .padding({ top: 15, bottom: 15 })
          .justifyContent(FlexAlign.Center);
        }
        .width('100%')
        .height('100%')
        .backgroundColor(getThemeColors().bg);
      }
      .width('100%')
      .height('100%');
    }
  }
}
