import { Database } from '@mlethe/room';
import relationalStore from '@ohos.data.relationalStore';
import { MessageEntity } from './entities/MessageEntity';
import { RoomEntity } from './entities/RoomEntity';
import { UserEntity } from './entities/UserEntity';
import { RoomMemberEntity } from './entities/RoomMemberEntity';
import { AppLogger } from '../utils/AppLogger';

const logger = AppLogger.getLogger('ToonaDatabase');

@Database({ entities: [MessageEntity, RoomEntity, UserEntity, RoomMemberEntity], name: "toona_matrix.db", version: 3 })
export class ToonaDatabase {
  async onCreate(db: relationalStore.RdbStore): Promise<void> {
    logger.info('Database created');
    // Room handles table creation via entity decorators automatically
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
          db.executeSql(migration);
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
          db.executeSql(migration);
          logger.info(`Migration v2→v3 succeeded: ${migration}`);
        } catch (error) {
          logger.error(`Migration v2→v3 failed: ${migration}`, error);
        }
      }
    }
  }
}
