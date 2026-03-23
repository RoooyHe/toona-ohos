import { MatrixHttpClient } from '../network/MatrixHttpClient';
import { 
  RoomCreateContent, 
  RoomCreateResponse, 
  JoinedRoomsResponse, 
  JoinedMembersResponse,
  DirectoryRoomResponse,
  RoomMessagesResponse,
  Event
} from '../models/MatrixTypes';
import { AuthManager } from './AuthManager';
import { LocalDatabase } from '../database/LocalDatabase';
import { Room, Message } from '../models/DataModels';

export interface CreateRoomOptions {
  name?: string;
  topic?: string;
  isDirect?: boolean;
  inviteUsers?: string[];
  roomAlias?: string;
}

export class RoomManager {
  private static instance: RoomManager;
  private httpClient: MatrixHttpClient;
  private authManager: AuthManager;
  private localDatabase: LocalDatabase;

  private constructor() {
    this.authManager = AuthManager.getInstance();
    this.httpClient = this.authManager.getHttpClient();
    this.localDatabase = LocalDatabase.getInstance();
  }

  static getInstance(): RoomManager {
    if (!RoomManager.instance) {
      RoomManager.instance = new RoomManager();
    }
    return RoomManager.instance;
  }

  async getRooms(): Promise<Room[]> {
    return await this.localDatabase.getRooms();
  }

  async getRoom(roomId: string): Promise<Room | null> {
    return await this.localDatabase.getRoom(roomId);
  }

  async createRoom(options?: CreateRoomOptions): Promise<string> {
    const content: RoomCreateContent = {};

    if (options?.name) {
      content.name = options.name;
    }
    if (options?.topic) {
      content.topic = options.topic;
    }
    if (options?.isDirect) {
      content.is_direct = true;
    }
    if (options?.inviteUsers && options.inviteUsers.length > 0) {
      content.invite = options.inviteUsers;
    }
    if (options?.roomAlias) {
      content.room_alias_name = options.roomAlias;
    }

    if (options?.isDirect && options?.inviteUsers && options.inviteUsers.length > 0) {
      content.preset = 'trusted_private_chat';
    } else if (options?.inviteUsers && options.inviteUsers.length > 0) {
      content.preset = 'private_chat';
    } else {
      content.preset = 'public_chat';
    }

    try {
      const response = await this.httpClient.post<RoomCreateResponse>('/createRoom', content);
      return response.room_id;
    } catch (error) {
      console.error('Failed to create room:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async joinRoom(roomIdOrAlias: string): Promise<void> {
    const encodedRoomId = encodeURIComponent(roomIdOrAlias);
    
    try {
      await this.httpClient.post(`/rooms/${encodedRoomId}/join`, {});
    } catch (error) {
      console.error('Failed to join room:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async leaveRoom(roomId: string): Promise<void> {
    const encodedRoomId = encodeURIComponent(roomId);
    
    try {
      await this.httpClient.post(`/rooms/${encodedRoomId}/leave`, {});
    } catch (error) {
      console.error('Failed to leave room:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async inviteUser(roomId: string, userId: string): Promise<void> {
    const encodedRoomId = encodeURIComponent(roomId);
    
    try {
      await this.httpClient.post(`/rooms/${encodedRoomId}/invite`, {
        user_id: userId
      });
    } catch (error) {
      console.error('Failed to invite user:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async getRoomMembers(roomId: string): Promise<string[]> {
    const encodedRoomId = encodeURIComponent(roomId);
    
    try {
      const response = await this.httpClient.get<JoinedMembersResponse>(
        `/rooms/${encodedRoomId}/joined_members`
      );
      return response.joined_members.map(m => m.user_id);
    } catch (error) {
      console.error('Failed to get room members:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async getRoomMessages(
    roomId: string, 
    limit: number = 20, 
    from?: string, 
    direction: 'b' | 'f' = 'b'
  ): Promise<Message[]> {
    const encodedRoomId = encodeURIComponent(roomId);
    const currentUserId = this.authManager.getSession()?.userId || '';
    
    const queryParams: Record<string, string> = {
      limit: limit.toString(),
      dir: direction
    };
    
    if (from) {
      queryParams.from = from;
    }

    try {
      const response = await this.httpClient.get<RoomMessagesResponse>(
        `/rooms/${encodedRoomId}/messages`,
        queryParams
      );

      const messages: Message[] = [];
      for (const event of response.chunk) {
        const message = Message.fromEvent(event, currentUserId);
        messages.push(message);
      }

      return messages;
    } catch (error) {
      console.error('Failed to get room messages:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async resolveRoomAlias(roomAlias: string): Promise<string> {
    const encodedAlias = encodeURIComponent(roomAlias);
    
    try {
      const response = await this.httpClient.get<DirectoryRoomResponse>(
        `/directory/room/${encodedAlias}`
      );
      return response.room_id;
    } catch (error) {
      console.error('Failed to resolve room alias:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async setRoomName(roomId: string, name: string): Promise<void> {
    const encodedRoomId = encodeURIComponent(roomId);
    
    try {
      await this.httpClient.put(`/rooms/${encodedRoomId}/state/m.room.name`, {
        name: name
      });
    } catch (error) {
      console.error('Failed to set room name:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async setRoomTopic(roomId: string, topic: string): Promise<void> {
    const encodedRoomId = encodeURIComponent(roomId);
    
    try {
      await this.httpClient.put(`/rooms/${encodedRoomId}/state/m.room.topic`, {
        topic: topic
      });
    } catch (error) {
      console.error('Failed to set room topic:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async getJoinedRooms(): Promise<string[]> {
    try {
      const response = await this.httpClient.get<JoinedRoomsResponse>('/joined_rooms');
      return response.joined_rooms;
    } catch (error) {
      console.error('Failed to get joined rooms:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async forgetRoom(roomId: string): Promise<void> {
    const encodedRoomId = encodeURIComponent(roomId);
    
    try {
      await this.httpClient.post(`/rooms/${encodedRoomId}/forget`, {});
    } catch (error) {
      console.error('Failed to forget room:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async kickUser(roomId: string, userId: string, reason?: string): Promise<void> {
    const encodedRoomId = encodeURIComponent(roomId);
    
    try {
      await this.httpClient.post(`/rooms/${encodedRoomId}/kick`, {
        user_id: userId,
        reason: reason
      });
    } catch (error) {
      console.error('Failed to kick user:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async banUser(roomId: string, userId: string, reason?: string): Promise<void> {
    const encodedRoomId = encodeURIComponent(roomId);
    
    try {
      await this.httpClient.post(`/rooms/${encodedRoomId}/ban`, {
        user_id: userId,
        reason: reason
      });
    } catch (error) {
      console.error('Failed to ban user:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async unbanUser(roomId: string, userId: string): Promise<void> {
    const encodedRoomId = encodeURIComponent(roomId);
    
    try {
      await this.httpClient.post(`/rooms/${encodedRoomId}/unban`, {
        user_id: userId
      });
    } catch (error) {
      console.error('Failed to unban user:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }
}
