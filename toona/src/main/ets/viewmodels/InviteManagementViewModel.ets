import { IRoomManager } from '../services/RoomManager';
import { AppLogger } from '../utils/AppLogger';
import { ToastUtils } from '../utils/ToastUtils';

const logger = AppLogger.getLogger('InviteManagementViewModel');

export interface RoomInvite {
  roomId: string;
  name: string;
  topic: string;
  avatarUrl: string;
  inviter: string;
  timestamp: number;
}

export interface InviteManagementState {
  invites: RoomInvite[];
  isLoading: boolean;
  processingInvite: string;
}

export type InviteManagementStateCallback = (state: InviteManagementState) => void;
export type InviteAcceptedCallback = () => void;

export class InviteManagementViewModel {
  private roomManager: IRoomManager;
  private state: InviteManagementState;
  private onStateChanged: InviteManagementStateCallback | null = null;
  private onInviteAccepted: InviteAcceptedCallback | null = null;

  constructor(roomManager: IRoomManager) {
    this.roomManager = roomManager;
    this.state = {
      invites: [],
      isLoading: true,
      processingInvite: ''
    };
  }

  setOnStateChanged(callback: InviteManagementStateCallback): void {
    this.onStateChanged = callback;
  }

  setOnInviteAccepted(callback: InviteAcceptedCallback): void {
    this.onInviteAccepted = callback;
  }

  private notifyStateChanged(): void {
    if (this.onStateChanged) {
      this.onStateChanged(this.state);
    }
  }

  getState(): InviteManagementState {
    return this.state;
  }

  async loadInvites(): Promise<void> {
    this.state.isLoading = true;
    this.notifyStateChanged();
    try {
      this.state.invites = [];
    } catch (error) {
      logger.error('Failed to load invites:', error);
      ToastUtils.show('Failed to load invites');
    } finally {
      this.state.isLoading = false;
      this.notifyStateChanged();
    }
  }

  async acceptInvite(invite: RoomInvite): Promise<void> {
    this.state.processingInvite = invite.roomId;
    this.notifyStateChanged();
    try {
      await this.roomManager.joinRoom(invite.roomId);
      ToastUtils.show('Joined room');
      this.state.invites = this.state.invites.filter((i: RoomInvite): boolean => i.roomId !== invite.roomId);
      if (this.onInviteAccepted) {
        this.onInviteAccepted();
      }
    } catch (error) {
      logger.error('Failed to accept invite:', error);
      ToastUtils.show('Failed to join room');
    } finally {
      this.state.processingInvite = '';
      this.notifyStateChanged();
    }
  }

  async declineInvite(invite: RoomInvite): Promise<void> {
    this.state.processingInvite = invite.roomId;
    this.notifyStateChanged();
    try {
      await this.roomManager.leaveRoom(invite.roomId);
      ToastUtils.show('Invite declined');
      this.state.invites = this.state.invites.filter((i: RoomInvite): boolean => i.roomId !== invite.roomId);
    } catch (error) {
      logger.error('Failed to decline invite:', error);
      ToastUtils.show('Failed to decline invite');
    } finally {
      this.state.processingInvite = '';
      this.notifyStateChanged();
    }
  }
}
