import { IRoomManager } from '../RoomManager';
import { RoomTagManager } from '../RoomTagManager';
import { IAuthManager } from '../AuthManager';
import { ServiceLocator } from '../ServiceLocator';

export class RoomContext {
  private roomManager: IRoomManager = ServiceLocator.getRoomManager();
  private roomTagManager: RoomTagManager = ServiceLocator.getRoomTagManager();
  private authManager: IAuthManager = ServiceLocator.getAuthManager();

  getRoomManager(): IRoomManager {
    return this.roomManager;
  }

  getRoomTagManager(): RoomTagManager {
    return this.roomTagManager;
  }

  getHomeserver(): string {
    return this.authManager.getHomeserver();
  }
}
