import promptAction from '@ohos.promptAction';
import { PresenceState } from '../../../models/MatrixTypes';
import { getThemeColors } from '../../../utils/ThemeManager';

@Component
export struct PresenceSettings {
  @Prop presence: PresenceState = 'online';
  @Prop statusMsg: string = '';
  @Prop showPresenceMenu: boolean = false;
  onSetPresence: (state: PresenceState) => void = () => {};
  onTogglePresenceMenu: () => void = () => {};
  onStatusMsgChange: (msg: string) => void = () => {};
  onSaveStatusMessage: () => void = () => {};

  getPresenceText(state: PresenceState): string {
    switch (state) {
      case 'online': return '在线';
      case 'offline': return '离线';
      case 'unavailable': return '离开';
      default: return '未知';
    }
  }

  getPresenceColor(state: PresenceState): string {
    switch (state) {
      case 'online': return '#4CAF50';
      case 'offline': return '#9E9E9E';
      case 'unavailable': return '#FF9800';
      default: return '#9E9E9E';
    }
  }

  build() {
    Column() {
      Row() {
        Text('在线状态')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(getThemeColors().text);
      }
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        top: 15,
        bottom: 10
      });

      Column() {
        Row() {
          Text('当前状态')
            .fontSize(14)
            .fontColor(getThemeColors().textSecondary);

          Blank();

          Row() {
            Circle()
              .width(10)
              .height(10)
              .fill(this.getPresenceColor(this.presence));
            Text(this.getPresenceText(this.presence))
              .fontSize(14)
              .fontColor(getThemeColors().text)
              .margin({ left: 6 });
          }
          .onClick(() => {
            this.onTogglePresenceMenu();
          });
        }
        .width('100%')
        .padding({
          left: 20,
          right: 20,
          top: 12,
          bottom: 12
        });

        if (this.showPresenceMenu) {
          Column() {
            ForEach(['online', 'unavailable', 'offline'] as PresenceState[], (state: PresenceState) => {
              Row() {
                Circle()
                  .width(10)
                  .height(10)
                  .fill(this.getPresenceColor(state));
                Text(this.getPresenceText(state))
                  .fontSize(14)
                  .fontColor(getThemeColors().text)
                  .margin({ left: 8 });
                Blank();
                if (this.presence === state) {
                  Text('✓')
                    .fontSize(14)
                    .fontColor('#10a37f');
                }
              }
              .width('100%')
              .padding({
                left: 20,
                right: 20,
                top: 10,
                bottom: 10
              })
              .onClick(() => {
                this.onSetPresence(state);
              });
            });
          }
          .width('100%')
          .backgroundColor(getThemeColors().bg);
        }

        Divider().color(getThemeColors().divider);

        Row() {
          Text('状态消息')
            .fontSize(14)
            .fontColor(getThemeColors().textSecondary);
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12 });

        TextInput({ text: this.statusMsg, placeholder: '设置状态消息' })
          .width('calc(100% - 40)')
          .height(36)
          .fontSize(14)
          .backgroundColor(getThemeColors().bg)
          .borderRadius(8)
          .margin({
            left: 20,
            right: 20,
            top: 8,
            bottom: 12
          })
          .onChange((value: string) => {
            this.onStatusMsgChange(value);
          })
          .onSubmit(() => {
            this.onSaveStatusMessage();
          });

        Button('保存状态消息')
          .fontSize(14)
          .backgroundColor('#10a37f')
          .fontColor('#ffffff')
          .width('calc(100% - 40)')
          .height(36)
          .borderRadius(8)
          .margin({ left: 20, right: 20, bottom: 12 })
          .onClick(() => {
            this.onSaveStatusMessage();
          });
      }
      .width('100%')
      .backgroundColor(getThemeColors().surface);
    }
    .width('100%')
    .margin({ top: 10 });
  }
}