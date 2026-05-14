import { Entity, PrimaryKey, Columns, ColumnType, Convert } from '@mlethe/room';
import { ContentConverter } from './ContentConverter';

@Entity({ name: "messages", indexes: [
  { values: ["event_id", "room_id"], unique: true },
  { values: ["room_id"] },
  { values: ["timestamp"] }
] })
export class MessageEntity {
  @PrimaryKey()
  @Columns({ type: ColumnType.str })
  event_id: string = '';

  @Columns({ type: ColumnType.str })
  room_id: string = '';

  @Columns({ type: ColumnType.str })
  sender: string = '';

  @Columns({ type: ColumnType.str })
  type: string = '';

  @Convert({ converter: ContentConverter })
  @Columns({ type: ColumnType.object })
  content?: Record<string, string | object>;

  @Columns({ type: ColumnType.bigint })
  timestamp: number = 0;

  @Columns({ type: ColumnType.bool })
  is_outgoing: boolean = false;

  @Columns({ type: ColumnType.str })
  status: string = 'sent';

  @Columns({ type: ColumnType.str })
  reply_event_id?: string;

  @Columns({ type: ColumnType.str })
  edited_event_id?: string;
}
