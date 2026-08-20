import { UserProfile } from '../models/DataModels';
import { PresenceState } from '../models/MatrixTypes';
import { IUserManager } from '../services/UserManager';
import { AppLogger } from '../utils/AppLogger';
import { ToastUtils } from '../utils/ToastUtils';

const logger = AppLogger.getLogger('UserProfileViewModel');

export interface UserProfileState {
  userId: string;
  displayName: string;
  avatarUrl: string;
  presence: PresenceState;
  statusMsg: string;
  isLoading: boolean;
}

export type UserProfileStateCallback = (state: UserProfileState) => void;
export type StartDirectChatCallback = () => void;

export class UserProfileViewModel {
  private userManager: IUserManager;
  private state: UserProfileState;
  private onStateChanged: UserProfileStateCallback | null = null;
  private onStartDirectChat: StartDirectChatCallback | null = null;

  constructor(userId: string, userManager: IUserManager) {
    this.userManager = userManager;
    this.state = {
      userId: userId,
      displayName: '',
      avatarUrl: '',
      presence: 'offline' as PresenceState,
      statusMsg: '',
      isLoading: true
    };
  }

  setOnStateChanged(callback: UserProfileStateCallback): void {
    this.onStateChanged = callback;
  }

  setOnStartDirectChat(callback: StartDirectChatCallback): void {
    this.onStartDirectChat = callback;
  }

  private notifyStateChanged(): void {
    if (this.onStateChanged) {
      this.onStateChanged(this.state);
    }
  }

  getState(): UserProfileState {
    return this.state;
  }

  async loadUserProfile(): Promise<void> {
    this.state.isLoading = true;
    this.notifyStateChanged();
    try {
      const profilePromise: Promise<UserProfile> = this.userManager.getUserProfile(this.state.userId);
      const presencePromise = this.userManager.getPresence(this.state.userId);
      const profile: UserProfile = await profilePromise;
      this.state.displayName = profile.displayName || '';
      this.state.avatarUrl = profile.avatarUrl || '';
      const presenceResponse = await presencePromise;
      this.state.presence = presenceResponse.presence as PresenceState;
      this.state.statusMsg = presenceResponse.status_msg || '';
    } catch (error) {
      logger.error('Failed to load user profile:', error);
      ToastUtils.show('Failed to load profile');
    } finally {
      this.state.isLoading = false;
      this.notifyStateChanged();
    }
  }

  startDirectChat(): void {
    ToastUtils.show('Starting direct chat...');
    if (this.onStartDirectChat) {
      this.onStartDirectChat();
    }
  }
}
