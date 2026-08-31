import { Room } from '@mlethe/room';

import { Context } from '@kit.AbilityKit';
import { AppLogger } from '../utils/AppLogger';
import { Room as RoomModel, Message, User, TagInfo } from '../models/DataModels';
import { MessageStatus } from '../models/types/MessageTypes';
import { ParsedRoomState, RoomMemberInfo } from '../models/types/RoomTypes';

import { ToonaDatabase } from './ToonaDatabase';
import { MessageDao } from './dao/MessageDao';
import { RoomDao } from './dao/RoomDao';
import { UserDao } from './dao/UserDao';
import { RoomMemberDao } from './dao/RoomMemberDao';
import { CryptoDao } from './dao/CryptoDao';
import { DeviceKeysStorage } from './dao/DeviceKeysDao';
import { MessageEntity } from './entities/MessageEntity';
import { RoomEntity } from './entities/RoomEntity';
import { UserEntity } from './entities/UserEntity';
import { RoomMemberEntity } from './entities/RoomMemberEntity';

export interface ILocalDatabase {
  init(context: Context): Promise<void>;
  saveMessage(message: Message): Promise<void>;
  saveMessages(messages: Message[]): Promise<void>;
  getMessages(roomId: string, limit?: number, beforeEventId?: string): Promise<Message[]>;
  clearRoomMessages(roomId: string): Promise<void>;
  saveRoom(room: RoomModel): Promise<void>;
  saveRooms(rooms: RoomModel[]): Promise<void>;
  getRooms(): Promise<RoomModel[]>;
  getRoom(roomId: string): Promise<RoomModel | null>;
  updateRoomState(roomId: string, state: ParsedRoomState): Promise<void>;
  getRoomState(roomId: string): Promise<ParsedRoomState | null>;
  updateRoomUnreadCount(roomId: string, unreadCount: number, highlightCount?: number): Promise<void>;
  deleteRoom(roomId: string): Promise<void>;
  saveUser(user: User): Promise<void>;
  getUser(userId: string): Promise<User | null>;
  saveRoomMember(roomId: string, userId: string, displayName?: string, avatarUrl?: string, membership?: string): Promise<void>;
  getRoomMembers(roomId: string): Promise<RoomMemberInfo[]>;
  clearAllData(): Promise<void>;
  close(): void;
}

export class LocalDatabase implements ILocalDatabase {
  private isInitialized: boolean = false;
  private messageDao: MessageDao | null = null;
  private roomDao: RoomDao | null = null;
  private userDao: UserDao | null = null;
  private roomMemberDao: RoomMemberDao | null = null;

  constructor() {
  }

  private static logger = AppLogger.getLogger(LocalDatabase);

