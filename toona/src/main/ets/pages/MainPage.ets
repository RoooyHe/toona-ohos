import router from '@ohos.router';
import { AuthManager } from '../services/AuthManager';
import { SyncManager } from '../services/SyncManager';
import { RoomListPage } from './RoomListPage';

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0;

  private authManager: AuthManager = AuthManager.getInstance();
  private syncManager: SyncManager = SyncManager.getInstance();

  async aboutToAppear() {
    try {
      await this.syncManager.init(getContext(this));
      await this.syncManager.start();
    } catch (error) {
      console.error('Failed to init sync:', error);
    }
  }

  async aboutToDisappear() {
    await this.syncManager.stop();
  }

  @Builder
  TabBarBuilder(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(14)
        .fontColor(this.currentIndex === index ? '#10a37f' : '#999999')
        .margin({ top: 4 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }

  build() {
    Column() {
      Tabs({ barPosition: BarPosition.End, controller: this.tabController }) {
        TabContent() {
          RoomListPage();
        }
        .tabBar(this.TabBarBuilder('消息', 0));

        TabContent() {
          ContactsPage();
        }
        .tabBar(this.TabBarBuilder('联系人', 1));

        TabContent() {
          SettingsPage();
        }
        .tabBar(this.TabBarBuilder('设置', 2));
      }
      .width('100%')
      .height('100%')
      .barHeight(60)
      .onChange((index: number) => {
        this.currentIndex = index;
      });
    }
    .width('100%')
    .height('100%');
  }

  private tabController: TabsController = new TabsController();
}

@Component
struct ContactsPage {
  @State searchQuery: string = '';
  @State contacts: string[] = [];

  build() {
    Column() {
      Text('联系人')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ left: 20, top: 20, bottom: 15 })
        .alignSelf(HorizontalAlign.Start);

      TextInput({ placeholder: '搜索用户' })
        .width('90%')
        .height(44)
        .fontSize(16)
        .backgroundColor('#f5f5f5')
        .borderRadius(10)
        .margin({ bottom: 15 })
        .onChange((value: string) => {
          this.searchQuery = value;
        });

      if (this.contacts.length === 0) {
        Column() {
          Text('暂无联系人')
            .fontSize(16)
            .fontColor('#999999');
          Text('通过房间添加联系人')
            .fontSize(14)
            .fontColor('#cccccc')
            .margin({ top: 5 });
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else {
        List() {
          ForEach(this.contacts, (contact: string) => {
            ListItem() {
              Row() {
                Text(contact.charAt(0).toUpperCase())
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#ffffff')
                  .width(40)
                  .height(40)
                  .borderRadius(20)
                  .backgroundColor('#10a37f')
                  .textAlign(TextAlign.Center);

                Text(contact)
                  .fontSize(16)
                  .fontColor('#333333')
                  .margin({ left: 12 });
              }
              .width('100%')
              .padding({ top: 12, bottom: 12, left: 20, right: 20 });
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
}

@Component
struct SettingsPage {
  @State userId: string = '';
  @State homeserver: string = '';
  @State showLogoutDialog: boolean = false;

  private authManager: AuthManager = AuthManager.getInstance();

  aboutToAppear() {
    const session = this.authManager.getSession();
    if (session) {
      this.userId = session.userId;
      this.homeserver = session.homeServer;
    }
  }

  async handleLogout() {
    try {
      await this.authManager.logout();
      router.replaceUrl({ url: 'pages/LoginPage' });
    } catch (error) {
      console.error('Logout failed:', error);
    }
  }

  build() {
    Column() {
      Text('设置')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ left: 20, top: 20, bottom: 20 })
        .alignSelf(HorizontalAlign.Start);

      Column() {
        Row() {
          Text('账号')
            .fontSize(16)
            .fontColor('#333333');
          Blank();
          Text(this.userId)
            .fontSize(14)
            .fontColor('#999999');
        }
        .width('100%')
        .padding({ top: 15, bottom: 15 });

        Divider().color('#f0f0f0');

        Row() {
          Text('服务器')
            .fontSize(16)
            .fontColor('#333333');
          Blank();
          Text(this.homeserver)
            .fontSize(14)
            .fontColor('#999999');
        }
        .width('100%')
        .padding({ top: 15, bottom: 15 });

        Divider().color('#f0f0f0');

        Row() {
          Text('版本')
            .fontSize(16)
            .fontColor('#333333');
          Blank();
          Text('1.0.0')
            .fontSize(14)
            .fontColor('#999999');
        }
        .width('100%')
        .padding({ top: 15, bottom: 15 });
      }
      .width('90%')
      .backgroundColor('#f8f8f8')
      .borderRadius(12)
      .padding({ left: 15, right: 15 });

      Blank();

      Button('退出登录')
        .fontSize(16)
        .fontColor('#e53935')
        .backgroundColor('#ffffff')
        .width('90%')
        .height(50)
        .borderRadius(10)
        .borderWidth(1)
        .borderColor('#e53935')
        .margin({ bottom: 30 })
        .onClick(() => {
          this.showLogoutDialog = true;
        });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff');

    if (this.showLogoutDialog) {
      Column() {
        Column() {
          Text('确认退出')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 10 });

          Text('确定要退出登录吗？')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ bottom: 20 });

          Row() {
            Button('取消')
              .fontSize(16)
              .backgroundColor('#f5f5f5')
              .fontColor('#333333')
              .width('45%')
              .height(44)
              .borderRadius(8)
              .onClick(() => {
                this.showLogoutDialog = false;
              });

            Button('退出')
              .fontSize(16)
              .backgroundColor('#e53935')
              .fontColor('#ffffff')
              .width('45%')
              .height(44)
              .borderRadius(8)
              .onClick(() => {
                this.showLogoutDialog = false;
                this.handleLogout();
              });
          }
          .width('100%');
        }
        .width('80%')
        .padding(20)
        .backgroundColor('#ffffff')
        .borderRadius(16);
      }
      .width('100%')
      .height('100%')
      .backgroundColor('rgba(0, 0, 0, 0.5)')
      .justifyContent(FlexAlign.Center);
    }
  }
}
