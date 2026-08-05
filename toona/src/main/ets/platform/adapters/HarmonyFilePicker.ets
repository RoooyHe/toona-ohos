import { fileIo } from '@kit.CoreFileKit';
import { IFilePicker, SelectedFile } from './IFilePicker';
import { AppLogger } from '../../utils/AppLogger';
import { ToastUtils } from '../../utils/ToastUtils';
import picker from '@ohos.file.picker';

const logger = AppLogger.getLogger('HarmonyFilePicker');

export class HarmonyFilePicker implements IFilePicker {
  async selectImage(): Promise<SelectedFile | null> {
    try {
      const photoSelectOptions: picker.PhotoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;

      const photoPicker: picker.PhotoViewPicker = new picker.PhotoViewPicker();
      const photoSelectResult: picker.PhotoSelectResult = await photoPicker.select(photoSelectOptions);

      if (photoSelectResult && photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        const imageUri: string = photoSelectResult.photoUris[0];
        const buffer: ArrayBuffer | null = await this.readFileBuffer(imageUri);
        if (buffer) {
          const fileName: string = 'image_' + Date.now() + '.jpg';
          const result: SelectedFile = {
            uri: imageUri,
            buffer: buffer,
            fileName: fileName,
            fileSize: buffer.byteLength
          };
          return result;
        }
      }
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('PhotoPicker failed: ' + errMsg);
    }
    return null;
  }

  async selectMultipleImages(maxCount: number): Promise<SelectedFile[]> {
    try {
      const photoSelectOptions: picker.PhotoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = maxCount;

      const photoPicker: picker.PhotoViewPicker = new picker.PhotoViewPicker();
      const photoSelectResult: picker.PhotoSelectResult = await photoPicker.select(photoSelectOptions);

      const results: SelectedFile[] = [];
      if (photoSelectResult && photoSelectResult.photoUris) {
        for (let i = 0; i < photoSelectResult.photoUris.length; i++) {
          const uri: string = photoSelectResult.photoUris[i];
          const buffer: ArrayBuffer | null = await this.readFileBuffer(uri);
          if (buffer) {
            const fileName: string = 'image_' + Date.now() + '_' + i + '.jpg';
            const file: SelectedFile = {
              uri: uri,
              buffer: buffer,
              fileName: fileName,
              fileSize: buffer.byteLength
            };
            results.push(file);
          }
        }
      }
      return results;
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Multi-image picker failed: ' + errMsg);
      ToastUtils.show('选择图片失败');
      return [];
    }
  }

  async readFileBuffer(uri: string): Promise<ArrayBuffer | null> {
    try {
      const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(uri);
      const buffer: ArrayBuffer = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);
      return buffer;
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to read file: ' + errMsg);
      return null;
    }
  }
}
