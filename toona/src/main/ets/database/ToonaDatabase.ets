import { Database } from '@mlethe/room';
import { MessageEntity } from './entities/MessageEntity';
import { RoomEntity } from './entities/RoomEntity';
import { UserEntity } from './entities/UserEntity';
import { RoomMemberEntity } from './entities/RoomMemberEntity';
import { InboundGroupSessionEntity } from './entities/InboundGroupSessionEntity';
import { OlmSessionEntity } from './entities/OlmSessionEntity';
import { DeviceKeysEntity } from './entities/DeviceKeysEntity';

@Database({ entities: [MessageEntity, RoomEntity, UserEntity, RoomMemberEntity, InboundGroupSessionEntity, OlmSessionEntity, DeviceKeysEntity], name: "toona_matrix.db", version: 1 })
export class ToonaDatabase {
  async onCreate(): Promise<void> {}
  async onUpgrade(): Promise<void> {}
}
