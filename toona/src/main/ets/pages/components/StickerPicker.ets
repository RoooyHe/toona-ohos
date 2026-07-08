import { getThemeColors } from '../../utils/ThemeManager';
import { ToastUtils } from '../../utils/ToastUtils';

/**
 * Sticker Picker Component
 * Shows sticker packs for sending stickers
 */
@Component
export struct StickerPicker {
  @Prop isVisible: boolean = false;
  onSticker: (stickerUrl: string, stickerBody: string) => void = () => {};
  onClose: () => void = () => {};

  @State selectedPack: number = 0;

  // Sticker packs (simplified - in production, these would come from the server)
  private stickerPacks: StickerPack[] = [
    {
      name: 'Default',
      stickers: [
        { url: 'https://example.com/sticker1.png', body: 'Hello' },
        { url: 'https://example.com/sticker2.png', body: 'Thanks' },
        { url: 'https://example.com/sticker3.png', body: 'Love' },
        { url: 'https://example.com/sticker4.png', body: 'Laugh' },
        { url: 'https://example.com/sticker5.png', body: 'Cool' },
        { url: 'https://example.com/sticker6.png', body: 'Wow' },
        { url: 'https://example.com/sticker7.png', body: 'Sad' },
        { url: 'https://example.com/sticker8.png', body: 'Angry' },
        { url: 'https://example.com/sticker9.png', body: 'Think' },
        { url: 'https://example.com/sticker10.png', body: 'Sleep' },
        { url: 'https://example.com/sticker11.png', body: 'Party' },
        { url: 'https://example.com/sticker12.png', body: 'Fire' }
      ]
    },
    {
      name: 'Animals',
      stickers: [
        { url: 'https://example.com/cat1.png', body: 'Cat' },
        { url: 'https://example.com/dog1.png', body: 'Dog' },
        { url: 'https://example.com/bunny1.png', body: 'Bunny' },
        { url: 'https://example.com/bear1.png', body: 'Bear' },
        { url: 'https://example.com/panda1.png', body: 'Panda' },
        { url: 'https://example.com/fox1.png', body: 'Fox' }
      ]
    },
    {
      name: 'Food',
      stickers: [
        { url: 'https://example.com/pizza1.png', body: 'Pizza' },
        { url: 'https://example.com/burger1.png', body: 'Burger' },
        { url: 'https://example.com/sushi1.png', body: 'Sushi' },
        { url: 'https://example.com/cake1.png', body: 'Cake' },
        { url: 'https://example.com/coffee1.png', body: 'Coffee' },
        { url: 'https://example.com/beer1.png', body: 'Beer' }
      ]
    }
  ];

  build() {
    if (!this.isVisible) {
      return;
    }

    Stack() {
      // Background overlay
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.3)')
        .onClick(() => {
          this.onClose();
        });

      // Sticker picker card
      Column() {
        // Header
        Row() {
          Text('Stickers')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(getThemeColors().text)
            .layoutWeight(1);

          Button('✕')
            .fontSize(14)
            .backgroundColor('transparent')
            .fontColor(getThemeColors().textSecondary)
            .width(28)
            .height(28)
            .onClick(() => {
              this.onClose();
            });
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 12, bottom: 8 });

        // Pack tabs
        Row() {
          ForEach(this.stickerPacks, (pack: StickerPack, index: number) => {
            Text(pack.name)
              .fontSize(12)
              .fontColor(this.selectedPack === index ? getThemeColors().primary : getThemeColors().textSecondary)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(this.selectedPack === index ? getThemeColors().bgSoft : 'transparent')
              .borderRadius(12)
              .margin({ right: 6 })
              .onClick(() => {
                this.selectedPack = index;
              });
          });
        }
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 8 });

        // Sticker grid
        Grid() {
          ForEach(this.getCurrentStickers(), (sticker: StickerItem) => {
            GridItem() {
              Column() {
                // Placeholder for sticker image
                Text(sticker.body.charAt(0))
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(getThemeColors().primary)
                  .width(60)
                  .height(60)
                  .backgroundColor(getThemeColors().bgSoft)
                  .borderRadius(8)
                  .textAlign(TextAlign.Center)
                  .onClick(() => {
                    this.onSticker(sticker.url, sticker.body);
                    this.onClose();
                  });

                Text(sticker.body)
                  .fontSize(10)
                  .fontColor(getThemeColors().textSecondary)
                  .margin({ top: 4 });
              }
              .width(80)
              .alignItems(HorizontalAlign.Center);
            }
          });
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .columnsGap(8)
        .rowsGap(8)
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
      .translate({ x: 0, y: -300 });
    }
    .width('100%')
    .height('100%');
  }

  private getCurrentStickers(): StickerItem[] {
    if (this.selectedPack >= 0 && this.selectedPack < this.stickerPacks.length) {
      return this.stickerPacks[this.selectedPack].stickers;
    }
    return [];
  }
}

interface StickerItem {
  url: string;
  body: string;
}

interface StickerPack {
  name: string;
  stickers: StickerItem[];
}
