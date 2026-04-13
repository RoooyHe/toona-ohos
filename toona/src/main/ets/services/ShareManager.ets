import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@ohos.promptAction';

export class ShareManager {
  private static instance: ShareManager;

  static getInstance(): ShareManager {
    if (!ShareManager.instance) {
      ShareManager.instance = new ShareManager();
    }
    return ShareManager.instance;
  }

  shareText(title: string, content: string): void {
    try {
      const context = getContext();
      const want = {
        action: 'ohos.want.action.viewData',
        type: 'text/plain',
        data: content,
        parameters: {
          title: title
        }
      } as Record<string, Object>;
      
      context.startAbility({
        want: want
      }).then(() => {
        console.info('Share started successfully');
      }).catch((error: BusinessError) => {
        console.error('Failed to start share: %{public}s', JSON.stringify(error));
        promptAction.showToast({ message: '分享失败' });
      });
    } catch (error) {
      console.error('Share error: %{public}s', JSON.stringify(error));
      promptAction.showToast({ message: '分享失败' });
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