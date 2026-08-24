import { ToastUtils } from '../utils/ToastUtils';
import { AppLogger } from '../utils/AppLogger';
import { IAuthManager } from '../services/AuthManager';
import { IRoomManager } from '../services/RoomManager';
import { IUserManager } from '../services/UserManager';
import { IMediaManager } from '../services/MediaManager';
import { IRoomTagManager } from '../services/RoomTagManager';
import { IDeviceManager } from '../services/DeviceManager';
import { IShareManager } from '../services/ShareManager';
import { IFilePicker, SelectedFile } from '../platform/adapters/IFilePicker';
import { Room } from '../models/DataModels';
import { UserProfile } from '../models/DataModels';
import { Device } from '../models/MatrixTypes';
import { PresenceState } from '../models/MatrixTypes';
import { ThemeManager, ColorModeType } from '../utils/ThemeManager';

const logger = AppLogger.getLogger('SettingsViewModel');

export interface SettingsDeps {
  authManager: IAuthManager;
  roomManager: IRoomManager;
  userManager: IUserManager;
  mediaManager: IMediaManager;
  roomTagManager: IRoomTagManager;
  deviceManager: IDeviceManager;
  shareManager: IShareManager;
  filePicker: IFilePicker;
}

export type DeviceSecurityCallback = () => void;

export type ScanCallback = () => void;

export type BiometricToggleCallback = (enable: boolean) => void;

export type BiometricVerifyCallback = () => void;

export type CollaborationCallback = () => void;

export interface SettingsState {
  userId: string;
  displayName: string;
  avatarUrl: string;
  presence: PresenceState;
  statusMsg: string;
  devices: Device[];
  favoriteRooms: Room[];
  lowPriorityRooms: Room[];
  allRooms: Room[];
  isLoadingProfile: boolean;
  isLoadingDevices: boolean;
  isLoadingRoomTags: boolean;
  isEditingName: boolean;
  editName: string;
  showPresenceMenu: boolean;
  showRoomTagsMenu: boolean;
  colorModeType: ColorModeType;
  isE2EEEnabled: boolean;
  currentDeviceId: string;
}

export type SettingsStateCallback = (state: SettingsState) => void;

export type LogoutCallback = () => void;

export class SettingsViewModel {
  private authManager: IAuthManager;
  private roomManager: IRoomManager;
  private userManager: IUserManager;
  private mediaManager: IMediaManager;
  private roomTagManager: IRoomTagManager;
  private deviceManager: IDeviceManager;
  private shareManager: IShareManager;
  private filePicker: IFilePicker;
  private themeManager: ThemeManager = ThemeManager.getInstance();
  private onStateChanged: SettingsStateCallback | null = null;
  private logoutCallback: LogoutCallback | null = null;
  private onDeviceSecurity: DeviceSecurityCallback | null = null;
  private onScan: ScanCallback | null = null;
  private onBiometricToggle: BiometricToggleCallback | null = null;
  private onBiometricVerify: BiometricVerifyCallback | null = null;
  private onCollaboration: CollaborationCallback | null = null;

  private state: SettingsState = {
    userId: '',
    displayName: '',
    avatarUrl: '',
    presence: 'online',
    statusMsg: '',
    devices: [],
    favoriteRooms: [],
    lowPriorityRooms: [],
    allRooms: [],
    isLoadingProfile: true,
    isLoadingDevices: true,
    isLoadingRoomTags: true,
    isEditingName: false,
    editName: '',
    showPresenceMenu: false,
    showRoomTagsMenu: false,
    colorModeType: 'light',
    isE2EEEnabled: false,
    currentDeviceId: ''
  };

  constructor(deps: SettingsDeps) {
    this.authManager = deps.authManager;
    this.roomManager = deps.roomManager;
    this.userManager = deps.userManager;
    this.mediaManager = deps.mediaManager;
    this.roomTagManager = deps.roomTagManager;
    this.deviceManager = deps.deviceManager;
    this.shareManager = deps.shareManager;
    this.filePicker = deps.filePicker;
  }

  setOnStateChanged(callback: SettingsStateCallback): void {
    this.onStateChanged = callback;
  }

  setLogoutCallback(callback: LogoutCallback): void {
    this.logoutCallback = callback;
  }

  setOnDeviceSecurity(callback: DeviceSecurityCallback): void {
    this.onDeviceSecurity = callback;
  }

  setOnScan(callback: ScanCallback): void {
    this.onScan = callback;
  }

  setOnBiometricToggle(callback: BiometricToggleCallback): void {
    this.onBiometricToggle = callback;
  }

