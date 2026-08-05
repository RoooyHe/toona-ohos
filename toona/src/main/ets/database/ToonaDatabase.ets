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
  async onCreate(db: relationalStore.RdbStore): Promise<void> {
    logger.info('Database created');
  }

  async onUpgrade(db: relationalStore.RdbStore, oldVersion: number, newVersion: number): Promise<void> {
    logger.info(`Database upgrade from ${oldVersion} to ${newVersion}`);

    if (oldVersion < 2 && newVersion >= 2) {
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
          await db.executeSql(migration);
          logger.info(`Migration v1→v2 succeeded: ${migration}`);
        } catch (error) {
          logger.error(`Migration v1→v2 failed: ${migration}`, error);
        }
      }
    }

    if (oldVersion < 3 && newVersion >= 3) {
      const migrations = [
        'ALTER TABLE rooms ADD COLUMN tags TEXT'
      ];

      for (const migration of migrations) {
        try {
          await db.executeSql(migration);
          logger.info(`Migration v2→v3 succeeded: ${migration}`);
        } catch (error) {
          logger.error(`Migration v2→v3 failed: ${migration}`, error);
        }
      }
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
      const migrations = [
        `ALTER TABLE device_keys ADD COLUMN trust_level TEXT DEFAULT 'unverified'`,
        `ALTER TABLE device_keys ADD COLUMN verified_at INTEGER DEFAULT 0`,
        `ALTER TABLE device_keys ADD COLUMN verified_by TEXT DEFAULT ''`
      ];

      for (const migration of migrations) {
        try {
          await db.executeSql(migration);
          logger.info(`Migration v5→v6 succeeded: ${migration.substring(0, 50)}...`);
        } catch (error) {
          logger.error(`Migration v5→v6 failed: ${migration.substring(0, 50)}...`, error);
        }
      }
    }

    if (oldVersion < 7 && newVersion >= 7) {
      const migrations = [
        'ALTER TABLE rooms ADD COLUMN last_event_id TEXT',
        'ALTER TABLE rooms ADD COLUMN last_event_time INTEGER'
      ];

      for (const migration of migrations) {
        try {
          await db.executeSql(migration);
          logger.info(`Migration v6→v7 succeeded: ${migration}`);
        } catch (error) {
          logger.error(`Migration v6→v7 failed: ${migration}`, error);
        }
      }
    }
  }
}
