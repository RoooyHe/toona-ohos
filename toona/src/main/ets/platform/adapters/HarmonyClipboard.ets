import { IClipboard } from './IClipboard';
import { pasteboard } from '@kit.BasicServicesKit';
import { AppLogger } from '../../utils/AppLogger';
import { ToastUtils } from '../../utils/ToastUtils';

const logger = AppLogger.getLogger('HarmonyClipboard');

export class HarmonyClipboard implements IClipboard {
  async copyText(text: string): Promise<void> {
    try {
      const pasteData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      const systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      await systemPasteboard.setData(pasteData);
      ToastUtils.show('消息已复制');
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to copy: ' + errMsg);
      ToastUtils.show('复制失败');
    }
  }
}
