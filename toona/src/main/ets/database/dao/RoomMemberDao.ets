import { Dao, Insert, OnConflictStrategy, Query, Params } from '@mlethe/room';
import { RoomMemberEntity } from '../entities/RoomMemberEntity';
import { ToonaDatabase } from '../ToonaDatabase';

@Dao({ database: ToonaDatabase, entity: RoomMemberEntity })
export class RoomMemberDao {
  @Insert({ onConflict: OnConflictStrategy.REPLACE })
  async insert(entity: RoomMemberEntity): Promise<number> {
    return Promise.resolve(0);
  }

  @Query({ entity: RoomMemberEntity, isArray: true, sql: "SELECT * FROM room_members WHERE room_id = :roomId" })
  async getByRoomId(@Params("roomId") roomId: string): Promise<RoomMemberEntity[]> {
    return [];
  }

  @Query({ entity: RoomMemberEntity, isArray: false, sql: "DELETE FROM room_members WHERE room_id = :roomId" })
  async deleteByRoomId(@Params("roomId") roomId: string): Promise<number> {
    return Promise.resolve(0);
  }

  @Query({ entity: RoomMemberEntity, isArray: false, sql: "DELETE FROM room_members" })
  async deleteAll(): Promise<number> {
    return Promise.resolve(0);
  }
}
