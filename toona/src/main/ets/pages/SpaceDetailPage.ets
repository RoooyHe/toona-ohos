import { Room } from '../models/DataModels';
import { getThemeColors } from '../utils/ThemeManager';
import { SpaceDetailViewModel, SpaceDetailState } from '../viewmodels/SpaceDetailViewModel';
import { ServiceLocator } from '../services/ServiceLocator';

@Component
struct SpaceRoomItem {
  @Prop room: Room = new Room('');
  onNavigateToRoom?: (roomId: string, roomName: string) => void;

  build() {
    Row() {
      Text(this.room.getDisplayName().charAt(0).toUpperCase())
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(getThemeColors().onPrimary)
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor(getThemeColors().primary)
        .textAlign(TextAlign.Center);

      Column() {
        Text(this.room.getDisplayName())
          .fontSize(16)
          .fontColor(getThemeColors().text)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });

        if (this.room.topic) {
          Text(this.room.topic)
            .fontSize(12)
            .fontColor(getThemeColors().textSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }
      }
      .margin({ left: 12 })
      .layoutWeight(1);
    }
    .width('100%')
    .padding({
      top: 12,
      bottom: 12,
      left: 20,
      right: 20
    })
    .backgroundColor(getThemeColors().bg)
    .onClick(() => {
      if (this.onNavigateToRoom) {
        this.onNavigateToRoom(this.room.id, this.room.getDisplayName());
      }
    });
  }
}

@Builder
export function SpaceDetailPageBuilder(name: string, param: Object) {
  SpaceDetailPage({
    spaceId: param ? (((param as Record<string, Object>)['spaceId'] as string) || '') : '',
    spaceName: param ? (((param as Record<string, Object>)['spaceName'] as string) || '空间') : '空间'
  })
}

@Component
struct SpaceDetailPage {
  @State spaceName: string = '';
  @State spaceId: string = '';
  @State childRooms: Room[] = [];
  @State isLoading: boolean = true;
  private viewModel: SpaceDetailViewModel | null = null;
  pathStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    this.viewModel = new SpaceDetailViewModel(
      this.spaceId,
      this.spaceName,
      ServiceLocator.getRoomManager()
    );

    const self = this;
    this.viewModel.setOnStateChanged((state: SpaceDetailState) => {
      self.spaceName = state.spaceName;
      self.spaceId = state.spaceId;
      self.childRooms = state.childRooms;
      self.isLoading = state.isLoading;
    });

    this.viewModel.setOnNavigateToRoom((roomId: string, roomName: string) => {
      const param: Record<string, Object> = {
        "roomId": roomId,
        "roomName": roomName
      };
      self.pathStack.pushPathByName('RoomDetailPage', param);
    });

    this.viewModel.loadSpaceDetails();
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          Row() {
            Text(this.spaceName)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(getThemeColors().text);
          }
          .width('100%')
          .padding({ left: 10, right: 10 })
          .backgroundColor(getThemeColors().bg);

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
          } else if (this.childRooms.length === 0) {
            Column() {
              Text('暂无房间')
                .fontSize(16)
                .fontColor(getThemeColors().textSecondary);
              Text('此空间内没有房间')
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
              ForEach(this.childRooms, (room: Room) => {
                ListItem() {
                  SpaceRoomItem({
                    room: room,
                    onNavigateToRoom: (roomId: string, roomName: string) => {
                      this.viewModel?.navigateToRoom(room);
                    }
                  });
                }
              });
            }
            .width('100%')
            .layoutWeight(1);
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(getThemeColors().bg);
      }
      .width('100%')
      .height('100%');
    }
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
    })
    .hideTitleBar(true)
  }
}
