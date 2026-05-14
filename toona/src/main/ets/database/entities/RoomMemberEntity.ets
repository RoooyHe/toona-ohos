import { Entity, PrimaryKey, Columns, ColumnType } from '@mlethe/room';

@Entity({
  name: "room_members", indexes: [
    { values: ["room_id", "user_id"], unique: true },
    { values: ["room_id"] }
  ]
})
export class RoomMemberEntity {
  @PrimaryKey()
  @Columns({ type: ColumnType.str })
  room_id: string = '';
  @PrimaryKey()
  @Columns({ type: ColumnType.str })
  user_id: string = '';
  @Columns({ type: ColumnType.str })
  display_name?: string;
  @Columns({ type: ColumnType.str })
  avatar_url?: string;
  @Columns({ type: ColumnType.str })
  membership?: string;
}
