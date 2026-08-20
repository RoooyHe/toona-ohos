import { IRoomManager } from './RoomManager';
import { IAuthManager } from './AuthManager';
import { IUserManager } from './UserManager';
import { PresenceState } from '../models/MatrixTypes';
import { AppLogger } from '../utils/AppLogger';

const logger = AppLogger.getLogger('RoomMetadataLoader');

export interface MemberPresence {
  userId: string;
  presence: PresenceState;
  displayName: string;
}

export interface RoomTopicResult {
  roomTopic: string;
  roomName: string;
}

export interface IRoomMetadataLoader {
  loadMemberPresences(roomId: string): Promise<MemberPresence[]>;
  loadRoomTopic(roomId: string): Promise<RoomTopicResult>;
  checkTypingUsers(roomId: string): Promise<string[]>;
  onInputChange(text: string, roomId: string): void;
  stopTyping(roomId: string): void;
  cleanup(roomId: string): Promise<void>;
}

export class RoomMetadataLoader implements IRoomMetadataLoader {
  private roomManager: IRoomManager;
  private authManager: IAuthManager;
  private userManager: IUserManager;

  private typingTimeout: number = 0;
  private typingStopTimeout: number = 0;

  constructor(
    roomManager: IRoomManager,
    authManager: IAuthManager,
    userManager: IUserManager
  ) {
    this.roomManager = roomManager;
    this.authManager = authManager;
    this.userManager = userManager;
  }

  async loadMemberPresences(roomId: string): Promise<MemberPresence[]> {
    try {
      const members: string[] = await this.roomManager.getRoomMembers(roomId);
      const currentUserId: string = this.authManager.getUserId();
      const otherMembers: string[] = members.filter((id: string) => id !== currentUserId);
      const presences: MemberPresence[] = [];

      for (let i = 0; i < otherMembers.length; i++) {
        const userId: string = otherMembers[i];
        try {
          const presence = await this.userManager.getPresence(userId);
          const displayName: string = presence.displayname || userId;
          const mp: MemberPresence = {
            userId: userId,
            presence: presence.presence as PresenceState,
            displayName: displayName
          };
          presences.push(mp);
        } catch (e) {
          const mp: MemberPresence = {
            userId: userId,
            presence: 'offline' as PresenceState,
            displayName: userId
          };
          presences.push(mp);
        }
      }
      return presences;
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to load member presences: ' + errMsg);
      return [];
    }
  }

  async loadRoomTopic(roomId: string): Promise<RoomTopicResult> {
    try {
      const room = await this.roomManager.getRoom(roomId);
      if (room) {
        const result: RoomTopicResult = {
          roomTopic: room.topic || '',
          roomName: room.displayName || room.name || '聊天室'
        };
        return result;
      }
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to load room topic: ' + errMsg);
    }
    const fallback: RoomTopicResult = { roomTopic: '', roomName: '聊天室' };
    return fallback;
  }

  async checkTypingUsers(roomId: string): Promise<string[]> {
    try {
      const typing: string[] = await this.roomManager.getTypingUsers(roomId);
      const currentUserId: string = this.authManager.getUserId();
      return typing.filter((id: string) => id !== currentUserId);
    } catch (error) {
      const errMsg: string = error instanceof Error ? error.message : String(error);
      logger.error('Failed to check typing users: ' + errMsg);
      return [];
    }
  }

  onInputChange(text: string, roomId: string): void {
    if (this.typingTimeout === 0) {
      this.roomManager.startTyping(roomId).catch(() => {});
    }
    if (this.typingStopTimeout) {
      clearTimeout(this.typingStopTimeout);
    }
    const self = this;
    this.typingStopTimeout = setTimeout(() => {
      self.roomManager.stopTyping(roomId).catch(() => {});
      self.typingTimeout = 0;
      self.typingStopTimeout = 0;
    }, 3000) as number;
  }

  stopTyping(roomId: string): void {
    this.roomManager.stopTyping(roomId).catch(() => {});
  }

  async cleanup(roomId: string): Promise<void> {
    if (this.typingTimeout) {
      clearTimeout(this.typingTimeout);
      this.typingTimeout = 0;
    }
    if (this.typingStopTimeout) {
      clearTimeout(this.typingStopTimeout);
      this.typingStopTimeout = 0;
    }
    await this.roomManager.stopTyping(roomId).catch(() => {});
  }
}
