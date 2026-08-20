import { Room } from '../models/DataModels';
import { getThemeColors } from '../utils/ThemeManager';
import { SpaceViewModel, SpaceState, SpaceItem } from '../viewmodels/SpaceViewModel';
import { IRoomManager } from '../services/RoomManager';

@Component
struct SpaceListItem {
  @Prop item: SpaceItem;
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
            .onClick(() => {
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
            onToggle: this.onToggle,
            onNavigateToSpace: this.onNavigateToSpace,
            onNavigateToRoom: this.onNavigateToRoom
          })
        })
      }
    }
  }
}

@Builder
export function SpacePageBuilder(name: string, param: Object) {
  SpacePage({
    pathStack: param ? (((param as Record<string, Object>)['pathStack'] as NavPathStack)) : new NavPathStack(),
    roomManager: param ? (((param as Record<string, Object>)['roomManager'] as IRoomManager)) : null
  })
}

@Component
export struct SpacePage {
  @State spaceItems: SpaceItem[] = [];
  @State isLoading: boolean = true;
  pathStack: NavPathStack = new NavPathStack();
  roomManager: IRoomManager | null = null;
  private viewModel: SpaceViewModel | null = null;

  aboutToAppear() {
    if (!this.roomManager) {
      return;
    }
    this.viewModel = new SpaceViewModel(this.roomManager);

    const self = this;
    this.viewModel.setOnStateChanged((state: SpaceState) => {
      self.spaceItems = state.spaceItems;
      self.isLoading = state.isLoading;
    });

    this.viewModel.setOnNavigateToSpace((spaceId: string, spaceName: string) => {
      const param: Record<string, Object> = {
        "spaceId": spaceId,
        "spaceName": spaceName
      };
      self.pathStack.pushPathByName('SpaceDetailPage', param);
    });

    this.viewModel.setOnNavigateToRoom((roomId: string, roomName: string) => {
      const param: Record<string, Object> = {
        "roomId": roomId,
        "roomName": roomName
      };
      self.pathStack.pushPathByName('RoomDetailPage', param);
    });

    this.viewModel.setOnNavigateToJoinSpace(() => {
      const param: Record<string, Object> = {};
      self.pathStack.pushPathByName('JoinSpacePage', param);
    });

    this.viewModel.loadSpaces();
  }

  build() {
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
                  onToggle: (id): void => this.viewModel?.toggleSpace(id),
                  onNavigateToSpace: (s): void => this.viewModel?.navigateToSpace(s),
                  onNavigateToRoom: (r): void => this.viewModel?.navigateToRoom(r)
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
