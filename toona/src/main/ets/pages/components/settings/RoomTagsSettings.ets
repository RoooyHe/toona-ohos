import { Room } from '../../../models/DataModels';
import { getThemeColors } from '../../../utils/ThemeManager';

@Component
export struct RoomTagsSettings {
  @State favoriteRooms: Room[] = [];
  @State lowPriorityRooms: Room[] = [];
  @State allRooms: Room[] = [];
  @State showRoomTagsMenu: boolean = false;
  onToggleFavorite: (room: Room) => void = () => {};
  onToggleLowPriority: (room: Room) => void = () => {};
  onToggleRoomTagsMenu: () => void = () => {};

  build() {
    Column() {
      Row() {
        Text('房间标签')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333');
      }
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        top: 15,
        bottom: 10
      });

      Column() {
        Row() {
          Text('收藏的房间')
            .fontSize(14)
            .fontColor('#666666');
        }
        .width('100%')
        .padding({
          left: 20,
          right: 20,
          top: 12,
          bottom: 8
        });

        if (this.favoriteRooms.length === 0) {
          Text('暂无收藏的房间')
            .fontSize(12)
            .fontColor('#999999')
            .padding({ left: 20, bottom: 12 });
        } else {
          Column() {
            ForEach(this.favoriteRooms, (room: Room) => {
              Row() {
                Text(room.getDisplayName())
                  .fontSize(14)
                  .fontColor('#333333')
                  .layoutWeight(1);
                Text('★')
                  .fontSize(14)
                  .fontColor('#FF9800');
              }
              .width('100%')
              .padding({
                left: 20,
                right: 20,
                top: 8,
                bottom: 8
              })
              .onClick(() => {
                this.onToggleFavorite(room);
              });
            });
          }
          .width('100%')
          .backgroundColor('#fafafa');
        }

        Divider().color('#f0f0f0').margin({ top: 8 });

        Row() {
          Text('低优先级的房间')
            .fontSize(14)
            .fontColor('#666666');
        }
        .width('100%')
        .padding({
          left: 20,
          right: 20,
          top: 12,
          bottom: 8
        });

        if (this.lowPriorityRooms.length === 0) {
          Text('暂无低优先级的房间')
            .fontSize(12)
            .fontColor('#999999')
            .padding({ left: 20, bottom: 12 });
        } else {
          Column() {
            ForEach(this.lowPriorityRooms, (room: Room) => {
              Row() {
                Text(room.getDisplayName())
                  .fontSize(14)
                  .fontColor('#333333')
                  .layoutWeight(1);
                Text('▼')
                  .fontSize(14)
                  .fontColor('#9E9E9E');
              }
              .width('100%')
              .padding({
                left: 20,
                right: 20,
                top: 8,
                bottom: 8
              })
              .onClick(() => {
                this.onToggleLowPriority(room);
              });
            });
          }
          .width('100%')
          .backgroundColor('#fafafa');
        }

        Divider().color('#f0f0f0').margin({ top: 8 });

        Row() {
          Text('管理所有房间标签')
            .fontSize(14)
            .fontColor('#10a37f');
        }
        .width('100%')
        .padding({
          left: 20,
          right: 20,
          top: 12,
          bottom: 12
        })
        .onClick(() => {
          this.onToggleRoomTagsMenu();
        });

        if (this.showRoomTagsMenu) {
          Column() {
            ForEach(this.allRooms, (room: Room) => {
              Row() {
                Text(room.getDisplayName())
                  .fontSize(14)
                  .fontColor('#333333')
                  .layoutWeight(1);

                Text(this.favoriteRooms.some(r => r.id === room.id) ? '★' : '☆')
                  .fontSize(14)
                  .fontColor(this.favoriteRooms.some(r => r.id === room.id) ? '#FF9800' : '#CCCCCC')
                  .onClick(() => {
                    this.onToggleFavorite(room);
                  });

                Text(this.lowPriorityRooms.some(r => r.id === room.id) ? '▼' : '▽')
                  .fontSize(14)
                  .fontColor(this.lowPriorityRooms.some(r => r.id === room.id) ? '#9E9E9E' : '#CCCCCC')
                  .margin({ left: 12 })
                  .onClick(() => {
                    this.onToggleLowPriority(room);
                  });
              }
              .width('100%')
              .padding({
                left: 20,
                right: 20,
                top: 10,
                bottom: 10
              });
            });
          }
          .width('100%')
          .backgroundColor('#fafafa');
        }
      }
      .width('100%')
      .backgroundColor('#ffffff');
    }
    .width('100%')
    .margin({ top: 10 });
  }
}