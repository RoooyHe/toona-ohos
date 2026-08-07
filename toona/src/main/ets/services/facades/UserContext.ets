import { UserManager } from '../UserManager';
import { MediaManager } from '../MediaManager';
import { IAuthManager } from '../AuthManager';
import { IRoomManager } from '../RoomManager';
import { RoomTagManager } from '../RoomTagManager';
import { DeviceManager } from '../DeviceManager';
import { ServiceLocator } from '../ServiceLocator';

export class UserContext {
  private userManager: UserManager = ServiceLocator.getUserManager();
  private mediaManager: MediaManager = ServiceLocator.getMediaManager();
  private authManager: IAuthManager = ServiceLocator.getAuthManager();
  private roomManager: IRoomManager = ServiceLocator.getRoomManager();
  private roomTagManager: RoomTagManager = ServiceLocator.getRoomTagManager();
  private deviceManager: DeviceManager = ServiceLocator.getDeviceManager();

  getUserManager(): UserManager {
    return this.userManager;
  }

  getMediaManager(): MediaManager {
    return this.mediaManager;
  }

  getAuthManager(): IAuthManager {
    return this.authManager;
  }

  getRoomManager(): IRoomManager {
    return this.roomManager;
  }

  getRoomTagManager(): RoomTagManager {
    return this.roomTagManager;
  }

  getDeviceManager(): DeviceManager {
    return this.deviceManager;
  }
}
