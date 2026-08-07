import { ToastUtils } from '../utils/ToastUtils';
import { Room, Message } from '../models/DataModels';
import { RoomListPage } from './RoomListPage';
import { getThemeColors } from '../utils/ThemeManager';
import { SpacePage } from './SpacePage';
import { AppLogger } from '../utils/AppLogger';
import { ISyncManager } from '../services/SyncManager';
import { IRoomManager } from '../services/RoomManager';
import { RoomTagManager } from '../services/RoomTagManager';
import { MainContext } from '../services/facades/MainContext';

const logger = AppLogger.getLogger('MainPage');

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

// ⚠️ 注意：不要在这里加 @Entry，它现在是 Navigation 的子页面
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

  // ⚠️ 严禁使用 @State 修饰 NavPathStack 系统对象，否则会引起底层指针丢失导致闪退
  pathStack: NavPathStack = new NavPathStack();

  private mainCtx: MainContext = new MainContext();
  private isNavigating: boolean = false;
  private syncManager: ISyncManager = this.mainCtx.getSyncManager();
  private roomManager: IRoomManager = this.mainCtx.getRoomManager();
  private roomTagManager: RoomTagManager = this.mainCtx.getRoomTagManager();

  aboutToAppear() {
      this.syncStatus = 'syncing';
      const self = this;

      this.syncManager.setSyncSuccessCallback(() => {
            logger.info('Sync success callback triggered, status: ' + self.syncStatus);
            self.syncStatus = 'synced';
            logger.info('syncStatus updated to synced');
            self.loadUnreadCounts();
          });

      this.syncManager.setSyncErrorCallback(() => {
        logger.info('Sync error callback triggered');
        self.syncStatus = 'error';
      });

      this.tryInitSync();
    }

  async tryInitSync() {
    try {
      await this.syncManager.init(getContext());
      await this.syncManager.start();
      const session = this.mainCtx.getAuthManager().getSession();
      if (session) {
        const userId = session.userId;
        const colonIndex = userId.indexOf(':');
        this.userInitial = colonIndex > 0 ? userId.charAt(1).toUpperCase() : userId.charAt(0).toUpperCase();
      }
      await this.loadUserProfile();
    } catch (error) {
      logger.error('Failed to init sync: ' + error);
      this.syncStatus = 'error';
ToastUtils.show('同步初始化失败', 3000);
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
      logger.error('Failed to load unread counts:', error);
    }
  }

  async loadUserProfile() {
    try {
      const userManager = this.mainCtx.getUserManager();
      const profile = await userManager.getUserProfile();
      this.userDisplayName = profile.displayName || '';
      this.userAvatarUrl = profile.avatarUrl || '';
      if (this.userDisplayName && !this.userInitial) {
        this.userInitial = this.userDisplayName.charAt(0).toUpperCase();
      }
    } catch (error) {
      logger.error('Failed to load user profile:', error);
ToastUtils.show('用户信息加载失败', 2000);
    }
  }

  aboutToDisappear() {
    this.syncManager.stop().catch((error: Error) => {
      logger.error('Failed to stop sync:', error);
    });
  }

  async handleLogout() {
    try {
      await this.mainCtx.getAuthManager().logout();
      this.pathStack?.clear();
    } catch (error) {
      logger.error('Logout failed:', error);
ToastUtils.show('退出登录失败', 3000);
    }
  }

  navigateToSearch() {
    if (this.isNavigating) {
      return;
    }
    this.isNavigating = true;
    const param: Record<string, Object> = {};
    this.pathStack.pushPathByName('MessageSearchPage', param);
    const self = this;
    setTimeout(() => { self.isNavigating = false; }, 500);
  }

  navigateToJoinRoom() {
    if (this.isNavigating) {
      return;
    }
    this.isNavigating = true;
    const param: Record<string, Object> = {};
    this.pathStack.pushPathByName('JoinRoomPage', param);
    const self = this;
    setTimeout(() => { self.isNavigating = false; }, 500);
  }

  navigateToJoinSpace() {
    if (this.isNavigating) {
      return;
    }
    this.isNavigating = true;
    const param: Record<string, Object> = {};
    this.pathStack.pushPathByName('JoinSpacePage', param);
    const self = this;
    setTimeout(() => { self.isNavigating = false; }, 500);
  }

  navigateToSetting() {
    if (this.isNavigating) {
      return;
    }
    this.isNavigating = true;
    const param: Record<string, Object> = {};
    this.pathStack.pushPathByName('SettingsPage', param);
    const self = this;
    setTimeout(() => { self.isNavigating = false; }, 500);
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
            .fontColor(getThemeColors().onPrimary)
            .backgroundColor(getThemeColors().error)
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
          // ✅ 修复点：根据当前的 Tab 动态跳转：0是房间，1是空间
          if (this.currentIndex === 0) {
            this.navigateToJoinRoom();
          } else if (this.currentIndex === 1) {
            this.navigateToJoinSpace();
          }
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
              .fontColor(getThemeColors().error)
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

      // ✅ 修改点：仅在消息页(Index 0)显示过滤栏
      if (this.currentIndex === 0) {
        this.FilterBarBuilder();
      }

      if (this.currentIndex === 0) {
        RoomListPage({
          filterType: this.currentFilter,
          syncManager: this.syncManager,
          roomManager: this.roomManager,
          roomTagManager: this.roomTagManager,
          onNavigateToRoom: (room: Room) => {
            if (room.isSpace === true) {
              const param: Record<string, Object> = {
                "spaceId": room.id,
                "spaceName": room.getDisplayName()
              };
              this.pathStack.pushPathByName('SpaceDetailPage', param);
            } else {
              const param: Record<string, Object> = {
                "roomId": room.id,
                "roomName": room.getDisplayName()
              };
              this.pathStack.pushPathByName('RoomDetailPage', param);
            }
          }
        });
      } else {
        SpacePage({ pathStack: this.pathStack, roomManager: this.roomManager });
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