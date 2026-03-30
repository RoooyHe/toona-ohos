export interface EncryptionKey {
  alg: string;
  key: string;
  key_id: string;
  v?: string;
}

export interface EncryptedFile {
  url?: string;
  key?: EncryptionKey;
  iv?: string;
  hashes?: Record<string, string>;
  file?: string;
}

export interface EncryptionKeys {
  k: string;
  key: string;
}

export interface MessageInfo {
  mimetype?: string;
  size?: number;
  duration?: number;
  width?: number;
  height?: number;
  thumbnail_url?: string;
  thumbnail_file?: EncryptedFile;
  thumbnail_info?: MessageInfo;
  orientation?: number;
  'xyz.amorgan.blurhash'?: string;
}

export interface Mentions {
  user_ids?: string[];
  room_id?: string;
}

export interface MessageEventContent {
  msgtype?: string;
  body: string;
  format?: string;
  formatted_body?: string;
  geo_uri?: string;
  info?: MessageInfo;
  url?: string;
  file?: EncryptedFile;
  keys?: EncryptionKeys;
  caption?: string;
  mentions?: Mentions;
}

export interface TextMessageContent extends MessageEventContent {
  msgtype: 'm.text';
  body: string;
  format?: string;
  formatted_body?: string;
  mentions?: Mentions;
}

export interface EmoteMessageContent extends MessageEventContent {
  msgtype: 'm.emote';
  body: string;
}

export interface NoticeMessageContent extends MessageEventContent {
  msgtype: 'm.notice';
  body: string;
}

export interface ImageMessageContent extends MessageEventContent {
  msgtype: 'm.image';
  url?: string;
  file?: EncryptedFile;
  info?: MessageInfo;
  body: string;
}

export interface AudioMessageContent extends MessageEventContent {
  msgtype: 'm.audio';
  url?: string;
  file?: EncryptedFile;
  info?: MessageInfo;
  body: string;
}

export interface VideoMessageContent extends MessageEventContent {
  msgtype: 'm.video';
  url?: string;
  file?: EncryptedFile;
  info?: MessageInfo;
  body: string;
}

export interface LocationMessageContent extends MessageEventContent {
  msgtype: 'm.location';
  geo_uri: string;
  info?: MessageInfo;
  body: string;
}

export interface FileMessageContent extends MessageEventContent {
  msgtype: 'm.file';
  url?: string;
  file?: EncryptedFile;
  info?: MessageInfo;
  body: string;
}

export interface RoomMessage {
  eventId: string;
  roomId: string;
  sender: string;
  type: string;
  content: MessageEventContent;
  timestamp: number;
  isOutgoing: boolean;
  status: MessageStatus;
  replyEventId?: string;
  editedEventId?: string;
}

export enum MessageStatus {
  SENDING = 'sending',
  SENT = 'sent',
  FAILED = 'failed',
  DECRYPTING = 'decrypting',
  PLACEHOLDER = 'placeholder'
}