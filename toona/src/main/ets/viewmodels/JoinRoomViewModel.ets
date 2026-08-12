import { ToastUtils } from '../utils/ToastUtils';
import { AppLogger } from '../utils/AppLogger';
import { ScanManager } from '../services/ScanManager';
import { ServiceLocator } from '../services/ServiceLocator';
import { CreateRoomOptions } from '../services/RoomManager';

const logger = AppLogger.getLogger('JoinRoomViewModel');

interface DirectoryUser {
  user_id: string;
  display_name?: string;
  avatar_url?: string;
}

export interface JoinRoomState {
  searchQuery: string;
  searchResults: DirectoryUser[];
  isSearching: boolean;
  roomAddress: string;
  isJoining: boolean;
}

export type JoinRoomStateCallback = (state: JoinRoomState) => void;

export type NavigateCallback = (pageName: string, param: Record<string, Object>) => void;

export type PopCallback = () => void;

export class JoinRoomViewModel {
  private roomManager = ServiceLocator.getRoomManager();
  private authManager = ServiceLocator.getAuthManager();
  private scanManager: ScanManager = ServiceLocator.getScanManager();
  private onStateChanged: JoinRoomStateCallback | null = null;
  private navigateCallback: NavigateCallback | null = null;
  private popCallback: PopCallback | null = null;

  private state: JoinRoomState = {
    searchQuery: '',
    searchResults: [],
    isSearching: false,
    roomAddress: '',
    isJoining: false
  };

  setOnStateChanged(callback: JoinRoomStateCallback): void {
    this.onStateChanged = callback;
  }

  setNavigateCallback(callback: NavigateCallback): void {
    this.navigateCallback = callback;
  }

  setPopCallback(callback: PopCallback): void {
    this.popCallback = callback;
  }

  private notifyStateChanged(): void {
    if (this.onStateChanged) {
      this.onStateChanged(this.state);
    }
  }

  getState(): JoinRoomState {
    return this.state;
  }

  async searchUsers(): Promise<void> {
    if (!this.state.searchQuery.trim()) {
      return;
    }
    this.state.isSearching = true;
    this.notifyStateChanged();
    try {
      const results = await this.roomManager.searchUsers(this.state.searchQuery.trim());
      const resultObj: Record<string, string | object> = results;
      const userId: string = (resultObj['user_id'] as string) || '';
      const mapped: DirectoryUser[] = [{
        user_id: userId,
        display_name: (resultObj['display_name'] as string) || userId,
        avatar_url: (resultObj['avatar_url'] as string) || ''
      }];
      this.state.searchResults = mapped;
    } catch (error) {
      logger.error('Search users failed:', error);
      this.state.searchResults = [];
    } finally {
      this.state.isSearching = false;
      this.notifyStateChanged();
    }
  }

  async startDirectChat(userId: string): Promise<void> {
    try {
      const options: CreateRoomOptions = {
        isDirect: true,
        inviteUsers: [userId]
      };
      const roomId = await this.roomManager.createRoom(options);
      if (this.navigateCallback) {
        const param: Record<string, Object> = {
          "roomId": roomId,
          "roomName": userId
        };
        this.navigateCallback('RoomDetailPage', param);
      }
    } catch (error) {
      logger.error('Failed to start direct chat:', error);
      ToastUtils.show('创建私聊失败');
    }
  }

  async onScanQRCode(): Promise<void> {
    try {
      const result = await this.scanManager.startScan();
      if (result) {
        const parsed = this.scanManager.parseMatrixToLink(result);
        if (parsed && parsed.roomId) {
          this.state.roomAddress = parsed.roomId;
          ToastUtils.show('已识别房间，可点击加入');
        } else {
          this.state.roomAddress = result;
          ToastUtils.show('已扫描内容');
        }
        this.notifyStateChanged();
      }
    } catch (error) {
      logger.error('Scan error: %{public}s', error.message);
      ToastUtils.show('扫码失败');
    }
  }

  async joinRoom(): Promise<void> {
    if (!this.state.roomAddress.trim()) {
      ToastUtils.show('请输入房间地址');
      return;
    }
    this.state.isJoining = true;
    this.notifyStateChanged();
    try {
      let roomId = this.state.roomAddress.trim();
      if (!roomId.startsWith('#') && !roomId.includes(':')) {
        roomId = `#${roomId}:${this.authManager.getHomeserver()}`;
      }
      await this.roomManager.joinRoom(roomId);
      ToastUtils.show('加入成功');
      if (this.popCallback) {
        this.popCallback();
      }
    } catch (error) {
      logger.error('Failed to join room:', error);
      ToastUtils.show('加入失败');
    } finally {
      this.state.isJoining = false;
      this.notifyStateChanged();
    }
  }

  async createRoom(roomName: string, isPublic: boolean): Promise<void> {
    try {
      const options: CreateRoomOptions = {
        name: roomName.trim(),
        visibility: isPublic ? 'public' : 'private'
      };
      await this.roomManager.createRoom(options);
      ToastUtils.show('创建成功');
      if (this.popCallback) {
        this.popCallback();
      }
    } catch (error) {
      logger.error('Failed to create room:', error);
      ToastUtils.show('创建失败');
    }
  }

  setSearchQuery(query: string): void {
    this.state.searchQuery = query;
    this.notifyStateChanged();
  }

  setRoomAddress(address: string): void {
    this.state.roomAddress = address;
    this.notifyStateChanged();
  }
}
