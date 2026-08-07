import { ISyncManager } from '../SyncManager';
import { IRoomManager } from '../RoomManager';
import { RoomTagManager } from '../RoomTagManager';
import { IAuthManager } from '../AuthManager';
import { UserManager } from '../UserManager';
import { ServiceLocator } from '../ServiceLocator';

export class MainContext {
  private syncManager: ISyncManager = ServiceLocator.getSyncManager();
  private roomManager: IRoomManager = ServiceLocator.getRoomManager();
  private roomTagManager: RoomTagManager = ServiceLocator.getRoomTagManager();
  private authManager: IAuthManager = ServiceLocator.getAuthManager();
  private userManager: UserManager = ServiceLocator.getUserManager();

  getSyncManager(): ISyncManager {
    return this.syncManager;
  }

  getRoomManager(): IRoomManager {
    return this.roomManager;
  }

  getRoomTagManager(): RoomTagManager {
    return this.roomTagManager;
  }

  getAuthManager(): IAuthManager {
    return this.authManager;
  }

  getUserManager(): UserManager {
    return this.userManager;
  }
}
