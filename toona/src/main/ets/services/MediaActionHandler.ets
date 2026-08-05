import { IFilePicker, SelectedFile } from '../platform/adapters/IFilePicker';
import { IAudioRecorder, RecordingResult } from '../platform/adapters/IAudioRecorder';
import { MediaManager } from './MediaManager';
import { MessageManager } from './MessageManager';
import { AppLogger } from '../utils/AppLogger';
import { ToastUtils } from '../utils/ToastUtils';

const logger = AppLogger.getLogger('MediaActionHandler');

export class MediaActionHandler {
  private filePicker: IFilePicker;
  private audioRecorder: IAudioRecorder;
  private mediaManager: MediaManager;
  private messageManager: MessageManager;

  constructor(
    filePicker: IFilePicker,
    audioRecorder: IAudioRecorder,
    mediaManager: MediaManager,
    messageManager: MessageManager
  ) {
    this.filePicker = filePicker;
    this.audioRecorder = audioRecorder;
    this.mediaManager = mediaManager;
    this.messageManager = messageManager;
  }

  async selectAndUploadImage(roomId: string): Promise<void> {
    try {
      const selected: SelectedFile | null = await this.filePicker.selectImage();
      if (selected) {
        await this.uploadAndSendImage(roomId, selected.buffer, selected.fileName, selected.fileSize);
      }
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to pick image: ' + errMsg);
      ToastUtils.show('选择图片失败');
    }
  }

  async selectAndUploadMultipleImages(roomId: string, maxCount: number): Promise<void> {
    try {
      const selectedFiles: SelectedFile[] = await this.filePicker.selectMultipleImages(maxCount);
      for (let i = 0; i < selectedFiles.length; i++) {
        const file: SelectedFile = selectedFiles[i];
        await this.uploadAndSendImage(roomId, file.buffer, file.fileName, file.fileSize);
      }
      if (selectedFiles.length > 1) {
        ToastUtils.show('已发送 ' + selectedFiles.length + ' 张图片');
      }
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to pick images: ' + errMsg);
      ToastUtils.show('选择图片失败');
    }
  }

  async uploadAndSendImage(roomId: string, imageBuffer: ArrayBuffer, fileName: string, fileSize: number): Promise<void> {
    try {
      const uploadResult: Object = await this.mediaManager.uploadImage(imageBuffer, fileName) as Object;
      let mxcUrl: string = '';
      if (typeof uploadResult === 'string') {
        mxcUrl = uploadResult as string;
      } else {
        mxcUrl = (uploadResult as Record<string, string>)['content_uri'];
      }

      if (mxcUrl) {
        const imageInfo: Record<string, Object> = {
          'size': fileSize as Object,
          'mimetype': 'image/jpeg' as Object
        };
        const imageMessageContent: Record<string, string | object> = {
          'msgtype': 'm.image',
          'body': fileName,
          'url': mxcUrl,
          'info': imageInfo as object
        };
        await this.messageManager.sendMessage(roomId, 'm.room.message', imageMessageContent);
        ToastUtils.show('图片发送成功');
      }
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to send image: ' + errMsg);
      ToastUtils.show('图片发送失败');
    }
  }

  async uploadAndSendAudio(roomId: string, audioBuffer: ArrayBuffer, fileName: string, fileSize: number): Promise<void> {
    try {
      const uploadResult: Object = await this.mediaManager.uploadImage(audioBuffer, fileName) as Object;
      let mxcUrl: string = '';
      if (typeof uploadResult === 'string') {
        mxcUrl = uploadResult as string;
      } else {
        mxcUrl = (uploadResult as Record<string, string>)['content_uri'];
      }

      if (mxcUrl) {
        const audioInfo: Record<string, Object> = {
          'size': fileSize as Object,
          'mimetype': 'audio/mp4' as Object
        };
        const voiceFlag: Record<string, Object> = {};
        const audioMessageContent: Record<string, string | object> = {
          'msgtype': 'm.audio',
          'body': '语音消息',
          'url': mxcUrl,
          'info': audioInfo as object,
          'org.matrix.msc3245.voice': voiceFlag as object,
          'm.voice': voiceFlag as object
        };
        await this.messageManager.sendMessage(roomId, 'm.room.message', audioMessageContent);
      }
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to send audio: ' + errMsg);
      ToastUtils.show('语音发送失败');
    }
  }

  async startRecording(context: Object): Promise<Object | null> {
    return await this.audioRecorder.start(context);
  }

  async stopRecording(recorder: Object, audioPath: string, audioFd: number): Promise<RecordingResult | null> {
    return await this.audioRecorder.stop(recorder, audioPath, audioFd);
  }
}
