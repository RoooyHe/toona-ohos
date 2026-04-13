import { mediaLibrary } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { promptAction } from '@ohos.promptAction';

export class MediaLibraryManager {
  private static instance: MediaLibraryManager;

  static getInstance(): MediaLibraryManager {
    if (!MediaLibraryManager.instance) {
      MediaLibraryManager.instance = new MediaLibraryManager();
    }
    return MediaLibraryManager.instance;
  }

  async selectImage(): Promise<string | null> {
    try {
      const photoPicker = new mediaLibrary.PhotoViewPicker();
      
      const result = await photoPicker.select({
        MIMEType: mediaLibrary.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      });

      if (result && result.photos && result.photos.length > 0) {
        const uri = result.photos[0];
        console.info('Selected image URI: %{public}s', uri);
        return uri;
      }
      
      return null;
    } catch (error) {
      console.error('Failed to select image: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '选择图片失败' });
      return null;
    }
  }

  async selectMultipleImages(maxCount: number = 9): Promise<string[]> {
    try {
      const photoPicker = new mediaLibrary.PhotoViewPicker();
      
      const result = await photoPicker.select({
        MIMEType: mediaLibrary.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: maxCount
      });

      if (result && result.photos && result.photos.length > 0) {
        console.info('Selected %{public}d images', result.photos.length);
        return result.photos;
      }
      
      return [];
    } catch (error) {
      console.error('Failed to select images: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '选择图片失败' });
      return [];
    }
  }

  async getFileDataFromUri(uri: string): Promise<ArrayBuffer | null> {
    try {
      const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(file.fd);
      const buffer = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);
      return buffer;
    } catch (error) {
      console.error('Failed to read file from URI: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  async getImageInfo(uri: string): Promise<{ width: number; height: number; size: number } | null> {
    try {
      const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(file.fd);
      fileIo.closeSync(file);
      
      return {
        width: 0,
        height: 0,
        size: stat.size
      };
    } catch (error) {
      console.error('Failed to get image info: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  getFileNameFromUri(uri: string): string {
    const parts = uri.split('/');
    return parts[parts.length - 1] || 'image.jpg';
  }

  isImageFile(uri: string): boolean {
    const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic', '.heif'];
    const lowerUri = uri.toLowerCase();
    return imageExtensions.some(ext => lowerUri.endsWith(ext));
  }
}