import { ToastUtils } from '../utils/ToastUtils';
import { QuickDialogManager, QuickDialogParams, QuickDialogController, QuickDialogDecoratorParams } from 'quickdialog';
import { RoomManager, CreateRoomOptions } from '../services/RoomManager';
import { AuthManager } from '../services/AuthManager';
import { MatrixHttpClient } from '../network/MatrixHttpClient';
import { ScanManager } from '../services/ScanManager';
import { getThemeColors } from '../utils/ThemeManager';
import { AppLogger } from '../utils/AppLogger';

interface CreateRoomDialogData {
  roomName: string;
  isPublic: boolean;
}

const logger = AppLogger.getLogger('JoinRoomPage');

// 创建聊天室弹窗 - 内容组件
@Component
struct CreateRoomDialogContent {
  private dialogParams: QuickDialogParams | undefined = undefined
  private dialogController: QuickDialogController | undefined = undefined
  @State roomName: string = ''
  @State isPublic: boolean = false

  aboutToAppear() {
    if (this.dialogParams) {
      this.dialogController = this.dialogParams.controller
    }
  }

  build() {
    Column() {
      Text('创建聊天室')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#ff333333')
        .margin({ bottom: 20 })

      TextInput({ placeholder: '房间名称' })
        .width('100%')
        .height(44)
        .fontSize(16)
        .backgroundColor('#fff5f5f5')
        .borderRadius(8)
        .onChange((value: string) => {
          this.roomName = value;
        })

      Row() {
        Text('设为公开房间')
          .fontSize(14)
          .fontColor('#ff333333')
        Blank()
        Toggle({ type: ToggleType.Switch, isOn: this.isPublic })
          .selectedColor(getThemeColors().primary)
          .onChange((isOn: boolean) => {
            this.isPublic = isOn
          })
      }
      .width('100%')
      .margin({ top: 12 })

      Row() {
        Button('取消')
          .fontSize(16)
          .backgroundColor('#fff5f5f5')
          .fontColor('#ff333333')
          .width('45%')
          .height(44)
          .borderRadius(8)
          .onClick(() => {
            this.dialogController?.dismiss()
          })

        Button('创建')
          .fontSize(16)
          .backgroundColor(getThemeColors().primary)
          .fontColor('#ffffff')
          .width('45%')
          .height(44)
          .borderRadius(8)
          .onClick(() => {
            this.dialogController?.callEventFromDialog('confirm', {
              roomName: this.roomName,
              isPublic: this.isPublic
            } as CreateRoomDialogData)
          })
      }
      .width('100%')
      .margin({ top: 20 })
    }
    .width('85%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}

// 创建聊天室弹窗 - Builder
@Builder
function CreateRoomDialogBuilder(dialogParams: QuickDialogParams) {
  CreateRoomDialogContent({ dialogParams: dialogParams })
}

// 创建聊天室弹窗 - 装饰器（半透明背景）
@Builder
function CreateRoomDialogDecorator(decoratorParams: QuickDialogDecoratorParams) {
  Stack() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor('rgba(0, 0, 0, 0.5)')

    NodeContainer(
      QuickDialogManager.decoratorCreateContentNodeController(decoratorParams)
    )
  }
}

interface DirectoryUser {
  user_id: string;
  display_name?: string;
  avatar_url?: string;
}

interface DirectorySearchResponse {
  results: DirectoryUser[];
}

@Builder
export function JoinRoomPageBuilder(name: string, param: Object) {
  JoinRoomPage({
    pathStack: ((param as Record<string, Object>)['pathStack'] as NavPathStack) || new NavPathStack()
  })
}

@Component
struct JoinRoomPage {
  @State searchQuery: string = '';
  @State searchResults: DirectoryUser[] = [];
  @State isSearching: boolean = false;
  @State roomAddress: string = '';
  @State isJoining: boolean = false;
  private createRoomDialogController: QuickDialogController | undefined = undefined;
  private roomManager: RoomManager = RoomManager.getInstance();
  private authManager: AuthManager = AuthManager.getInstance();
  private httpClient: MatrixHttpClient | null = null;
  private scanManager: ScanManager = ScanManager.getInstance();
  @Prop pathStack: NavPathStack;

  aboutToAppear() {
    this.httpClient = this.authManager.getHttpClient();
  }

  async searchUsers() {
    if (!this.searchQuery.trim()) {
      return;
    }

    this.isSearching = true;
    try {
      const response = await this.httpClient?.get<DirectorySearchResponse>(
        `/user_directory/search?name=${encodeURIComponent(this.searchQuery.trim())}`
      );
      if (response && response.results) {
        this.searchResults = response.results;
      }
    } catch (error) {
      logger.error('Search users failed:', error);
      this.searchResults = [];
    } finally {
      this.isSearching = false;
    }
  }

  startDirectChat(userId: string) {
    this.doStartDirectChat(userId).catch((error: Error) => {
      logger.error('Failed to start direct chat:', error);
      ToastUtils.show('创建私聊失败');
    });
  }

  async doStartDirectChat(userId: string): Promise<void> {
    const options: CreateRoomOptions = {
      isDirect: true,
      inviteUsers: [userId]
    };
    const roomId = await this.roomManager.createRoom(options);
    const param: Record<string, Object> = {
      "roomId": roomId,
      "roomName": userId,
      "pathStack": this.pathStack
    };
    this.pathStack.pushPathByName('RoomDetailPage', param);
  }

  async onScanQRCode() {
    try {
      const result = await this.scanManager.startScan();
      if (result) {
        const parsed = this.scanManager.parseMatrixToLink(result);
        if (parsed && parsed.roomId) {
          this.roomAddress = parsed.roomId;
          ToastUtils.show('已识别房间，可点击加入');
        } else {
          this.roomAddress = result;
          ToastUtils.show('已扫描内容');
        }
      }
    } catch (error) {
      logger.error('Scan error: %{public}s', error.message);
      ToastUtils.show('扫码失败');
    }
  }

  joinRoom() {
    if (!this.roomAddress.trim()) {
      ToastUtils.show('请输入房间地址');
      return;
    }

    this.isJoining = true;
    const self = this;
    this.doJoinRoom().catch((error: Error) => {
      logger.error('Failed to join room:', error);
      ToastUtils.show('加入失败');
    }).finally(() => {
      self.isJoining = false;
    });
  }

  async doJoinRoom(): Promise<void> {
    let roomId = this.roomAddress.trim();
    if (!roomId.startsWith('#') && !roomId.includes(':')) {
      roomId = `#${roomId}:${this.authManager.getHomeserver()}`;
    }
    await this.roomManager.joinRoom(roomId);
    ToastUtils.show('加入成功');
    this.pathStack?.pop();
  }

  createRoom() {
    const self = this;
    // 通过 QuickDialog 展示创建聊天室弹窗
    this.createRoomDialogController = QuickDialogManager.newBuilder(
      this.getUIContext(),
      wrapBuilder(CreateRoomDialogBuilder),
      wrapBuilder(CreateRoomDialogDecorator)
    )
      .onEvent<Record<string, Object>>('confirm', (controller, param) => {
        const roomName = param?.['roomName'] as string || '';
        const isPublic = param?.['isPublic'] as boolean || false;
        controller.dismiss();
        self.doCreateRoom(roomName, isPublic).catch((error: Error) => {
          logger.error('Failed to create room:', error);
          ToastUtils.show('创建失败');
        });
      })
      .build();
    this.createRoomDialogController.show();
  }

  async doCreateRoom(roomName: string, isPublic: boolean): Promise<void> {
    const options: CreateRoomOptions = {
      name: roomName.trim(),
      visibility: isPublic ? 'public' : 'private'
    };
    await this.roomManager.createRoom(options);
    ToastUtils.show('创建成功');
    this.pathStack?.pop();
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          Row() {
            Text('加入房间')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(getThemeColors().text)
              .layoutWeight(1);
          }
          .width('100%')
          .padding({ left: 10, right: 10 })
          .backgroundColor(getThemeColors().bg);

          Column() {
            TextInput({ placeholder: '搜索用户进行私聊', text: this.searchQuery })
              .width('100%')
              .height(44)
              .fontSize(16)
              .backgroundColor(getThemeColors().inputBg)
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
              .backgroundColor(getThemeColors().primary)
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
                        .backgroundColor(getThemeColors().primary)
                        .textAlign(TextAlign.Center);

                      Column() {
                        Text(user.display_name || user.user_id)
                          .fontSize(16)
                          .fontColor(getThemeColors().text);
                        Text(user.user_id)
                          .fontSize(12)
                          .fontColor(getThemeColors().textSecondary);
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

          Divider().color(getThemeColors().divider);

          Column() {
            Row() {
              Text('创建新聊天室')
                .fontSize(16)
                .fontColor(getThemeColors().text);
              Blank();
              Button('+')
                .fontSize(24)
                .backgroundColor(getThemeColors().primary)
                .fontColor('#ffffff')
                .width(36)
                .height(36)
                .borderRadius(18)
                .onClick(() => {
                  this.createRoom();
                });
            }
            .width('100%')
            .padding({ top: 15, bottom: 15 });
          }
          .width('90%');

          Divider().color(getThemeColors().divider);

          Column() {
            Text('通过地址加入')
              .fontSize(16)
              .fontColor(getThemeColors().text)
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 10 });

            TextInput({ placeholder: '输入 room ID 或地址', text: this.roomAddress })
              .width('85%')
              .height(44)
              .fontSize(16)
              .backgroundColor(getThemeColors().inputBg)
              .borderRadius(10)
              .onChange((value: string) => {
                this.roomAddress = value;
              });

            Button('Scan')
              .fontSize(20)
              .backgroundColor(getThemeColors().primary)
              .fontColor('#ffffff')
              .width(44)
              .height(44)
              .borderRadius(10)
              .margin({ left: 8 })
              .onClick(() => {
                this.onScanQRCode();
              });

            Button(this.isJoining ? '加入中...' : '加入')
              .fontSize(16)
              .backgroundColor(getThemeColors().primary)
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
        .backgroundColor(getThemeColors().bg);

        // 创建聊天室弹窗由 QuickDialogManager 管理
      }
      .width('100%')
      .height('100%');
    }
    .hideTitleBar(true);
  }
}