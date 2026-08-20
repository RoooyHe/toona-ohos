import { BusinessError } from '@kit.BasicServicesKit';
import { ToastUtils } from '../utils/ToastUtils';
import { common, Want } from '@kit.AbilityKit';
import { AppLogger } from '../utils/AppLogger';

export interface IShareManager {
  shareRoomLink(roomId: string, roomName: string, homeserver: string): void;
  shareMessage(content: string, senderName: string): void;
  shareText(title: string, content: string): void;
}

export class ShareManager implements IShareManager {
  private logger = AppLogger.getLogger(ShareManager);

  shareText(title: string, content: string): void {
    const logger = this.logger;
    try {
      const context: common.UIAbilityContext = getContext() as common.UIAbilityContext;
      const want: Want = {
        action: 'ohos.want.action.viewData',
        type: 'text/plain',
        parameters: {
          "title": title,
          "data": content
        } as Record<string, Object>
      };

      context.startAbility(want).then(() => {
        logger.info('Share started successfully');
      }).catch((error: BusinessError) => {
        logger.error('Failed to start share: %{public}s', error);
        ToastUtils.show('分享失败');
      });
    } catch (error) {
      logger.error('Share error: %{public}s', error.message);
      ToastUtils.show('分享失败');
    }
  }

  shareRoomLink(roomId: string, roomName: string, homeserver: string): void {
    const matrixToLink = `https://matrix.to/#/${roomId}`;
    this.shareText(
      roomName,
      `加入我的Matrix房间: ${roomName}\n${matrixToLink}`
    );
  }

  shareMessage(content: string, senderName: string): void {
    this.shareText(
      '来自 ' + senderName + ' 的消息',
      content
    );
  }

  shareUserId(userId: string, displayName: string): void {
    const shareText = displayName
      ? `${displayName} (${userId})`
      : userId;
    this.shareText(
      '分享用户',
      shareText
    );
  }

  shareSpaceLink(roomId: string, spaceName: string): void {
    const matrixToLink = `https://matrix.to/#/${roomId}`;
    this.shareText(
      spaceName,
      `加入我的Matrix空间: ${spaceName}\n${matrixToLink}`
    );
  }
}