  setOnBiometricVerify(callback: BiometricVerifyCallback): void {
    this.onBiometricVerify = callback;
  }

  setOnCollaboration(callback: CollaborationCallback): void {
    this.onCollaboration = callback;
  }

  private notifyStateChanged(): void {
    if (this.onStateChanged) {
      this.onStateChanged(this.state);
    }
  }

  getState(): SettingsState {
    return this.state;
  }

  initialize(): void {
    const session = this.authManager.getSession();
    if (session) {
      this.state.userId = session.userId;
      this.state.displayName = session.userId;
      this.state.currentDeviceId = session.deviceId || '';
    }
    this.state.colorModeType = this.themeManager.getColorModeType();
    this.state.isE2EEEnabled = false;
    this.loadProfile();
    this.loadDevices();
    this.loadRoomTags();
    this.notifyStateChanged();
  }

  setColorMode(mode: ColorModeType): void {
    this.state.colorModeType = mode;
    this.themeManager.setColorMode(mode);
    const messages: Record<ColorModeType, string> = {
      'light': '日间模式',
      'dark': '夜间模式',
      'system': '跟随系统'
    };
    ToastUtils.show(`已切换至${messages[mode]}`);
    this.notifyStateChanged();
  }

  async loadProfile(): Promise<void> {
    this.state.isLoadingProfile = true;
    this.notifyStateChanged();
    try {
      const profilePromise = this.userManager.getUserProfile();
      const presencePromise = this.userManager.getPresence(this.state.userId);
      const profile: UserProfile = await profilePromise;
      this.state.displayName = profile.displayName || '';
      this.state.avatarUrl = profile.avatarUrl || '';
      this.state.editName = this.state.displayName;
      const presenceResponse = await presencePromise;
      this.state.presence = presenceResponse.presence as PresenceState;
      this.state.statusMsg = presenceResponse.status_msg || '';
    } catch (error) {
      logger.error('Failed to load profile: %{public}s', error.message);
    } finally {
      this.state.isLoadingProfile = false;
      this.notifyStateChanged();
    }
  }

  async loadDevices(): Promise<void> {
    this.state.isLoadingDevices = true;
    this.notifyStateChanged();
    try {
      const devicesResponse = await this.deviceManager.getDevices();
      this.state.devices = devicesResponse.devices || [];
    } catch (e) {
      logger.error('Failed to load devices: %{public}s', e.message);
      this.state.devices = [];
    } finally {
      this.state.isLoadingDevices = false;
      this.notifyStateChanged();
    }
  }

  async loadRoomTags(): Promise<void> {
    this.state.isLoadingRoomTags = true;
    this.notifyStateChanged();
    try {
      this.state.allRooms = await this.roomManager.getRooms() as Room[];
      this.state.favoriteRooms = [];
      this.state.lowPriorityRooms = [];
      for (let i = 0; i < this.state.allRooms.length; i++) {
        const room = this.state.allRooms[i];
        try {
          const isFav = await this.roomTagManager.isFavorite(room.id);
          if (isFav) {
            this.state.favoriteRooms.push(room);
          }
          const isLow = await this.roomTagManager.isLowPriority(room.id);
          if (isLow) {
            this.state.lowPriorityRooms.push(room);
          }
        } catch (e) {
          logger.error('Failed to check room tags: %{public}s', e.message);
        }
      }
    } catch (error) {
      logger.error('Failed to load room tags: %{public}s', error.message);
    } finally {
      this.state.isLoadingRoomTags = false;
      this.notifyStateChanged();
    }
  }

  async saveDisplayName(): Promise<void> {
    if (!this.state.editName.trim()) {
      return;
    }
    try {
      await this.userManager.setDisplayName(this.state.editName.trim());
      this.state.displayName = this.state.editName.trim();
      this.state.isEditingName = false;
      ToastUtils.show('显示名称已更新');
    } catch (error) {
      logger.error('Failed to save display name: %{public}s', error.message);
      ToastUtils.show('更新失败');
    }
    this.notifyStateChanged();
  }

  async setPresence(state: PresenceState): Promise<void> {
    try {
      await this.userManager.setPresence(this.state.userId, state, this.state.statusMsg);
      this.state.presence = state;
      this.state.showPresenceMenu = false;
      ToastUtils.show('状态已更新');
    } catch (error) {
      logger.error('Failed to set presence: %{public}s', error.message);
      ToastUtils.show('更新失败');
    }
    this.notifyStateChanged();
  }

  async setStatusMessage(): Promise<void> {
    try {
      await this.userManager.setPresence(this.state.userId, this.state.presence, this.state.statusMsg);
      ToastUtils.show('状态消息已更新');
    } catch (error) {
      logger.error('Failed to set status message: %{public}s', error.message);
      ToastUtils.show('更新失败');
    }
  }

