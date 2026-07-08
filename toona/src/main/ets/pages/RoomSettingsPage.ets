import { ToastUtils } from '../utils/ToastUtils';
import { RoomManager } from '../services/RoomManager';
import { AuthManager } from '../services/AuthManager';
import { getThemeColors } from '../utils/ThemeManager';
import { AppLogger } from '../utils/AppLogger';

const logger = AppLogger.getLogger('RoomSettingsPage');

@Builder
export function RoomSettingsPageBuilder(name: string, param: Object) {
  RoomSettingsPage({
    roomId: ((param as Record<string, Object>)['roomId'] as string) || '',
    roomName: ((param as Record<string, Object>)['roomName'] as string) || '',
    pathStack: ((param as Record<string, Object>)['pathStack'] as NavPathStack) || new NavPathStack()
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
  private roomManager: RoomManager = RoomManager.getInstance();
  private authManager: AuthManager = AuthManager.getInstance();
  @Prop pathStack: NavPathStack;
  private logger = AppLogger.getLogger('RoomSettingsPage');

  aboutToAppear() {
    this.loadRoomSettings();
  }

  async loadRoomSettings() {
    this.isLoading = true;
    try {
      const room = await this.roomManager.getRoom(this.roomId);
      if (room) {
        this.roomName = room.getDisplayName();
        this.roomTopic = room.topic || '';
        this.editName = this.roomName;
        this.editTopic = this.roomTopic;
        this.memberCount = room.memberCount || 0;
      }
    } catch (error) {
      this.logger.error('Failed to load room settings:', error);
      ToastUtils.show('Failed to load room settings');
    } finally {
      this.isLoading = false;
    }
  }

  async saveRoomName() {
    if (!this.editName.trim()) {
      ToastUtils.show('Room name cannot be empty');
      return;
    }

    try {
      await this.roomManager.setRoomName(this.roomId, this.editName.trim());
      this.roomName = this.editName.trim();
      this.isEditingName = false;
      ToastUtils.show('Room name updated');
    } catch (error) {
      this.logger.error('Failed to update room name:', error);
      ToastUtils.show('Failed to update room name');
    }
  }

  async saveRoomTopic() {
    try {
      await this.roomManager.setRoomTopic(this.roomId, this.editTopic.trim());
      this.roomTopic = this.editTopic.trim();
      this.isEditingTopic = false;
      ToastUtils.show('Room topic updated');
    } catch (error) {
      this.logger.error('Failed to update room topic:', error);
      ToastUtils.show('Failed to update room topic');
    }
  }

  async leaveRoom() {
    try {
      await this.roomManager.leaveRoom(this.roomId);
      ToastUtils.show('Left room');
      this.pathStack.pop();
    } catch (error) {
      this.logger.error('Failed to leave room:', error);
      ToastUtils.show('Failed to leave room');
    }
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
                        this.saveRoomName();
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
                        this.isEditingName = true;
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
                      this.editName = value;
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
                        this.saveRoomTopic();
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
                        this.isEditingTopic = true;
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
                      this.editTopic = value;
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
                    this.leaveRoom();
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
    .hideTitleBar(true);
  }
}
