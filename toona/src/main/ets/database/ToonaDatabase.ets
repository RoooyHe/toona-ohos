import { Database } from '@mlethe/room';
import relationalStore from '@ohos.data.relationalStore';
import { MessageEntity } from './entities/MessageEntity';
import { RoomEntity } from './entities/RoomEntity';
import { UserEntity } from './entities/UserEntity';
import { RoomMemberEntity } from './entities/RoomMemberEntity';
import { InboundGroupSessionEntity } from './entities/InboundGroupSessionEntity';
import { OlmSessionEntity } from './entities/OlmSessionEntity';
import { DeviceKeysEntity } from './entities/DeviceKeysEntity';
import { AppLogger } from '../utils/AppLogger';

const logger = AppLogger.getLogger('ToonaDatabase');

@Database({ entities: [MessageEntity, RoomEntity, UserEntity, RoomMemberEntity, InboundGroupSessionEntity, OlmSessionEntity, DeviceKeysEntity], name: "toona_matrix.db", version: 7 })
export class ToonaDatabase {
  private static async columnExists(db: relationalStore.RdbStore, tableName: string, columnName: string): Promise<boolean> {
    try {
      const resultSet = await db.querySql(`PRAGMA table_info(${tableName})`);
      let row = resultSet.go();
      while (!row.isEndOfRecord()) {
        if (row.getString(1) === columnName) {
          return true;
        }
        row = resultSet.go();
      }
      return false;
    } catch (error) {
      logger.error(`columnExists check failed: ${tableName}.${columnName}`, error);
      return false;
    }
  }

  private static async addColumnIfMissing(
    db: relationalStore.RdbStore,
    tableName: string,
    columnName: string,
    columnDef: string
  ): Promise<void> {
    if (!(await ToonaDatabase.columnExists(db, tableName, columnName))) {
      try {
        await db.executeSql(`ALTER TABLE ${tableName} ADD COLUMN ${columnDef}`);
        logger.info(`Added column ${columnName} to ${tableName}`);
      } catch (error) {
        logger.error(`Failed to add column ${columnName} to ${tableName}`, error);
      }
    }
  }

  async onCreate(db: relationalStore.RdbStore): Promise<void> {
    logger.info('Database created');
  }

  async onUpgrade(db: relationalStore.RdbStore, oldVersion: number, newVersion: number): Promise<void> {
    logger.info(`Database upgrade from ${oldVersion} to ${newVersion}`);

    if (oldVersion < 2 && newVersion >= 2) {
      await ToonaDatabase.addColumnIfMissing(db, 'rooms', 'canonical_alias', 'canonical_alias TEXT');
      await ToonaDatabase.addColumnIfMissing(db, 'rooms', 'join_rule', 'join_rule TEXT');
      await ToonaDatabase.addColumnIfMissing(db, 'rooms', 'history_visibility', 'history_visibility TEXT');
      await ToonaDatabase.addColumnIfMissing(db, 'rooms', 'create_time', 'create_time INTEGER');
      await ToonaDatabase.addColumnIfMissing(db, 'rooms', 'creator', 'creator TEXT');
      await ToonaDatabase.addColumnIfMissing(db, 'rooms', 'is_space', 'is_space INTEGER DEFAULT 0');
    }

    if (oldVersion < 3 && newVersion >= 3) {
      await ToonaDatabase.addColumnIfMissing(db, 'rooms', 'tags', 'tags TEXT');
    }

    if (oldVersion < 4 && newVersion >= 4) {
      const migrations = [
        `CREATE TABLE IF NOT EXISTS inbound_group_sessions (
          sessionId TEXT PRIMARY KEY,
          room_id TEXT,
          sender_key TEXT,
          megolm_session_id TEXT,
          session_data TEXT,
          forwarding_chain TEXT DEFAULT '[]',
          created_at INTEGER
        )`,
        `CREATE TABLE IF NOT EXISTS olm_sessions (
          sessionId TEXT PRIMARY KEY,
          device_key TEXT,
          session_data TEXT,
          last_used INTEGER
        )`
      ];

      for (const migration of migrations) {
        try {
          await db.executeSql(migration);
          logger.info(`Migration v3→v4 succeeded: ${migration.substring(0, 50)}...`);
        } catch (error) {
          logger.error(`Migration v3→v4 failed: ${migration.substring(0, 50)}...`, error);
        }
      }
    }

    if (oldVersion < 5 && newVersion >= 5) {
      const migrations = [
        `CREATE TABLE IF NOT EXISTS device_keys (
          user_id TEXT PRIMARY KEY,
          device_id TEXT,
          ed25519_key TEXT,
          curve25519_key TEXT,
          algorithms TEXT DEFAULT '[]',
          signatures TEXT DEFAULT '{}',
          created_at INTEGER
        )`
      ];

      for (const migration of migrations) {
        try {
          await db.executeSql(migration);
          logger.info(`Migration v4→v5 succeeded: ${migration.substring(0, 50)}...`);
        } catch (error) {
          logger.error(`Migration v4→v5 failed: ${migration.substring(0, 50)}...`, error);
        }
      }
    }

    if (oldVersion < 6 && newVersion >= 6) {
      await ToonaDatabase.addColumnIfMissing(db, 'device_keys', 'trust_level', "trust_level TEXT DEFAULT 'unverified'");
      await ToonaDatabase.addColumnIfMissing(db, 'device_keys', 'verified_at', 'verified_at INTEGER DEFAULT 0');
      await ToonaDatabase.addColumnIfMissing(db, 'device_keys', 'verified_by', "verified_by TEXT DEFAULT ''");
    }

    if (oldVersion < 7 && newVersion >= 7) {
      await ToonaDatabase.addColumnIfMissing(db, 'rooms', 'last_event_id', 'last_event_id TEXT');
      await ToonaDatabase.addColumnIfMissing(db, 'rooms', 'last_event_time', 'last_event_time INTEGER');
    }

    // Post-upgrade schema validation: ensure all expected columns exist
    try {
      await ToonaDatabase.addColumnIfMissing(db, 'rooms', 'canonical_alias', 'canonical_alias TEXT');
      await ToonaDatabase.addColumnIfMissing(db, 'rooms', 'join_rule', 'join_rule TEXT');
      await ToonaDatabase.addColumnIfMissing(db, 'rooms', 'history_visibility', 'history_visibility TEXT');
      await ToonaDatabase.addColumnIfMissing(db, 'rooms', 'create_time', 'create_time INTEGER');
      await ToonaDatabase.addColumnIfMissing(db, 'rooms', 'creator', 'creator TEXT');
      await ToonaDatabase.addColumnIfMissing(db, 'rooms', 'is_space', 'is_space INTEGER DEFAULT 0');
      await ToonaDatabase.addColumnIfMissing(db, 'rooms', 'tags', 'tags TEXT');
      await ToonaDatabase.addColumnIfMissing(db, 'rooms', 'last_event_id', 'last_event_id TEXT');
      await ToonaDatabase.addColumnIfMissing(db, 'rooms', 'last_event_time', 'last_event_time INTEGER');
      await ToonaDatabase.addColumnIfMissing(db, 'device_keys', 'trust_level', "trust_level TEXT DEFAULT 'unverified'");
      await ToonaDatabase.addColumnIfMissing(db, 'device_keys', 'verified_at', 'verified_at INTEGER DEFAULT 0');
      await ToonaDatabase.addColumnIfMissing(db, 'device_keys', 'verified_by', "verified_by TEXT DEFAULT ''");
      logger.info('Post-upgrade schema validation completed');
    } catch (error) {
      logger.error('Post-upgrade schema validation failed', error);
    }
  }
}
