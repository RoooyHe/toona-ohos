import { PresenceState } from '../../models/MatrixTypes';
import { getThemeColors } from '../../utils/ThemeManager';

interface MemberPresence {
  userId: string;
  presence: PresenceState;
  displayName: string;
}

interface MemberPanelThemeColors {
  bg: string;
  bgSoft: string;
  text: string;
  textSecondary: string;
  textMute: string;
  textMute2: string;
  textFaint: string;
  inputBg: string;
  primary: string;
  primaryDeep: string;
  primarySoft: string;
  onPrimary: string;
  error: string;
  success: string;
  warning: string;
  divider: string;
  dividerStrong: string;
  dividerCool: string;
  surface: string;
  surfaceNight: string;
  surfaceNightSoft: string;
  tabBg: string;
}

@Component
export struct MemberListPanel {
  @Prop memberPresences: MemberPresence[] = [];
  @Prop showMembersPanel: boolean = false;
  onClose: () => void = () => {};

  getThemeColors(): MemberPanelThemeColors {
    const base = getThemeColors();
    return {
      bg: base.bg,
      bgSoft: base.bgSoft,
      text: base.text,
      textSecondary: base.textSecondary,
      textMute: base.textMute,
      textMute2: base.textMute2,
      textFaint: base.textFaint,
      inputBg: base.inputBg,
      primary: base.primary,
      primaryDeep: base.primaryDeep,
      primarySoft: base.primarySoft,
      onPrimary: base.onPrimary,
      error: base.error,
      success: base.success,
      warning: base.warning,
      divider: base.divider,
      dividerStrong: base.dividerStrong,
      dividerCool: base.dividerCool,
      surface: base.surface,
      surfaceNight: base.surfaceNight,
      surfaceNightSoft: base.surfaceNightSoft,
      tabBg: base.tabBg
    };
  }

  getPresenceText(presence: PresenceState): string {
    switch (presence) {
      case 'online':
        return '在线';
      case 'offline':
        return '离线';
      case 'unavailable':
        return '离开';
      default:
        return '未知';
    }
  }

  getPresenceColor(presence: PresenceState): string {
    const colors = getThemeColors();
    switch (presence) {
      case 'online':
        return colors.success;
      case 'offline':
        return colors.textMute;
      case 'unavailable':
        return colors.warning;
      default:
        return colors.textMute;
    }
  }

  build() {
    Column() {
      Row() {
        Text('成员列表')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getThemeColors().text);
        Blank();
        Button('✕')
          .fontSize(16)
          .backgroundColor('transparent')
          .fontColor(this.getThemeColors().textSecondary)
          .width(30)
          .height(30)
          .onClick(() => {
            this.onClose();
          });
      }
      .width('100%')
      .padding({
        left: 15,
        right: 15,
        top: 12,
        bottom: 12
      });

      Divider().color(this.getThemeColors().divider);

      if (this.memberPresences.length === 0) {
        Text('暂无成员信息')
          .fontSize(14)
          .fontColor(this.getThemeColors().textSecondary)
          .padding(15);
      } else {
        Scroll() {
          Column() {
            ForEach(this.memberPresences, (member: MemberPresence) => {
              Row() {
                Stack() {
                  Text(member.displayName.charAt(0).toUpperCase())
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.getThemeColors().onPrimary)
                    .width(36)
                    .height(36)
                    .borderRadius(18)
                    .backgroundColor(this.getThemeColors().primary)
                    .textAlign(TextAlign.Center);

                  Circle()
                    .width(10)
                    .height(10)
                    .fill(this.getPresenceColor(member.presence))
                    .stroke(this.getThemeColors().bg)
                    .strokeWidth(1.5)
                    .position({ x: 26, y: 26 });
                }
                .width(36)
                .height(36)
                .margin({ right: 12 });

                Column() {
                  Text(member.displayName)
                    .fontSize(14)
                    .fontColor(this.getThemeColors().text);
                  Text(this.getPresenceText(member.presence))
                    .fontSize(12)
                    .fontColor(this.getThemeColors().textSecondary);
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1);

                Text(member.userId.split(':')[0].replace('@', ''))
                  .fontSize(11)
                  .fontColor(this.getThemeColors().textSecondary);
              }
              .width('100%')
              .padding({
                left: 15,
                right: 15,
                top: 10,
                bottom: 10
              });
            });
          }
          .width('100%');
        }
        .layoutWeight(1);
      }
    }
    .width('70%')
    .height('100%')
    .backgroundColor(this.getThemeColors().bg)
    .shadow({
      radius: 10,
      color: 'rgba(0, 0, 0, 0.15)',
      offsetX: -2,
      offsetY: 0
    })
    .position({ x: '30%', y: 0 });
  }
}