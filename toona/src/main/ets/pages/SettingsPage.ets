import { ToastUtils } from '../utils/ToastUtils';
import { ThemeManager, getThemeColors, ColorModeType } from '../utils/ThemeManager';
import { SettingsHeader } from './components/settings/SettingsHeader';
import { UserProfileCard } from './components/settings/UserProfileCard';
import { ThemeSettings } from './components/settings/ThemeSettings';
import { PresenceSettings } from './components/settings/PresenceSettings';
import { RoomTagsSettings } from './components/settings/RoomTagsSettings';
import { DeviceManagement } from './components/settings/DeviceManagement';
import { SecuritySettings } from './components/settings/SecuritySettings';
import { QRScannerSettings } from './components/settings/QRScannerSettings';
import { BiometricSettings } from './components/settings/BiometricSettings';
import { CollaborationSettings } from './components/settings/CollaborationSettings';
import { AboutSection } from './components/settings/AboutSection';
import { LogoutButton } from './components/settings/LogoutButton';
import { SettingsViewModel, SettingsState } from '../viewmodels/SettingsViewModel';
import { Room } from '../models/DataModels';
import { Device } from '../models/MatrixTypes';
import { PresenceState } from '../models/MatrixTypes';

@Builder
export function SettingsPageBuilder(name: string, param: Object) {
  SettingsPage()
}

@Component
export struct SettingsPage {
  @State userId: string = '';
  @State displayName: string = '';
  @State avatarUrl: string = '';
  @State presence: PresenceState = 'online';
  @State statusMsg: string = '';
  @State devices: Device[] = [];
  @State favoriteRooms: Room[] = [];
  @State lowPriorityRooms: Room[] = [];
  @State allRooms: Room[] = [];
  @State isLoadingProfile: boolean = true;
  @State isLoadingDevices: boolean = true;
  @State isLoadingRoomTags: boolean = true;
  @State isEditingName: boolean = false;
  @State editName: string = '';
  @State showPresenceMenu: boolean = false;
  @State showRoomTagsMenu: boolean = false;
  @State colorModeType: ColorModeType = 'light';
  @State isE2EEEnabled: boolean = false;
  @State currentDeviceId: string = '';