  async pickAndUploadAvatar(): Promise<void> {
    try {
      const selected: SelectedFile | null = await this.filePicker.selectImage();
      if (selected) {
        const fileName: string = 'avatar_' + Date.now() + '.jpg';
        const mxcUri: string = await this.mediaManager.uploadImage(selected.buffer, fileName);
        await this.userManager.setAvatarUrl(mxcUri);
        this.state.avatarUrl = this.mediaManager.getHttpUrl(mxcUri);
        ToastUtils.show('头像已更新');
      }
    } catch (error) {
      logger.error('Failed to upload avatar: %{public}s', error.message);
      ToastUtils.show('头像上传失败');
    }
    this.notifyStateChanged();
  }

  async toggleFavorite(room: Room): Promise<void> {
    try {
      const isFav = await this.roomTagManager.isFavorite(room.id);
      if (isFav) {
        await this.roomTagManager.removeFavorite(room.id);
        const index = this.state.favoriteRooms.findIndex(r => r.id === room.id);
        if (index >= 0) {
          this.state.favoriteRooms.splice(index, 1);
        }
      } else {
        await this.roomTagManager.addFavorite(room.id);
        this.state.favoriteRooms.push(room);
      }
      ToastUtils.show(isFav ? '已取消收藏' : '已添加收藏');
    } catch (error) {
      logger.error('Failed to toggle favorite: %{public}s', error.message);
      ToastUtils.show('操作失败');
    }
    this.notifyStateChanged();
  }

  async toggleLowPriority(room: Room): Promise<void> {
    try {
      const isLow = await this.roomTagManager.isLowPriority(room.id);
      if (isLow) {
        await this.roomTagManager.removeLowPriority(room.id);
        const index = this.state.lowPriorityRooms.findIndex(r => r.id === room.id);
        if (index >= 0) {
          this.state.lowPriorityRooms.splice(index, 1);
        }
      } else {
        await this.roomTagManager.addLowPriority(room.id);
        this.state.lowPriorityRooms.push(room);
      }
      ToastUtils.show(isLow ? '已取消低优先级' : '已设为低优先级');
    } catch (error) {
      logger.error('Failed to toggle low priority: %{public}s', error.message);
      ToastUtils.show('操作失败');
    }
    this.notifyStateChanged();
  }

  async deleteDevice(deviceId: string): Promise<void> {
    try {
      await this.deviceManager.deleteDevice(deviceId);
      const index = this.state.devices.findIndex(d => d.device_id === deviceId);
      if (index >= 0) {
        this.state.devices.splice(index, 1);
      }
      ToastUtils.show('设备已删除');
    } catch (error) {
      logger.error('Failed to delete device: %{public}s', error.message);
      ToastUtils.show('删除失败');
    }
    this.notifyStateChanged();
  }

  async handleLogout(): Promise<void> {
    try {
      await this.authManager.logout();
      if (this.logoutCallback) {
        this.logoutCallback();
      }
    } catch (error) {
      logger.error('Logout failed: %{public}s', error.message);
      ToastUtils.show('退出失败');
    }
  }

  async onFindCollaborativeDevices(): Promise<void> {
    if (this.onCollaboration) {
      this.onCollaboration();
    }
  }

  async onCheckDeviceSecurity(): Promise<void> {
    if (this.onDeviceSecurity) {
      this.onDeviceSecurity();
    }
  }

  async onScanQRCode(): Promise<void> {
    if (this.onScan) {
      this.onScan();
    }
  }

  async onToggleBiometric(enable: boolean): Promise<void> {
    if (this.onBiometricToggle) {
      this.onBiometricToggle(enable);
    }
  }

  async onVerifyBiometric(): Promise<void> {
    if (this.onBiometricVerify) {
      this.onBiometricVerify();
    }
  }

  setEditingName(editing: boolean): void {
    this.state.isEditingName = editing;
    if (!editing) {
      this.state.editName = this.state.displayName;
    }
    this.notifyStateChanged();
  }

  setEditName(name: string): void {
    this.state.editName = name;
    this.notifyStateChanged();
  }

  togglePresenceMenu(): void {
    this.state.showPresenceMenu = !this.state.showPresenceMenu;
    this.notifyStateChanged();
  }

  setStatusMsg(msg: string): void {
    this.state.statusMsg = msg;
    this.notifyStateChanged();
  }

  toggleRoomTagsMenu(): void {
    this.state.showRoomTagsMenu = !this.state.showRoomTagsMenu;
    this.notifyStateChanged();
  }
}
