import { RoomManager } from '../services/RoomManager';
import { RoomTagManager } from '../services/RoomTagManager';
import { Room, Message } from '../models/DataModels';
import { SyncManager } from '../services/SyncManager';
import { getThemeColors } from '../utils/ThemeManager';

enum FilterType {
  ALL = 'all',
  UNREAD = 'unread',
  DM = 'dm',
  ROOM = 'room',
  FAVORITE = 'favorite',
  INVITE = 'invite',
  SPACE = "space"
}

@Builder
export function RoomListPageBuilder(name: string, param: Object) {
  RoomListPage({ filterType: param as FilterType })
}

@Entry
@Component
struct RoomListPage {
  @State filterType: FilterType = FilterType.ALL;
  @Prop pathStack: NavPathStack | null = null;
  @State rooms: Room[] = [];
  @State isLoading: boolean = true;
  @State isRefreshing: boolean = false;
  @State searchQuery: string = '';
  @State showSearch: boolean = false;
  @State favoriteRoomIds: string[] = [];
  private roomManager: RoomManager = RoomManager.getInstance();
  private roomTagManager: RoomTagManager = RoomTagManager.getInstance();
  private syncManager: SyncManager = SyncManager.getInstance();

  aboutToAppear() {
    this.loadRooms();
    this.loadFavoriteRooms();

    this.syncManager.setSyncSuccessCallback(() => {
      this.loadRooms();
      this.loadFavoriteRooms();
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

  async loadFavoriteRooms() {
    try {
      this.favoriteRoomIds = [];
      const rooms = await this.roomManager.getRooms();
      for (let i = 0; i < rooms.length; i++) {
        const room = rooms[i];
        if (room.isSpace) {
          continue;
        }
        const isFav = await this.roomTagManager.isFavorite(room.id);
        if (isFav) {
          this.favoriteRoomIds.push(room.id);
        }
      }
    } catch (error) {
      console.error('Failed to load favorite rooms:', error);
    }
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
      this.isRefreshing = false;
    }
  }

  @Builder
  buildRoomListContent() {
    List() {
      ForEach(this.getFilteredRooms(), (room: Room) => {
        ListItem() {
          Column() {
            Row() {
              Stack() {
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
                      .fontColor($r('sys.color.white'))
                      .width(50)
                      .height(50)
                      .borderRadius(25)
                      .backgroundColor(getThemeColors().primary)
                      .textAlign(TextAlign.Center);
                  }

                  if (this.favoriteRoomIds.includes(room.id)) {
                    Text('★')
                      .fontSize(14)
                      .fontColor('#FF9800')
                      .position({ x: 35, y: -3 });
                  }
                }
                .alignItems(HorizontalAlign.Start);
              }
              .width(50)
              .margin({ right: 12 });

              Column() {
                Row() {
                  Text(room.getDisplayName())
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(getThemeColors().text)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1);

                  Text(this.formatTimestamp(room.lastEventTime))
                    .fontSize(12)
                    .fontColor(getThemeColors().textSecondary);
                }
                .width('100%');

                if (room.unreadCount && room.unreadCount > 0) {
                  Row() {
                    Text(this.getMessageBodyFromContent(room.lastEvent?.content) || '')
                      .fontSize(14)
                      .fontColor(getThemeColors().textSecondary)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1);

                    Text(room.unreadCount > 99 ? '99+' : room.unreadCount.toString())
                      .fontSize(12)
                      .fontColor('#ffffff')
                      .backgroundColor(room.unreadCount > 0 ? getThemeColors().primary : '#cccccc')
                      .borderRadius(10)
                      .padding({
                        left: room.unreadCount > 99 ? 4 : 8,
                        right: room.unreadCount > 99 ? 4 : 8,
                        top: 2,
                        bottom: 2
                      });
                  }
                  .width('100%')
                  .margin({ top: 4 });
                } else {
                  Text(this.getMessageBodyFromContent(room.lastEvent?.content) || '')
                    .fontSize(14)
                    .fontColor(getThemeColors().textSecondary)
                    .opacity(0.7)
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
            .backgroundColor(getThemeColors().bg)
            .onClick(() => {
              this.navigateToRoom(room);
            });

            Divider()
              .color(getThemeColors().divider)
              .padding({ left: 82 });
          }
          .width('100%');
        };
      });
    }
    .width('100%')
    .backgroundColor(getThemeColors().bg)
    .onReachStart(() => {
    })
    .onReachEnd(() => {
    });
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
    } else if (this.filterType === FilterType.FAVORITE) {
      filtered = filtered.filter(room => this.favoriteRoomIds.includes(room.id) && room.isSpace !== true);
    } else if (this.filterType === FilterType.SPACE) {
      filtered = filtered.filter(room => room.isSpace === true);
    } else {
      filtered = filtered.filter(room => room.isSpace !== true);
    }

    if (this.searchQuery.trim()) {
      const query = this.searchQuery.toLowerCase();
      filtered = filtered.filter(room => {
        const name = room.getDisplayName().toLowerCase();
        const topic = (room.topic || '').toLowerCase();
        return name.includes(query) || topic.includes(query);
      });
    }

    return filtered;
  }

