import { IRoomManager } from '../RoomManager';
import { MessageManager } from '../MessageManager';
import { MediaManager } from '../MediaManager';
import { IAuthManager } from '../AuthManager';
import { ISyncManager } from '../SyncManager';
import { UserManager } from '../UserManager';
import { VerificationService } from '../VerificationService';
import { ServiceLocator } from '../ServiceLocator';

export class MessagingContext {
  private roomManager: IRoomManager = ServiceLocator.getRoomManager();
  private messageManager: MessageManager = ServiceLocator.getMessageManager();
  private mediaManager: MediaManager = ServiceLocator.getMediaManager();
  private authManager: IAuthManager = ServiceLocator.getAuthManager();
  private syncManager: ISyncManager = ServiceLocator.getSyncManager();
  private userManager: UserManager = ServiceLocator.getUserManager();
  private verificationService: VerificationService = ServiceLocator.getVerificationService();

  getRoomManager(): IRoomManager {
    return this.roomManager;
  }

  getMessageManager(): MessageManager {
    return this.messageManager;
  }

  getMediaManager(): MediaManager {
    return this.mediaManager;
  }

  getAuthManager(): IAuthManager {
    return this.authManager;
  }

  getSyncManager(): ISyncManager {
    return this.syncManager;
  }

  getUserManager(): UserManager {
    return this.userManager;
  }

  getVerificationService(): VerificationService {
    return this.verificationService;
  }
}
