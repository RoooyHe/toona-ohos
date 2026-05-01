import { RoomManager } from '../services/RoomManager';
import { Room } from '../models/DataModels';
import { getThemeColors } from '../utils/ThemeManager';

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
    // 修复点：增加安全判空，防止 param 为空时崩溃
    pathStack: param ? (((param as Record<string, Object>)['pathStack'] as NavPathStack)) : new NavPathStack()
  })
}

/**
 * 内部组件：空间列表项
 * 负责渲染树形结构中的每一行
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
        // 根据层级缩进
        Row().width(this.item.level * 20)

        // 展开/折叠图标
        if (this.item.children.length > 0) {
          Text(this.item.isExpanded ? '▼' : '▶')
            .fontSize(12)
            .fontColor(getThemeColors().textSecondary)
            .margin({ right: 8 })
            .onClick((e) => {
              // 阻止冒泡，只触发折叠
              if (this.onToggle) this.onToggle(this.item.room.id);
            })
        } else {
          Row().width(20) // 占位
        }

        // 房间图标（首字母）
        Text(this.item.room.getDisplayName().charAt(0).toUpperCase())
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .width(32)
          .height(32)
          .borderRadius(16)
          .backgroundColor(this.item.room.isSpace ? getThemeColors().primary : getThemeColors().textSecondary)
          .textAlign(TextAlign.Center)
          .margin({ right: 12 });

        // 房间名称
        Text(this.item.room.getDisplayName())
          .fontSize(16)
          .fontColor(getThemeColors().text)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });

        // 详情跳转按钮
        if (this.item.room.isSpace) {
          Text('详情')
            .fontSize(12)
            .fontColor(getThemeColors().primary)
            .padding(8)
            .onClick(() => {
              if (this.onNavigateToSpace) this.onNavigateToSpace(this.item.room);
            })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(getThemeColors().bg)
      .onClick(() => {
        // 如果是空间，则尝试展开；如果是普通房间，则进入聊天
        if (this.item.room.isSpace) {
          if (this.onToggle) this.onToggle(this.item.room.id);
        } else {
          if (this.onNavigateToRoom) this.onNavigateToRoom(this.item.room);
        }
      });

      // 递归渲染子节点（如果已展开）
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
  @State navCtx: NavDestinationContext | null = null;

  // 修复点：严禁使用 @State 修饰 NavPathStack，改为普通属性
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
      console.error('Failed to load spaces:', error);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 构建空间树结构
   */
  buildSpaceTree(rooms: Room[]): SpaceItem[] {
    const spaceMap: Map<string, SpaceItem> = new Map();
    const rootItems: SpaceItem[] = [];

    // 第一步：初始化所有空间节点
    const spaceRooms = rooms.filter(room => room.isSpace === true);
    for (const room of spaceRooms) {
      spaceMap.set(room.id, {
        room: room,
        children: [],
        isExpanded: this.expandedSpaces.has(room.id),
        level: 0
      });
    }

    // 第二步：建立父子关系
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

    // 第三步：处理不在空间内的普通房间（作为根级展示）
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
    // 简单的逻辑判断该房间是否有父级空间（Matrix 协议中通常通过 m.space.child 事件判断）
    // 这里暂用 lastEvent 里的 parent 模拟
    const content = room.lastEvent?.content as Record<string, string | object>;
    return !!(content?.parent);
  }

  onToggleSpace(roomId: string) {
    if (this.expandedSpaces.has(roomId)) {
      this.expandedSpaces.delete(roomId);
    } else {
      this.expandedSpaces.add(roomId);
    }
    // 重新触发树构建以更新 UI 状态
    this.refreshTree();
  }

  async refreshTree() {
    const rooms = await this.roomManager.getRooms();
    this.spaceItems = this.buildSpaceTree(rooms);
  }

  navigateToSpaceDetail(space: Room) {
    const stack = this.navCtx?.pathStack ?? this.pathStack;
    if (!stack) return;

    // 显式声明为 Record<string, Object> 类型
    const param: Record<string, Object> = {
      "spaceId": space.id,
      "spaceName": space.getDisplayName()
    };
    stack.pushPathByName('SpaceDetailPage', param);
  }

  navigateToRoom(room: Room) {
    const stack = this.navCtx?.pathStack ?? this.pathStack;
    if (!stack) return;

    // 显式声明为 Record<string, Object> 类型
    const param: Record<string, Object> = {
      "roomId": room.id,
      "roomName": room.getDisplayName()
    };
    stack.pushPathByName('RoomDetailPage', param);
  }

  navigateToJoinSpace() {
    const stack = this.navCtx?.pathStack ?? this.pathStack;
    if (stack) {
      // 即使是空对象也要显式声明类型
      const param: Record<string, Object> = {};
      stack.pushPathByName('JoinSpacePage', param);
    }
  }

  build() {
    // 建议外层包裹 NavDestination 以便获取上下文
    NavDestination() {
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
                    pathStack: this.navCtx?.pathStack ?? this.pathStack,
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

          // 底部操作栏
          Row() {
            Button('创建空间')
              .backgroundColor(getThemeColors().primary)
              .width('80%')
              .height(45)
              .onClick(() => this.navigateToJoinSpace());
          }
          .width('100%')
          .padding(20)
          .justifyContent(FlexAlign.Center);
        }
        .width('100%')
        .height('100%')
        .backgroundColor(getThemeColors().bg);
      }
    }
    .onReady((ctx) => {
      this.navCtx = ctx;
    })
    .hideTitleBar(true)
  }
}