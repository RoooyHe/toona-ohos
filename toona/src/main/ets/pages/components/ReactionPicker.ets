import { getThemeColors } from '../../utils/ThemeManager';
import { ToastUtils } from '../../utils/ToastUtils';

/**
 * Reaction Picker Component
 * Shows emoji picker for reacting to messages
 */
@Component
export struct ReactionPicker {
  @Prop isVisible: boolean = false;
  @Prop messageId: string = '';
  onReaction: (emoji: string) => void = () => {};
  onClose: () => void = () => {};

  @State selectedCategory: number = 0;

  // Common emoji categories
  private smileys: string[] = ['😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '🤩', '😘', '😗', '😚', '😙', '🥲', '😋', '😛', '😜', '🤪', '😝', '🤑', '🤗', '🤭', '🫢', '🫣', '🫡', '🤫', '🤔', '🫡', '🤐', '🤨', '😐', '😑', '😶', '🫥', '😏', '😒', '🙄', '😬', '🤥', '😌', '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕', '🤢', '🤮', '🥵', '🥶', '🥴', '😵', '🤯', '🤠', '🥳', '🥸', '😎', '🤓', '🧐'];
  private gestures: string[] = ['👋', '🤚', '🖐️', '✋', '🖖', '🫱', '🫲', '🫳', '🫴', '👌', '🤌', '🤏', '✌️', '🤞', '🫰', '🤟', '🤘', '🤙', '👈', '👉', '👆', '🖕', '👇', '☝️', '🫵', '👍', '👎', '✊', '👊', '🤛', '🤜', '👏', '🙌', '🫶', '👐', '🤲', '🤝', '🙏'];
  private hearts: string[] = ['❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔', '❤️‍🔥', '❤️‍🩹', '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝'];
  private objects: string[] = ['🔥', '✨', '🌟', '💫', '🎉', '🎊', '🎈', '🎁', '🏆', '🥇', '🥈', '🥉', '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🥏', '🎱', '🪀', '🏓', '🏸', '🏒', '🥅', '⛳', '🪁', '🏹', '🎣', '🤿', '🥊', '🥋', '🎽', '🛹', '🛼', '🛷', '⛸️', '🥌'];

  build() {
    Stack() {
      if (this.isVisible) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.3)')
          .onClick(() => {
            this.onClose();
          });

        Column() {
          Row() {
            Text('😀')
              .fontSize(20)
              .padding(8)
              .backgroundColor(this.selectedCategory === 0 ? getThemeColors().primary : 'transparent')
              .borderRadius(8)
              .onClick(() => {
                this.selectedCategory = 0;
              });

            Text('👋')
              .fontSize(20)
              .padding(8)
              .backgroundColor(this.selectedCategory === 1 ? getThemeColors().primary : 'transparent')
              .borderRadius(8)
              .margin({ left: 8 })
              .onClick(() => {
                this.selectedCategory = 1;
              });

            Text('❤️')
              .fontSize(20)
              .padding(8)
              .backgroundColor(this.selectedCategory === 2 ? getThemeColors().primary : 'transparent')
              .borderRadius(8)
              .margin({ left: 8 })
              .onClick(() => {
                this.selectedCategory = 2;
              });

            Text('🔥')
              .fontSize(20)
              .padding(8)
              .backgroundColor(this.selectedCategory === 3 ? getThemeColors().primary : 'transparent')
              .borderRadius(8)
              .margin({ left: 8 })
              .onClick(() => {
                this.selectedCategory = 3;
              });
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 12, bottom: 8 });

          Grid() {
            ForEach(this.getCurrentEmojis(), (emoji: string) => {
              GridItem() {
                Text(emoji)
                  .fontSize(28)
                  .padding(8)
                  .width(44)
                  .height(44)
                  .textAlign(TextAlign.Center)
                  .onClick(() => {
                    this.onReaction(emoji);
                    this.onClose();
                  });
              }
            });
          }
          .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
          .columnsGap(4)
          .rowsGap(4)
          .width('100%')
          .height(200)
          .padding({ left: 8, right: 8, top: 8, bottom: 8 })
          .scrollBar(BarState.Off);
        }
        .width('100%')
        .backgroundColor(getThemeColors().surface)
        .borderRadius(16)
        .shadow({
          radius: 20,
          color: 'rgba(0, 0, 0, 0.15)',
          offsetX: 0,
          offsetY: 4
        })
        .position({ x: 0, y: '100%' })
        .translate({ x: 0, y: -280 });
      }
    }
    .width('100%')
    .height('100%');
  }

  private getCurrentEmojis(): string[] {
    switch (this.selectedCategory) {
      case 0:
        return this.smileys;
      case 1:
        return this.gestures;
      case 2:
        return this.hearts;
      case 3:
        return this.objects;
      default:
        return this.smileys;
    }
  }
}