  private vm: SettingsViewModel = new SettingsViewModel();
  pathStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    this.vm.setOnStateChanged((state: SettingsState) => {
      this.userId = state.userId;
      this.displayName = state.displayName;
      this.avatarUrl = state.avatarUrl;
      this.presence = state.presence;
      this.statusMsg = state.statusMsg;
      this.devices = state.devices;
      this.favoriteRooms = state.favoriteRooms;
      this.lowPriorityRooms = state.lowPriorityRooms;
      this.allRooms = state.allRooms;
      this.isLoadingProfile = state.isLoadingProfile;
      this.isLoadingDevices = state.isLoadingDevices;
      this.isLoadingRoomTags = state.isLoadingRoomTags;
      this.isEditingName = state.isEditingName;
      this.editName = state.editName;
      this.showPresenceMenu = state.showPresenceMenu;
      this.showRoomTagsMenu = state.showRoomTagsMenu;
      this.colorModeType = state.colorModeType;
      this.isE2EEEnabled = state.isE2EEEnabled;
      this.currentDeviceId = state.currentDeviceId;
    });
    this.vm.setLogoutCallback(() => {
      this.pathStack.clear();
    });
    this.vm.initialize();
  }

  setColorMode(mode: ColorModeType) {
    this.vm.setColorMode(mode);
  }

  pickAndUploadAvatar() {
    this.vm.pickAndUploadAvatar();
  }

  saveDisplayName() {
    this.vm.saveDisplayName();
  }

  setPresence(state: PresenceState) {
    this.vm.setPresence(state);
  }

  setStatusMessage() {
    this.vm.setStatusMessage();
  }

  toggleFavorite(room: Room) {
    this.vm.toggleFavorite(room);
  }

  toggleLowPriority(room: Room) {
    this.vm.toggleLowPriority(room);
  }

  deleteDevice(deviceId: string) {
    this.vm.deleteDevice(deviceId);
  }

  handleLogout() {
    this.vm.handleLogout();
  }

  onCheckDeviceSecurity() {
    this.vm.onCheckDeviceSecurity();
  }

  onScanQRCode() {
    this.vm.onScanQRCode();
  }

  onToggleBiometric(enable: boolean) {
    this.vm.onToggleBiometric(enable);
  }

  onVerifyBiometric() {
    this.vm.onVerifyBiometric();
  }

  onFindCollaborativeDevices() {
    this.vm.onFindCollaborativeDevices();
  }

  navigateToInviteManagement() {
    const param: Record<string, Object> = {};
    this.pathStack.pushPathByName('InviteManagementPage', param);
  }

  navigateToNotificationSettings() {
    const param: Record<string, Object> = {};
    this.pathStack.pushPathByName('NotificationSettingsPage', param);
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          SettingsHeader();

          if (this.isLoadingProfile) {
            Column() {
              Row() {
                Column() {
                  Row()
                    .width(60)
                    .height(60)
                    .borderRadius(30)
                    .backgroundColor(getThemeColors().inputBg);
                  Column()
                    .width(120)
                    .height(16)
                    .borderRadius(4)
                    .backgroundColor(getThemeColors().inputBg)
                    .margin({ top: 12 });
                  Column()
                    .width(80)
                    .height(12)
                    .borderRadius(4)
                    .backgroundColor(getThemeColors().inputBg)
                    .margin({ top: 8 });
                }
                .alignItems(HorizontalAlign.Center);
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .padding({ top: 30, bottom: 20 });
            }
            .width('100%')
            .backgroundColor(getThemeColors().surface);
          } else {
            UserProfileCard({
              displayName: this.displayName,
              avatarUrl: this.avatarUrl,
              presence: this.presence,
              userId: this.userId,
              isEditingName: this.isEditingName,
              editName: this.editName,
              onPickAvatar: () => {
                this.pickAndUploadAvatar();
              },
              onStartEditName: () => {
                this.vm.setEditingName(true);
              },
              onSaveDisplayName: () => {
                this.saveDisplayName();
              },
              onCancelEditName: () => {
                this.vm.setEditingName(false);
              },
              onEditNameChange: (name: string) => {
                this.vm.setEditName(name);
              }
            });
          }

          ThemeSettings({
            colorModeType: this.colorModeType,
            onSetColorMode: (mode: ColorModeType) => {
              this.setColorMode(mode);
            }
          });

          if (this.isLoadingProfile) {
            Column() {
              Row() {
                Column()
                  .width(80)
                  .height(14)
                  .borderRadius(4)
                  .backgroundColor(getThemeColors().inputBg);
                Blank();
                Column()
                  .width(40)
                  .height(14)
                  .borderRadius(4)
                  .backgroundColor(getThemeColors().inputBg);
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 15, bottom: 15 });
            }
            .width('100%')
            .margin({ top: 10 })
            .backgroundColor(getThemeColors().surface);
          } else {
            PresenceSettings({
              presence: this.presence,
              statusMsg: this.statusMsg,
              showPresenceMenu: this.showPresenceMenu,
              onSetPresence: (state: PresenceState) => {
                this.setPresence(state);
              },
              onTogglePresenceMenu: () => {
                this.vm.togglePresenceMenu();
              },
              onStatusMsgChange: (msg: string) => {
                this.vm.setStatusMsg(msg);
              },
              onSaveStatusMessage: () => {
                this.setStatusMessage();
              }
            });
          }

          if (this.isLoadingRoomTags) {
            Column() {
              Row() {
                Column()
                  .width(100)
                  .height(14)
                  .borderRadius(4)
                  .backgroundColor(getThemeColors().inputBg);
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 15, bottom: 15 });
              Row() {
                LoadingProgress()
                  .width(20)
                  .height(20)
                  .color(getThemeColors().textSecondary);
                Text('加载房间标签...')
                  .fontSize(12)
                  .fontColor(getThemeColors().textSecondary)
                  .margin({ left: 8 });
              }
              .width('100%')
              .padding({ left: 20, right: 20, bottom: 15 });
            }
            .width('100%')
            .margin({ top: 10 })
            .backgroundColor(getThemeColors().surface);
          } else {
            RoomTagsSettings({
              favoriteRooms: this.favoriteRooms,
              lowPriorityRooms: this.lowPriorityRooms,
              allRooms: this.allRooms,
              showRoomTagsMenu: this.showRoomTagsMenu,
              onToggleFavorite: (room: Room) => {
                this.toggleFavorite(room);
              },
              onToggleLowPriority: (room: Room) => {
                this.toggleLowPriority(room);
              },
              onToggleRoomTagsMenu: () => {
                this.vm.toggleRoomTagsMenu();
              }
            });
          }

          if (this.isLoadingDevices) {
            Column() {
              Row() {
                Column()
                  .width(100)
                  .height(14)
                  .borderRadius(4)
                  .backgroundColor(getThemeColors().inputBg);
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 15, bottom: 15 });
              Row() {
                LoadingProgress()
                  .width(20)
                  .height(20)
                  .color(getThemeColors().textSecondary);
                Text('加载设备列表...')
                  .fontSize(12)
                  .fontColor(getThemeColors().textSecondary)
                  .margin({ left: 8 });
              }
              .width('100%')
              .padding({ left: 20, right: 20, bottom: 15 });
            }
            .width('100%')
            .margin({ top: 10 })
            .backgroundColor(getThemeColors().surface);
          } else {
            DeviceManagement({
              devices: this.devices,
              currentDeviceId: this.currentDeviceId,
              onDeleteDevice: (deviceId: string) => {
                this.deleteDevice(deviceId);
              }
            });
          }

          SecuritySettings({
            onCheckDeviceSecurity: () => {
              this.onCheckDeviceSecurity();
            }
          });

          Column() {
            Row() {
              Text('加密设置')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(getThemeColors().text);
            }
            .width('100%')
            .padding({
              left: 20,
              right: 20,
              top: 15,
              bottom: 10
            });

            Column() {
              Row() {
                Text('端到端加密')
                  .fontSize(14)
                  .fontColor(getThemeColors().text);
                Blank();
                Text('暂不可用')
                  .fontSize(14)
                  .fontColor(getThemeColors().textMute2);
              }
              .width('100%')
              .padding({
                left: 20,
                right: 20,
                top: 12,
                bottom: 12
              });
            }
            .width('100%')
            .backgroundColor(getThemeColors().surface);
          }
          .width('100%')
          .margin({ top: 10 });

          Column() {
            Row() {
              Text('设备验证')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(getThemeColors().text);
            }
            .width('100%')
            .padding({
              left: 20,
              right: 20,
              top: 15,
              bottom: 10
            });

            Column() {
              Row() {
                Text('验证状态')
                  .fontSize(14)
                  .fontColor(getThemeColors().textSecondary);
                Blank();
                Text('暂不可用')
                  .fontSize(14)
                  .fontColor(getThemeColors().textMute2);
              }
              .width('100%')
              .padding({
                left: 20,
                right: 20,
                top: 12,
                bottom: 12
              });
            }
            .width('100%')
            .backgroundColor(getThemeColors().surface);
          }
          .width('100%')
          .margin({ top: 10 });

          BiometricSettings({
            onToggleBiometric: (enable: boolean) => {
              this.onToggleBiometric(enable);
            },
            onVerifyBiometric: () => {
              this.onVerifyBiometric();
            }
          });

          CollaborationSettings({
            onFindCollaborativeDevices: () => {
              this.onFindCollaborativeDevices();
            }
          });

          Column() {
            Row() {
              Text('Invites')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(getThemeColors().text);
              Blank();
              Button('View')
                .fontSize(12)
                .backgroundColor(getThemeColors().primary)
                .fontColor(getThemeColors().onPrimary)
                .borderRadius(6)
                .padding({
                  left: 12,
                  right: 12,
                  top: 6,
                  bottom: 6
                })
                .onClick(() => {
                  this.navigateToInviteManagement();
                });
            }
            .width('100%')
            .padding({
              left: 20,
              right: 20,
              top: 15,
              bottom: 15
            });
          }
          .width('100%')
          .margin({ top: 10 })
          .backgroundColor(getThemeColors().surface);

          QRScannerSettings({
            onScanQRCode: () => {
              this.onScanQRCode();
            }
          });

          Column() {
            Row() {
              Text('Notification Settings')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(getThemeColors().text);
              Blank();
              Button('Configure')
                .fontSize(12)
                .backgroundColor(getThemeColors().primary)
                .fontColor(getThemeColors().onPrimary)
                .borderRadius(6)
                .padding({
                  left: 12,
                  right: 12,
                  top: 6,
                  bottom: 6
                })
                .onClick(() => {
                  this.navigateToNotificationSettings();
                });
            }
            .width('100%')
            .padding({
              left: 20,
              right: 20,
              top: 15,
              bottom: 15
            });
          }
          .width('100%')
          .margin({ top: 10 })
          .backgroundColor(getThemeColors().surface);

          AboutSection();

          LogoutButton({
            onLogout: () => {
              this.handleLogout();
            }
          });
        }
      }
    }
    .width('100%')
    .height('100%')
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
    })
    .hideTitleBar(true);
  }
}
