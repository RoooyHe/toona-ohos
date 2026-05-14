import { Dao, Insert, OnConflictStrategy, Query, Params } from '@mlethe/room';
import { RoomEntity } from '../entities/RoomEntity';
import { ToonaDatabase } from '../ToonaDatabase';

@Dao({ database: ToonaDatabase, entity: RoomEntity })
export class RoomDao {
  @Insert({ onConflict: OnConflictStrategy.REPLACE })
  async insert(entity: RoomEntity): Promise<number> {
    return Promise.resolve(0);
  }

  @Query({ entity: RoomEntity, isArray: true, sql: "SELECT * FROM rooms ORDER BY last_event_time DESC" })
  async getAll(): Promise<RoomEntity[]> {
    return [];
  }

  @Query({ entity: RoomEntity, isArray: false, sql: "SELECT * FROM rooms WHERE room_id = :roomId" })
  async getById(@Params("roomId") roomId: string): Promise<RoomEntity | null> {
    return null;
  }

  @Query({ entity: RoomEntity, isArray: false, sql: "UPDATE rooms SET unread_count = :unreadCount, highlight_count = :highlightCount WHERE room_id = :roomId" })
  async updateUnreadCount(@Params("roomId") roomId: string, @Params("unreadCount") unreadCount: number, @Params("highlightCount") highlightCount: number): Promise<number> {
    return Promise.resolve(0);
  }

  @Query({ entity: RoomEntity, isArray: false, sql: "DELETE FROM rooms WHERE room_id = :roomId" })
  async deleteById(@Params("roomId") roomId: string): Promise<number> {
    return Promise.resolve(0);
  }

  @Query({ entity: RoomEntity, isArray: false, sql: "DELETE FROM rooms" })
  async deleteAll(): Promise<number> {
    return Promise.resolve(0);
  }
}