  async init(context: Context): Promise<void> {
    if (this.isInitialized) {
      return;
    }

    try {
      await Room.init(context, ToonaDatabase, true);
      this.messageDao = Room.getDao(MessageDao);
      this.roomDao = Room.getDao(RoomDao);
      this.userDao = Room.getDao(UserDao);
      this.roomMemberDao = Room.getDao(RoomMemberDao);

      // Initialize CryptoDao for E2EE support
      const cryptoDao = CryptoDao.getInstance();
      cryptoDao.init();

      // Initialize DeviceKeysStorage for device key persistence
      const deviceKeysStorage = DeviceKeysStorage.getInstance();
      deviceKeysStorage.init();

      this.isInitialized = true;
    } catch (error) {
      LocalDatabase.logger.error('Failed to initialize Room database:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to initialize LocalDatabase: ${errMsg}`);
    }
  }

  // ── Message CRUD ──

  async saveMessage(message: Message): Promise<void> {
    if (!this.messageDao) {
      throw new Error('Database not initialized');
    }

    try {
      const entity = this.messageToEntity(message);
      await this.messageDao.insert(entity);
    } catch (error) {
      LocalDatabase.logger.error('Failed to save message:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to save message: ${errMsg}`);
    }
  }

  async saveMessages(messages: Message[]): Promise<void> {
    if (!this.messageDao) {
      throw new Error('Database not initialized');
    }

    try {
      for (const message of messages) {
        const entity = this.messageToEntity(message);
        await this.messageDao.insert(entity);
      }
    } catch (error) {
      LocalDatabase.logger.error('Failed to save messages batch:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to save messages: ${errMsg}`);
    }
  }

  async getMessages(roomId: string, limit: number = 50, beforeEventId?: string): Promise<Message[]> {
    if (!this.messageDao) {
      throw new Error('Database not initialized');
    }

    try {
      const entities = await this.messageDao.getByRoomId(roomId, limit);
      const messages: Message[] = [];

      for (let i = entities.length - 1; i >= 0; i--) {
        const message = this.entityToMessage(entities[i]);
        messages.push(message);
      }

      return messages;
    } catch (error) {
      LocalDatabase.logger.error('Failed to get messages:', error);
      return [];
    }
  }

  async clearRoomMessages(roomId: string): Promise<void> {
    if (!this.messageDao) {
      throw new Error('Database not initialized');
    }

    try {
      await this.messageDao.deleteByRoomId(roomId);
    } catch (error) {
      LocalDatabase.logger.error('Failed to clear room messages:', error);
    }
  }

  // ── Room CRUD ──

  async saveRoom(room: RoomModel): Promise<void> {
    if (!this.roomDao) {
      throw new Error('Database not initialized');
    }

    try {
      const entity = this.roomToEntity(room);
      await this.roomDao.insert(entity);
    } catch (error) {
      LocalDatabase.logger.error('Failed to save room:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to save room: ${errMsg}`);
    }
  }

  async saveRooms(rooms: RoomModel[]): Promise<void> {
    if (!this.roomDao) {
      throw new Error('Database not initialized');
    }

    try {
      for (const room of rooms) {
        const entity = this.roomToEntity(room);
        await this.roomDao.insert(entity);
      }
    } catch (error) {
      LocalDatabase.logger.error('Failed to save rooms batch:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to save rooms: ${errMsg}`);
    }
  }

  async getRooms(): Promise<RoomModel[]> {
    if (!this.roomDao) {
      throw new Error('Database not initialized');
    }

    try {
      const entities = await this.roomDao.getAll();
      const rooms: RoomModel[] = [];

      for (const entity of entities) {
        const room = this.entityToRoom(entity);
        rooms.push(room);
      }

      return rooms;
    } catch (error) {
      LocalDatabase.logger.error('Failed to get rooms:', error);
      return [];
    }
  }

  async getRoom(roomId: string): Promise<RoomModel | null> {
    if (!this.roomDao) {
      throw new Error('Database not initialized');
    }

    try {
      const entity = await this.roomDao.getById(roomId);
      if (!entity) {
        return null;
      }
      return this.entityToRoom(entity);
    } catch (error) {
      LocalDatabase.logger.error('Failed to get room:', error);
      return null;
    }
  }

  async updateRoomState(roomId: string, state: ParsedRoomState): Promise<void> {
    if (!this.roomDao) {
      throw new Error('Database not initialized');
    }

    try {
      const entity = await this.roomDao.getById(roomId);
      if (entity) {
        entity.name = state.name || undefined;
        entity.display_name = state.name || undefined;
        entity.topic = state.topic || undefined;
        entity.avatar_url = state.avatarUrl || undefined;
        entity.canonical_alias = state.canonicalAlias || undefined;
        entity.join_rule = state.joinRule || undefined;
        entity.history_visibility = state.historyVisibility || undefined;
        entity.create_time = state.createTime || undefined;
        entity.creator = state.creator || undefined;
        entity.is_space = state.isSpace === true;
        if (state.memberCount !== undefined) {
          entity.member_count = state.memberCount;
        }
        await this.roomDao.insert(entity);
      } else {
        const newEntity = new RoomEntity();
        newEntity.room_id = roomId;
        newEntity.name = state.name || undefined;
        newEntity.display_name = state.name || undefined;
        newEntity.topic = state.topic || undefined;
        newEntity.avatar_url = state.avatarUrl || undefined;
        newEntity.canonical_alias = state.canonicalAlias || undefined;
        newEntity.join_rule = state.joinRule || undefined;
        newEntity.history_visibility = state.historyVisibility || undefined;
        newEntity.create_time = state.createTime || undefined;
        newEntity.creator = state.creator || undefined;
        newEntity.is_space = state.isSpace === true;
        if (state.memberCount !== undefined) {
          newEntity.member_count = state.memberCount;
        }
        await this.roomDao.insert(newEntity);
      }
    } catch (error) {
      LocalDatabase.logger.error('Failed to update room state:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to update room state: ${errMsg}`);
    }
  }

  async getRoomState(roomId: string): Promise<ParsedRoomState | null> {
    if (!this.roomDao) {
      throw new Error('Database not initialized');
    }

    try {
      const entity = await this.roomDao.getById(roomId);
      if (!entity) {
        return null;
      }

      const state: ParsedRoomState = {
        roomId: entity.room_id,
        name: entity.name || undefined,
        topic: entity.topic || undefined,
        avatarUrl: entity.avatar_url || undefined,
        canonicalAlias: entity.canonical_alias || undefined,
        joinRule: entity.join_rule || undefined,
        historyVisibility: entity.history_visibility || undefined,
        createTime: entity.create_time || undefined,
        creator: entity.creator || undefined,
        isSpace: entity.is_space === true,
        memberCount: entity.member_count || undefined
      };

      return state;
    } catch (error) {
      LocalDatabase.logger.error('Failed to get room state:', error);
      return null;
    }
  }

  async updateRoomUnreadCount(roomId: string, unreadCount: number, highlightCount: number = 0): Promise<void> {
    if (!this.roomDao) {
      throw new Error('Database not initialized');
    }

    try {
      const entity = await this.roomDao.getById(roomId);
      if (entity) {
        entity.unread_count = unreadCount;
        entity.highlight_count = highlightCount;
        await this.roomDao.insert(entity);
      }
    } catch (error) {
      LocalDatabase.logger.error('Failed to update room unread count:', error);
    }
  }

  async deleteRoom(roomId: string): Promise<void> {
    if (!this.roomDao || !this.messageDao || !this.roomMemberDao) {
      throw new Error('Database not initialized');
    }

    try {
      await this.messageDao.deleteByRoomId(roomId);
      await this.roomDao.deleteById(roomId);
      await this.roomMemberDao.deleteByRoomId(roomId);
    } catch (error) {
      LocalDatabase.logger.error('Failed to delete room:', error);
    }
  }

  // ── User CRUD ──

  async saveUser(user: User): Promise<void> {
    if (!this.userDao) {
      throw new Error('Database not initialized');
    }

    try {
      const entity = this.userToEntity(user);
      await this.userDao.insert(entity);
    } catch (error) {
      LocalDatabase.logger.error('Failed to save user:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to save user: ${errMsg}`);
    }
  }

  async getUser(userId: string): Promise<User | null> {
    if (!this.userDao) {
      throw new Error('Database not initialized');
    }

    try {
      const entity = await this.userDao.getById(userId);
      if (!entity) {
        return null;
      }
      return this.entityToUser(entity);
    } catch (error) {
      LocalDatabase.logger.error('Failed to get user:', error);
      return null;
    }
  }

  // ── Room Member CRUD ──

  async saveRoomMember(roomId: string, userId: string, displayName?: string, avatarUrl?: string,
    membership?: string): Promise<void> {
    if (!this.roomMemberDao) {
      throw new Error('Database not initialized');
    }

    try {
      const entity = new RoomMemberEntity();
      entity.room_id = roomId;
      entity.user_id = userId;
      entity.display_name = displayName || undefined;
      entity.avatar_url = avatarUrl || undefined;
      entity.membership = membership || undefined;
      await this.roomMemberDao.insert(entity);
    } catch (error) {
      LocalDatabase.logger.error('Failed to save room member:', error);
    }
  }

  async getRoomMembers(roomId: string): Promise<RoomMemberInfo[]> {
    if (!this.roomMemberDao) {
      throw new Error('Database not initialized');
    }

    try {
      const entities = await this.roomMemberDao.getByRoomId(roomId);
      const members: RoomMemberInfo[] = [];

      for (const entity of entities) {
        members.push({
          user_id: entity.user_id,
          display_name: entity.display_name || undefined,
          avatar_url: entity.avatar_url || undefined
        });
      }

      return members;
    } catch (error) {
      LocalDatabase.logger.error('Failed to get room members:', error);
      return [];
    }
  }

  // ── Utility ──

  async clearAllData(): Promise<void> {
    if (!this.messageDao || !this.roomDao || !this.userDao || !this.roomMemberDao) {
      throw new Error('Database not initialized');
    }

    try {
      await this.messageDao.deleteAll();
      await this.roomDao.deleteAll();
      await this.userDao.deleteAll();
      await this.roomMemberDao.deleteAll();
    } catch (error) {
      LocalDatabase.logger.error('Failed to clear all data:', error);
    }
  }

  close(): void {
    this.messageDao = null;
    this.roomDao = null;
    this.userDao = null;
    this.roomMemberDao = null;
    this.isInitialized = false;
  // ── Entity ↔ Model mappers ──

  private messageToEntity(msg: Message): MessageEntity {
    const entity = new MessageEntity();
    entity.event_id = msg.eventId;
    entity.room_id = msg.roomId;
    entity.sender = msg.sender;
    entity.type = msg.type;
    entity.content = msg.content;
    entity.timestamp = msg.timestamp;
    entity.is_outgoing = msg.isOutgoing;
    entity.status = msg.status as string;
    entity.reply_event_id = msg.replyEventId || undefined;
    entity.edited_event_id = msg.editedEventId || undefined;
    return entity;
  }

  private entityToMessage(entity: MessageEntity): Message {
    const message = new Message({
      event_id: entity.event_id,
      room_id: entity.room_id,
      sender: entity.sender,
      type: entity.type,
      content: entity.content || {} as Record<string, string | object>,
      origin_server_ts: entity.timestamp
    });

    message.isOutgoing = entity.is_outgoing === true;
    message.status = (entity.status || 'sent') as MessageStatus;
    message.replyEventId = entity.reply_event_id || undefined;
    message.editedEventId = entity.edited_event_id || undefined;

    return message;
  }

  private roomToEntity(room: RoomModel): RoomEntity {
    const entity = new RoomEntity();
    entity.room_id = room.id;
    entity.name = room.name || undefined;
    entity.display_name = room.displayName || undefined;
    entity.topic = room.topic || undefined;
    entity.avatar_url = room.avatarUrl || undefined;
    entity.member_count = room.memberCount || undefined;
    entity.my_membership = room.myMembership || 'join';
    entity.is_direct = room.isDirect === true;
    entity.unread_count = room.unreadCount || 0;
    entity.highlight_count = room.highlightCount || 0;
    entity.last_event_id = room.lastEvent?.event_id || undefined;
    entity.last_event_time = room.lastEventTime || undefined;
    entity.canonical_alias = room.canonicalAlias || undefined;
    entity.join_rule = room.joinRule || undefined;
    entity.history_visibility = room.historyVisibility || undefined;
    entity.create_time = room.createTime || undefined;
    entity.creator = room.creator || undefined;
    entity.is_space = room.isSpace === true;
    entity.tags = room.tags as Record<string, object> || undefined;
    return entity;
  }

  private entityToRoom(entity: RoomEntity): RoomModel {
    const room = new RoomModel(entity.room_id);
    room.name = entity.name || undefined;
    room.displayName = entity.display_name || undefined;
    room.topic = entity.topic || undefined;
    room.avatarUrl = entity.avatar_url || undefined;
    room.memberCount = entity.member_count || undefined;
    room.myMembership = entity.my_membership || undefined;
    room.isDirect = entity.is_direct === true;
    room.unreadCount = entity.unread_count || 0;
    room.highlightCount = entity.highlight_count || 0;
    room.canonicalAlias = entity.canonical_alias || undefined;
    room.joinRule = entity.join_rule || undefined;
    room.historyVisibility = entity.history_visibility || undefined;
    room.createTime = entity.create_time || undefined;
    room.creator = entity.creator || undefined;
    room.isSpace = entity.is_space === true;
    room.tags = entity.tags as Record<string, TagInfo> || undefined;
    return room;
  }

  private userToEntity(user: User): UserEntity {
    const entity = new UserEntity();
    entity.user_id = user.userId;
    entity.display_name = user.displayName || undefined;
    entity.avatar_url = user.avatarUrl || undefined;
    entity.presence = user.presence || undefined;
    entity.last_active_ago = user.lastActiveAgo || undefined;
    entity.currently_active = user.currentlyActive === true;
    entity.status_msg = user.statusMsg || undefined;
    return entity;
  }

  private entityToUser(entity: UserEntity): User {
    const user = new User(entity.user_id);
    user.displayName = entity.display_name || undefined;
    user.avatarUrl = entity.avatar_url || undefined;
    user.presence = entity.presence || undefined;
    user.lastActiveAgo = entity.last_active_ago || undefined;
    user.currentlyActive = entity.currently_active === true;
    user.statusMsg = entity.status_msg || undefined;
    return user;
  }
}

