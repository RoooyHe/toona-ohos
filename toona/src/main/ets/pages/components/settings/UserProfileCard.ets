import promptAction from '@ohos.promptAction';
import { PresenceState } from '../../../models/MatrixTypes';
import { getThemeColors } from '../../../utils/ThemeManager';

@Component
export struct UserProfileCard {
  @Prop displayName: string = '';
  @Prop avatarUrl: string = '';
  @Prop presence: PresenceState = 'online';
  @Prop userId: string = '';
  @Prop isEditingName: boolean = false;
  @Prop editName: string = '';
  onPickAvatar: () => void = () => {};
  onStartEditName: () => void = () => {};
  onSaveDisplayName: () => void = () => {};
  onCancelEditName: () => void = () => {};
  onEditNameChange: (name: string) => void = () => {};

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

  getAvatarInitials(): string {
    if (this.displayName) {
      return this.displayName.charAt(0).toUpperCase();
    }
    if (this.userId) {
      return this.userId.charAt(0).toUpperCase();
    }
    return 'U';
  }

  build() {
    Column() {
      Row() {
        Text('用户资料')
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
          Stack() {
            if (this.avatarUrl) {
              Image(this.avatarUrl)
                .width(60)
                .height(60)
                .borderRadius(30);
            } else {
              Text(this.getAvatarInitials())
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#ffffff')
                .width(60)
                .height(60)
                .borderRadius(30)
                .backgroundColor('#10a37f')
                .textAlign(TextAlign.Center);
            }

            Row() {
              Circle()
                .width(14)
                .height(14)
                .fill(this.getPresenceColor(this.presence))
                .stroke('#ffffff')
                .strokeWidth(2);
            }
            .width(14)
            .height(14)
            .position({ x: 42, y: 42 });

            Row() {
              Text('✎')
                .fontSize(10)
                .fontColor('#ffffff')
                .width(18)
                .height(18)
                .borderRadius(9)
                .backgroundColor('#10a37f')
                .textAlign(TextAlign.Center)
                .onClick(() => {
                  this.onPickAvatar();
                });
            }
            .width(18)
            .height(18)
            .position({ x: 42, y: 42 });
          }
          .width(60)
          .height(60)
          .margin({ right: 15 });

          Column() {
            if (this.isEditingName) {
              Row() {
                TextInput({ text: this.editName })
                  .width(150)
                  .height(36)
                  .fontSize(16)
                  .backgroundColor(getThemeColors().bg)
                  .borderRadius(8)
                  .onChange((value: string) => {
                    this.onEditNameChange(value);
                  });

                Button('保存')
                  .fontSize(12)
                  .backgroundColor('#10a37f')
                  .fontColor('#ffffff')
                  .width(50)
                  .height(30)
                  .borderRadius(6)
                  .margin({ left: 8 })
                  .onClick(() => {
                    this.onSaveDisplayName();
                  });

                Button('取消')
                  .fontSize(12)
                  .backgroundColor(getThemeColors().bg)
                  .fontColor(getThemeColors().textSecondary)
                  .width(50)
                  .height(30)
                  .borderRadius(6)
                  .margin({ left: 5 })
                  .onClick(() => {
                    this.onCancelEditName();
                  });
              }
            } else {
              Text(this.displayName || '未设置名称')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(getThemeColors().text)
                .onClick(() => {
                  this.onStartEditName();
                });

              Text(this.userId)
                .fontSize(12)
                .fontColor(getThemeColors().textSecondary)
                .margin({ top: 2 });
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1);
        }
        .width('100%')
        .padding({
          left: 20,
          right: 20,
          top: 15,
          bottom: 15
        });
      }
      .width('100%')
      .backgroundColor(getThemeColors().surface);
    }
    .width('100%');
  }
}