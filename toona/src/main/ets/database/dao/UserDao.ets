import { Dao, Insert, OnConflictStrategy, Query, Params } from '@mlethe/room';
import { UserEntity } from '../entities/UserEntity';
import { ToonaDatabase } from '../ToonaDatabase';

@Dao({ database: ToonaDatabase, entity: UserEntity })
export class UserDao {
  @Insert({ onConflict: OnConflictStrategy.REPLACE })
  async insert(entity: UserEntity): Promise<number> {
    return Promise.resolve(0);
  }

  @Query({ entity: UserEntity, isArray: false, sql: "SELECT * FROM users WHERE user_id = :userId" })
  async getById(@Params("userId") userId: string): Promise<UserEntity | null> {
    return null;
  }

  @Query({ entity: UserEntity, isArray: false, sql: "DELETE FROM users" })
  async deleteAll(): Promise<number> {
    return Promise.resolve(0);
  }
}
