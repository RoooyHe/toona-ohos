import { IFilePicker, SelectedFile } from '../platform/adapters/IFilePicker';
import { IAudioRecorder, RecordingResult } from '../platform/adapters/IAudioRecorder';
import { IMediaManager } from './MediaManager';
import { IMessageSender } from './MessageSender';
import { AppLogger } from '../utils/AppLogger';
import { ToastUtils } from '../utils/ToastUtils';

const logger = AppLogger.getLogger('MediaActionHandler');

export enum MediaSendType {
  IMAGE = 'm.image',
  AUDIO = 'm.audio',
  VIDEO = 'm.video',
  FILE = 'm.file'
}

interface MediaUploadConfig {
  uploadMethod: (data: ArrayBuffer, fileName: string) => Promise<string>;
  msgtype: string;
  mimetype: string;
  body: string;
  extraFields?: Record<string, object>;
  successToast: string;
  failureToast: string;
}

export interface IMediaActionHandler {
  selectAndUploadImage(roomId: string): Promise<void>;
  uploadAndSend(roomId: string, buffer: ArrayBuffer, fileName: string, fileSize: number, mediaType: MediaSendType): Promise<void>;
  startRecording(context: Object): Promise<Object | null>;
  stopRecording(recorder: Object, audioPath: string, audioFd: number): Promise<RecordingResult | null>;
}

export class MediaActionHandler implements IMediaActionHandler {
  private filePicker: IFilePicker;
  private audioRecorder: IAudioRecorder;
  private mediaManager: IMediaManager;
  private messageSender: IMessageSender;

  constructor(
    filePicker: IFilePicker,
    audioRecorder: IAudioRecorder,
    mediaManager: IMediaManager,
    messageSender: IMessageSender
  ) {
    this.filePicker = filePicker;
    this.audioRecorder = audioRecorder;
    this.mediaManager = mediaManager;
    this.messageSender = messageSender;
  }

  private getUploadConfig(mediaType: MediaSendType): MediaUploadConfig {
    switch (mediaType) {
      case MediaSendType.AUDIO: {
        const voiceFlag: Record<string, object> = {} as Record<string, object>;
        const audioExtraFields: Record<string, object> = {
          'org.matrix.msc3245.voice': voiceFlag as object,
          'm.voice': voiceFlag as object
        };
        return {
          uploadMethod: (data: ArrayBuffer, fileName: string): Promise<string> => this.mediaManager.uploadAudio(data, fileName),
          msgtype: 'm.audio',
          mimetype: 'audio/mp4',
          body: '语音消息',
          extraFields: audioExtraFields as Record<string, object>,
          successToast: '语音发送成功',
          failureToast: '语音发送失败'
        };
      }
      case MediaSendType.VIDEO:
        return {
          uploadMethod: (data: ArrayBuffer, fileName: string): Promise<string> => this.mediaManager.uploadVideo(data, fileName),
          msgtype: 'm.video',
          mimetype: 'video/mp4',
          body: '',
          successToast: '视频发送成功',
          failureToast: '视频发送失败'
        };
      case MediaSendType.FILE:
        return {
          uploadMethod: (data: ArrayBuffer, fileName: string): Promise<string> => this.mediaManager.uploadFile(data, fileName),
          msgtype: 'm.file',
          mimetype: 'application/octet-stream',
          body: '',
          successToast: '文件发送成功',
          failureToast: '文件发送失败'
        };
      case MediaSendType.IMAGE:
      default:
        return {
          uploadMethod: (data: ArrayBuffer, fileName: string): Promise<string> => this.mediaManager.uploadImage(data, fileName),
          msgtype: 'm.image',
          mimetype: 'image/jpeg',
          body: '',
          successToast: '图片发送成功',
          failureToast: '图片发送失败'
        };
    }
  }

  async selectAndUploadImage(roomId: string): Promise<void> {
    try {
      const selected: SelectedFile | null = await this.filePicker.selectImage();
      if (selected) {
        await this.uploadAndSend(roomId, selected.buffer, selected.fileName, selected.fileSize, MediaSendType.IMAGE);
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
        await this.uploadAndSend(roomId, file.buffer, file.fileName, file.fileSize, MediaSendType.IMAGE);
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

  async uploadAndSend(
    roomId: string,
    buffer: ArrayBuffer,
    fileName: string,
    fileSize: number,
    mediaType: MediaSendType
  ): Promise<void> {
    const config: MediaUploadConfig = this.getUploadConfig(mediaType);
    try {
      const mxcUrl: string = await config.uploadMethod(buffer, fileName);

      if (mxcUrl) {
        const mediaInfo: Record<string, Object> = {
          'size': fileSize as Object,
          'mimetype': config.mimetype as Object
        };
        const bodyText: string = config.body || fileName;
        const messageContent: Record<string, string | object> = {
          'msgtype': config.msgtype,
          'body': bodyText,
          'url': mxcUrl,
          'info': mediaInfo as object
        };
        if (config.extraFields) {
          const extraKeys: string[] = Object.keys(config.extraFields);
          for (let i = 0; i < extraKeys.length; i++) {
            const key: string = extraKeys[i];
            messageContent[key] = config.extraFields[key];
          }
        }
        await this.messageSender.sendMedia(roomId, messageContent);
        ToastUtils.show(config.successToast);
      }
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to send media: ' + errMsg);
      ToastUtils.show(config.failureToast);
    }
  }

  async startRecording(context: Object): Promise<Object | null> {
    return await this.audioRecorder.start(context);
  }

  async stopRecording(recorder: Object, audioPath: string, audioFd: number): Promise<RecordingResult | null> {
    return await this.audioRecorder.stop(recorder, audioPath, audioFd);
  }
}
