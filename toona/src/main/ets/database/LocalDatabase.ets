import relationalStore from '@ohos.data.relationalStore';
import { Message, Room, User, MessageStatus, TagInfo } from '../models/DataModels';
import { Context } from '@kit.AbilityKit';
import { ParsedRoomState } from '../models/MatrixTypes';

const DATABASE_NAME = 'toona_matrix.db';
const DATABASE_VERSION = 3;

interface TableNames {
  MESSAGES: string;
  ROOMS: string;
  USERS: string;
  ROOM_MEMBERS: string;
}

const TABLES: TableNames = {
  MESSAGES: 'messages',
  ROOMS: 'rooms',
  USERS: 'users',
  ROOM_MEMBERS: 'room_members'
};

export class LocalDatabase {
  private static instance: LocalDatabase;
  private store: relationalStore.RdbStore | null = null;
  private isInitialized: boolean = false;

  private constructor() {
  }

  static getInstance(): LocalDatabase {
    if (!LocalDatabase.instance) {
      LocalDatabase.instance = new LocalDatabase();
    }
    return LocalDatabase.instance;
  }

  async init(context: Context): Promise<void> {
    if (this.isInitialized) {
      return;
    }

    const config: relationalStore.StoreConfig = {
      name: DATABASE_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };

    try {
      this.store = await relationalStore.getRdbStore(context, config);
      await this.createTables();
      await this.runMigrations();
      this.isInitialized = true;
    } catch (error) {
      console.error('Failed to initialize LocalDatabase:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to initialize LocalDatabase: ${errMsg}`);
    }
  }

  private async runMigrations(): Promise<void> {
    if (!this.store) {
      return;
    }

    try {
      const schemaVersionExists = await this.tableExists('schema_version');
      let currentVersion = 0;

      if (schemaVersionExists) {
        currentVersion = await this.getSchemaVersion();
      }

      if (currentVersion < DATABASE_VERSION) {
        await this.migrateDatabase(currentVersion, DATABASE_VERSION);
      }
    } catch (error) {
      console.info('No schema_version table found, will create tables');
    }
  }

  private tableExists(tableName: string): Promise<boolean> {
    const store: relationalStore.RdbStore | null = this.store;
    if (!store) {
      return Promise.resolve(false);
    }
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(tableName);
    return new Promise((resolve) => {
      store.query(predicates, (err: Error, resultSet: relationalStore.ResultSet) => {
        if (err || !resultSet) {
          resolve(false);
          return;
        }
        const exists: boolean = resultSet.goToFirstRow();
        resultSet.close();
        resolve(exists);
      });
    });
  }

  private getSchemaVersion(): Promise<number> {
    const store: relationalStore.RdbStore | null = this.store;
    if (!store) {
      return Promise.resolve(0);
    }
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('schema_version');
    return new Promise((resolve) => {
      store.query(predicates, (err: Error, resultSet: relationalStore.ResultSet) => {
        if (err || !resultSet) {
          resolve(0);
          return;
        }
        if (resultSet.goToFirstRow()) {
          const version: number = resultSet.getLong(resultSet.getColumnIndex('version'));
          resultSet.close();
          resolve(version);
        } else {
          resultSet.close();
          resolve(0);
        }
      });
    });
  }

  private async migrateDatabase(fromVersion: number, toVersion: number): Promise<void> {
    if (!this.store) {
      return;
    }

    console.info(`Migrating database from version ${fromVersion} to ${toVersion}`);

    if (fromVersion < 2 && toVersion >= 2) {
      const migrations = [
        'ALTER TABLE rooms ADD COLUMN canonical_alias TEXT',
        'ALTER TABLE rooms ADD COLUMN join_rule TEXT',
        'ALTER TABLE rooms ADD COLUMN history_visibility TEXT',
        'ALTER TABLE rooms ADD COLUMN create_time INTEGER',
        'ALTER TABLE rooms ADD COLUMN creator TEXT',
        'ALTER TABLE rooms ADD COLUMN is_space INTEGER DEFAULT 0'
      ];

      for (const migration of migrations) {
        try {
          await this.store.executeSql(migration);
          console.info(`Migration succeeded: ${migration}`);
        } catch (error) {
          console.error(`Migration failed: ${migration}`, error);
        }
      }
    }

    if (fromVersion < 3 && toVersion >= 3) {
      const migrations = [
        'ALTER TABLE rooms ADD COLUMN tags TEXT'
      ];

      for (const migration of migrations) {
        try {
          await this.store.executeSql(migration);
          console.info(`Migration succeeded: ${migration}`);
        } catch (error) {
          console.error(`Migration failed: ${migration}`, error);
        }
      }
    }

    try {
      await this.store.executeSql(
        'CREATE TABLE IF NOT EXISTS schema_version (version INTEGER PRIMARY KEY)'
      );
      await this.store.executeSql('DELETE FROM schema_version');
      await this.store.executeSql(`INSERT INTO schema_version (version) VALUES (${toVersion})`);
      console.info(`Database migration to version ${toVersion} completed`);
    } catch (error) {
      console.error('Failed to update schema_version:', error);
    }
  }

  private async createTables(): Promise<void> {
    if (!this.store) {
      return;
    }

    const createMessagesTable = `
      CREATE TABLE IF NOT EXISTS ${TABLES.MESSAGES} (
        event_id TEXT PRIMARY KEY,
        room_id TEXT NOT NULL,
        sender TEXT NOT NULL,
        type TEXT NOT NULL,
        content TEXT,
        timestamp INTEGER NOT NULL,
        is_outgoing INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'sent',
        reply_event_id TEXT,
        edited_event_id TEXT,
        UNIQUE(event_id, room_id)
      )
    `;

    const createRoomsTable = `
      CREATE TABLE IF NOT EXISTS ${TABLES.ROOMS} (
        room_id TEXT PRIMARY KEY,
        name TEXT,
        display_name TEXT,
        topic TEXT,
        avatar_url TEXT,
        member_count INTEGER,
        my_membership TEXT,
        is_direct INTEGER NOT NULL DEFAULT 0,
        unread_count INTEGER DEFAULT 0,
        highlight_count INTEGER DEFAULT 0,
        last_event_id TEXT,
        last_event_time INTEGER,
        canonical_alias TEXT,
        join_rule TEXT,
        history_visibility TEXT,
        create_time INTEGER,
        creator TEXT,
        is_space INTEGER DEFAULT 0,
        tags TEXT,
        UNIQUE(room_id)
      )
    `;

    const createUsersTable = `
      CREATE TABLE IF NOT EXISTS ${TABLES.USERS} (
        user_id TEXT PRIMARY KEY,
        display_name TEXT,
        avatar_url TEXT,
        presence TEXT,
        last_active_ago INTEGER,
        currently_active INTEGER DEFAULT 0,
        status_msg TEXT
      )
    `;

    const createRoomMembersTable = `
      CREATE TABLE IF NOT EXISTS ${TABLES.ROOM_MEMBERS} (
        room_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        display_name TEXT,
        avatar_url TEXT,
        membership TEXT,
        PRIMARY KEY(room_id, user_id)
      )
    `;

    const createIndexes = `
      CREATE INDEX IF NOT EXISTS idx_messages_room_id ON ${TABLES.MESSAGES}(room_id);
      CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON ${TABLES.MESSAGES}(timestamp);
      CREATE INDEX IF NOT EXISTS idx_room_members_room_id ON ${TABLES.ROOM_MEMBERS}(room_id);
    `;

    try {
      await this.store.executeSql(createMessagesTable);
      await this.store.executeSql(createRoomsTable);
      await this.store.executeSql(createUsersTable);
      await this.store.executeSql(createRoomMembersTable);
      const indexStatements = createIndexes.split(';').filter(s => s.trim());
      for (const stmt of indexStatements) {
        if (stmt.trim()) {
          await this.store.executeSql(stmt);
        }
      }
    } catch (error) {
      console.error('Failed to create tables:', error);
    }
  }

  async saveMessage(message: Message): Promise<void> {
    if (!this.store) {
      throw new Error('Database not initialized');
    }

    const valueBucket: relationalStore.ValuesBucket = {
      event_id: message.eventId,
      room_id: message.roomId,
      sender: message.sender,
      type: message.type,
      content: JSON.stringify(message.content),
      timestamp: message.timestamp,
      is_outgoing: message.isOutgoing ? 1 : 0,
      status: message.status as string,
      reply_event_id: message.replyEventId || null,
      edited_event_id: message.editedEventId || null
    };

    try {
      await this.store.insert(TABLES.MESSAGES, valueBucket);
    } catch (error) {
      console.error('Failed to save message:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to save message: ${errMsg}`);
    }
  }

  async saveMessages(messages: Message[]): Promise<void> {
    if (!this.store) {
      throw new Error('Database not initialized');
    }

    for (const message of messages) {
      await this.saveMessage(message);
    }
  }

  async getMessages(roomId: string, limit: number = 50, beforeEventId?: string): Promise<Message[]> {
    if (!this.store) {
      throw new Error('Database not initialized');
    }

    const predicates = new relationalStore.RdbPredicates(TABLES.MESSAGES);
    predicates.equalTo('room_id', roomId);

    if (beforeEventId) {
      predicates.lessThan('timestamp', beforeEventId);
    }

    predicates.orderByDesc('timestamp').limitAs(limit);

    try {
      const resultSet = await this.store.query(predicates);
      const messages: Message[] = [];

      while (resultSet.goToNextRow()) {
        const message = this.resultSetToMessage(resultSet);
        messages.push(message);
      }

      resultSet.close();
      return messages;
    } catch (error) {
      console.error('Failed to get messages:', error);
      return [];
    }
  }

  private resultSetToMessage(resultSet: relationalStore.ResultSet): Message {
    const contentStr = resultSet.getString(resultSet.getColumnIndex('content'));
    const content: Record<string, string | object> =
      contentStr ? JSON.parse(contentStr) as Record<string, string | object> : {} as Record<string, string | object>;

    const message = new Message({
      event_id: resultSet.getString(resultSet.getColumnIndex('event_id')),
      room_id: resultSet.getString(resultSet.getColumnIndex('room_id')),
      sender: resultSet.getString(resultSet.getColumnIndex('sender')),
      type: resultSet.getString(resultSet.getColumnIndex('type')),
      content: content,
      origin_server_ts: resultSet.getLong(resultSet.getColumnIndex('timestamp'))
    });

    message.isOutgoing = resultSet.getLong(resultSet.getColumnIndex('is_outgoing')) === 1;
    message.status = resultSet.getString(resultSet.getColumnIndex('status')) as MessageStatus;
    message.replyEventId = resultSet.getString(resultSet.getColumnIndex('reply_event_id')) || undefined;
    message.editedEventId = resultSet.getString(resultSet.getColumnIndex('edited_event_id')) || undefined;

    return message;
  }

  async saveRoom(room: Room): Promise<void> {
    if (!this.store) {
      throw new Error('Database not initialized');
    }

    let tagsJson: string | null = null;
    if (room.tags) {
      try {
        tagsJson = JSON.stringify(room.tags);
      } catch (error) {
        console.error('Failed to stringify tags:', error);
      }
    }

    const valueBucket: relationalStore.ValuesBucket = {
      room_id: room.id,
      name: room.name || null,
      display_name: room.displayName || null,
      topic: room.topic || null,
      avatar_url: room.avatarUrl || null,
      member_count: room.memberCount || null,
      my_membership: room.myMembership || 'join',
      is_direct: room.isDirect ? 1 : 0,
      unread_count: room.unreadCount || 0,
      highlight_count: room.highlightCount || 0,
      last_event_id: room.lastEvent?.event_id || null,
      last_event_time: room.lastEventTime || null,
      canonical_alias: room.canonicalAlias || null,
      join_rule: room.joinRule || null,
      history_visibility: room.historyVisibility || null,
      create_time: room.createTime || null,
      creator: room.creator || null,
      is_space: room.isSpace ? 1 : 0,
      tags: tagsJson
    };

    try {
      const predicates = new relationalStore.RdbPredicates(TABLES.ROOMS);
      predicates.equalTo('room_id', room.id);
      const existing = await this.store.query(predicates);
      if (existing.goToFirstRow()) {
        await this.store.update(valueBucket, predicates);
      } else {
        await this.store.insert(TABLES.ROOMS, valueBucket);
      }
      existing.close();
    } catch (error) {
      console.error('Failed to save room:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to save room: ${errMsg}`);
    }
  }

  async saveRooms(rooms: Room[]): Promise<void> {
    if (!this.store) {
      throw new Error('Database not initialized');
    }

    for (const room of rooms) {
      await this.saveRoom(room);
    }
  }

  async getRooms(): Promise<Room[]> {
    if (!this.store) {
      throw new Error('Database not initialized');
    }

    const predicates = new relationalStore.RdbPredicates(TABLES.ROOMS);
    predicates.orderByDesc('last_event_time');

    try {
      const resultSet = await this.store.query(predicates);
      const rooms: Room[] = [];

      while (resultSet.goToNextRow()) {
        const room = this.resultSetToRoom(resultSet);
        rooms.push(room);
      }

      resultSet.close();
      return rooms;
    } catch (error) {
      console.error('Failed to get rooms:', error);
      return [];
    }
  }

  async getRoom(roomId: string): Promise<Room | null> {
    if (!this.store) {
      throw new Error('Database not initialized');
    }

    const predicates = new relationalStore.RdbPredicates(TABLES.ROOMS);
    predicates.equalTo('room_id', roomId);

    try {
      const resultSet = await this.store.query(predicates);
      if (resultSet.goToFirstRow()) {
        const room = this.resultSetToRoom(resultSet);
        resultSet.close();
        return room;
      }
      resultSet.close();
      return null;
    } catch (error) {
      console.error('Failed to get room:', error);
      return null;
    }
  }

  async updateRoomState(roomId: string, state: ParsedRoomState): Promise<void> {
    if (!this.store) {
      throw new Error('Database not initialized');
    }

    const valueBucket: relationalStore.ValuesBucket = {
      name: state.name || null,
      display_name: state.name || null,
      topic: state.topic || null,
      avatar_url: state.avatarUrl || null,
      canonical_alias: state.canonicalAlias || null,
      join_rule: state.joinRule || null,
      history_visibility: state.historyVisibility || null,
      create_time: state.createTime || null,
      creator: state.creator || null,
      is_space: state.isSpace ? 1 : 0
    };

    try {
      const predicates = new relationalStore.RdbPredicates(TABLES.ROOMS);
      predicates.equalTo('room_id', roomId);
      await this.store.update(valueBucket, predicates);
    } catch (error) {
      console.error('Failed to update room state:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to update room state: ${errMsg}`);
    }
  }

  async getRoomState(roomId: string): Promise<ParsedRoomState | null> {
    if (!this.store) {
      throw new Error('Database not initialized');
    }

    const predicates = new relationalStore.RdbPredicates(TABLES.ROOMS);
    predicates.equalTo('room_id', roomId);

    try {
      const resultSet = await this.store.query(predicates);
      if (resultSet.goToFirstRow()) {
        const state: ParsedRoomState = {
          roomId: resultSet.getString(resultSet.getColumnIndex('room_id')),
          name: resultSet.getString(resultSet.getColumnIndex('name')) || undefined,
          topic: resultSet.getString(resultSet.getColumnIndex('topic')) || undefined,
          avatarUrl: resultSet.getString(resultSet.getColumnIndex('avatar_url')) || undefined,
          canonicalAlias: resultSet.getString(resultSet.getColumnIndex('canonical_alias')) || undefined,
          joinRule: resultSet.getString(resultSet.getColumnIndex('join_rule')) || undefined,
          historyVisibility: resultSet.getString(resultSet.getColumnIndex('history_visibility')) || undefined,
          createTime: resultSet.getLong(resultSet.getColumnIndex('create_time')) || undefined,
          creator: resultSet.getString(resultSet.getColumnIndex('creator')) || undefined,
          isSpace: resultSet.getLong(resultSet.getColumnIndex('is_space')) === 1
        };
        resultSet.close();
        return state;
      }
      resultSet.close();
      return null;
    } catch (error) {
      console.error('Failed to get room state:', error);
      return null;
    }
  }

  private resultSetToRoom(resultSet: relationalStore.ResultSet): Room {
    const roomId = resultSet.getString(resultSet.getColumnIndex('room_id'));
    const room = new Room(roomId);

    room.name = resultSet.getString(resultSet.getColumnIndex('name')) || undefined;
    room.displayName = resultSet.getString(resultSet.getColumnIndex('display_name')) || undefined;
    room.topic = resultSet.getString(resultSet.getColumnIndex('topic')) || undefined;
    room.avatarUrl = resultSet.getString(resultSet.getColumnIndex('avatar_url')) || undefined;
    room.memberCount = resultSet.getLong(resultSet.getColumnIndex('member_count')) || undefined;
    room.myMembership = resultSet.getString(resultSet.getColumnIndex('my_membership')) || undefined;
    room.isDirect = resultSet.getLong(resultSet.getColumnIndex('is_direct')) === 1;
    room.unreadCount = resultSet.getLong(resultSet.getColumnIndex('unread_count')) || 0;
    room.highlightCount = resultSet.getLong(resultSet.getColumnIndex('highlight_count')) || 0;
    room.canonicalAlias = resultSet.getString(resultSet.getColumnIndex('canonical_alias')) || undefined;
    room.joinRule = resultSet.getString(resultSet.getColumnIndex('join_rule')) || undefined;
    room.historyVisibility = resultSet.getString(resultSet.getColumnIndex('history_visibility')) || undefined;
    const createTimeCol = resultSet.getColumnIndex('create_time');
    if (createTimeCol >= 0) {
      room.createTime = resultSet.getLong(createTimeCol) || undefined;
    }
    room.creator = resultSet.getString(resultSet.getColumnIndex('creator')) || undefined;
    const isSpaceCol = resultSet.getColumnIndex('is_space');
    if (isSpaceCol >= 0) {
      room.isSpace = resultSet.getLong(isSpaceCol) === 1;
    }

    const tagsCol = resultSet.getColumnIndex('tags');
    if (tagsCol >= 0) {
      const tagsStr = resultSet.getString(tagsCol);
      if (tagsStr) {
        try {
          room.tags = JSON.parse(tagsStr) as Record<string, TagInfo>;
        } catch (error) {
          console.error('Failed to parse tags:', error);
        }
      }
    }

    return room;
  }

  async saveUser(user: User): Promise<void> {
    if (!this.store) {
      throw new Error('Database not initialized');
    }

    const valueBucket: relationalStore.ValuesBucket = {
      user_id: user.userId,
      display_name: user.displayName || null,
      avatar_url: user.avatarUrl || null,
      presence: user.presence || null,
      last_active_ago: user.lastActiveAgo || null,
      currently_active: user.currentlyActive ? 1 : 0,
      status_msg: user.statusMsg || null
    };

    try {
      await this.store.insert(TABLES.USERS, valueBucket);
    } catch (error) {
      console.error('Failed to save user:', error);
      const errMsg: string = error instanceof Error ? error.message : String(error);
      throw new Error(`Failed to save user: ${errMsg}`);
    }
  }

  async getUser(userId: string): Promise<User | null> {
    if (!this.store) {
      throw new Error('Database not initialized');
    }

    const predicates = new relationalStore.RdbPredicates(TABLES.USERS);
    predicates.equalTo('user_id', userId);

    try {
      const resultSet = await this.store.query(predicates);
      if (resultSet.goToFirstRow()) {
        const user = this.resultSetToUser(resultSet);
        resultSet.close();
        return user;
      }
      resultSet.close();
      return null;
    } catch (error) {
      console.error('Failed to get user:', error);
      return null;
    }
  }

  private resultSetToUser(resultSet: relationalStore.ResultSet): User {
    const userId = resultSet.getString(resultSet.getColumnIndex('user_id'));
    const user = new User(userId);

    user.displayName = resultSet.getString(resultSet.getColumnIndex('display_name')) || undefined;
    user.avatarUrl = resultSet.getString(resultSet.getColumnIndex('avatar_url')) || undefined;
    user.presence = resultSet.getString(resultSet.getColumnIndex('presence')) || undefined;
    user.lastActiveAgo = resultSet.getLong(resultSet.getColumnIndex('last_active_ago')) || undefined;
    user.currentlyActive = resultSet.getLong(resultSet.getColumnIndex('currently_active')) === 1;
    user.statusMsg = resultSet.getString(resultSet.getColumnIndex('status_msg')) || undefined;

    return user;
  }

  async updateRoomUnreadCount(roomId: string, unreadCount: number, highlightCount: number = 0): Promise<void> {
    if (!this.store) {
      throw new Error('Database not initialized');
    }

    const predicates = new relationalStore.RdbPredicates(TABLES.ROOMS);
    predicates.equalTo('room_id', roomId);

    const valueBucket: relationalStore.ValuesBucket = {
      unread_count: unreadCount,
      highlight_count: highlightCount
    };

    try {
      await this.store.update(valueBucket, predicates);
    } catch (error) {
      console.error('Failed to update room unread count:', error);
    }
  }

  async clearRoomMessages(roomId: string): Promise<void> {
    if (!this.store) {
      throw new Error('Database not initialized');
    }

    const predicates = new relationalStore.RdbPredicates(TABLES.MESSAGES);
    predicates.equalTo('room_id', roomId);

    try {
      await this.store.delete(predicates);
    } catch (error) {
      console.error('Failed to clear room messages:', error);
    }
  }

  async deleteRoom(roomId: string): Promise<void> {
    if (!this.store) {
      throw new Error('Database not initialized');
    }

    try {
      await this.clearRoomMessages(roomId);

      let predicates = new relationalStore.RdbPredicates(TABLES.ROOMS);
      predicates.equalTo('room_id', roomId);
      await this.store.delete(predicates);

      predicates = new relationalStore.RdbPredicates(TABLES.ROOM_MEMBERS);
      predicates.equalTo('room_id', roomId);
      await this.store.delete(predicates);
    } catch (error) {
      console.error('Failed to delete room:', error);
    }
  }

  async clearAllData(): Promise<void> {
    if (!this.store) {
      throw new Error('Database not initialized');
    }

    try {
      await this.store.executeSql(`DELETE FROM ${TABLES.MESSAGES}`);
      await this.store.executeSql(`DELETE FROM ${TABLES.ROOMS}`);
      await this.store.executeSql(`DELETE FROM ${TABLES.USERS}`);
      await this.store.executeSql(`DELETE FROM ${TABLES.ROOM_MEMBERS}`);
    } catch (error) {
      console.error('Failed to clear all data:', error);
    }
  }

  close(): void {
    if (this.store) {
      this.store = null;
      this.isInitialized = false;
    }
  }
}
