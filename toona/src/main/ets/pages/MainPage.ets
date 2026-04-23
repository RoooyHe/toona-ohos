import promptAction from '@ohos.promptAction';
import { AuthManager } from '../services/AuthManager';
import { UserManager } from '../services/UserManager';
import { SyncManager } from '../services/SyncManager';
import { RoomManager } from '../services/RoomManager';
import { Room, Message } from '../models/DataModels';
import { RoomListPage } from './RoomListPage';
import { getThemeColors } from '../utils/ThemeManager';
import { SpacePage } from './SpacePage';

enum FilterType {
  ALL = 'all',
  UNREAD = 'unread',
  DM = 'dm',
  ROOM = 'room',
  FAVORITE = 'favorite',
  INVITE = 'invite'
}

@Builder
export function MainPageBuilder(name: string, param: Object) {
  MainPage()
}

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0;
  @State userInitial: string = '';
  @State userDisplayName: string = '';
  @State userAvatarUrl: string = '';
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
  @State pathStack: NavPathStack = new NavPathStack();

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
      await this.syncManager.init(getContext());
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
      promptAction.showToast({
        message: '同步初始化失败',
        duration: 3000
      });
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
      promptAction.showToast({
        message: '用户信息加载失败',
        duration: 2000
      });
    }
  }

  aboutToDisappear() {
    this.syncManager.stop().catch((error: Error) => {
      console.error('Failed to stop sync:', error);
    });
  }

  async handleLogout() {
    try {
      await this.authManager.logout();
      this.pathStack?.clear();
    } catch (error) {
      console.error('Logout failed:', error);
      promptAction.showToast({
        message: '退出登录失败',
        duration: 3000
      });
    }
  }

  navigateToSearch() {
      this.pathStack.pushPathByName('SearchPage', undefined);
  }

  navigateToJoinRoom() {
      this.pathStack.pushPathByName('JoinRoomPage', undefined);
  }

  navigateToSetting() {
      if (this.pathStack) {
        this.pathStack.pushPathByName('SettingsPage', undefined);
      }
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
    .padding({
      left: 20,
      right: 20,
      top: 10,
      bottom: 10
    })
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
            .fontColor($r('sys.color.white'))
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
  MainTabBar() {
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
        .padding({
          left: 10,
          right: 10,
          top: 4,
          bottom: 4
        })
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
  }

  @Builder
  MainContent() {
    Column() {
      Row() {
        if (this.userInitial) {
          Row() {
            Text(this.userInitial)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.white'))
              .width(36)
              .height(36)
              .borderRadius(18)
              .backgroundColor(getThemeColors().primary)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.navigateToSetting();
              });
          }
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
      .padding({
        left: 20,
        right: 20,
        top: 10,
        bottom: 5
      })
      .backgroundColor(getThemeColors().bg);

      this.FilterBarBuilder();

      if (this.currentIndex === 0) {
        RoomListPage({
          filterType: this.currentFilter,
          onNavigateToRoom: (room: Room) => {
            if (room.isSpace === true) {
              const param: Record<string, string> = {
                "spaceId": room.id,
                "spaceName": room.getDisplayName()
              };
              this.pathStack.pushPathByName('SpaceDetailPage', param);
            } else {
              const param: Record<string, string> = {
                "roomId": room.id,
                "roomName": room.getDisplayName()
              };
              this.pathStack.pushPathByName('RoomDetailPage', param);
            }
          }
        });
      } else {
        SpacePage({ pathStack: this.pathStack });
      }
    }
    .width('100%')
    .height('100%');
  }

  build() {
    NavDestination() {
      this.MainContent();
      this.MainTabBar();
    }
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
    })
    .hideTitleBar(true);
  }
}
