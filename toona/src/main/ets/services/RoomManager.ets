import { RoomStateParser } from '../utils/RoomStateParser';
import {
  RoomCreateResponse,
  JoinedRoomsResponse,
  JoinedMembersResponse,
  DirectoryRoomResponse,
  RoomMessagesResponse,
  InitialStateEvent,
  ParsedRoomState,
  Event,
  PublicRoomsResponse,
  PublicRoom,
  RoomAvatarContent,
  RoomMembersResponse,
  SetReadMarkersRequest,
  ReceiptContent,
  RoomDirectoryResponse,
  CanonicalAliasContent,
  RoomAliasesContent
} from '../models/MatrixTypes';
import { AuthManager, IAuthManager } from './AuthManager';
import { LocalDatabase } from '../database/LocalDatabase';
import { Room, Message } from '../models/DataModels';
import { AppLogger } from '../utils/AppLogger';
import { BaseHttpClient } from '../network/clients/BaseHttpClient';

const logger = AppLogger.getLogger('RoomManager');

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
  visibility?: 'public' | 'private';
}

interface ImageInfo {
  size: number;
  mimetype: string;
}

interface ImageMessageContent {
  msgtype: string;
  body: string;
  url: import("../models/MatrixTypes").MediaUploadResponse;
  info: ImageInfo;
}

interface TypingUsersResponse {
  user_ids: string[];
}

export interface IRoomManager {
  getRooms(): Promise<Room[]>;
  getRoom(roomId: string): Promise<Room | null>;
  createRoom(options?: CreateRoomOptions): Promise<string>;
  joinRoom(roomIdOrAlias: string): Promise<void>;
  leaveRoom(roomId: string): Promise<void>;
  inviteUser(roomId: string, userId: string): Promise<void>;
  getRoomMembers(roomId: string): Promise<string[]>;
  getRoomMessages(roomId: string, limit?: number, from?: string, direction?: 'b' | 'f'): Promise<Message[]>;
  resolveRoomAlias(roomAlias: string): Promise<string>;
  setRoomName(roomId: string, name: string): Promise<void>;
  setRoomTopic(roomId: string, topic: string): Promise<void>;
  getJoinedRooms(): Promise<string[]>;
  getRoomState(roomId: string): Promise<ParsedRoomState>;
  getRoomName(roomId: string): Promise<string | null>;
  getRoomTopic(roomId: string): Promise<string | null>;
  forgetRoom(roomId: string): Promise<void>;
  kickUser(roomId: string, userId: string, reason?: string): Promise<void>;
  banUser(roomId: string, userId: string, reason?: string): Promise<void>;
  unbanUser(roomId: string, userId: string): Promise<void>;
  createSpace(name: string, topic?: string, isDirect?: boolean, inviteUsers?: string[]): Promise<string>;
  getSpaceChildren(roomId: string): Promise<SpaceChild[]>;
  addChildToSpace(parentRoomId: string, childRoomId: string, via?: string[]): Promise<void>;
  removeChildFromSpace(parentRoomId: string, childRoomId: string): Promise<void>;
  startTyping(roomId: string, timeout?: number): Promise<void>;
  stopTyping(roomId: string): Promise<void>;
  getTypingUsers(roomId: string): Promise<string[]>;
  sendReadReceipt(roomId: string, eventId: string, threadId?: string): Promise<void>;
  sendPrivateReadReceipt(roomId: string, eventId: string, threadId?: string): Promise<void>;
  searchPublicRooms(server?: string, query?: string, limit?: number, since?: string): Promise<PublicRoomsResponse>;
  searchUsers(query: string, limit?: number): Promise<Record<string, string | object>>;
}

export class RoomManager implements IRoomManager {
  sendMessage(roomId: string, arg1: string,
    imageMessageContent: ImageMessageContent) {
  }
  private baseClient: BaseHttpClient;
  private authManager: IAuthManager;
  private localDatabase: LocalDatabase;

