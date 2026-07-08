import { getThemeColors } from '../../../utils/ThemeManager';
import { ToastUtils } from '../../../utils/ToastUtils';

/**
 * History Visibility Settings Component
 * Allows users to configure who can see room history
 */
@Component
export struct HistoryVisibilitySettings {
  @Prop currentVisibility: string = 'shared';
  onSetVisibility: (visibility: string) => void = () => {};

  @State selectedVisibility: string = 'shared';

  private visibilityOptions: VisibilityOption[] = [
    {
      value: 'shared',
      label: 'Shared',
      description: 'Members can see history from the point they were invited'
    },
    {
      value: 'joined',
      label: 'Joined',
      description: 'Members can only see history from when they joined'
    },
    {
      value: 'invited',
      label: 'Invited',
      description: 'Members can only see history from when they were invited'
    },
    {
      value: 'world_readable',
      label: 'World Readable',
      description: 'Anyone can see history, even without joining'
    }
  ];

  aboutToAppear() {
    this.selectedVisibility = this.currentVisibility;
  }

  build() {
    Column() {
      Row() {
        Text('History Visibility')
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

      ForEach(this.visibilityOptions, (option: VisibilityOption) => {
        Row() {
          Column() {
            Text(option.label)
              .fontSize(14)
              .fontColor(getThemeColors().text);
            Text(option.description)
              .fontSize(12)
              .fontColor(getThemeColors().textSecondary)
              .margin({ top: 4 });
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1);

          Circle()
            .width(16)
            .height(16)
            .fill(this.selectedVisibility === option.value ? getThemeColors().primary : 'transparent')
            .stroke(getThemeColors().dividerStrong)
            .strokeWidth(1);
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 12 })
        .onClick(() => {
          this.selectedVisibility = option.value;
          this.onSetVisibility(option.value);
        });
      });
    }
    .width('100%')
    .backgroundColor(getThemeColors().surface);
  }
}

interface VisibilityOption {
  value: string;
  label: string;
  description: string;
}
