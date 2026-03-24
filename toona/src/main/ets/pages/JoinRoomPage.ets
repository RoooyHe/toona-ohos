import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { RoomManager, CreateRoomOptions } from '../services/RoomManager';
import { AuthManager } from '../services/AuthManager';
import { MatrixHttpClient } from '../network/MatrixHttpClient';

interface DirectoryUser {
  user_id: string;
  display_name?: string;
  avatar_url?: string;
}

interface GeneratedTypeLiteralInterface_1 {
  results: DirectoryUser[];
}

@Entry
@Component
struct JoinRoomPage {
  @State searchQuery: string = '';
  @State searchResults: DirectoryUser[] = [];
  @State isSearching: boolean = false;
  @State roomAddress: string = '';
  @State isJoining: boolean = false;
  @State showCreateDialog: boolean = false;
  @State newRoomName: string = '';
  private roomManager: RoomManager = RoomManager.getInstance();
  private authManager: AuthManager = AuthManager.getInstance();
  private httpClient: MatrixHttpClient | null = null;

  aboutToAppear() {
    this.httpClient = this.authManager.getHttpClient();
  }

  async searchUsers() {
    if (!this.searchQuery.trim()) {
      return;
    }

    this.isSearching = true;
    try {
      const response = await this.httpClient?.get<GeneratedTypeLiteralInterface_1>(
        `/user_directory/search?name=${encodeURIComponent(this.searchQuery.trim())}`
      );
      if (response && response.results) {
        this.searchResults = response.results;
      }
    } catch (error) {
      console.error('Search users failed:', error);
      this.searchResults = [];
    } finally {
      this.isSearching = false;
    }
  }

  async startDirectChat(userId: string) {
    try {
      const options: CreateRoomOptions = {
        isDirect: true,
        inviteUsers: [userId]
      };
      const roomId = await this.roomManager.createRoom(options);
      router.pushUrl({
        url: 'pages/RoomDetailPage',
        params: {
          roomId: roomId,
          roomName: userId
        }
      }).catch(() => {
        // TODO: Implement error handling.
      });
    } catch (error) {
      console.error('Failed to start direct chat:', error);
      promptAction.showToast({ message: '创建私聊失败' });
    }
  }

  async joinRoom() {
    if (!this.roomAddress.trim()) {
      try {
        promptAction.showToast({ message: '请输入房间地址' });
      } catch (error) {
        // TODO: Implement error handling.
      }
      return;
    }

    this.isJoining = true;
    try {
      let roomId = this.roomAddress.trim();
      if (!roomId.startsWith('#') && !roomId.includes(':')) {
        roomId = `#${roomId}:${this.authManager.getHomeserver()}`;
      }
      await this.roomManager.joinRoom(roomId);
      promptAction.showToast({ message: '加入成功' });
      router.back();
    } catch (error) {
      console.error('Failed to join room:', error);
      promptAction.showToast({ message: '加入失败' });
    } finally {
      this.isJoining = false;
    }
  }

