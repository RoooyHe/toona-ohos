import { ToastUtils } from '../utils/ToastUtils';
import { getThemeColors } from '../utils/ThemeManager';
import { AppLogger } from '../utils/AppLogger';
import { PushRule } from '../models/types/PushTypes';
import { ServiceRegistry } from '../services/ServiceRegistry';

const logger = AppLogger.getLogger('NotificationSettingsPage');

@Builder
export function NotificationSettingsPageBuilder(name: string, param: Object) {
  NotificationSettingsPage()
}

@Component
struct NotificationSettingsPage {
  @State enableNotifications: boolean = true;
  @State enableSound: boolean = true;
  @State enableVibration: boolean = true;
  @State showMutedRooms: boolean = false;
  @State mutedRooms: string[] = [];
  @State isLoading: boolean = true;
  pathStack: NavPathStack = new NavPathStack();
  private logger = AppLogger.getLogger('NotificationSettingsPage');

  aboutToAppear() {
    this.loadNotificationSettings();
  }

  async loadNotificationSettings() {
    this.isLoading = true;
    try {
      // Load push rules from server
      const pushRules = await ServiceRegistry.getCurrent().getPushManager().getPushRules();
      
      // Check if notifications are enabled globally
      if (pushRules?.global?.underride) {
        const rule = pushRules.global.underride.find(r => r.rule_id === '.m.rule.master');
        this.enableNotifications = rule?.enabled !== false;
      }

      // Load muted rooms
      if (pushRules?.global?.room) {
        const roomRules: PushRule[] = pushRules.global.room;
        this.mutedRooms = roomRules.filter((r: PushRule): boolean => {
          return r.enabled === false;
        }).map((r: PushRule): string => r.rule_id);
      }
    } catch (error) {
      this.logger.error('Failed to load notification settings:', error);
      ToastUtils.show('Failed to load settings');
    } finally {
      this.isLoading = false;
    }
  }

  async toggleNotifications(enable: boolean) {
    try {
      this.enableNotifications = enable;
      // In a real implementation, this would update the master push rule
      ToastUtils.show(enable ? 'Notifications enabled' : 'Notifications disabled');
    } catch (error) {
      this.logger.error('Failed to toggle notifications:', error);
      ToastUtils.show('Failed to update settings');
    }
  }

  async toggleSound(enable: boolean) {
    this.enableSound = enable;
    ToastUtils.show(enable ? 'Sound enabled' : 'Sound disabled');
  }

  async toggleVibration(enable: boolean) {
    this.enableVibration = enable;
    ToastUtils.show(enable ? 'Vibration enabled' : 'Vibration disabled');
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

          Text('Notification Settings')
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
            Text('Loading settings...')
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
              // Global Notifications Toggle
              Column() {
                Row() {
                  Text('Enable Notifications')
                    .fontSize(16)
                    .fontColor(getThemeColors().text)
                    .layoutWeight(1);
                  Toggle({ type: ToggleType.Switch, isOn: this.enableNotifications })
                    .selectedColor(getThemeColors().primary)
                    .onChange((isOn: boolean) => {
                      this.toggleNotifications(isOn);
                    });
                }
                .width('100%')
                .padding({ left: 20, right: 20, top: 15, bottom: 15 });
              }
              .width('100%')
              .backgroundColor(getThemeColors().surface);

              Divider().color(getThemeColors().divider);

              // Sound Toggle
              Column() {
                Row() {
                  Text('Sound')
                    .fontSize(16)
                    .fontColor(getThemeColors().text)
                    .layoutWeight(1);
                  Toggle({ type: ToggleType.Switch, isOn: this.enableSound })
                    .selectedColor(getThemeColors().primary)
                    .onChange((isOn: boolean) => {
                      this.toggleSound(isOn);
                    });
                }
                .width('100%')
                .padding({ left: 20, right: 20, top: 15, bottom: 15 });
              }
              .width('100%')
              .backgroundColor(getThemeColors().surface);

              Divider().color(getThemeColors().divider);

              // Vibration Toggle
              Column() {
                Row() {
                  Text('Vibration')
                    .fontSize(16)
                    .fontColor(getThemeColors().text)
                    .layoutWeight(1);
                  Toggle({ type: ToggleType.Switch, isOn: this.enableVibration })
                    .selectedColor(getThemeColors().primary)
                    .onChange((isOn: boolean) => {
                      this.toggleVibration(isOn);
                    });
                }
                .width('100%')
                .padding({ left: 20, right: 20, top: 15, bottom: 15 });
              }
              .width('100%')
              .backgroundColor(getThemeColors().surface);

              Divider().color(getThemeColors().divider);

              // Muted Rooms Section
              Column() {
                Row() {
                  Text('Muted Rooms')
                    .fontSize(16)
                    .fontColor(getThemeColors().text)
                    .layoutWeight(1);
                  Text(this.mutedRooms.length.toString())
                    .fontSize(14)
                    .fontColor(getThemeColors().textSecondary);
                }
                .width('100%')
                .padding({ left: 20, right: 20, top: 15, bottom: 15 })
                .onClick(() => {
                  this.showMutedRooms = !this.showMutedRooms;
                });

                if (this.showMutedRooms && this.mutedRooms.length > 0) {
                  ForEach(this.mutedRooms, (roomId: string) => {
                    Row() {
                      Text(roomId)
                        .fontSize(14)
                        .fontColor(getThemeColors().textSecondary)
                        .layoutWeight(1);
                      Button('Unmute')
                        .fontSize(12)
                        .backgroundColor(getThemeColors().primary)
                        .fontColor(getThemeColors().onPrimary)
                        .borderRadius(6)
                        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                        .onClick(() => {
                          ToastUtils.show('Room unmuted');
                        });
                    }
                    .width('100%')
                    .padding({ left: 20, right: 20, top: 8, bottom: 8 });
                  });
                }
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
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
    })
    .hideTitleBar(true);
  }
}
