import { ToastUtils } from '../utils/ToastUtils';
import { AppLogger } from '../utils/AppLogger';
import { PushRule } from '../models/types/PushTypes';
import { ServiceLocator } from '../services/ServiceLocator';

const logger = AppLogger.getLogger('NotificationSettingsViewModel');

export interface NotificationSettingsState {
  enableNotifications: boolean;
  enableSound: boolean;
  enableVibration: boolean;
  showMutedRooms: boolean;
  mutedRooms: string[];
  isLoading: boolean;
}

export type NotificationSettingsStateCallback = (state: NotificationSettingsState) => void;

export class NotificationSettingsViewModel {
  private onStateChanged: NotificationSettingsStateCallback | null = null;

  private state: NotificationSettingsState = {
    enableNotifications: true,
    enableSound: true,
    enableVibration: true,
    showMutedRooms: false,
    mutedRooms: [],
    isLoading: true
  };

  setOnStateChanged(callback: NotificationSettingsStateCallback): void {
    this.onStateChanged = callback;
  }

  private notifyStateChanged(): void {
    if (this.onStateChanged) {
      this.onStateChanged(this.state);
    }
  }

  getState(): NotificationSettingsState {
    return this.state;
  }

  initialize(): void {
    this.loadNotificationSettings();
  }

  async loadNotificationSettings(): Promise<void> {
    this.state.isLoading = true;
    this.notifyStateChanged();
    try {
      const pushRules = await ServiceLocator.getPushManager().getPushRules();
      if (pushRules?.global?.underride) {
        const rule = pushRules.global.underride.find(r => r.rule_id === '.m.rule.master');
        this.state.enableNotifications = rule?.enabled !== false;
      }
      if (pushRules?.global?.room) {
        const roomRules: PushRule[] = pushRules.global.room;
        this.state.mutedRooms = roomRules.filter((r: PushRule): boolean => {
          return r.enabled === false;
        }).map((r: PushRule): string => r.rule_id);
      }
    } catch (error) {
      logger.error('Failed to load notification settings:', error);
      ToastUtils.show('Failed to load settings');
    } finally {
      this.state.isLoading = false;
      this.notifyStateChanged();
    }
  }

  async toggleNotifications(enable: boolean): Promise<void> {
    try {
      this.state.enableNotifications = enable;
      ToastUtils.show(enable ? 'Notifications enabled' : 'Notifications disabled');
    } catch (error) {
      logger.error('Failed to toggle notifications:', error);
      ToastUtils.show('Failed to update settings');
    }
    this.notifyStateChanged();
  }

  async toggleSound(enable: boolean): Promise<void> {
    this.state.enableSound = enable;
    ToastUtils.show(enable ? 'Sound enabled' : 'Sound disabled');
    this.notifyStateChanged();
  }

  async toggleVibration(enable: boolean): Promise<void> {
    this.state.enableVibration = enable;
    ToastUtils.show(enable ? 'Vibration enabled' : 'Vibration disabled');
    this.notifyStateChanged();
  }

  toggleMutedRooms(): void {
    this.state.showMutedRooms = !this.state.showMutedRooms;
    this.notifyStateChanged();
  }
}
