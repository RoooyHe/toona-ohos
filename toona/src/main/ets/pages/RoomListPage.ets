import router from '@ohos.router';
import { RoomManager } from '../services/RoomManager';
import { Room, Message } from '../models/DataModels';
import { SyncManager } from '../services/SyncManager';

enum FilterType {
  ALL = 'all',
  UNREAD = 'unread',
  DM = 'dm',
  ROOM = 'room',
  FAVORITE = 'favorite',
  INVITE = 'invite',
  SPACE = "SPACE"
}

@Component
struct RoomListPage {
  @Prop filterType: FilterType = FilterType.ALL;
  @State rooms: Room[] = [];
  @State isLoading: boolean = true;
  private roomManager: RoomManager = RoomManager.getInstance();
  private syncManager: SyncManager = SyncManager.getInstance();

  async aboutToAppear() {
    await this.loadRooms();

    this.syncManager.setSyncSuccessCallback(() => {
      this.loadRooms();
    });

    this.syncManager.setSyncErrorCallback((error: Error) => {
      console.error('Sync error in room list:', error);
    });

    this.syncManager.setRoomUpdatedCallback((room: Room) => {
      this.updateRoomInList(room);
    });

    this.syncManager.setRoomInvitedCallback(() => {
      this.loadRooms();
    });

    this.syncManager.setRoomLeftCallback((roomId: string) => {
      this.removeRoomFromList(roomId);
    });

    this.syncManager.setNewMessagesCallback((roomId: string, messages: Message[]) => {
      console.info('New messages in room:', roomId, messages.length);
    });
  }

  aboutToDisappear() {
    this.syncManager.clearAllCallbacks();
  }

  async loadRooms() {
    try {
      this.rooms = await this.roomManager.getRooms();
      this.rooms.sort((a, b) => {
        const timeA = a.lastEventTime || 0;
        const timeB = b.lastEventTime || 0;
        return timeB - timeA;
      });
    } catch (error) {
      console.error('Failed to load rooms:', error);
    } finally {
      this.isLoading = false;
    }
  }

  updateRoomInList(room: Room) {
    const index = this.rooms.findIndex(r => r.id === room.id);
    if (index >= 0) {
      this.rooms[index] = room;
    } else {
      this.rooms.unshift(room);
    }
    this.rooms.sort((a, b) => {
      const timeA = a.lastEventTime || 0;
      const timeB = b.lastEventTime || 0;
      return timeB - timeA;
    });
  }

  removeRoomFromList(roomId: string) {
    const index = this.rooms.findIndex(r => r.id === roomId);
    if (index >= 0) {
      this.rooms.splice(index, 1);
    }
  }

  getFilteredRooms(): Room[] {
    let filtered = this.rooms;

    if (this.filterType === FilterType.UNREAD) {
      filtered = filtered.filter(room => (room.unreadCount && room.unreadCount > 0) && room.isSpace !== true);
    } else if (this.filterType === FilterType.DM) {
      filtered = filtered.filter(room => room.isDirect === true);
    } else if (this.filterType === FilterType.ROOM) {
      filtered = filtered.filter(room => room.isDirect !== true && room.isSpace !== true);
    } else if (this.filterType === FilterType.SPACE) {
      filtered = filtered.filter(room => room.isSpace === true);
    } else {
      filtered = filtered.filter(room => room.isSpace !== true);
    }

    return filtered;
  }

  navigateToRoom(room: Room) {
    if (room.isSpace === true) {
      router.pushUrl({
        url: 'pages/SpacePage',
        params: {
          spaceId: room.id
        }
      }).catch(() => {
        // Ignore error
      });
    } else {
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
  }

  formatTimestamp(timestamp: number | undefined): string {
    if (!timestamp) {
      return '';
    }
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now.getTime() - date.getTime();

    if (diff < 60000) {
      return '刚刚';
    } else if (diff < 3600000) {
      return Math.floor(diff / 60000) + '分钟前';
    } else if (diff < 86400000) {
      return Math.floor(diff / 3600000) + '小时前';
    } else if (date.getDate() === now.getDate() &&
      date.getMonth() === now.getMonth() &&
      date.getFullYear() === now.getFullYear()) {
      return date.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' });
    } else {
      return date.toLocaleDateString('zh-CN', { month: 'short', day: 'numeric' });
    }
  }

  private getMessageBodyFromContent(content: Record<string, string | object> | undefined): string {
    if (content) {
      const body = content['body'];
      if (body !== undefined) {
        return String(body);
      }
    }
    return '';
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
        } else if (this.getFilteredRooms().length === 0) {
          Column() {
            Text('暂无房间')
              .fontSize(16)
              .fontColor('#999999');
            Text('点击上方 + 创建新房间')
              .fontSize(14)
              .fontColor('#cccccc')
              .margin({ top: 5 });
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center);
        } else {
          List() {
            ForEach(this.getFilteredRooms(), (room: Room) => {
              ListItem() {
                Row() {
                  Column() {
                    if (room.avatarUrl) {
                      Image(room.avatarUrl)
                        .width(50)
                        .height(50)
                        .borderRadius(25);
                    } else {
                      Text(room.getDisplayName().charAt(0).toUpperCase())
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#ffffff')
                        .width(50)
                        .height(50)
                        .borderRadius(25)
                        .backgroundColor('#10a37f')
                        .textAlign(TextAlign.Center);
                    }
                  }
                  .width(50)
                  .margin({ right: 12 });

                  Column() {
                    Row() {
                      Text(room.getDisplayName())
                        .fontSize(16)
                        .fontWeight(FontWeight.Medium)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .layoutWeight(1);

                      Text(this.formatTimestamp(room.lastEventTime))
                        .fontSize(12)
                        .fontColor('#999999');
                    }
                    .width('100%');

                    if (room.unreadCount && room.unreadCount > 0) {
                      Row() {
                        Text(this.getMessageBodyFromContent(room.lastEvent?.content) || '')
                          .fontSize(14)
                          .fontColor('#666666')
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .layoutWeight(1);

                        Text(room.unreadCount.toString())
                          .fontSize(12)
                          .fontColor('#ffffff')
                          .backgroundColor('#10a37f')
                          .borderRadius(10)
                          .padding({
                            left: 8,
                            right: 8,
                            top: 2,
                            bottom: 2
                          });
                      }
                      .width('100%')
                      .margin({ top: 4 });
                    } else {
                      Text(this.getMessageBodyFromContent(room.lastEvent?.content) || '')
                        .fontSize(14)
                        .fontColor('#999999')
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .margin({ top: 4 });
                    }
                  }
                  .layoutWeight(1);
                }
                .width('100%')
                .padding({
                  top: 12,
                  bottom: 12,
                  left: 20,
                  right: 20
                })
                .onClick(() => {
                  this.navigateToRoom(room);
                });
              };
            });
          }
          .width('100%')
          .layoutWeight(1);
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#ffffff');
    }
    .width('100%')
    .height('100%');
  }
}

export { RoomListPage };
