import { Event } from '../models/MatrixTypes';
import { ParsedRoomState } from '../models/MatrixTypes';
import { Room } from '../models/DataModels';

export class RoomStateParser {
  static applyStateEvents(room: Room, events: Event[], currentUserId?: string): void {
    for (let i = 0; i < events.length; i++) {
      const event = events[i];
      const content = event.content as Record<string, string | object>;
      switch (event.type) {
        case 'm.room.name':
          const nameVal = content['name'];
          if (nameVal !== undefined) {
            room.name = String(nameVal);
            room.displayName = String(nameVal);
          }
          break;
        case 'm.room.topic':
          const topicVal = content['topic'];
          if (topicVal !== undefined) {
            room.topic = String(topicVal);
          }
          break;
        case 'm.room.avatar':
          const avatarVal = content['url'];
          if (avatarVal !== undefined) {
            room.avatarUrl = String(avatarVal);
          }
          break;
        case 'm.room.canonical_alias':
          const aliasVal = content['alias'];
          if (aliasVal !== undefined) {
            room.name = String(aliasVal);
          }
          break;
        case 'm.room.create':
          const isDirectVal = content['is_direct'];
          if (isDirectVal !== undefined) {
            room.isDirect = isDirectVal === 'true';
          }
          const typeVal = content['type'];
          if (typeVal === 'm.space') {
            room.isSpace = true;
          }
          break;
        case 'm.room.member':
          if (currentUserId) {
            const stateKey = event.state_key;
            if (stateKey && stateKey !== currentUserId) {
              const displaynameVal = content['displayname'];
              if (displaynameVal !== undefined) {
                room.displayName = String(displaynameVal);
              }
              const avatarVal = content['avatar_url'];
              if (avatarVal !== undefined) {
                room.avatarUrl = String(avatarVal);
              }
            }
          }
          break;
      }
    }
  }

  static toParsedRoomState(roomId: string, stateEvents: Event[]): ParsedRoomState {
    let roomName: string = '';
    let roomTopic: string = '';
    let joinRule: string = '';
    let historyVisibility: string = '';
    let canonicalAlias: string = '';
    let creator: string = '';

    for (let i: number = 0; i < stateEvents.length; i++) {
      const event: Event = stateEvents[i];
      switch (event.type) {
        case 'm.room.name':
          roomName = RoomStateParser.stringContent(event);
          break;
        case 'm.room.topic':
          roomTopic = RoomStateParser.stringContent(event);
          break;
        case 'm.room.join_rules':
          const joinRulesContent = event.content as Record<string, string | object>;
          if (joinRulesContent && typeof joinRulesContent.join_rule === 'string') {
            joinRule = joinRulesContent.join_rule;
          }
          break;
        case 'm.room.history_visibility':
          const historyContent = event.content as Record<string, string | object>;
          if (historyContent && typeof historyContent.history_visibility === 'string') {
            historyVisibility = historyContent.history_visibility;
          }
          break;
        case 'm.room.canonical_alias':
          const canonicalContent = event.content as Record<string, string | object>;
          if (canonicalContent && typeof canonicalContent.alias === 'string') {
            canonicalAlias = canonicalContent.alias;
          }
          break;
        case 'm.room.create':
          const createContent = event.content as Record<string, string | object>;
          if (createContent && typeof createContent.creator === 'string') {
            creator = createContent.creator;
          }
          break;
      }
    }

    return {
      roomId: roomId,
      name: roomName,
      topic: roomTopic,
      joinRule: joinRule,
      historyVisibility: historyVisibility,
      canonicalAlias: canonicalAlias,
      creator: creator
    };
  }

  private static stringContent(event: Event): string {
    const content = event.content as Record<string, string | object>;
    if (content && typeof content.body === 'string') {
      return content.body;
    }
    return '';
  }
}