  constructor(
    authManager: IAuthManager,
    localDatabase: LocalDatabase,
    baseClient: BaseHttpClient
  ) {
    this.authManager = authManager;
    this.localDatabase = localDatabase;
    this.baseClient = baseClient;
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

    if (options?.visibility === 'public') {
      content.preset = 'public_chat';
    } else if (options?.isDirect && options?.inviteUsers && options.inviteUsers.length > 0) {
      content.preset = 'trusted_private_chat';
    } else if (options?.inviteUsers && options.inviteUsers.length > 0) {
      content.preset = 'private_chat';
    } else {
      content.preset = 'private_chat';
    }

    try {
      const response = await this.baseClient.post<RoomCreateResponse>('/createRoom', content);
      return response.room_id;
    } catch (error) {
      logger.error('Failed to create room:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async joinRoom(roomIdOrAlias: string): Promise<void> {
    const encodedRoomId = encodeURIComponent(roomIdOrAlias);
    const emptyContent: Record<string, string | object> = {};

    try {
      await this.baseClient.post<object>(`/rooms/${encodedRoomId}/join`, emptyContent);
    } catch (error) {
      logger.error('Failed to join room:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async leaveRoom(roomId: string): Promise<void> {
    const encodedRoomId = encodeURIComponent(roomId);
    const emptyContent: Record<string, string | object> = {};

    try {
      await this.baseClient.post<object>(`/rooms/${encodedRoomId}/leave`, emptyContent);
    } catch (error) {
      logger.error('Failed to leave room:', error);
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
      await this.baseClient.post<object>(`/rooms/${encodedRoomId}/invite`, content);
    } catch (error) {
      logger.error('Failed to invite user:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async getRoomMembers(roomId: string): Promise<string[]> {
    const encodedRoomId = encodeURIComponent(roomId);

    try {
      const response = await this.baseClient.get<JoinedMembersResponse>(
        `/rooms/${encodedRoomId}/joined_members`
      );
      return Object.keys(response.joined);
    } catch (error) {
      logger.error('Failed to get room members:', error);
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
      const response = await this.baseClient.get<RoomMessagesResponse>(
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
      logger.error('Failed to get room messages:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async resolveRoomAlias(roomAlias: string): Promise<string> {
    const encodedAlias = encodeURIComponent(roomAlias);

    try {
      const response = await this.baseClient.get<DirectoryRoomResponse>(
        `/directory/room/${encodedAlias}`
      );
      return response.room_id;
    } catch (error) {
      logger.error('Failed to resolve room alias:', error);
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
      await this.baseClient.put<object>(`/rooms/${encodedRoomId}/state/m.room.name`, content);
    } catch (error) {
      logger.error('Failed to set room name:', error);
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
      await this.baseClient.put<object>(`/rooms/${encodedRoomId}/state/m.room.topic`, content);
    } catch (error) {
      logger.error('Failed to set room topic:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async getJoinedRooms(): Promise<string[]> {
    try {
      const response = await this.baseClient.get<JoinedRoomsResponse>('/joined_rooms');
      return response.joined_rooms;
    } catch (error) {
      logger.error('Failed to get joined rooms:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async getRoomState(roomId: string): Promise<ParsedRoomState> {
    const encodedRoomId = encodeURIComponent(roomId);

    try {
      const response = await this.baseClient.get<RoomCreateResponse>(
        `/rooms/${encodedRoomId}/state`
      );
      const state = this.parseRoomStateEvents(roomId, response.events);
      await this.localDatabase.updateRoomState(roomId, state);
      return state;
    } catch (error) {
      logger.error('Failed to get room state:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get room state: ${errMsg}`);
    }
  }

  async getRoomName(roomId: string): Promise<string | null> {
    const encodedRoomId = encodeURIComponent(roomId);

    try {
      const response = await this.baseClient.get<Record<string, string | object>>(
        `/rooms/${encodedRoomId}/state/m.room.name`
      );
      const nameVal = response['name'];
      return nameVal !== undefined ? String(nameVal) : null;
    } catch (error) {
      logger.error('Failed to get room name:', error);
      return null;
    }
  }

  async getRoomTopic(roomId: string): Promise<string | null> {
    const encodedRoomId = encodeURIComponent(roomId);

    try {
      const response = await this.baseClient.get<Record<string, string | object>>(
        `/rooms/${encodedRoomId}/state/m.room.topic`
      );
      const topicVal = response['topic'];
      return topicVal !== undefined ? String(topicVal) : null;
    } catch (error) {
      logger.error('Failed to get room topic:', error);
      return null;
    }
  }

  async forgetRoom(roomId: string): Promise<void> {
    const encodedRoomId = encodeURIComponent(roomId);
    const emptyContent: Record<string, string | object> = {};

    try {
      await this.baseClient.post<object>(`/rooms/${encodedRoomId}/forget`, emptyContent);
    } catch (error) {
      logger.error('Failed to forget room:', error);
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
      await this.baseClient.post<object>(`/rooms/${encodedRoomId}/kick`, content);
    } catch (error) {
      logger.error('Failed to kick user:', error);
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
      await this.baseClient.post<object>(`/rooms/${encodedRoomId}/ban`, content);
    } catch (error) {
      logger.error('Failed to ban user:', error);
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
      await this.baseClient.post<object>(`/rooms/${encodedRoomId}/unban`, content);
    } catch (error) {
      logger.error('Failed to unban user:', error);
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
      const response = await this.baseClient.post<RoomCreateResponse>('/createRoom', content);
      return response.room_id;
    } catch (error) {
      logger.error('Failed to create space:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async getSpaceChildren(roomId: string): Promise<SpaceChild[]> {
    const encodedRoomId = encodeURIComponent(roomId);

    try {
      const response = await this.baseClient.get<SpaceChildrenResponse>(
        `/rooms/${encodedRoomId}/spaces`,
        undefined,
        'v1'
      );
      return response.children || [];
    } catch (error) {
      logger.error('Failed to get space children:', error);
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
      await this.baseClient.put<object>(
        `/rooms/${encodedParentId}/state/m.space.child/${encodedChildId}`,
        content
      );
    } catch (error) {
      logger.error('Failed to add child to space:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  async removeChildFromSpace(parentRoomId: string, childRoomId: string): Promise<void> {
    const encodedParentId = encodeURIComponent(parentRoomId);
    const encodedChildId = encodeURIComponent(childRoomId);

    try {
      await this.baseClient.delete<object>(
        `/rooms/${encodedParentId}/state/m.space.child/${encodedChildId}`
      );
    } catch (error) {
      logger.error('Failed to remove child from space:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed: ${errMsg}`);
    }
  }

  parseRoomStateEvents(roomId: string, stateEvents: Event[]): ParsedRoomState {
    return RoomStateParser.toParsedRoomState(roomId, stateEvents);
  }

  async startTyping(roomId: string, timeout: number = 10000): Promise<void> {
    const userId: string = this.authManager.getSession()?.userId || '';
    if (!userId) {
      throw new Error('Not logged in');
    }

    try {
      const encodedRoomId = this.baseClient.encodePath(roomId);
      const encodedUserId = this.baseClient.encodePath(userId);
      const body: Record<string, string | object> = { 'typing': 'true' };
      if (timeout !== undefined) {
        body['timeout'] = String(timeout);
      }
      await this.baseClient.put<void>(
        `/rooms/${encodedRoomId}/typing/${encodedUserId}`,
        body
      );
    } catch (error) {
      logger.error('Failed to start typing:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to start typing: ${errMsg}`);
    }
  }

  async stopTyping(roomId: string): Promise<void> {
    const userId: string = this.authManager.getSession()?.userId || '';
    if (!userId) {
      throw new Error('Not logged in');
    }

    try {
      const encodedRoomId = this.baseClient.encodePath(roomId);
      const encodedUserId = this.baseClient.encodePath(userId);
      const body: Record<string, string | object> = { 'typing': 'false' };
      await this.baseClient.put<void>(
        `/rooms/${encodedRoomId}/typing/${encodedUserId}`,
        body
      );
    } catch (error) {
      logger.error('Failed to stop typing:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to stop typing: ${errMsg}`);
    }
  }

  async getTypingUsers(roomId: string): Promise<string[]> {
    const userId: string = this.authManager.getSession()?.userId || '';
    if (!userId) {
      throw new Error('Not logged in');
    }

    try {
      const encodedRoomId = this.baseClient.encodePath(roomId);
      const encodedUserId = this.baseClient.encodePath(userId);
      const response = await this.baseClient.get<TypingUsersResponse>(
        `/rooms/${encodedRoomId}/typing/${encodedUserId}`
      );
      return response.user_ids || [];
    } catch (error) {
      logger.error('Failed to get typing users:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to get typing users: ${errMsg}`);
    }
  }

  async sendReadReceipt(roomId: string, eventId: string, threadId?: string): Promise<void> {
    try {
      const encodedRoomId = this.baseClient.encodePath(roomId);
      const encodedEventId = this.baseClient.encodePath(eventId);
      const body: Record<string, string | object> = {};
      if (threadId !== undefined) {
        body['thread_id'] = threadId;
      }
      await this.baseClient.post<void>(`/rooms/${encodedRoomId}/receipt/m.read/${encodedEventId}`, body);
    } catch (error) {
      logger.error('Failed to send read receipt:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to send read receipt: ${errMsg}`);
    }
  }

  async sendPrivateReadReceipt(roomId: string, eventId: string, threadId?: string): Promise<void> {
    try {
      const encodedRoomId = this.baseClient.encodePath(roomId);
      const encodedEventId = this.baseClient.encodePath(eventId);
      const body: Record<string, string | object> = {};
      if (threadId !== undefined) {
        body['thread_id'] = threadId;
      }
      await this.baseClient.post<void>(`/rooms/${encodedRoomId}/receipt/m.read.private/${encodedEventId}`, body);
    } catch (error) {
      logger.error('Failed to send private read receipt:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to send private read receipt: ${errMsg}`);
    }
  }

  async searchPublicRooms(server?: string, query?: string, limit?: number, since?: string): Promise<PublicRoomsResponse> {
    if (query) {
      const room: Record<string, string | object> = {
        'name': query
      };
      return await this.postPublicRooms(room);
    }
    return await this.getPublicRooms(server, limit, since);
  }

  async searchUsers(query: string, limit?: number): Promise<Record<string, string | object>> {
    const body: Record<string, string | object> = {
      'search_term': query,
      'limit': String(limit ?? 10)
    };
    return await this.baseClient.post<Record<string, string | object>>('/user_directory/search', body);
  }

  private async getPublicRooms(server?: string, limit?: number, since?: string): Promise<PublicRoomsResponse> {
    const queryParams = this.baseClient.buildQueryParams({
      'server': server,
      'limit': limit,
      'since': since
    });
    return await this.baseClient.get<PublicRoomsResponse>('/publicRooms', queryParams);
  }

  private async postPublicRooms(room: Record<string, string | object>): Promise<PublicRoomsResponse> {
    return await this.baseClient.post<PublicRoomsResponse>('/publicRooms', room);
  }
}
