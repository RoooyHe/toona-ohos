import { IAudioRecorder, RecordingResult } from './IAudioRecorder';
import { media } from '@kit.MediaKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import { AppLogger } from '../../utils/AppLogger';
import { ToastUtils } from '../../utils/ToastUtils';

const logger = AppLogger.getLogger('HarmonyAudioRecorder');

export class HarmonyAudioRecorder implements IAudioRecorder {
  async requestPermission(context: Object): Promise<boolean> {
    const abilityContext: common.UIAbilityContext = context as common.UIAbilityContext;
    const atManager = abilityAccessCtrl.createAtManager();
    try {
      const data = await atManager.requestPermissionsFromUser(abilityContext, ['ohos.permission.MICROPHONE']);
      return data.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (err) {
      const errMsg: string = err instanceof Error ? err.message : String(err);
      logger.error('Failed to request permission: ' + errMsg);
      return false;
    }
  }

  async start(context: Object): Promise<Object | null> {
    const abilityContext: common.UIAbilityContext = context as common.UIAbilityContext;
    const hasPermission: boolean = await this.requestPermission(context);
    if (!hasPermission) {
      ToastUtils.show('需要麦克风权限才能录制语音');
      return null;
    }

    try {
      const avRecorder: media.AVRecorder = await media.createAVRecorder();
      const audioPath: string = abilityContext.cacheDir + '/voice_' + Date.now() + '.m4a';
      const file = fileIo.openSync(audioPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      const audioFd: number = file.fd;

      const avProfile: media.AVRecorderProfile = {
        audioBitrate: 48000,
        audioChannels: 1,
        audioCodec: media.CodecMimeType.AUDIO_AAC,
        audioSampleRate: 48000,
        fileFormat: media.ContainerFormatType.CFT_MPEG_4A,
      };

      const avConfig: media.AVRecorderConfig = {
        audioSourceType: media.AudioSourceType.AUDIO_SOURCE_TYPE_MIC,
        profile: avProfile,
        url: 'fd://' + audioFd,
      };

      await avRecorder.prepare(avConfig);
      await avRecorder.start();

      const result: Record<string, Object> = {
        'avRecorder': avRecorder as Object,
        'audioPath': audioPath as Object,
        'audioFd': audioFd as Object
      };
      return result;
    } catch (err) {
      const errMsg: string = err instanceof Error ? err.message : String(err);
      logger.error('Failed to start recording: ' + errMsg);
      ToastUtils.show('无法启动录音设备');
      return null;
    }
  }

  async stop(recorder: Object, audioPath: string, audioFd: number): Promise<RecordingResult | null> {
    const avRecorder: media.AVRecorder = recorder as media.AVRecorder;
    if (avRecorder) {
      try {
        await avRecorder.stop();
        await avRecorder.release();
      } catch (err) {
        const errMsg: string = err instanceof Error ? err.message : String(err);
        logger.error('Failed to stop recording: ' + errMsg);
      }
    }

    try {
      fileIo.closeSync(audioFd);
      const file = fileIo.openSync(audioPath, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(audioPath);
      const buffer: ArrayBuffer = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);
      const result: RecordingResult = {
        buffer: buffer,
        fileName: 'voice_' + Date.now() + '.m4a'
      };
      return result;
    } catch (err) {
      const errMsg: string = err instanceof Error ? err.message : String(err);
      logger.error('Failed to read recording: ' + errMsg);
      return null;
    }
  }
}
