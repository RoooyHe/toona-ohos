import { getThemeColors } from '../../utils/ThemeManager';
import { MediaManager } from '../../services/MediaManager';
import { ToastUtils } from '../../utils/ToastUtils';

/**
 * Image Viewer Component
 * Fullscreen modal for viewing images with zoom and pan support
 */
@Component
export struct ImageViewer {
  @Prop isVisible: boolean = false;
  @Prop imageUrl: string = '';
  @Prop imageInfo: Record<string, string | object> = {};
  @Prop sender: string = '';
  @Prop timestamp: number = 0;
  onClose: () => void = () => {};

  private mediaManager: MediaManager = MediaManager.getInstance();
  @State imageScale: number = 1;
  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State isLoading: boolean = true;
  @State loadError: boolean = false;

  aboutToAppear() {
    this.resetTransform();
  }

  resetTransform() {
    this.imageScale = 1;
    this.offsetX = 0;
    this.offsetY = 0;
    this.isLoading = true;
    this.loadError = false;
  }

  build() {
    Stack() {
      if (this.isVisible) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.9)')
          .onClick(() => {
            this.onClose();
          });

        Column() {
          if (this.isLoading) {
            LoadingProgress()
              .width(40)
              .height(40)
              .color(Color.White);
          } else if (this.loadError) {
            Column() {
              Text('Failed to load image')
                .fontSize(16)
                .fontColor(Color.White);
              Text('Tap to close')
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 8 });
            }
            .onClick(() => {
              this.onClose();
            });
          } else {
            Image(this.mediaManager.getHttpUrl(this.imageUrl))
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Contain)
              .scale({ x: this.imageScale, y: this.imageScale })
              .translate({ x: this.offsetX, y: this.offsetY })
              .gesture(
                PinchGesture()
                  .onActionStart(() => {
                  })
                  .onActionUpdate((event: GestureEvent) => {
                    this.imageScale = Math.max(0.5, Math.min(5, this.imageScale * event.scale));
                  })
                  .onActionEnd(() => {
                    if (this.imageScale < 1) {
                      this.imageScale = 1;
                      this.offsetX = 0;
                      this.offsetY = 0;
                    }
                  })
              )
              .gesture(
                PanGesture()
                  .onActionStart(() => {
                  })
                  .onActionUpdate((event: GestureEvent) => {
                    if (this.imageScale > 1) {
                      this.offsetX += event.offsetX;
                      this.offsetY += event.offsetY;
                    }
                  })
                  .onActionEnd(() => {
                  })
              )
              .onClick(() => {
              })
              .onComplete(() => {
                this.isLoading = false;
              })
              .onError(() => {
                this.isLoading = false;
                this.loadError = true;
              });
          }
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);

        Row() {
          Column() {
            Text(this.sender || 'Unknown')
              .fontSize(14)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Medium);
            Text(this.formatTime(this.timestamp))
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 2 });
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1);

          Button('✕')
            .fontSize(18)
            .backgroundColor('rgba(255, 255, 255, 0.2)')
            .fontColor(Color.White)
            .width(36)
            .height(36)
            .borderRadius(18)
            .onClick(() => {
              this.onClose();
            });
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 40, bottom: 16 })
        .position({ x: 0, y: 0 });

        Row() {
          Button('Download')
            .fontSize(14)
            .backgroundColor('rgba(255, 255, 255, 0.2)')
            .fontColor(Color.White)
            .borderRadius(6)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .onClick(() => {
              this.downloadImage();
            });

          Blank();

          Button('Zoom In')
            .fontSize(14)
            .backgroundColor('rgba(255, 255, 255, 0.2)')
            .fontColor(Color.White)
            .borderRadius(6)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .onClick(() => {
              this.imageScale = Math.min(5, this.imageScale + 0.5);
            });

          Button('Zoom Out')
            .fontSize(14)
            .backgroundColor('rgba(255, 255, 255, 0.2)')
            .fontColor(Color.White)
            .borderRadius(6)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .margin({ left: 8 })
            .onClick(() => {
              this.imageScale = Math.max(0.5, this.imageScale - 0.5);
            });

          Button('Reset')
            .fontSize(14)
            .backgroundColor('rgba(255, 255, 255, 0.2)')
            .fontColor(Color.White)
            .borderRadius(6)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .margin({ left: 8 })
            .onClick(() => {
              this.resetTransform();
            });
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 40 })
        .position({ x: 0, y: '100%' })
        .translate({ x: 0, y: -80 });
      }
    }
    .width('100%')
    .height('100%');
  }

  formatTime(timestamp: number): string {
    if (!timestamp) {
      return '';
    }
    const date = new Date(timestamp);
    return date.toLocaleString('zh-CN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  downloadImage() {
    try {
      // In a real implementation, this would download the image to device storage
      ToastUtils.show('Image download started');
    } catch (error) {
      ToastUtils.show('Download failed');
    }
  }
}