  navigateToRoom(room: Room) {
    if (room.isSpace === true) {
      const param: Record<string, string> = {
        "spaceId": room.id,
        "spaceName": room.getDisplayName()
      };
      this.pathStack?.pushPathByName('SpaceDetailPage', param);
    } else {
      const param: Record<string, string> = {
        "roomId": room.id,
        "roomName": room.getDisplayName()
      };
      this.pathStack?.pushPathByName('RoomDetailPage', param);
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

  toggleSearch() {
    this.showSearch = !this.showSearch;
    if (!this.showSearch) {
      this.searchQuery = '';
    }
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          if (this.showSearch) {
            Row() {
              TextInput({ placeholder: '搜索房间...', text: this.searchQuery })
                .width('100%')
                .height(40)
                .fontSize(16)
                .backgroundColor(getThemeColors().inputBg)
                .borderRadius(20)
                .padding({ left: 15, right: 40 })
                .onChange((value: string) => {
                  this.searchQuery = value;
                })
                .onSubmit(() => {
                });

              Button('✕')
                .fontSize(14)
                .backgroundColor('transparent')
                .fontColor(getThemeColors().textSecondary)
                .width(30)
                .height(30)
                .position({ x: '85%', y: 5 })
                .onClick(() => {
                  this.toggleSearch();
                });
            }
            .width('100%')
            .padding({
              left: 20,
              right: 20,
              top: 10,
              bottom: 10
            })
            .backgroundColor(getThemeColors().bg);
          }

          if (this.isLoading) {
            Column() {
              LoadingProgress()
                .width(40)
                .height(40)
                .color(getThemeColors().primary);
              Text('加载中...')
                .fontSize(14)
                .fontColor(getThemeColors().textSecondary)
                .margin({ top: 10 });
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center);
          } else if (this.getFilteredRooms().length === 0) {
            Column() {
              Text(this.searchQuery ? '没有找到房间' : '暂无房间')
                .fontSize(16)
                .fontColor(getThemeColors().textSecondary);
              Text(this.searchQuery ? '尝试其他关键词' : '点击上方 + 创建新房间')
                .fontSize(14)
                .fontColor(getThemeColors().textSecondary)
                .opacity(0.6)
                .margin({ top: 5 });
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center);
          } else {
            Column() {
              this.buildRoomListContent();
            }
            .width('100%')
            .layoutWeight(1);
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(getThemeColors().bg);

        Column() {
          Row() {
            Button('搜索')
              .fontSize(12)
              .backgroundColor(getThemeColors().bg)
              .fontColor(getThemeColors().primary)
              .borderRadius(20)
              .height(32)
              .onClick(() => {
                this.toggleSearch();
              });
          }
          .width(50)
          .height(50)
          .backgroundColor(getThemeColors().bg)
          .borderRadius(25)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .shadow({
            radius: 6,
            color: 'rgba(0, 0, 0, 0.1)',
            offsetX: 0,
            offsetY: 2
          })
          .onClick(() => {
            this.toggleSearch();
          });
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
        .alignItems(HorizontalAlign.End)
        .padding({ right: 20, bottom: 20 });
      }
      .width('100%')
      .height('100%');
    }
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
    })
  }
}

export { RoomListPage };
