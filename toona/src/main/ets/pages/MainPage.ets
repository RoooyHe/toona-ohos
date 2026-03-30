import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AuthManager } from '../services/AuthManager';
import { UserManager } from '../services/UserManager';
import { SyncManager } from '../services/SyncManager';
import { RoomManager } from '../services/RoomManager';
import { RoomListPage } from './RoomListPage';
import { SpacePage } from './SpacePage';
import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant';

enum FilterType {
  ALL = 'all',
  UNREAD = 'unread',
  DM = 'dm',
  ROOM = 'room',
  FAVORITE = 'favorite',
  INVITE = 'invite'
}

interface UserProfile {
  displayName: string | null;
  avatarUrl: string | null;
}

@Entry
@Component
struct MainPage {
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
  @State isDarkMode: boolean = false;
  @State syncStatus: string = 'synced';
  @State showCreateMenu: boolean = false;

  private authManager: AuthManager = AuthManager.getInstance();
  private syncManager: SyncManager = SyncManager.getInstance();
  private roomManager: RoomManager = RoomManager.getInstance();

  aboutToAppear() {
    const colorMode = AppStorage.get<number>('colorMode');
    this.isDarkMode = colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;

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
      const profile: UserProfile = await UserManager.getUserProfile();
      this.userDisplayName = profile.displayName || '';
      this.userAvatarUrl = profile.avatarUrl || '';
      if (this.userDisplayName && !this.userInitial) {
        this.userInitial = this.userDisplayName.charAt(0).toUpperCase();
      }
    } catch (error) {
      console.error('Failed to load user profile:', error);
    }
  }

  getThemeColors() {
    return {
      bg: this.isDarkMode ? '#1a1a1a' : '#ffffff',
      text: this.isDarkMode ? '#ffffff' : '#333333',
      textSecondary: this.isDarkMode ? '#999999' : '#999999',
      primary: '#10a37f',
      tabBg: this.isDarkMode ? '#2a2a2a' : '#f0f0f0',
      divider: this.isDarkMode ? '#3a3a3a' : '#f0f0f0'
    };
  }

  toggleDarkMode() {
    this.isDarkMode = !this.isDarkMode;
    const newMode = this.isDarkMode ? ConfigurationConstant.ColorMode.COLOR_MODE_DARK : ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
    AppStorage.setOrCreate('colorMode', newMode);
  }

  getSyncStatusIcon(): Resource {
    if (this.syncStatus === 'syncing') {
      return $r('app.media.sync_indicator');
    } else if (this.syncStatus === 'error') {
      return $r('app.media.error_indicator');
    }
    return $r('app.media.check_indicator');
  }

  navigateToCreateRoom() {
    router.pushUrl({ url: 'pages/CreateRoomPage' }).catch(() => {
    });
    this.showCreateMenu = false;
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
    .backgroundColor(this.getThemeColors().bg);
  }

  @Builder
  FilterTabBuilder(label: string, filter: FilterType, count: number) {
    Column() {
      Row() {
        if (this.currentFilter === filter) {
          Text(label)
            .fontSize(14)
            .fontColor(this.getThemeColors().primary)
            .decoration({ type: TextDecorationType.Underline, color: this.getThemeColors().primary })
            .padding({ bottom: 4 });
        } else {
          Text(label)
            .fontSize(14)
            .fontColor(this.getThemeColors().textSecondary)
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
        Text('Matrix Room')
          .fontSize(12)
          .fontColor(this.currentIndex === index ? this.getThemeColors().textSecondary : this.getThemeColors().primary)
          .margin({ left: 4 });
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(this.currentIndex === index ? this.getThemeColors().tabBg : this.getThemeColors().bg)
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
        Text('Matrix Space')
          .fontSize(12)
          .fontColor(this.currentIndex === index ? this.getThemeColors().textSecondary : this.getThemeColors().primary)
          .margin({ left: 4 });
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(this.currentIndex === index ? this.getThemeColors().tabBg : this.getThemeColors().bg)
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
              .backgroundColor(this.getThemeColors().primary)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.showUserMenu = !this.showUserMenu;
              });
          }

          Text(this.currentIndex === 0 ? '全部消息' : '空间')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getThemeColors().text)
            .margin({ left: 12 });

          Blank();

          if (this.syncStatus === 'syncing') {
            Row() {
              LoadingProgress()
                .width(20)
                .height(20)
                .color(this.getThemeColors().primary);
              Text('同步中')
                .fontSize(12)
                .fontColor(this.getThemeColors().textSecondary)
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
        .backgroundColor(this.getThemeColors().bg);

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
          this.TabBarBuilder(0);
          Blank();
          Column() {
            if (this.showCreateMenu) {
              Row() {
                Text('创建聊天室')
                  .fontSize(12)
                  .fontColor(this.getThemeColors().text)
                  .padding({ left: 12, right: 12, top: 8, bottom: 8 });
              }
              .backgroundColor(this.getThemeColors().bg)
              .borderRadius(8)
              .shadow({
                radius: 4,
                color: 'rgba(0, 0, 0, 0.1)',
                offsetX: 0,
                offsetY: 2
              })
              .margin({ bottom: 8 })
              .onClick(() => {
                this.showCreateMenu = false;
                this.navigateToCreateRoom();
              });

              Row() {
                Text('加入聊天室')
                  .fontSize(12)
                  .fontColor(this.getThemeColors().text)
                  .padding({ left: 12, right: 12, top: 8, bottom: 8 });
              }
              .backgroundColor(this.getThemeColors().bg)
              .borderRadius(8)
              .shadow({
                radius: 4,
                color: 'rgba(0, 0, 0, 0.1)',
                offsetX: 0,
                offsetY: 2
              })
              .onClick(() => {
                this.showCreateMenu = false;
                this.navigateToJoinRoom();
              });
            }

            Row() {
              Image($r('app.media.add'))
                .width(24)
                .height(24)
                .objectFit(ImageFit.Contain);
            }
            .width(48)
            .height(48)
            .backgroundColor(this.getThemeColors().primary)
            .borderRadius(24)
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.showCreateMenu = !this.showCreateMenu;
            });
          }
          Blank();
          this.TabBarBuilder(1);
        }
        .width('100%')
        .height(48)
        .padding({ left: 20, right: 20 })
        .alignItems(VerticalAlign.Bottom);
      }
      .width('100%')
      .position({ x: 0, y: '100%' })
      .translate({ x: 0, y: -48 });

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
                  .backgroundColor(this.getThemeColors().primary)
                  .textAlign(TextAlign.Center);
              }
              Column() {
                Text(this.userDisplayName || this.authManager.getSession()?.userId || '用户')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.getThemeColors().text);
                Text(this.authManager.getSession()?.userId || '')
                  .fontSize(11)
                  .fontColor(this.getThemeColors().textSecondary);
              }
              .margin({ left: 10 })
              .alignItems(HorizontalAlign.Start);
            }
            .width('100%')
            .padding({ left: 15, right: 15, top: 15, bottom: 10 });

            Divider().color(this.getThemeColors().divider);

            Text('深色模式')
              .fontSize(14)
              .fontColor(this.getThemeColors().text)
              .width('100%')
              .height(40)
              .padding({ left: 15 })
              .textAlign(TextAlign.Start)
              .onClick(() => {
                this.toggleDarkMode();
              });

            Divider().color(this.getThemeColors().divider);

            Text('设置')
              .fontSize(14)
              .fontColor(this.getThemeColors().text)
              .width('100%')
              .height(40)
              .padding({ left: 15 })
              .textAlign(TextAlign.Start)
              .onClick(() => {
                this.showUserMenu = false;
                router.pushUrl({ url: 'pages/SettingsPage' }).catch(() => {
                });
              });

            Divider().color(this.getThemeColors().divider);

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
          .backgroundColor(this.getThemeColors().bg)
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