  async createRoom() {
    if (!this.newRoomName.trim()) {
      return;
    }

    try {
      this.showCreateDialog = false;
      this.newRoomName = '';
      promptAction.showToast({ message: '创建成功' });
      router.back();
    } catch (error) {
      console.error('Failed to create room:', error);
      promptAction.showToast({ message: '创建失败' });
    }
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Button('←')
            .fontSize(24)
            .backgroundColor('transparent')
            .fontColor('#333333')
            .width(44)
            .height(44)
            .onClick(() => {
              router.back();
            });

          Text('加入房间')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1);
        }
        .width('100%')
        .padding({ left: 10, right: 10 })
        .backgroundColor('#ffffff');

        Column() {
          TextInput({ placeholder: '搜索用户进行私聊', text: this.searchQuery })
            .width('100%')
            .height(44)
            .fontSize(16)
            .backgroundColor('#f5f5f5')
            .borderRadius(10)
            .margin({ bottom: 10 })
            .onChange((value: string) => {
              this.searchQuery = value;
            })
            .onSubmit(() => {
              this.searchUsers();
            });

          Button('搜索')
            .fontSize(14)
            .backgroundColor('#10a37f')
            .fontColor('#ffffff')
            .width('100%')
            .height(40)
            .borderRadius(10)
            .onClick(() => {
              this.searchUsers();
            });

          if (this.isSearching) {
            LoadingProgress()
              .width(30)
              .height(30)
              .margin({ top: 10 });
          } else if (this.searchResults.length > 0) {
            List() {
              ForEach(this.searchResults, (user: DirectoryUser) => {
                ListItem() {
                  Row() {
                    Text(user.display_name?.charAt(0).toUpperCase() || user.user_id.charAt(0).toUpperCase())
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#ffffff')
                      .width(40)
                      .height(40)
                      .borderRadius(20)
                      .backgroundColor('#10a37f')
                      .textAlign(TextAlign.Center);

                    Column() {
                      Text(user.display_name || user.user_id)
                        .fontSize(16)
                        .fontColor('#333333');
                      Text(user.user_id)
                        .fontSize(12)
                        .fontColor('#999999');
                    }
                    .margin({ left: 12 })
                    .alignItems(HorizontalAlign.Start);
                  }
                  .width('100%')
                  .padding({ top: 10, bottom: 10 })
                  .onClick(() => {
                    this.startDirectChat(user.user_id);
                  });
                };
              });
            }
            .width('100%')
            .layoutWeight(1);
          }
        }
        .width('90%')
        .padding({ top: 15, bottom: 15 });

        Divider().color('#f0f0f0');

        Column() {
          Row() {
            Text('创建新聊天室')
              .fontSize(16)
              .fontColor('#333333');
            Blank();
            Button('+')
              .fontSize(24)
              .backgroundColor('#10a37f')
              .fontColor('#ffffff')
              .width(36)
              .height(36)
              .borderRadius(18)
              .onClick(() => {
                this.showCreateDialog = true;
              });
          }
          .width('100%')
          .padding({ top: 15, bottom: 15 });
        }
        .width('90%');

        Divider().color('#f0f0f0');

        Column() {
          Text('通过地址加入')
            .fontSize(16)
            .fontColor('#333333')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 10 });

          TextInput({ placeholder: '输入 room ID 或地址', text: this.roomAddress })
            .width('100%')
            .height(44)
            .fontSize(16)
            .backgroundColor('#f5f5f5')
            .borderRadius(10)
            .onChange((value: string) => {
              this.roomAddress = value;
            });

          Button(this.isJoining ? '加入中...' : '加入')
            .fontSize(16)
            .backgroundColor('#10a37f')
            .fontColor('#ffffff')
            .width('100%')
            .height(44)
            .borderRadius(10)
            .margin({ top: 10 })
            .enabled(!this.isJoining)
            .onClick(() => {
              this.joinRoom();
            });
        }
        .width('90%')
        .padding({ top: 15, bottom: 30 });
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#ffffff');

      if (this.showCreateDialog) {
        Column() {
          Column() {
            Text('创建聊天室')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 20 });

            TextInput({ placeholder: '房间名称' })
              .width('100%')
              .height(44)
              .fontSize(16)
              .backgroundColor('#f5f5f5')
              .borderRadius(8)
              .onChange((value: string) => {
                this.newRoomName = value;
              });

            Row() {
              Button('取消')
                .fontSize(16)
                .backgroundColor('#f5f5f5')
                .fontColor('#333333')
                .width('45%')
                .height(44)
                .borderRadius(8)
                .onClick(() => {
                  this.showCreateDialog = false;
                  this.newRoomName = '';
                });

              Button('创建')
                .fontSize(16)
                .backgroundColor('#10a37f')
                .fontColor('#ffffff')
                .width('45%')
                .height(44)
                .borderRadius(8)
                .onClick(() => {
                  this.createRoom();
                });
            }
            .width('100%')
            .margin({ top: 20 });
          }
          .width('85%')
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
    .width('100%')
    .height('100%');
  }
}
