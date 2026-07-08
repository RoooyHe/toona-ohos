import { ToastUtils } from '../utils/ToastUtils';
import { UserManager } from '../services/UserManager';
import { PresenceManager } from '../services/PresenceManager';
import { MediaManager } from '../services/MediaManager';
import { getThemeColors } from '../utils/ThemeManager';
import { PresenceState } from '../models/MatrixTypes';
import { AppLogger } from '../utils/AppLogger';

const logger = AppLogger.getLogger('UserProfilePage');

@Builder
export function UserProfilePageBuilder(name: string, param: Object) {
  UserProfilePage({
    userId: ((param as Record<string, Object>)['userId'] as string) || '',
    pathStack: ((param as Record<string, Object>)['pathStack'] as NavPathStack) || new NavPathStack()
  })
}

@Component
struct UserProfilePage {
  @State userId: string = '';
  @State displayName: string = '';
  @State avatarUrl: string = '';
  @State presence: PresenceState = 'offline';
  @State statusMsg: string = '';
  @State isLoading: boolean = true;
  private userManager: UserManager = UserManager.getInstance();
  private presenceManager: PresenceManager = PresenceManager.getInstance();
  private mediaManager: MediaManager = MediaManager.getInstance();
  @Prop pathStack: NavPathStack;
  private logger = AppLogger.getLogger('UserProfilePage');

  aboutToAppear() {
    this.loadUserProfile();
  }

  async loadUserProfile() {
    this.isLoading = true;
    try {
      const profile = await this.userManager.getUserProfile(this.userId);
      this.displayName = profile.displayname || '';
      this.avatarUrl = profile.avatar_url || '';

      const presenceResponse = await this.presenceManager.getPresence(this.userId);
      this.presence = presenceResponse.presence as PresenceState;
      this.statusMsg = presenceResponse.status_msg || '';
    } catch (error) {
      this.logger.error('Failed to load user profile:', error);
      ToastUtils.show('Failed to load profile');
    } finally {
      this.isLoading = false;
    }
  }

  async startDirectChat() {
    try {
      // In a real implementation, this would create a direct chat with the user
      ToastUtils.show('Starting direct chat...');
      this.pathStack.pop();
    } catch (error) {
      this.logger.error('Failed to start direct chat:', error);
      ToastUtils.show('Failed to start chat');
    }
  }

  getPresenceText(state: PresenceState): string {
    switch (state) {
      case 'online': return 'Online';
      case 'offline': return 'Offline';
      case 'unavailable': return 'Away';
      default: return 'Unknown';
    }
  }

  getPresenceColor(state: PresenceState): string {
    switch (state) {
      case 'online': return getThemeColors().success;
      case 'offline': return getThemeColors().textMute;
      case 'unavailable': return getThemeColors().warning;
      default: return getThemeColors().textMute;
    }
  }

  build() {
    NavDestination() {
      Column() {
        // Header
        Row() {
          Button('←')
            .fontSize(18)
            .backgroundColor('transparent')
            .fontColor(getThemeColors().primary)
            .width(36)
            .height(36)
            .onClick(() => {
              this.pathStack.pop();
            });

          Text('User Profile')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(getThemeColors().text)
            .layoutWeight(1);
        }
        .width('100%')
        .padding({ left: 10, right: 10, top: 10, bottom: 10 })
        .backgroundColor(getThemeColors().bg);

        Divider().color(getThemeColors().divider);

        if (this.isLoading) {
          Column() {
            LoadingProgress()
              .width(40)
              .height(40);
            Text('Loading...')
              .fontSize(14)
              .fontColor(getThemeColors().textSecondary)
              .margin({ top: 10 });
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center);
        } else {
          Scroll() {
            Column() {
              // Avatar and Name Section
              Column() {
                // Avatar
                Stack() {
                  if (this.avatarUrl) {
                    Image(this.mediaManager.getHttpUrl(this.avatarUrl))
                      .width(80)
                      .height(80)
                      .borderRadius(40);
                  } else {
                    Text(this.displayName.charAt(0).toUpperCase() || '?')
                      .fontSize(32)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(getThemeColors().onPrimary)
                      .width(80)
                      .height(80)
                      .borderRadius(40)
                      .backgroundColor(getThemeColors().primary)
                      .textAlign(TextAlign.Center);
                  }

                  // Presence indicator
                  Circle()
                    .width(16)
                    .height(16)
                    .fill(this.getPresenceColor(this.presence))
                    .stroke(getThemeColors().surface)
                    .strokeWidth(2)
                    .position({ x: 60, y: 60 });
                }
                .width(80)
                .height(80)
                .margin({ bottom: 16 });

                // Display Name
                Text(this.displayName || 'Unknown User')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(getThemeColors().text)
                  .margin({ bottom: 8 });

                // User ID
                Text(this.userId)
                  .fontSize(14)
                  .fontColor(getThemeColors().textSecondary)
                  .margin({ bottom: 8 });

                // Presence Status
                Row() {
                  Circle()
                    .width(8)
                    .height(8)
                    .fill(this.getPresenceColor(this.presence));
                  Text(this.getPresenceText(this.presence))
                    .fontSize(14)
                    .fontColor(getThemeColors().textSecondary)
                    .margin({ left: 6 });
                }
                .margin({ bottom: 8 });

                // Status Message
                if (this.statusMsg) {
                  Text(this.statusMsg)
                    .fontSize(14)
                    .fontColor(getThemeColors().textMute2)
                    .margin({ bottom: 16 });
                }
              }
              .width('100%')
              .padding(20)
              .backgroundColor(getThemeColors().surface);

              Divider().color(getThemeColors().divider);

              // Actions Section
              Column() {
                Button('Start Direct Chat')
                  .fontSize(16)
                  .backgroundColor(getThemeColors().primary)
                  .fontColor(getThemeColors().onPrimary)
                  .borderRadius(6)
                  .width('100%')
                  .height(44)
                  .margin({ left: 20, right: 20, top: 20, bottom: 10 })
                  .onClick(() => {
                    this.startDirectChat();
                  });

                Button('Block User')
                  .fontSize(16)
                  .backgroundColor(getThemeColors().bg)
                  .fontColor(getThemeColors().error)
                  .borderWidth(1)
                  .borderColor(getThemeColors().error)
                  .borderRadius(6)
                  .width('100%')
                  .height(44)
                  .margin({ left: 20, right: 20, bottom: 20 })
                  .onClick(() => {
                    ToastUtils.show('Block user feature coming soon');
                  });
              }
              .width('100%')
              .backgroundColor(getThemeColors().surface);
            }
            .width('100%');
          }
          .layoutWeight(1);
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(getThemeColors().bg);
    }
    .hideTitleBar(true);
  }
}
