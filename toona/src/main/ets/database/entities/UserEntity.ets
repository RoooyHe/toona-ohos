import { Entity, PrimaryKey, Columns, ColumnType } from '@mlethe/room';

@Entity({ name: "users" })
export class UserEntity {
  @PrimaryKey()
  @Columns({ type: ColumnType.str })
  user_id: string = '';

  @Columns({ type: ColumnType.str })
  display_name?: string;

  @Columns({ type: ColumnType.str })
  avatar_url?: string;

  @Columns({ type: ColumnType.str })
  presence?: string;

  @Columns({ type: ColumnType.bigint })
  last_active_ago?: number;

  @Columns({ type: ColumnType.bool })
  currently_active: boolean = false;

  @Columns({ type: ColumnType.str })
  status_msg?: string;
}
