import router from '@ohos.router';
import { RoomManager } from '../services/RoomManager';
import { Room } from '../models/DataModels';
import { SpaceChild } from '../services/RoomManager';
import { getThemeColors } from '../utils/ThemeManager';

@Component
struct SpaceRoomItem {
  @Prop room: Room = new Room('');

  aboutToAppear() {
  }

  build() {
    Row() {
      Text(this.room.getDisplayName().charAt(0).toUpperCase())
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#ffffff')
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
    .padding({ top: 12, bottom: 12, left: 20, right: 20 })
    .backgroundColor(getThemeColors().bg)
    .onClick(() => {
      router.pushUrl({
        url: 'pages/RoomDetailPage',
        params: {
          roomId: this.room.id,
          roomName: this.room.getDisplayName()
        }
      }).catch(() => {
        // Ignore error
      });
    });
  }
}

@Entry
@Component
struct SpaceDetailPage {
  @State spaceName: string = '';
  @State spaceId: string = '';
  @State childRooms: Room[] = [];
  @State isLoading: boolean = true;

  private roomManager: RoomManager = RoomManager.getInstance();

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    if (params) {
      this.spaceId = params.spaceId || '';
      this.spaceName = params.spaceName || '空间';
    }
    this.loadSpaceDetails();
  }

  async loadSpaceDetails() {
    this.isLoading = true;
    try {
      const space = await this.roomManager.getRoom(this.spaceId);
      if (space) {
        this.spaceName = space.getDisplayName();
      }

      const children: SpaceChild[] = await this.roomManager.getSpaceChildren(this.spaceId);
      const rooms: Room[] = [];
      for (let i = 0; i < children.length; i++) {
        const child = children[i];
        const room = await this.roomManager.getRoom(child.room_id);
        if (room) {
          rooms.push(room);
        }
      }
      this.childRooms = rooms;
    } catch (error) {
      console.error('Failed to load space details:', error);
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Button('←')
            .fontSize(24)
            .backgroundColor('transparent')
            .fontColor(getThemeColors().text)
            .width(44)
            .height(44)
            .onClick(() => {
              router.back();
            });

          Text(this.spaceName)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(getThemeColors().text)
            .layoutWeight(1);
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
                SpaceRoomItem({ room: room });
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
}

export { SpaceDetailPage };
