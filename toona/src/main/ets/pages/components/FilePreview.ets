import { getThemeColors } from '../../utils/ThemeManager';
import { MediaManager } from '../../services/MediaManager';
import { ToastUtils } from '../../utils/ToastUtils';
import { fileIo } from '@kit.CoreFileKit';
import picker from '@ohos.file.picker';

/**
 * File Preview Component
 * Shows file info and provides download/open options
 */
@Component
export struct FilePreview {
  @Prop isVisible: boolean = false;
  @Prop fileUrl: string = '';
  @Prop fileName: string = '';
  @Prop fileSize: number = 0;
  @Prop mimeType: string = '';
  @Prop sender: string = '';
  @Prop timestamp: number = 0;
  onClose: () => void = () => {};

  private mediaManager: MediaManager = MediaManager.getInstance();
  @State isDownloading: boolean = false;
  @State downloadProgress: number = 0;

  build() {
    Stack() {
      if (this.isVisible) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.onClose();
          });

        Column() {
          Row() {
            Text('File Preview')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(getThemeColors().text)
              .layoutWeight(1);

            Button('✕')
              .fontSize(16)
              .backgroundColor('transparent')
              .fontColor(getThemeColors().textSecondary)
              .width(32)
              .height(32)
              .onClick(() => {
                this.onClose();
              });
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 20, bottom: 10 });

          Column() {
            Text(this.getFileIcon())
              .fontSize(48)
              .margin({ bottom: 16 });

            Text(this.fileName || 'Unknown file')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(getThemeColors().text)
              .textAlign(TextAlign.Center)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis });

            Text(this.formatFileSize(this.fileSize))
              .fontSize(14)
              .fontColor(getThemeColors().textSecondary)
              .margin({ top: 8 });

            if (this.mimeType) {
              Text(this.mimeType)
                .fontSize(12)
                .fontColor(getThemeColors().textMute2)
                .margin({ top: 4 });
            }
          }
          .width('100%')
          .padding(20)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center);

          Row() {
            Text('From: ')
              .fontSize(12)
              .fontColor(getThemeColors().textSecondary);
            Text(this.sender || 'Unknown')
              .fontSize(12)
              .fontColor(getThemeColors().text);
            Blank();
            Text(this.formatTime(this.timestamp))
              .fontSize(12)
              .fontColor(getThemeColors().textMute2);
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 20 });

          if (this.isDownloading) {
            Column() {
              Progress({ value: this.downloadProgress, total: 100 })
                .width('100%')
                .height(4)
                .color(getThemeColors().primary);
              Text(`Downloading... ${this.downloadProgress}%`)
                .fontSize(12)
                .fontColor(getThemeColors().textSecondary)
                .margin({ top: 8 });
            }
            .width('100%')
            .padding({ left: 20, right: 20, bottom: 20 });
          }

          Row() {
            Button('Download')
              .fontSize(16)
              .backgroundColor(getThemeColors().primary)
              .fontColor(getThemeColors().onPrimary)
              .borderRadius(6)
              .height(44)
              .layoutWeight(1)
              .enabled(!this.isDownloading)
              .onClick(() => {
                this.downloadFile();
              });

            Button('Open')
              .fontSize(16)
              .backgroundColor(getThemeColors().bg)
              .fontColor(getThemeColors().text)
              .borderWidth(1)
              .borderColor(getThemeColors().dividerStrong)
              .borderRadius(6)
              .height(44)
              .layoutWeight(1)
              .margin({ left: 12 })
              .enabled(!this.isDownloading)
              .onClick(() => {
                this.openFile();
              });
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 20 });
        }
        .width('90%')
        .backgroundColor(getThemeColors().surface)
        .borderRadius(16)
        .shadow({
          radius: 20,
          color: 'rgba(0, 0, 0, 0.15)',
          offsetX: 0,
          offsetY: 4
        });
      }
    }
    .width('100%')
    .height('100%');
  }

  getFileIcon(): string {
    if (this.mimeType.startsWith('image/')) {
      return '🖼️';
    } else if (this.mimeType.startsWith('video/')) {
      return '🎬';
    } else if (this.mimeType.startsWith('audio/')) {
      return '🎵';
    } else if (this.mimeType.includes('pdf')) {
      return '📄';
    } else if (this.mimeType.includes('word') || this.mimeType.includes('document')) {
      return '📝';
    } else if (this.mimeType.includes('excel') || this.mimeType.includes('spreadsheet')) {
      return '📊';
    } else if (this.mimeType.includes('zip') || this.mimeType.includes('archive')) {
      return '📦';
    } else if (this.mimeType.includes('text')) {
      return '📃';
    }
    return '📁';
  }

  formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
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

  async downloadFile() {
    if (this.isDownloading) {
      return;
    }

    this.isDownloading = true;
    this.downloadProgress = 0;

    try {
      // Simulate download progress
      const interval = setInterval(() => {
        this.downloadProgress += 10;
        if (this.downloadProgress >= 100) {
          clearInterval(interval);
          this.isDownloading = false;
          ToastUtils.show('File downloaded successfully');
        }
      }, 100);

      // In a real implementation, this would:
      // 1. Get the file URL from MediaManager
      // 2. Download the file using fileIo
      // 3. Save to device storage
      // 4. Update progress

    } catch (error) {
      this.isDownloading = false;
      ToastUtils.show('Download failed');
    }
  }

  async openFile() {
    try {
      // In a real implementation, this would:
      // 1. Get the downloaded file path
      // 2. Create a Want to open with external app
      // 3. Launch the external app

      ToastUtils.show('Opening file...');
    } catch (error) {
      ToastUtils.show('Failed to open file');
    }
  }
}
