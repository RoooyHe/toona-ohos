import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AuthManager } from '../services/AuthManager';
import { UserManager } from '../services/UserManager';
import { SyncManager } from '../services/SyncManager';
import { RoomManager } from '../services/RoomManager';
import { RoomListPage } from './RoomListPage';
import { SpacePage } from './SpacePage';
import { ThemeColors, getThemeColors } from '../utils/ThemeManager';

enum FilterType {
  ALL = 'all',
  UNREAD = 'unread',
  DM = 'dm',
  ROOM = 'room',
  FAVORITE = 'favorite',
  INVITE = 'invite'
}

@Entry
@Component
struct MainPage {
  @StorageLink('colorMode') colorMode: number = 0;
  @State currentIndex: number = 0;
  @State userInitial: string = '';
  @State userDisplayName: string = '';
  @State userAvatarUrl: string = '';
  @State showUserMenu: boolean = false;
  @State currentFilter: FilterType = FilterType.ALL;
  @State unreadCountAll: number = 0;
  @State unreadCountUnread: number = 0;
  @State unreadCountDm: number = 0;
  @State unreadCountRoom: number = 0;
  @State unreadCountInvite: number = 0;
  @State syncStatus: string = 'synced';

  private authManager: AuthManager = AuthManager.getInstance();
  private syncManager: SyncManager = SyncManager.getInstance();
  private roomManager: RoomManager = RoomManager.getInstance();

  aboutToAppear() {
    this.syncStatus = 'syncing';

    this.syncManager.setSyncSuccessCallback(() => {
      this.syncStatus = 'synced';
      this.loadUnreadCounts();
    });

    this.syncManager.setSyncErrorCallback(() => {
      this.syncStatus = 'error';
    });

    this.tryInitSync();
  }

  async tryInitSync() {
    try {
      await this.syncManager.init(getContext(this));
      await this.syncManager.start();
      const session = this.authManager.getSession();
      if (session) {
        const userId = session.userId;
        const colonIndex = userId.indexOf(':');
        this.userInitial = colonIndex > 0 ? userId.charAt(1).toUpperCase() : userId.charAt(0).toUpperCase();
      }
      await this.loadUserProfile();
    } catch (error) {
      console.error('Failed to init sync:', error);
      this.syncStatus = 'error';
    }
  }

  async loadUnreadCounts() {
    try {
      const rooms = await this.roomManager.getRooms();
      let totalUnread = 0;
      let totalDm = 0;
      let totalRoom = 0;
      let totalInvite = 0;

      for (let i = 0; i < rooms.length; i++) {
        const room = rooms[i];
        if (room.isSpace) {
          continue;
        }
        if (room.unreadCount && room.unreadCount > 0) {
          totalUnread = totalUnread + room.unreadCount;
        }
        if (room.isDirect === true && room.unreadCount && room.unreadCount > 0) {
          totalDm = totalDm + room.unreadCount;
        }
        if (room.isDirect !== true && room.unreadCount && room.unreadCount > 0) {
          totalRoom = totalRoom + room.unreadCount;
        }
      }

      this.unreadCountAll = totalUnread;
      this.unreadCountUnread = totalUnread;
      this.unreadCountDm = totalDm;
      this.unreadCountRoom = totalRoom;
      this.unreadCountInvite = totalInvite;
    } catch (error) {
      console.error('Failed to load unread counts:', error);
    }
  }

  async loadUserProfile() {
    try {
      const userManager: UserManager = UserManager.getInstance();
      const profile = await userManager.getUserProfile();
      this.userDisplayName = profile.displayName || '';
      this.userAvatarUrl = profile.avatarUrl || '';
      if (this.userDisplayName && !this.userInitial) {
        this.userInitial = this.userDisplayName.charAt(0).toUpperCase();
      }
    } catch (error) {
      console.error('Failed to load user profile:', error);
    }
  }

  getSyncStatusIcon(): Resource {
    if (this.syncStatus === 'syncing') {
      return $r('app.media.sync_indicator');
    } else if (this.syncStatus === 'error') {
      return $r('app.media.error_indicator');
    }
    return $r('app.media.check_indicator');
  }

  async aboutToDisappear() {
    await this.syncManager.stop();
  }

  async handleLogout() {
    try {
      await this.authManager.logout();
      router.replaceUrl({ url: 'pages/LoginPage' }).catch(() => {
        // TODO: Implement error handling.
      });
    } catch (error) {
      console.error('Logout failed:', error);
    }
  }

