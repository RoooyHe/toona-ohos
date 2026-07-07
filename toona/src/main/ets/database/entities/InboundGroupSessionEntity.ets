import { Entity, PrimaryKey, Columns, ColumnType } from '@mlethe/room';

@Entity({ name: "inbound_group_sessions", indexes: [
  { values: ["room_id", "megolm_session_id"] }
] })
export class InboundGroupSessionEntity {
  @PrimaryKey()
  @Columns({ type: ColumnType.str })
  sessionId: string = '';

  @Columns({ type: ColumnType.str })
  room_id: string = '';

  @Columns({ type: ColumnType.str })
  sender_key: string = '';

  @Columns({ type: ColumnType.str })
  megolm_session_id: string = '';

  @Columns({ type: ColumnType.str })
  session_data: string = '';

  @Columns({ type: ColumnType.str })
  forwarding_chain: string = '[]';

  @Columns({ type: ColumnType.bigint })
  created_at: number = 0;
}
