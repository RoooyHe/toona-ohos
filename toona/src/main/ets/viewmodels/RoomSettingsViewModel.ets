import { ToastUtils } from '../utils/ToastUtils';
import { AppLogger } from '../utils/AppLogger';
import { IRoomManager } from '../services/RoomManager';

const logger = AppLogger.getLogger('RoomSettingsViewModel');

export interface RoomSettingsState {
  roomId: string;
  roomName: string;
  roomTopic: string;
  editName: string;
  editTopic: string;
  isEditingName: boolean;
  isEditingTopic: boolean;
  memberCount: number;
  isPublic: boolean;
  isLoading: boolean;
}

export type RoomSettingsStateCallback = (state: RoomSettingsState) => void;

export type PopCallback = () => void;

export class RoomSettingsViewModel {
  private roomManager: IRoomManager;
  private onStateChanged: RoomSettingsStateCallback | null = null;
  private popCallback: PopCallback | null = null;

  private state: RoomSettingsState = {
    roomId: '',
    roomName: '',
    roomTopic: '',
    editName: '',
    editTopic: '',
    isEditingName: false,
    isEditingTopic: false,
    memberCount: 0,
    isPublic: false,
    isLoading: true
  };

  constructor(roomId: string, roomName: string, roomManager: IRoomManager) {
    this.state.roomId = roomId;
    this.state.roomName = roomName;
    this.roomManager = roomManager;
  }

  setOnStateChanged(callback: RoomSettingsStateCallback): void {
    this.onStateChanged = callback;
  }

  setPopCallback(callback: PopCallback): void {
    this.popCallback = callback;
  }

  private notifyStateChanged(): void {
    if (this.onStateChanged) {
      this.onStateChanged(this.state);
    }
  }

  getState(): RoomSettingsState {
    return this.state;
  }

  initialize(): void {
    this.loadRoomSettings();
  }

  async loadRoomSettings(): Promise<void> {
    this.state.isLoading = true;
    this.notifyStateChanged();
    try {
      const room = await this.roomManager.getRoom(this.state.roomId);
      if (room) {
        this.state.roomName = room.getDisplayName();
        this.state.roomTopic = room.topic || '';
        this.state.editName = this.state.roomName;
        this.state.editTopic = this.state.roomTopic;
        this.state.memberCount = room.memberCount || 0;
      }
    } catch (error) {
      logger.error('Failed to load room settings:', error);
      ToastUtils.show('Failed to load room settings');
    } finally {
      this.state.isLoading = false;
      this.notifyStateChanged();
    }
  }

  async saveRoomName(): Promise<void> {
    if (!this.state.editName.trim()) {
      ToastUtils.show('Room name cannot be empty');
      return;
    }
    try {
      await this.roomManager.setRoomName(this.state.roomId, this.state.editName.trim());
      this.state.roomName = this.state.editName.trim();
      this.state.isEditingName = false;
      ToastUtils.show('Room name updated');
    } catch (error) {
      logger.error('Failed to update room name:', error);
      ToastUtils.show('Failed to update room name');
    }
    this.notifyStateChanged();
  }

  async saveRoomTopic(): Promise<void> {
    try {
      await this.roomManager.setRoomTopic(this.state.roomId, this.state.editTopic.trim());
      this.state.roomTopic = this.state.editTopic.trim();
      this.state.isEditingTopic = false;
      ToastUtils.show('Room topic updated');
    } catch (error) {
      logger.error('Failed to update room topic:', error);
      ToastUtils.show('Failed to update room topic');
    }
    this.notifyStateChanged();
  }

  async leaveRoom(): Promise<void> {
    try {
      await this.roomManager.leaveRoom(this.state.roomId);
      ToastUtils.show('Left room');
      if (this.popCallback) {
        this.popCallback();
      }
    } catch (error) {
      logger.error('Failed to leave room:', error);
      ToastUtils.show('Failed to leave room');
    }
  }

  setEditingName(editing: boolean): void {
    this.state.isEditingName = editing;
    this.notifyStateChanged();
  }

  setEditingTopic(editing: boolean): void {
    this.state.isEditingTopic = editing;
    this.notifyStateChanged();
  }

  setEditName(name: string): void {
    this.state.editName = name;
    this.notifyStateChanged();
  }

  setEditTopic(topic: string): void {
    this.state.editTopic = topic;
    this.notifyStateChanged();
  }
}
