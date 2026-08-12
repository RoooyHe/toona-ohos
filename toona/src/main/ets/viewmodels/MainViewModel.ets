import { ToastUtils } from '../utils/ToastUtils';
import { AppLogger } from '../utils/AppLogger';
import { ISyncManager } from '../services/SyncManager';
import { IRoomManager } from '../services/RoomManager';
import { RoomTagManager } from '../services/RoomTagManager';
import { ServiceLocator } from '../services/ServiceLocator';

const logger = AppLogger.getLogger('MainViewModel');

export interface MainState {
  userInitial: string;
  userDisplayName: string;
  userAvatarUrl: string;
  currentFilter: string;
  unreadCountAll: number;
  unreadCountUnread: number;
  unreadCountDm: number;
  unreadCountRoom: number;
  unreadCountInvite: number;
  syncStatus: string;
}

export type MainStateCallback = (state: MainState) => void;

export type LogoutCallback = () => void;

export class MainViewModel {
  private syncManager: ISyncManager = ServiceLocator.getSyncManager();
  private roomManager: IRoomManager = ServiceLocator.getRoomManager();
  private roomTagManager: RoomTagManager = ServiceLocator.getRoomTagManager();
  private onStateChanged: MainStateCallback | null = null;
  private logoutCallback: LogoutCallback | null = null;

  private state: MainState = {
    userInitial: '',
    userDisplayName: '',
    userAvatarUrl: '',
    currentFilter: 'all',
    unreadCountAll: 0,
    unreadCountUnread: 0,
    unreadCountDm: 0,
    unreadCountRoom: 0,
    unreadCountInvite: 0,
    syncStatus: 'synced'
  };

  setOnStateChanged(callback: MainStateCallback): void {
    this.onStateChanged = callback;
  }

  setLogoutCallback(callback: LogoutCallback): void {
    this.logoutCallback = callback;
  }

  private notifyStateChanged(): void {
    if (this.onStateChanged) {
      this.onStateChanged(this.state);
    }
  }

  getState(): MainState {
    return this.state;
  }

  getSyncManager(): ISyncManager {
    return this.syncManager;
  }

  getRoomManager(): IRoomManager {
    return this.roomManager;
  }

  getRoomTagManager(): RoomTagManager {
    return this.roomTagManager;
  }

  initialize(): void {
    this.state.syncStatus = 'syncing';
    this.notifyStateChanged();

    const self = this;
    this.syncManager.setSyncSuccessCallback(() => {
      logger.info('Sync success callback triggered');
      self.state.syncStatus = 'synced';
      self.loadUnreadCounts();
      self.notifyStateChanged();
    });

    this.syncManager.setSyncErrorCallback(() => {
      logger.info('Sync error callback triggered');
      self.state.syncStatus = 'error';
      self.notifyStateChanged();
    });

    this.tryInitSync();
  }

  destroy(): void {
    this.syncManager.stop().catch((error: Error) => {
      logger.error('Failed to stop sync:', error);
    });
  }

  async tryInitSync(): Promise<void> {
    try {
      await this.syncManager.init(getContext());
      await this.syncManager.start();
      const session = ServiceLocator.getAuthManager().getSession();
      if (session) {
        const userId = session.userId;
        const colonIndex = userId.indexOf(':');
        this.state.userInitial = colonIndex > 0 ? userId.charAt(1).toUpperCase() : userId.charAt(0).toUpperCase();
      }
      await this.loadUserProfile();
    } catch (error) {
      logger.error('Failed to init sync: ' + error);
      this.state.syncStatus = 'error';
      ToastUtils.show('同步初始化失败', 3000);
      this.notifyStateChanged();
    }
  }

  async loadUnreadCounts(): Promise<void> {
    try {
      const rooms = await this.roomManager.getRooms();
      let totalUnread = 0;
      let totalDm = 0;
      let totalRoom = 0;
      let totalInvite = 0;

      for (let i = 0; i < rooms.length; i++) {
        const room = rooms[i];
        if (room.isSpace) {
          continue;
        }
        if (room.unreadCount && room.unreadCount > 0) {
          totalUnread = totalUnread + room.unreadCount;
        }
        if (room.isDirect === true && room.unreadCount && room.unreadCount > 0) {
          totalDm = totalDm + room.unreadCount;
        }
        if (room.isDirect !== true && room.unreadCount && room.unreadCount > 0) {
          totalRoom = totalRoom + room.unreadCount;
        }
      }

      this.state.unreadCountAll = totalUnread;
      this.state.unreadCountUnread = totalUnread;
      this.state.unreadCountDm = totalDm;
      this.state.unreadCountRoom = totalRoom;
      this.state.unreadCountInvite = totalInvite;
    } catch (error) {
      logger.error('Failed to load unread counts:', error);
    }
    this.notifyStateChanged();
  }

  async loadUserProfile(): Promise<void> {
    try {
      const userManager = ServiceLocator.getUserManager();
      const profile = await userManager.getUserProfile();
      this.state.userDisplayName = profile.displayName || '';
      this.state.userAvatarUrl = profile.avatarUrl || '';
      if (this.state.userDisplayName && !this.state.userInitial) {
        this.state.userInitial = this.state.userDisplayName.charAt(0).toUpperCase();
      }
    } catch (error) {
      logger.error('Failed to load user profile:', error);
      ToastUtils.show('用户信息加载失败', 2000);
    }
    this.notifyStateChanged();
  }

  async handleLogout(): Promise<void> {
    try {
      await ServiceLocator.getAuthManager().logout();
      if (this.logoutCallback) {
        this.logoutCallback();
      }
    } catch (error) {
      logger.error('Logout failed:', error);
      ToastUtils.show('退出登录失败', 3000);
    }
  }

  setFilter(filter: string): void {
    this.state.currentFilter = filter;
    this.notifyStateChanged();
  }
}
