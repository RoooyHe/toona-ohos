import { Entity, PrimaryKey, Columns, ColumnType, Convert } from '@mlethe/room';
import { TagsConverter } from './TagsConverter';

@Entity({ name: "rooms", indexes: [
  { values: ["room_id"], unique: true }
] })
export class RoomEntity {
  @PrimaryKey()
  @Columns({ type: ColumnType.str })
  room_id: string = '';

  @Columns({ type: ColumnType.str })
  name?: string;

  @Columns({ type: ColumnType.str })
  display_name?: string;

  @Columns({ type: ColumnType.str })
  topic?: string;

  @Columns({ type: ColumnType.str })
  avatar_url?: string;

  @Columns({ type: ColumnType.int })
  member_count?: number;

  @Columns({ type: ColumnType.str })
  my_membership?: string;

  @Columns({ type: ColumnType.bool })
  is_direct: boolean = false;

  @Columns({ type: ColumnType.int })
  unread_count: number = 0;

  @Columns({ type: ColumnType.int })
  highlight_count: number = 0;

  @Columns({ type: ColumnType.str })
  last_event_id?: string;

  @Columns({ type: ColumnType.bigint })
  last_event_time?: number;

  @Columns({ type: ColumnType.str })
  canonical_alias?: string;

  @Columns({ type: ColumnType.str })
  join_rule?: string;

  @Columns({ type: ColumnType.str })
  history_visibility?: string;

  @Columns({ type: ColumnType.bigint })
  create_time?: number;

  @Columns({ type: ColumnType.str })
  creator?: string;

  @Columns({ type: ColumnType.bool })
  is_space: boolean = false;

  @Convert({ converter: TagsConverter })
  @Columns({ type: ColumnType.object })
  tags?: Record<string, object>;
}
