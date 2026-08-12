import { ToastUtils } from '../utils/ToastUtils';
import { QuickDialogManager, QuickDialogParams, QuickDialogController, QuickDialogDecoratorParams } from 'quickdialog';
import { getThemeColors } from '../utils/ThemeManager';
import { JoinRoomViewModel, JoinRoomState } from '../viewmodels/JoinRoomViewModel';

interface DirectoryUser {
  user_id: string;
  display_name?: string;
  avatar_url?: string;
}

interface CreateRoomDialogData {
  roomName: string;
  isPublic: boolean;
}

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
        .fontColor(getThemeColors().text)
        .margin({ bottom: 20 })

      TextInput({ placeholder: '房间名称' })
        .width('100%')
        .height(44)
        .fontSize(16)
        .backgroundColor(getThemeColors().inputBg)
        .borderRadius(6)
        .onChange((value: string) => {
          this.roomName = value;
        })

      Row() {
        Text('设为公开房间')
          .fontSize(14)
          .fontColor(getThemeColors().text)
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
          .backgroundColor(getThemeColors().inputBg)
          .fontColor(getThemeColors().text)
          .width('45%')
          .height(44)
          .borderRadius(6)
          .onClick(() => {
            this.dialogController?.dismiss()
          })

        Button('创建')
          .fontSize(16)
          .backgroundColor(getThemeColors().primary)
          .fontColor(getThemeColors().onPrimary)
          .width('45%')
          .height(44)
          .borderRadius(6)
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
    .backgroundColor(getThemeColors().surface)
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

@Builder
export function JoinRoomPageBuilder(name: string, param: Object) {
  JoinRoomPage()
}

@Component
struct JoinRoomPage {
  @State searchQuery: string = '';
  @State searchResults: DirectoryUser[] = [];
  @State isSearching: boolean = false;
  @State roomAddress: string = '';
  @State isJoining: boolean = false;
  private vm: JoinRoomViewModel = new JoinRoomViewModel();
  private createRoomDialogController: QuickDialogController | undefined = undefined;
  pathStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    this.vm.setOnStateChanged((state: JoinRoomState) => {
      this.searchQuery = state.searchQuery;
      this.searchResults = state.searchResults as DirectoryUser[];
      this.isSearching = state.isSearching;
      this.roomAddress = state.roomAddress;
      this.isJoining = state.isJoining;
    });
    this.vm.setNavigateCallback((pageName: string, param: Record<string, Object>) => {
      this.pathStack.pushPathByName(pageName, param);
    });
    this.vm.setPopCallback(() => {
      this.pathStack.pop();
    });
  }

  searchUsers() {
    this.vm.searchUsers();
  }

  startDirectChat(userId: string) {
    this.vm.startDirectChat(userId);
  }

  onScanQRCode() {
    this.vm.onScanQRCode();
  }

  joinRoom() {
    this.vm.joinRoom();
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
        self.vm.createRoom(roomName, isPublic);
      })
      .build();
    this.createRoomDialogController.show();
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
              .borderRadius(6)
              .margin({ bottom: 10 })
              .onChange((value: string) => {
                this.vm.setSearchQuery(value);
              })
              .onSubmit(() => {
                this.searchUsers();
              });

            Button('搜索')
              .fontSize(14)
              .backgroundColor(getThemeColors().primary)
              .fontColor(getThemeColors().onPrimary)
              .width('100%')
              .height(40)
              .borderRadius(6)
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
                        .fontColor(getThemeColors().onPrimary)
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
                .fontColor(getThemeColors().onPrimary)
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
              .borderRadius(6)
              .onChange((value: string) => {
                this.vm.setRoomAddress(value);
              });

            Button('Scan')
              .fontSize(20)
              .backgroundColor(getThemeColors().primary)
              .fontColor(getThemeColors().onPrimary)
              .width(44)
              .height(44)
              .borderRadius(6)
              .margin({ left: 8 })
              .onClick(() => {
                this.onScanQRCode();
              });

            Button(this.isJoining ? '加入中...' : '加入')
              .fontSize(16)
              .backgroundColor(getThemeColors().primary)
              .fontColor(getThemeColors().onPrimary)
              .width('100%')
              .height(44)
              .borderRadius(6)
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
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
    })
    .hideTitleBar(true);
  }
}
