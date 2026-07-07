import { Entity, PrimaryKey, Columns, ColumnType } from '@mlethe/room';

@Entity({ name: "olm_sessions", indexes: [
  { values: ["device_key"] }
] })
export class OlmSessionEntity {
  @PrimaryKey()
  @Columns({ type: ColumnType.str })
  sessionId: string = '';

  @Columns({ type: ColumnType.str })
  device_key: string = '';

  @Columns({ type: ColumnType.str })
  session_data: string = '';

  @Columns({ type: ColumnType.bigint })
  last_used: number = 0;
}
