import { ToastUtils } from '../utils/ToastUtils';
import { getThemeColors } from '../utils/ThemeManager';
import { RoomSettingsViewModel, RoomSettingsState } from '../viewmodels/RoomSettingsViewModel';

@Builder
export function RoomSettingsPageBuilder(name: string, param: Object) {
  RoomSettingsPage({
    roomId: ((param as Record<string, Object>)['roomId'] as string) || '',
    roomName: ((param as Record<string, Object>)['roomName'] as string) || ''
  })
}

@Component
struct RoomSettingsPage {
  @State roomId: string = '';
  @State roomName: string = '';
  @State roomTopic: string = '';
  @State editName: string = '';
  @State editTopic: string = '';
  @State isEditingName: boolean = false;
  @State isEditingTopic: boolean = false;
  @State memberCount: number = 0;
  @State isPublic: boolean = false;
  @State isLoading: boolean = true;
  pathStack: NavPathStack = new NavPathStack();
  private vm: RoomSettingsViewModel = new RoomSettingsViewModel(this.roomId, this.roomName);

  private syncState(state: RoomSettingsState): void {
    this.roomId = state.roomId;
    this.roomName = state.roomName;
    this.roomTopic = state.roomTopic;
    this.editName = state.editName;
    this.editTopic = state.editTopic;
    this.isEditingName = state.isEditingName;
    this.isEditingTopic = state.isEditingTopic;
    this.memberCount = state.memberCount;
    this.isPublic = state.isPublic;
    this.isLoading = state.isLoading;
  }

  aboutToAppear() {
    this.vm.setOnStateChanged((state: RoomSettingsState) => {
      this.syncState(state);
    });
    this.vm.setPopCallback(() => {
      this.pathStack.pop();
    });
    this.vm.initialize();
  }

  build() {
    NavDestination() {
      Column() {
        // Header
        Row() {
          Button('←')
            .fontSize(18)
            .backgroundColor('transparent')
            .fontColor(getThemeColors().primary)
            .width(36)
            .height(36)
            .onClick(() => {
              this.pathStack.pop();
            });

          Text('Room Settings')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(getThemeColors().text)
            .layoutWeight(1);
        }
        .width('100%')
        .padding({ left: 10, right: 10, top: 10, bottom: 10 })
        .backgroundColor(getThemeColors().bg);

        Divider().color(getThemeColors().divider);

        if (this.isLoading) {
          Column() {
            LoadingProgress()
              .width(40)
              .height(40);
            Text('Loading...')
              .fontSize(14)
              .fontColor(getThemeColors().textSecondary)
              .margin({ top: 10 });
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center);
        } else {
          Scroll() {
            Column() {
              // Room Name Section
              Column() {
                Row() {
                  Text('Room Name')
                    .fontSize(14)
                    .fontColor(getThemeColors().textSecondary);
                  Blank();
                  if (this.isEditingName) {
                    Button('Save')
                      .fontSize(12)
                      .backgroundColor(getThemeColors().primary)
                      .fontColor(getThemeColors().onPrimary)
                      .borderRadius(6)
                      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                      .onClick(() => {
                        this.vm.saveRoomName();
                      });
                  } else {
                    Button('Edit')
                      .fontSize(12)
                      .backgroundColor(getThemeColors().bg)
                      .fontColor(getThemeColors().primary)
                      .borderWidth(1)
                      .borderColor(getThemeColors().primary)
                      .borderRadius(6)
                      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                      .onClick(() => {
                        this.vm.setEditingName(true);
                      });
                  }
                }
                .width('100%')
                .padding({ left: 20, right: 20, top: 15, bottom: 10 });

                if (this.isEditingName) {
                  TextInput({ text: this.editName })
                    .width('calc(100% - 40)')
                    .height(40)
                    .fontSize(16)
                    .backgroundColor(getThemeColors().inputBg)
                    .borderRadius(6)
                    .margin({ left: 20, right: 20, bottom: 15 })
                    .onChange((value: string) => {
                      this.vm.setEditName(value);
                    });
                } else {
                  Text(this.roomName)
                    .fontSize(16)
                    .fontColor(getThemeColors().text)
                    .width('100%')
                    .padding({ left: 20, right: 20, bottom: 15 });
                }
              }
              .width('100%')
              .backgroundColor(getThemeColors().surface);

              Divider().color(getThemeColors().divider);

              // Room Topic Section
              Column() {
                Row() {
                  Text('Room Topic')
                    .fontSize(14)
                    .fontColor(getThemeColors().textSecondary);
                  Blank();
                  if (this.isEditingTopic) {
                    Button('Save')
                      .fontSize(12)
                      .backgroundColor(getThemeColors().primary)
                      .fontColor(getThemeColors().onPrimary)
                      .borderRadius(6)
                      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                      .onClick(() => {
                        this.vm.saveRoomTopic();
                      });
                  } else {
                    Button('Edit')
                      .fontSize(12)
                      .backgroundColor(getThemeColors().bg)
                      .fontColor(getThemeColors().primary)
                      .borderWidth(1)
                      .borderColor(getThemeColors().primary)
                      .borderRadius(6)
                      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                      .onClick(() => {
                        this.vm.setEditingTopic(true);
                      });
                  }
                }
                .width('100%')
                .padding({ left: 20, right: 20, top: 15, bottom: 10 });

                if (this.isEditingTopic) {
                  TextInput({ text: this.editTopic })
                    .width('calc(100% - 40)')
                    .height(80)
                    .fontSize(16)
                    .backgroundColor(getThemeColors().inputBg)
                    .borderRadius(6)
                    .margin({ left: 20, right: 20, bottom: 15 })
                    .onChange((value: string) => {
                      this.vm.setEditTopic(value);
                    });
                } else {
                  Text(this.roomTopic || 'No topic set')
                    .fontSize(16)
                    .fontColor(this.roomTopic ? getThemeColors().text : getThemeColors().textMute2)
                    .width('100%')
                    .padding({ left: 20, right: 20, bottom: 15 });
                }
              }
              .width('100%')
              .backgroundColor(getThemeColors().surface);

              Divider().color(getThemeColors().divider);

              // Room Info Section
              Column() {
                Row() {
                  Text('Members')
                    .fontSize(14)
                    .fontColor(getThemeColors().textSecondary);
                  Blank();
                  Text(this.memberCount.toString())
                    .fontSize(14)
                    .fontColor(getThemeColors().text);
                }
                .width('100%')
                .padding({ left: 20, right: 20, top: 15, bottom: 15 });
              }
              .width('100%')
              .backgroundColor(getThemeColors().surface);

              Divider().color(getThemeColors().divider);

              // Leave Room Button
              Column() {
                Button('Leave Room')
                  .fontSize(16)
                  .backgroundColor(getThemeColors().bg)
                  .fontColor(getThemeColors().error)
                  .borderWidth(1)
                  .borderColor(getThemeColors().error)
                  .borderRadius(6)
                  .width('100%')
                  .height(44)
                  .margin({ left: 20, right: 20, top: 20, bottom: 20 })
                  .onClick(() => {
                    this.vm.leaveRoom();
                  });
              }
              .width('100%')
              .backgroundColor(getThemeColors().surface);
            }
            .width('100%');
          }
          .layoutWeight(1);
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(getThemeColors().bg);
    }
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
    })
    .hideTitleBar(true);
  }
}
