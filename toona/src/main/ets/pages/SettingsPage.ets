import { ToastUtils } from '../utils/ToastUtils';
import { AuthManager } from '../services/AuthManager';
import { UserManager } from '../services/UserManager';
import { PresenceManager } from '../services/PresenceManager';
import { DeviceManager } from '../services/DeviceManager';
import { RoomTagManager } from '../services/RoomTagManager';
import { RoomManager } from '../services/RoomManager';
import { MediaManager } from '../services/MediaManager';
import { ServiceCollaborationManager } from '../services/ServiceCollaborationManager';
import { DeviceSecurityManager } from '../services/DeviceSecurityManager';
import { ScanManager } from '../services/ScanManager';
import { UserAuthManager } from '../services/UserAuthManager';
import { CryptoService } from '../services/CryptoService';
import { VerificationService } from '../services/VerificationService';
import { VerificationState } from '../crypto/types/CryptoTypes';
import { Room } from '../models/DataModels';
import { Device } from '../models/MatrixTypes';
import { PresenceState } from '../models/MatrixTypes';
import { fileIo } from '@kit.CoreFileKit';
import { picker } from '@kit.CoreFileKit';
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
import { AppLogger } from '../utils/AppLogger';

@Builder
export function SettingsPageBuilder(name: string, param: Object) {
  SettingsPage({
    pathStack: ((param as Record<string, Object>)['pathStack'] as NavPathStack) || new NavPathStack()
  })
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
  @State isLoading: boolean = true;
  @State isEditingName: boolean = false;
  @State editName: string = '';
  @State showPresenceMenu: boolean = false;
  @State showRoomTagsMenu: boolean = false;
  @State selectedRoomForTags: Room | null = null;
  @State showAboutPage: boolean = false;
  @State colorModeType: ColorModeType = 'light';
  @State isE2EEEnabled: boolean = false;
  @State deviceId: string = '';
  private authManager: AuthManager = AuthManager.getInstance();
  private userManager: UserManager = UserManager.getInstance();
  private presenceManager: PresenceManager = PresenceManager.getInstance();
  private deviceManager: DeviceManager = DeviceManager.getInstance();
  private roomTagManager: RoomTagManager = RoomTagManager.getInstance();
  private roomManager: RoomManager = RoomManager.getInstance();
  private mediaManager: MediaManager = MediaManager.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();
  private collaborationManager: ServiceCollaborationManager = ServiceCollaborationManager.getInstance();
  private deviceSecurityManager: DeviceSecurityManager = DeviceSecurityManager.getInstance();
  private scanManager: ScanManager = ScanManager.getInstance();
  private userAuthManager: UserAuthManager = UserAuthManager.getInstance();
  private cryptoService: CryptoService = CryptoService.getInstance();
  private verificationService: VerificationService = VerificationService.getInstance();
  private logger = AppLogger.getLogger(SettingsPage);
  @Prop pathStack: NavPathStack;

  aboutToAppear() {
    const session = this.authManager.getSession();
    if (session) {
      this.userId = session.userId;
    }
    this.colorModeType = this.themeManager.getColorModeType();
    this.loadUserData();
    this.loadEncryptionStatus();
  }

  setColorMode(mode: ColorModeType) {
    this.colorModeType = mode;
    this.themeManager.setColorMode(mode);
    const messages: Record<ColorModeType, string> = {
      'light': '日间模式',
      'dark': '夜间模式',
      'system': '跟随系统'
    };
    ToastUtils.show(`已切换至${messages[mode]}`);
  }

  async loadUserData() {
    this.isLoading = true;
    try {
      const profile = await this.userManager.getUserProfile();
      this.displayName = profile.displayName || '';
      this.avatarUrl = profile.avatarUrl || '';
      this.editName = this.displayName;

      const presenceResponse = await this.presenceManager.getPresence(this.userId);
      this.presence = presenceResponse.presence as PresenceState;
      this.statusMsg = presenceResponse.status_msg || '';

      try {
        const devicesResponse = await this.deviceManager.getDevices();
        this.devices = devicesResponse.devices || [];
      } catch (e) {
        this.logger.error('Failed to load devices: %{public}s', e.message);
        this.devices = [];
      }

      this.allRooms = await this.roomManager.getRooms();
      this.favoriteRooms = [];
      this.lowPriorityRooms = [];

      for (let i = 0; i < this.allRooms.length; i++) {
        const room = this.allRooms[i];
        try {
          const isFav = await this.roomTagManager.isFavorite(room.id);
          if (isFav) {
            this.favoriteRooms.push(room);
          }
          const isLow = await this.roomTagManager.isLowPriority(room.id);
          if (isLow) {
            this.lowPriorityRooms.push(room);
          }
        } catch (e) {
          this.logger.error('Failed to check room tags: %{public}s', e.message);
        }
      }
    } catch (error) {
      this.logger.error('Failed to load user data: %{public}s', error.message);
    } finally {
      this.isLoading = false;
    }
  }

  async saveDisplayName() {
    if (!this.editName.trim()) {
      return;
    }
    try {
      await this.userManager.setDisplayName(this.editName.trim());
      this.displayName = this.editName.trim();
      this.isEditingName = false;
      ToastUtils.show('显示名称已更新');
    } catch (error) {
      this.logger.error('Failed to save display name: %{public}s', error.message);
      ToastUtils.show('更新失败');
    }
  }

  async setPresence(state: PresenceState) {
    try {
      await this.presenceManager.setPresence(this.userId, state, this.statusMsg);
      this.presence = state;
      this.showPresenceMenu = false;
      ToastUtils.show('状态已更新');
    } catch (error) {
      this.logger.error('Failed to set presence: %{public}s', error.message);
      ToastUtils.show('更新失败');
    }
  }

  async setStatusMessage() {
    try {
      await this.presenceManager.setPresence(this.userId, this.presence, this.statusMsg);
      ToastUtils.show('状态消息已更新');
    } catch (error) {
      this.logger.error('Failed to set status message: %{public}s', error.message);
      ToastUtils.show('更新失败');
    }
  }

  async pickAndUploadAvatar() {
    try {
      const photoPicker = new picker.PhotoViewPicker();
      const result = await photoPicker.select({
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      });
      if (result && result.photoUris && result.photoUris.length > 0) {
        const photoUri = result.photoUris[0];
        const file = fileIo.openSync(photoUri, fileIo.OpenMode.READ_ONLY);
        const fileInfo = fileIo.statSync(photoUri);
        const buffer = new Uint8Array(fileInfo.size);
        fileIo.readSync(file.fd, buffer);
        fileIo.closeSync(file);
        const fileName = 'avatar_' + Date.now() + '.jpg';
        const mxcUri = await this.mediaManager.uploadImage(buffer.buffer as ArrayBuffer, fileName);
        await this.userManager.setAvatarUrl(mxcUri);
        this.avatarUrl = this.mediaManager.getHttpUrl(mxcUri);
        ToastUtils.show('头像已更新');
      }
    } catch (error) {
      this.logger.error('Failed to upload avatar: %{public}s', error.message);
      ToastUtils.show('头像上传失败');
    }
  }

  async toggleFavorite(room: Room) {
    try {
      const isFav = await this.roomTagManager.isFavorite(room.id);
      if (isFav) {
        await this.roomTagManager.removeFavorite(room.id);
        const index = this.favoriteRooms.findIndex(r => r.id === room.id);
        if (index >= 0) {
          this.favoriteRooms.splice(index, 1);
        }
      } else {
        await this.roomTagManager.addFavorite(room.id);
        this.favoriteRooms.push(room);
      }
      ToastUtils.show(isFav ? '已取消收藏' : '已添加收藏');
    } catch (error) {
      this.logger.error('Failed to toggle favorite: %{public}s', error.message);
      ToastUtils.show('操作失败');
    }
  }

  async toggleLowPriority(room: Room) {
    try {
      const isLow = await this.roomTagManager.isLowPriority(room.id);
      if (isLow) {
        await this.roomTagManager.removeLowPriority(room.id);
        const index = this.lowPriorityRooms.findIndex(r => r.id === room.id);
        if (index >= 0) {
          this.lowPriorityRooms.splice(index, 1);
        }
      } else {
        await this.roomTagManager.addLowPriority(room.id);
        this.lowPriorityRooms.push(room);
      }
      ToastUtils.show(isLow ? '已取消低优先级' : '已设为低优先级');
    } catch (error) {
      this.logger.error('Failed to toggle low priority: %{public}s', error.message);
      ToastUtils.show('操作失败');
    }
  }

  async deleteDevice(deviceId: string) {
    try {
      await this.deviceManager.deleteDevice(deviceId);
      const index = this.devices.findIndex(d => d.device_id === deviceId);
      if (index >= 0) {
        this.devices.splice(index, 1);
      }
      ToastUtils.show('设备已删除');
    } catch (error) {
      this.logger.error('Failed to delete device: %{public}s', error.message);
      ToastUtils.show('删除失败');
    }
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          SettingsHeader();

          if (this.isLoading) {
            Column() {
              LoadingProgress()
                .width(40)
                .height(40);
              Text('加载中...')
                .fontSize(14)
                .fontColor(getThemeColors().textMute2)
                .margin({ top: 10 });
            }
            .width('100%')
            .padding({ top: 100 });
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
                this.isEditingName = true;
              },
              onSaveDisplayName: () => {
                this.saveDisplayName();
              },
              onCancelEditName: () => {
                this.isEditingName = false;
                this.editName = this.displayName;
              },
              onEditNameChange: (name: string) => {
                this.editName = name;
              }
            });

            ThemeSettings({
              colorModeType: this.colorModeType,
              onSetColorMode: (mode: ColorModeType) => {
                this.setColorMode(mode);
              }
            });

            PresenceSettings({
              presence: this.presence,
              statusMsg: this.statusMsg,
              showPresenceMenu: this.showPresenceMenu,
              onSetPresence: (state: PresenceState) => {
                this.setPresence(state);
              },
              onTogglePresenceMenu: () => {
                this.showPresenceMenu = !this.showPresenceMenu;
              },
              onStatusMsgChange: (msg: string) => {
                this.statusMsg = msg;
              },
              onSaveStatusMessage: () => {
                this.setStatusMessage();
              }
            });

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
                this.showRoomTagsMenu = !this.showRoomTagsMenu;
              }
            });

            DeviceManagement({
              devices: this.devices,
              currentDeviceId: this.authManager.getSession()?.deviceId || '',
              onDeleteDevice: (deviceId: string) => {
                this.deleteDevice(deviceId);
              }
            });

            SecuritySettings({
              onCheckDeviceSecurity: () => {
                this.onCheckDeviceSecurity();
              }
            });

            // Encryption Settings Section
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
                  Toggle({ type: ToggleType.Switch, isOn: this.isE2EEEnabled })
                    .selectedColor(getThemeColors().primary)
                    .onChange((isOn: boolean) => {
                      this.toggleE2EE(isOn);
                    });
                }
                .width('100%')
                .padding({
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: 12
                });

                if (this.isE2EEEnabled) {
                  Divider().color(getThemeColors().divider);

                  Row() {
                    Text('设备ID')
                      .fontSize(14)
                      .fontColor(getThemeColors().textSecondary);
                    Blank();
                    Text(this.deviceId || '未初始化')
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

                  Divider().color(getThemeColors().divider);

                  Row() {
                    Text('加密状态')
                      .fontSize(14)
                      .fontColor(getThemeColors().textSecondary);
                    Blank();
                    Row() {
                      Circle()
                        .width(8)
                        .height(8)
                        .fill(this.isE2EEEnabled ? getThemeColors().success : getThemeColors().textMute);
                      Text(this.isE2EEEnabled ? '已启用' : '未启用')
                        .fontSize(14)
                        .fontColor(getThemeColors().textMute2)
                        .margin({ left: 6 });
                    }
                  }
                  .width('100%')
                  .padding({
                    left: 20,
                    right: 20,
                    top: 12,
                    bottom: 12
                  });
                }
              }
              .width('100%')
              .backgroundColor(getThemeColors().surface);
            }
            .width('100%')
            .margin({ top: 10 });

            // Verification Settings Section
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
                  Text(this.isE2EEEnabled ? '设备已验证' : '未验证')
                    .fontSize(14)
                    .fontColor(this.isE2EEEnabled ? getThemeColors().success : getThemeColors().textMute2);
                }
                .width('100%')
                .padding({
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: 12
                });

                if (this.isE2EEEnabled) {
                  Divider().color(getThemeColors().divider);

                  Row() {
                    Text('验证其他设备')
                      .fontSize(14)
                      .fontColor(getThemeColors().text);
                    Blank();
                    Button('开始验证')
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
                        this.startDeviceVerification();
                      });
                  }
                  .width('100%')
                  .padding({
                    left: 20,
                    right: 20,
                    top: 12,
                    bottom: 12
                  });
                }
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

            // Invite Management Section
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

            // Notification Settings Section
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
    }
    .width('100%')
    .height('100%')
    .hideTitleBar(true);
  }

  async toggleE2EE(enable: boolean) {
    if (enable) {
      try {
        await this.cryptoService.initialize();
        this.isE2EEEnabled = true;
        this.deviceId = this.cryptoService.getDeviceId();
        ToastUtils.show('端到端加密已启用');
      } catch (error) {
        this.logger.error('Failed to enable E2EE: %{public}s', error.message);
        ToastUtils.show('启用加密失败');
        this.isE2EEEnabled = false;
      }
    } else {
      ToastUtils.show('端到端加密当前无法关闭');
    }
  }

  loadEncryptionStatus() {
    this.isE2EEEnabled = this.cryptoService.isInitialized();
    if (this.isE2EEEnabled) {
      this.deviceId = this.cryptoService.getDeviceId();
    }
  }

  async startDeviceVerification() {
    if (!this.isE2EEEnabled) {
      ToastUtils.show('请先启用端到端加密');
      return;
    }

    try {
      // For demo purposes, we'll show a toast
      // In a real implementation, this would open a device list and allow selecting a device to verify
      ToastUtils.show('设备验证功能开发中');

      // Example of starting SAS verification:
      // const transactionId = await this.verificationService.startSasVerification(userId, deviceId);
      // Then show the SAS verification dialog with the transactionId
    } catch (error) {
      this.logger.error('Failed to start device verification: %{public}s', error.message);
      ToastUtils.show('启动验证失败');
    }
  }

  async handleLogout() {
    try {
      await this.authManager.logout();
      this.pathStack.clear();
    } catch (error) {
      this.logger.error('Logout failed: %{public}s', error.message);
      ToastUtils.show('退出失败');
    }
  }

  async onFindCollaborativeDevices() {
    const isSupported = await this.collaborationManager.isCollaborationSupported();
    if (!isSupported) {
      ToastUtils.show('当前设备不支持跨设备协作');
      return;
    }

    const devices = await this.collaborationManager.getCollaborationDevices();
    if (devices.length === 0) {
      ToastUtils.show('未发现可协作设备');
      return;
    }

    ToastUtils.show(`发现 ${devices.length} 个可协作设备`);
  }

  async onCheckDeviceSecurity() {
    const status = await this.deviceSecurityManager.checkDeviceSecurityStatus();

    let message = '';
    if (status.isTrusted) {
      message = '设备安全: 安全芯片已启用';
    } else if (status.hasSecurityChip) {
      message = '设备安全: 部分安全功能可用';
    } else {
      message = '设备安全: 使用软件级安全保护';
    }

    ToastUtils.show(message, 3000);
  }

  async onScanQRCode() {
    try {
      const result = await this.scanManager.startScan();
      if (result) {
        const parsed = this.scanManager.parseMatrixToLink(result);
        if (parsed && parsed.roomId) {
          ToastUtils.show(`识别房间: ${parsed.roomId}`);
        } else {
          ToastUtils.show('扫描成功，请在加入房间页面使用');
        }
      }
    } catch (error) {
      this.logger.error('Scan error: %{public}s', error.message);
      ToastUtils.show('扫码失败');
    }
  }

  async onToggleBiometric(enable: boolean) {
    if (enable) {
      const success = await this.userAuthManager.authenticateWithFace();
      if (success) {
        this.userAuthManager.setBiometricEnabled(true);
        ToastUtils.show('生物识别登录已启用');
      } else {
        ToastUtils.show('生物识别验证失败');
      }
    } else {
      this.userAuthManager.setBiometricEnabled(false);
      ToastUtils.show('生物识别登录已关闭');
    }
  }

  async onVerifyBiometric() {
    const success = await this.userAuthManager.authenticateWithFace();
    if (success) {
      ToastUtils.show('生物识别验证成功');
    } else {
      ToastUtils.show('生物识别验证失败');
    }
  }

  navigateToInviteManagement() {
    if (this.pathStack) {
      const param: Record<string, Object> = {
        "pathStack": this.pathStack
      };
      this.pathStack.pushPathByName('InviteManagementPage', param);
    }
  }

  navigateToNotificationSettings() {
    if (this.pathStack) {
      const param: Record<string, Object> = {
        "pathStack": this.pathStack
      };
      this.pathStack.pushPathByName('NotificationSettingsPage', param);
    }
  }
}