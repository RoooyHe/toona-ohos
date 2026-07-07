import { Entity, PrimaryKey, Columns, ColumnType } from '@mlethe/room';

@Entity({ name: "device_keys" })
export class DeviceKeysEntity {
  @PrimaryKey()
  @Columns({ type: ColumnType.str })
  user_id: string = '';

  @Columns({ type: ColumnType.str })
  device_id: string = '';

  @Columns({ type: ColumnType.str })
  ed25519_key: string = '';

  @Columns({ type: ColumnType.str })
  curve25519_key: string = '';

  @Columns({ type: ColumnType.str })
  algorithms: string = '[]';

  @Columns({ type: ColumnType.str })
  signatures: string = '{}';

  @Columns({ type: ColumnType.str })
  trust_level: string = 'unverified';

  @Columns({ type: ColumnType.bigint })
  verified_at: number = 0;

  @Columns({ type: ColumnType.str })
  verified_by: string = '';

  @Columns({ type: ColumnType.bigint })
  created_at: number = 0;
}
