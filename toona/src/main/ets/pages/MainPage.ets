import { ToastUtils } from '../utils/ToastUtils';
import { Room, Message } from '../models/DataModels';
import { RoomListPage } from './RoomListPage';
import { getThemeColors } from '../utils/ThemeManager';
import { SpacePage } from './SpacePage';
import { AppLogger } from '../utils/AppLogger';
import { MainViewModel, MainState } from '../viewmodels/MainViewModel';

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

  private isNavigating: boolean = false;
  private vm: MainViewModel = new MainViewModel();

  aboutToAppear() {
    const self = this;

    this.vm.setOnStateChanged((state: MainState) => {
      self.userInitial = state.userInitial;
      self.userDisplayName = state.userDisplayName;
      self.userAvatarUrl = state.userAvatarUrl;
      self.currentFilter = state.currentFilter as FilterType;
      self.unreadCountAll = state.unreadCountAll;
      self.unreadCountUnread = state.unreadCountUnread;
      self.unreadCountDm = state.unreadCountDm;
      self.unreadCountRoom = state.unreadCountRoom;
      self.unreadCountInvite = state.unreadCountInvite;
      self.syncStatus = state.syncStatus;
    });

    this.vm.setLogoutCallback(() => {
      self.pathStack?.clear();
    });

    this.vm.initialize();
  }

  aboutToDisappear() {
    this.vm.destroy();
  }

  async handleLogout() {
    await this.vm.handleLogout();
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
    this.vm.setFilter(filter as string);
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
            this.vm.tryInitSync();
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
          syncManager: this.vm.getSyncManager(),
          roomManager: this.vm.getRoomManager(),
          roomTagManager: this.vm.getRoomTagManager(),
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
        SpacePage({ pathStack: this.pathStack, roomManager: this.vm.getRoomManager() });
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
