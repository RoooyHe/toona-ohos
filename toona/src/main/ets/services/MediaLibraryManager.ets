import { fileIo } from '@kit.CoreFileKit';
import { ToastUtils } from '../utils/ToastUtils';
import { AppLogger } from '../utils/AppLogger';

interface ImageInfo {
  width: number;
  height: number;
  size: number;
}

export class MediaLibraryManager {
  private static instance: MediaLibraryManager;
  private logger = AppLogger.getLogger(MediaLibraryManager);

  static getInstance(): MediaLibraryManager {
    if (!MediaLibraryManager.instance) {
      MediaLibraryManager.instance = new MediaLibraryManager();
    }
    return MediaLibraryManager.instance;
  }

  async selectImage(): Promise<string | null> {
    // Stub implementation - photo picker API compatibility varies by SDK version
    ToastUtils.show('图片选择功能暂不可用');
    return null;
  }

  async selectMultipleImages(maxCount: number = 9): Promise<string[]> {
    // Stub implementation - photo picker API compatibility varies by SDK version
    ToastUtils.show('图片选择功能暂不可用');
    return [];
  }

  async getFileDataFromUri(uri: string): Promise<ArrayBuffer | null> {
    try {
      const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(file.fd);
      const buffer: ArrayBuffer = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);
      return buffer;
    } catch (error) {
      this.logger.error('Failed to read file from URI: %{public}s', error.message);
      return null;
    }
  }

  async getImageInfo(uri: string): Promise<ImageInfo | null> {
    try {
      const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(file.fd);
      fileIo.closeSync(file);

      const imageInfo: ImageInfo = {
        width: 0,
        height: 0,
        size: stat.size
      };
      return imageInfo;
    } catch (error) {
      this.logger.error('Failed to get image info: %{public}s', error.message);
      return null;
    }
  }

  getFileNameFromUri(uri: string): string {
    const parts: string[] = uri.split('/');
    return parts[parts.length - 1] || 'image.jpg';
  }

  isImageFile(uri: string): boolean {
    const imageExtensions: string[] = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic', '.heif'];
    const lowerUri: string = uri.toLowerCase();
    return imageExtensions.some((ext: string) => lowerUri.endsWith(ext));
  }
}
