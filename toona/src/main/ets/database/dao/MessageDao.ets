import { Dao, Insert, OnConflictStrategy, Query, Params } from '@mlethe/room';
import { MessageEntity } from '../entities/MessageEntity';
import { ToonaDatabase } from '../ToonaDatabase';

@Dao({ database: ToonaDatabase, entity: MessageEntity })
export class MessageDao {
  @Insert({ onConflict: OnConflictStrategy.REPLACE })
  async insert(entity: MessageEntity): Promise<number> {
    return Promise.resolve(0);
  }

  @Query({ entity: MessageEntity, isArray: true, sql: "SELECT * FROM messages WHERE room_id = :roomId ORDER BY timestamp DESC LIMIT :limit" })
  async getByRoomId(@Params("roomId") roomId: string, @Params("limit") limit: number): Promise<MessageEntity[]> {
    return [];
  }

  @Query({ entity: MessageEntity, isArray: false, sql: "DELETE FROM messages WHERE room_id = :roomId" })
  async deleteByRoomId(@Params("roomId") roomId: string): Promise<number> {
    return Promise.resolve(0);
  }

  @Query({ entity: MessageEntity, isArray: false, sql: "DELETE FROM messages" })
  async deleteAll(): Promise<number> {
    return Promise.resolve(0);
  }

  @Query({ entity: MessageEntity, isArray: true, sql: "SELECT * FROM messages WHERE room_id = :roomId AND event_id = :eventId LIMIT 1" })
  async getByEventId(@Params("roomId") roomId: string, @Params("eventId") eventId: string): Promise<MessageEntity[]> {
    return [];
  }
}
