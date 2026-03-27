import router from '@ohos.router';
import { RoomManager, CreateRoomOptions } from '../services/RoomManager';
import { Room } from '../models/DataModels';
import promptAction from '@ohos.promptAction';

interface SpaceItem {
  room: Room;
  children: SpaceItem[];
  isExpanded: boolean;
  level: number;
}

@Component
struct SpaceListItem {
  @ObjectLink item: SpaceItem;
  @State isExpanded: boolean = false;
  onToggle: (roomId: string) => void = () => {};
  onNavigateToSpace: (space: Room) => void = () => {};
  onNavigateToRoom: (room: Room) => void = () => {};

  aboutToAppear() {
    this.isExpanded = this.item.isExpanded;
  }

  build() {
    Column() {
      Row() {
        if (this.item.level > 0) {
          Blank().width(20 * this.item.level);
        }

        if (this.item.children.length > 0) {
          Text(this.isExpanded ? '▼' : '▶')
            .fontSize(12)
            .fontColor('#999999')
            .width(20)
            .onClick(() => {
              this.isExpanded = !this.isExpanded;
              this.onToggle(this.item.room.id);
            });
        } else {
          Blank().width(20);
        }

        Text(this.item.room.getDisplayName().charAt(0).toUpperCase())
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .width(36)
          .height(36)
          .borderRadius(18)
          .backgroundColor('#10a37f')
          .textAlign(TextAlign.Center);

        Text(this.item.room.getDisplayName())
          .fontSize(16)
          .fontColor('#333333')
          .margin({ left: 12 })
          .layoutWeight(1);

        if (this.item.children.length > 0) {
          Text(`${this.item.children.length}`)
            .fontSize(12)
            .fontColor('#999999')
            .backgroundColor('#f5f5f5')
            .borderRadius(10)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 });
        }
      }
      .width('100%')
      .padding({ top: 12, bottom: 12, left: 20, right: 20 })
      .backgroundColor(this.item.level === 0 ? '#ffffff' : '#fafafa')
      .onClick(() => {
        if (this.item.room.isSpace === true) {
          this.onNavigateToSpace(this.item.room);
        } else {
          this.onNavigateToRoom(this.item.room);
        }
      });

      if (this.isExpanded && this.item.children.length > 0) {
        ForEach(this.item.children, (child: SpaceItem) => {
          SpaceListItem({
            item: child,
            onToggle: this.onToggle,
            onNavigateToSpace: this.onNavigateToSpace,
            onNavigateToRoom: this.onNavigateToRoom
          });
        });
      }
    }
  }
}

@Entry
@Component
struct SpacePage {
  @State spaceItems: SpaceItem[] = [];
  @State isLoading: boolean = true;
  @State showCreateDialog: boolean = false;
  @State newSpaceName: string = '';

  private roomManager: RoomManager = RoomManager.getInstance();
  private expandedSpaces: Set<string> = new Set();

  async aboutToAppear() {
    await this.loadSpaces();
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
    router.pushUrl({
      url: 'pages/SpaceDetailPage',
      params: {
        spaceId: space.id,
        spaceName: space.getDisplayName()
      }
    }).catch(() => {
      // Ignore error
    });
  }

  navigateToRoom(room: Room) {
    router.pushUrl({
      url: 'pages/RoomDetailPage',
      params: {
        roomId: room.id,
        roomName: room.getDisplayName()
      }
    }).catch(() => {
      // Ignore error
    });
  }

  async createSpace() {
    if (!this.newSpaceName.trim()) {
      return;
    }

    try {
      const options: CreateRoomOptions = {
        name: this.newSpaceName.trim()
      };
      await this.roomManager.createRoom(options);
      this.showCreateDialog = false;
      this.newSpaceName = '';
      promptAction.showToast({ message: '创建成功' });
      await this.loadSpaces();
    } catch (error) {
      console.error('Failed to create space:', error);
      promptAction.showToast({ message: '创建失败' });
    }
  }

  build() {
    Stack() {
      Column() {
        if (this.isLoading) {
          Column() {
            LoadingProgress()
              .width(40)
              .height(40);
            Text('加载中...')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 10 });
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center);
        } else if (this.spaceItems.length === 0) {
          Column() {
            Text('暂无空间')
              .fontSize(16)
              .fontColor('#999999');
            Text('点击下方创建空间')
              .fontSize(14)
              .fontColor('#cccccc')
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
            .fontColor('#10a37f')
            .onClick(() => {
              this.showCreateDialog = true;
            });
        }
        .width('90%')
        .padding({ top: 15, bottom: 15 })
        .justifyContent(FlexAlign.Center);
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#ffffff');

      if (this.showCreateDialog) {
        Column() {
          Column() {
            Text('创建空间')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 20 });

            TextInput({ placeholder: '空间名称' })
              .width('100%')
              .height(44)
              .fontSize(16)
              .backgroundColor('#f5f5f5')
              .borderRadius(8)
              .onChange((value: string) => {
                this.newSpaceName = value;
              });

            Row() {
              Button('取消')
                .fontSize(16)
                .backgroundColor('#f5f5f5')
                .fontColor('#333333')
                .width('45%')
                .height(44)
                .borderRadius(8)
                .onClick(() => {
                  this.showCreateDialog = false;
                  this.newSpaceName = '';
                });

              Button('创建')
                .fontSize(16)
                .backgroundColor('#10a37f')
                .fontColor('#ffffff')
                .width('45%')
                .height(44)
                .borderRadius(8)
                .onClick(() => {
                  this.createSpace();
                });
            }
            .width('100%')
            .margin({ top: 20 });
          }
          .width('85%')
          .padding(20)
          .backgroundColor('#ffffff')
          .borderRadius(16);
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .justifyContent(FlexAlign.Center);
      }
    }
    .width('100%')
    .height('100%');
  }
}

export { SpacePage };
