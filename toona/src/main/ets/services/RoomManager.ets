import { MatrixHttpClient } from '../network/MatrixHttpClient';
import {
  RoomCreateResponse,
  JoinedRoomsResponse,
  JoinedMembersResponse,
  DirectoryRoomResponse,
  RoomMessagesResponse,
  InitialStateEvent
} from '../models/MatrixTypes';
import { AuthManager } from './AuthManager';
import { LocalDatabase } from '../database/LocalDatabase';
import { Room, Message } from '../models/DataModels';

export interface SpaceChild {
  room_id: string;
  via?: string[];
  order?: string;
  auto_join?: boolean;
  suggested?: boolean;
}

export interface SpaceChildrenResponse {
  children: SpaceChild[];
  orphaned?: string[];
}

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
    const content: Record<string, string | object> = {};

    if (options?.name) {
      content.name = options.name;
    }
    if (options?.topic) {
      content.topic = options.topic;
    }
    if (options?.isDirect) {
      content.is_direct = 'true';
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
    const emptyContent: Record<string, string | object> = {};

    try {
      await this.httpClient.post<object>(`/rooms/${encodedRoomId}/join`, emptyContent);
    } catch (error) {
      console.error('Failed to join room:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async leaveRoom(roomId: string): Promise<void> {
    const encodedRoomId = encodeURIComponent(roomId);
    const emptyContent: Record<string, string | object> = {};

    try {
      await this.httpClient.post<object>(`/rooms/${encodedRoomId}/leave`, emptyContent);
    } catch (error) {
      console.error('Failed to leave room:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async inviteUser(roomId: string, userId: string): Promise<void> {
    const encodedRoomId = encodeURIComponent(roomId);
    const content: Record<string, string | object> = {
      "user_id": userId
    };

    try {
      await this.httpClient.post<object>(`/rooms/${encodedRoomId}/invite`, content);
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
      "limit": limit.toString(),
      "dir": direction
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
    const content: Record<string, string | object> = {
      "name": name
    };

    try {
      await this.httpClient.put<object>(`/rooms/${encodedRoomId}/state/m.room.name`, content);
    } catch (error) {
      console.error('Failed to set room name:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async setRoomTopic(roomId: string, topic: string): Promise<void> {
    const encodedRoomId = encodeURIComponent(roomId);
    const content: Record<string, string | object> = {
      "topic": topic
    };

    try {
      await this.httpClient.put<object>(`/rooms/${encodedRoomId}/state/m.room.topic`, content);
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
    const emptyContent: Record<string, string | object> = {};

    try {
      await this.httpClient.post<object>(`/rooms/${encodedRoomId}/forget`, emptyContent);
    } catch (error) {
      console.error('Failed to forget room:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async kickUser(roomId: string, userId: string, reason?: string): Promise<void> {
    const encodedRoomId = encodeURIComponent(roomId);
    const content: Record<string, string | object> = {
      "user_id": userId,
      "reason": reason !== undefined ? reason : ''
    };

    try {
      await this.httpClient.post<object>(`/rooms/${encodedRoomId}/kick`, content);
    } catch (error) {
      console.error('Failed to kick user:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async banUser(roomId: string, userId: string, reason?: string): Promise<void> {
    const encodedRoomId = encodeURIComponent(roomId);
    const content: Record<string, string | object> = {
      "user_id": userId,
      "reason": reason !== undefined ? reason : ''
    };

    try {
      await this.httpClient.post<object>(`/rooms/${encodedRoomId}/ban`, content);
    } catch (error) {
      console.error('Failed to ban user:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async unbanUser(roomId: string, userId: string): Promise<void> {
    const encodedRoomId = encodeURIComponent(roomId);
    const content: Record<string, string | object> = {
      "user_id": userId
    };

    try {
      await this.httpClient.post<object>(`/rooms/${encodedRoomId}/unban`, content);
    } catch (error) {
      console.error('Failed to unban user:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async createSpace(name: string, topic?: string, isDirect?: boolean, inviteUsers?: string[]): Promise<string> {
    const content: Record<string, string | object> = {
      'name': name,
      'preset': 'private_chat',
      'is_direct': isDirect === true ? 'true' : 'false'
    };

    if (topic) {
      content.topic = topic;
    }

    if (inviteUsers && inviteUsers.length > 0) {
      content.invite = inviteUsers;
    }

    const createContent: Record<string, string | object> = {
      'creator': this.authManager.getSession()?.userId || '',
      'room_version': '9',
      'type': 'm.space'
    };

    const parentContent: Record<string, string | object> = {
      'via': [this.authManager.getSession()?.homeServer || 'localhost'],
      'canonical': 'true'
    };

    const initialState: InitialStateEvent[] = [
      {
        type: 'm.room.create',
        state_key: '',
        content: createContent
      },
      {
        type: 'm.space.parent',
        state_key: '',
        content: parentContent
      }
    ];

    content.initial_state = initialState;

    try {
      const response = await this.httpClient.post<RoomCreateResponse>('/createRoom', content);
      return response.room_id;
    } catch (error) {
      console.error('Failed to create space:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async getSpaceChildren(roomId: string): Promise<SpaceChild[]> {
    const encodedRoomId = encodeURIComponent(roomId);

    try {
      const response = await this.httpClient.get<SpaceChildrenResponse>(
        `/rooms/${encodedRoomId}/spaces`,
        undefined,
        'v1'
      );
      return response.children || [];
    } catch (error) {
      console.error('Failed to get space children:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async addChildToSpace(parentRoomId: string, childRoomId: string, via?: string[]): Promise<void> {
    const encodedParentId = encodeURIComponent(parentRoomId);
    const encodedChildId = encodeURIComponent(childRoomId);

    const content: Record<string, string | object> = {
      "via": via || [this.authManager.getSession()?.homeServer || 'localhost']
    };

    try {
      await this.httpClient.put<object>(
        `/rooms/${encodedParentId}/state/m.space.child/${encodedChildId}`,
        content
      );
    } catch (error) {
      console.error('Failed to add child to space:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async removeChildFromSpace(parentRoomId: string, childRoomId: string): Promise<void> {
    const encodedParentId = encodeURIComponent(parentRoomId);
    const encodedChildId = encodeURIComponent(childRoomId);

    try {
      await this.httpClient.delete<object>(
        `/rooms/${encodedParentId}/state/m.space.child/${encodedChildId}`
      );
    } catch (error) {
      console.error('Failed to remove child from space:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }
}
