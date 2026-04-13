import { scanCore, scanBarcode } from '@kit.ScanKit';
import { promptAction } from '@ohos.promptAction';
import { AsyncCallback } from '@kit.BaseKit';

export class ScanManager {
  private static instance: ScanManager;

  static getInstance(): ScanManager {
    if (!ScanManager.instance) {
      ScanManager.instance = new ScanManager();
    }
    return ScanManager.instance;;
  }

  async startScan(): Promise<string | null> {
    try {
      const options: scanBarcode.ScanOptions = {
        scanTypes: [scanCore.ScanType.QR_CODE],
        enableMultiMode: false,
        enableAlbum: true
      };

      return new Promise<string | null>((resolve) => {
        scanBarcode.scan(options, (err: error, result: scanBarcode.ScanResult) => {
          if (err) {
            console.error('Scan failed: %{public}s', JSON.stringify(err));
            promptAction.showToast({ message: '扫码失败' });
            resolve(null);
            return;
          }

          if (result) {
            const scannedValue = result.originalValue;
            console.info('Scanned: %{public}s', scannedValue);
            resolve(scannedValue);
          } else {
            resolve(null);
          }
        });
      });
    } catch (error) {
      console.error('Scan error: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '扫码失败' });
      return null;
    }
  }

  parseMatrixToLink(url: string): { type: string; roomId?: string; userId?: string; server?: string; via?: string[] } | null {
    const matrixToRegex = /^https?:\/\/matrix\.to\/((#|!)([^\?]+))(\?.*)?$/;
    const match = url.match(matrixToRegex);

    if (!match) {
      return null;
    }

    const type = match[2];
    const identifier = match[3];
    const queryString = match[4] || '';

    const result: { type: string; roomId?: string; userId?: string; server?: string; via?: string[] } = {
      type: type === '#' ? 'room' : 'room-or-space'
    };

    if (identifier.includes(':')) {
      const parts = identifier.split(':');
      result.roomId = parts[0];
      result.server = parts[1];
    } else {
      result.roomId = identifier;
    }

    const viaMatch = queryString.match(/via=([^&]+)/g);
    if (viaMatch) {
      result.via = viaMatch.map(v => v.replace('via=', ''));
    }

    return result;
  }

  parseRoomId(input: string): string {
    input = input.trim();

    if (input.startsWith('http://') || input.startsWith('https://')) {
      const parsed = this.parseMatrixToLink(input);
      if (parsed && parsed.roomId) {
        return parsed.roomId;
      }
      return input;
    }

    if (input.startsWith('#')) {
      return input;
    }

    if (input.startsWith('!') && input.includes(':')) {
      return input;
    }

    if (input.includes(':')) {
      return input;
    }

    return input;
  }

  isValidRoomId(input: string): boolean {
    if (!input || input.length < 1) {
      return false;
    }
    return input.startsWith('#') || input.startsWith('!') || input.includes(':');
  }

  getShareableRoomLink(roomId: string, server?: string): string {
    if (roomId.startsWith('#') || roomId.startsWith('!')) {
      return `https://matrix.to/#/${roomId}`;
    }
    if (server) {
      return `https://matrix.to/#/${roomId}:${server}`;
    }
    return `https://matrix.to/#/${roomId}`;
  }
}