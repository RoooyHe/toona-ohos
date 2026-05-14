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
  private logger = AppLogger.getLogger(SettingsPage);
  @Prop pathStack: NavPathStack;

  aboutToAppear() {
    const session = this.authManager.getSession();
    if (session) {
      this.userId = session.userId;
    }
    this.colorModeType = this.themeManager.getColorModeType();
    this.loadUserData();
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
                .fontColor('#999999')
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

            QRScannerSettings({
              onScanQRCode: () => {
                this.onScanQRCode();
              }
            });

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
}