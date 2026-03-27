import router from '@ohos.router';
import { AuthManager } from '../services/AuthManager';
import { SyncManager } from '../services/SyncManager';
import { RoomListPage } from './RoomListPage';
import { SpacePage } from './SpacePage';

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
  @State currentIndex: number = 0;
  @State userInitial: string = '';
  @State showUserMenu: boolean = false;
  @State currentFilter: FilterType = FilterType.ALL;

  private authManager: AuthManager = AuthManager.getInstance();
  private syncManager: SyncManager = SyncManager.getInstance();

  async aboutToAppear() {
    try {
      await this.syncManager.init(getContext(this));
      await this.syncManager.start();
      const session = this.authManager.getSession();
      if (session) {
        const userId = session.userId;
        const colonIndex = userId.indexOf(':');
        this.userInitial = colonIndex > 0 ? userId.charAt(1).toUpperCase() : userId.charAt(0).toUpperCase();
      }
    } catch (error) {
      console.error('Failed to init sync:', error);
    }
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
      if (this.currentFilter === FilterType.ALL) {
        Text('全部消息')
          .fontSize(14)
          .fontColor('#10a37f')
          .decoration({ type: TextDecorationType.Underline, color: '#10a37f' })
          .padding({ bottom: 4 });
      } else {
        Text('全部消息')
          .fontSize(14)
          .fontColor('#999999')
          .onClick(() => {
            this.setFilter(FilterType.ALL);
          });
      }

      Blank().width(20);

      if (this.currentFilter === FilterType.UNREAD) {
        Text('未读')
          .fontSize(14)
          .fontColor('#10a37f')
          .decoration({ type: TextDecorationType.Underline, color: '#10a37f' })
          .padding({ bottom: 4 });
      } else {
        Text('未读')
          .fontSize(14)
          .fontColor('#999999')
          .onClick(() => {
            this.setFilter(FilterType.UNREAD);
          });
      }

      Blank().width(20);

      if (this.currentFilter === FilterType.DM) {
        Text('用户')
          .fontSize(14)
          .fontColor('#10a37f')
          .decoration({ type: TextDecorationType.Underline, color: '#10a37f' })
          .padding({ bottom: 4 });
      } else {
        Text('用户')
          .fontSize(14)
          .fontColor('#999999')
          .onClick(() => {
            this.setFilter(FilterType.DM);
          });
      }

      Blank().width(20);

      if (this.currentFilter === FilterType.ROOM) {
        Text('聊天室')
          .fontSize(14)
          .fontColor('#10a37f')
          .decoration({ type: TextDecorationType.Underline, color: '#10a37f' })
          .padding({ bottom: 4 });
      } else {
        Text('聊天室')
          .fontSize(14)
          .fontColor('#999999')
          .onClick(() => {
            this.setFilter(FilterType.ROOM);
          });
      }

      Blank().width(20);

      if (this.currentFilter === FilterType.INVITE) {
        Text('邀请')
          .fontSize(14)
          .fontColor('#10a37f')
          .decoration({ type: TextDecorationType.Underline, color: '#10a37f' })
          .padding({ bottom: 4 });
      } else {
        Text('邀请')
          .fontSize(14)
          .fontColor('#999999')
          .onClick(() => {
            this.setFilter(FilterType.INVITE);
          });
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 10, bottom: 10 })
    .backgroundColor('#ffffff');
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
          .fontColor(this.currentIndex === index ? '#999999' : '#10a37f')
          .margin({ left: 4 });
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(this.currentIndex === index ? '#f0f0f0' : '#ffffff')
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
          .fontColor(this.currentIndex === index ? '#999999' : '#10a37f')
          .margin({ left: 4 });
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(this.currentIndex === index ? '#f0f0f0' : '#ffffff')
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
              .backgroundColor('#10a37f')
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.showUserMenu = !this.showUserMenu;
              });
          }

          Text(this.currentIndex === 0 ? '全部消息' : '空间')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .margin({ left: 12 });

          Blank();

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
        .backgroundColor('#ffffff');

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
          Row() {
            Image($r('app.media.add'))
              .width(24)
              .height(24)
              .objectFit(ImageFit.Contain);
          }
          .width(48)
          .height(48)
          .backgroundColor('#10a37f')
          .borderRadius(24)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.navigateToJoinRoom();
          });
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
            Text('退出登录')
              .fontSize(16)
              .fontColor('#e53935')
              .width('100%')
              .height(44)
              .textAlign(TextAlign.Center)
              .onClick(() => {
                this.showUserMenu = false;
                this.handleLogout();
              });
          }
          .width(160)
          .backgroundColor('#ffffff')
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