  navigateToSearch() {
    router.pushUrl({ url: 'pages/SearchPage' }).catch(() => {
      // TODO: Implement error handling.
    });
  }

  navigateToJoinRoom() {
    router.pushUrl({ url: 'pages/JoinRoomPage' }).catch(() => {
      // TODO: Implement error handling.
    });
  }

  navigateToSetting() {
    router.pushUrl({ url: 'pages/SettingsPage' }).catch(() => {
      // TODO: Implement error handling.
    });
  }

  setFilter(filter: FilterType) {
    this.currentFilter = filter;
  }

  @Builder
  FilterBarBuilder() {
    Row() {
      this.FilterTabBuilder('全部', FilterType.ALL, this.unreadCountAll);

      Blank().width(20);

      this.FilterTabBuilder('未读', FilterType.UNREAD, this.unreadCountUnread);

      Blank().width(20);

      this.FilterTabBuilder('用户', FilterType.DM, this.unreadCountDm);

      Blank().width(20);

      this.FilterTabBuilder('聊天室', FilterType.ROOM, this.unreadCountRoom);

      Blank().width(20);

      this.FilterTabBuilder('收藏', FilterType.FAVORITE, 0);

      Blank().width(20);

      this.FilterTabBuilder('邀请', FilterType.INVITE, this.unreadCountInvite);
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 10, bottom: 10 })
    .backgroundColor(getThemeColors().bg);
  }

  @Builder
  FilterTabBuilder(label: string, filter: FilterType, count: number) {
    Column() {
      Row() {
        if (this.currentFilter === filter) {
          Text(label)
            .fontSize(14)
            .fontColor(getThemeColors().primary)
            .decoration({ type: TextDecorationType.Underline, color: getThemeColors().primary })
            .padding({ bottom: 4 });
        } else {
          Text(label)
            .fontSize(14)
            .fontColor(getThemeColors().textSecondary)
            .onClick(() => {
              this.setFilter(filter);
            });
        }

        if (count > 0) {
          Text(count > 99 ? '99+' : count.toString())
            .fontSize(10)
            .fontColor('#ffffff')
            .backgroundColor('#e53935')
            .borderRadius(10)
            .padding({
              left: count > 99 ? 4 : 6,
              right: count > 99 ? 4 : 6,
              top: 2,
              bottom: 2
            })
            .margin({ left: 4 });
        }
      }
    }
    .onClick(() => {
      this.setFilter(filter);
    });
  }

  @Builder
  TabBarBuilder(index: number) {
    if (index === 0) {
      Row() {
        Image($r('app.media.message'))
          .width(24)
          .height(24)
          .objectFit(ImageFit.Contain);
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(this.currentIndex === index ? getThemeColors().tabBg : getThemeColors().bg)
      .borderRadius(20)
      .onClick(() => {
        this.currentIndex = index;
      });
    } else if (index === 1) {
      Row() {
        Image($r('app.media.space'))
          .width(24)
          .height(24)
          .objectFit(ImageFit.Contain);
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(this.currentIndex === index ? getThemeColors().tabBg : getThemeColors().bg)
      .borderRadius(20)
      .onClick(() => {
        this.currentIndex = index;
      });
    }
  }

  build() {
    Stack() {
      Column() {
        Row() {
          if (this.userInitial) {
            Text(this.userInitial)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#ffffff')
              .width(36)
              .height(36)
              .borderRadius(18)
              .backgroundColor(getThemeColors().primary)
              .textAlign(TextAlign.Center)
              .onClick(() => this.navigateToSetting);
          }

          Text(this.currentIndex === 0 ? '全部消息' : '空间')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(getThemeColors().text)
            .margin({ left: 12 });

          Blank();

          if (this.syncStatus === 'syncing') {
            Row() {
              LoadingProgress()
                .width(20)
                .height(20)
                .color(getThemeColors().primary);
              Text('同步中')
                .fontSize(12)
                .fontColor(getThemeColors().textSecondary)
                .margin({ left: 4 });
            }
            .margin({ right: 12 });
          } else if (this.syncStatus === 'error') {
            Row() {
              Image($r('app.media.error_indicator'))
                .width(16)
                .height(16);
              Text('同步失败')
                .fontSize(12)
                .fontColor('#e53935')
                .margin({ left: 4 });
            }
            .margin({ right: 12 })
            .onClick(() => {
              this.tryInitSync();
            });
          }

          Image($r('app.media.search'))
            .width(24)
            .height(24)
            .objectFit(ImageFit.Contain)
            .onClick(() => {
              this.navigateToSearch();
            });
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 10, bottom: 5 })
        .backgroundColor(getThemeColors().bg);

        this.FilterBarBuilder();

        if (this.currentIndex === 0) {
          RoomListPage({ filterType: this.currentFilter });
        } else {
          SpacePage();
        }
      }
      .width('100%')
      .height('100%');

      Column() {
        Row() {
          Blank();

          Row() {
            Stack() {
              if (this.currentIndex === 0) {
                Row()
                  .width(64)
                  .height(40)
                  .borderRadius(20)
                  .backgroundColor(getThemeColors().tabBg);
              }

              Image($r('app.media.message'))
                .width(36)
                .height(36)
                .objectFit(ImageFit.Contain)
                .fillColor(this.currentIndex === 0 ? getThemeColors().primary : getThemeColors().textSecondary);
            }
            .width(48)
            .height(48)
            .onClick(() => {
              this.currentIndex = 0;
            });

            Stack() {
              if (this.currentIndex === 1) {
                Row()
                  .width(64)
                  .height(40)
                  .borderRadius(20)
                  .backgroundColor(getThemeColors().tabBg);
              }

              Image($r('app.media.space'))
                .width(36)
                .height(36)
                .objectFit(ImageFit.Contain)
                .fillColor(this.currentIndex === 1 ? getThemeColors().primary : getThemeColors().textSecondary);
            }
            .width(48)
            .height(48)
            .onClick(() => {
              this.currentIndex = 1;
            });
          }
          .height(48)
          .backgroundColor(getThemeColors().bg)
          .borderRadius(28)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .shadow({
            radius: 10,
            color: 'rgba(0, 0, 0, 0.1)',
            offsetX: 0,
            offsetY: 3
          });

          Blank().width(24);

          Row() {
            Image($r('app.media.add'))
              .width(36)
              .height(36)
              .objectFit(ImageFit.Contain);
          }
          .width(56)
          .height(56)
          .backgroundColor(getThemeColors().primary)
          .borderRadius(28)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .shadow({
            radius: 12,
            color: 'rgba(0, 0, 0, 0.2)',
            offsetX: 0,
            offsetY: 4
          })
          .onClick(() => {
            this.navigateToJoinRoom();
          });

          Blank();
        }
        .width('100%')
        .height(64)
        .padding({ left: 40, right: 40 })
        .alignItems(VerticalAlign.Bottom);
      }
      .width('100%')
      .position({ x: 0, y: '100%' })
      .translate({ x: 0, y: -64 });

      if (this.showUserMenu) {
        Column() {
          Column() {
            Row() {
              if (this.userAvatarUrl) {
                Image(this.userAvatarUrl)
                  .width(40)
                  .height(40)
                  .borderRadius(20);
              } else {
                Text(this.userInitial)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#ffffff')
                  .width(40)
                  .height(40)
                  .borderRadius(20)
                  .backgroundColor(getThemeColors().primary)
                  .textAlign(TextAlign.Center);
              }
              Column() {
                Text(this.userDisplayName || this.authManager.getSession()?.userId || '用户')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(getThemeColors().text);
                Text(this.authManager.getSession()?.userId || '')
                  .fontSize(11)
                  .fontColor(getThemeColors().textSecondary);
              }
              .margin({ left: 10 })
              .alignItems(HorizontalAlign.Start);
            }
            .width('100%')
            .padding({ left: 15, right: 15, top: 15, bottom: 10 });

            Divider().color(getThemeColors().divider);

            Text('设置')
              .fontSize(14)
              .fontColor(getThemeColors().text)
              .width('100%')
              .height(40)
              .padding({ left: 15 })
              .textAlign(TextAlign.Start)
              .onClick(() => {
                this.showUserMenu = false;
                router.pushUrl({ url: 'pages/SettingsPage' }).catch(() => {
                });
              });

            Divider().color(getThemeColors().divider);

            Text('退出登录')
              .fontSize(14)
              .fontColor('#e53935')
              .width('100%')
              .height(40)
              .padding({ left: 15 })
              .textAlign(TextAlign.Start)
              .onClick(() => {
                this.showUserMenu = false;
                this.handleLogout();
              });
          }
          .width(220)
          .backgroundColor(getThemeColors().bg)
          .borderRadius(8)
          .shadow({
            radius: 10,
            color: 'rgba(0, 0, 0, 0.15)',
            offsetX: 0,
            offsetY: 2
          });
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
        .padding({ right: 20, top: 60 });
      }
    }
    .width('100%')
    .height('100%');
  }
}
