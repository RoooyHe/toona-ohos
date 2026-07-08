import { ToastUtils } from '../utils/ToastUtils';
import { RoomManager } from '../services/RoomManager';
import { MessageManager } from '../services/MessageManager';
import { AuthManager } from '../services/AuthManager';
import { getThemeColors } from '../utils/ThemeManager';
import { Message } from '../models/DataModels';
import { AppLogger } from '../utils/AppLogger';

const logger = AppLogger.getLogger('MessageSearchPage');

interface SearchResult {
  roomId: string;
  roomName: string;
  messages: SearchResultMessage[];
}

interface SearchResultMessage {
  eventId: string;
  sender: string;
  body: string;
  timestamp: number;
}

@Builder
export function MessageSearchPageBuilder(name: string, param: Object) {
  MessageSearchPage({
    pathStack: ((param as Record<string, Object>)['pathStack'] as NavPathStack) || new NavPathStack()
  })
}

@Component
struct MessageSearchPage {
  @State searchQuery: string = '';
  @State searchResults: SearchResult[] = [];
  @State isSearching: boolean = false;
  @State hasSearched: boolean = false;
  private roomManager: RoomManager = RoomManager.getInstance();
  private messageManager: MessageManager = MessageManager.getInstance();
  private authManager: AuthManager = AuthManager.getInstance();
  @Prop pathStack: NavPathStack;
  private logger = AppLogger.getLogger('MessageSearchPage');

  async onSearch() {
    if (!this.searchQuery.trim()) {
      return;
    }

    this.isSearching = true;
    this.hasSearched = true;

    try {
      // In a real implementation, this would call the Matrix search API
      // POST /_matrix/client/v3/search
      // For now, we'll search through local messages
      const rooms = await this.roomManager.getRooms();
      const results: SearchResult[] = [];

      for (const room of rooms) {
        if (room.isSpace) {
          continue;
        }

        try {
          const messages = await this.messageManager.getMessages(room.id, 50);
          const matchingMessages = messages.filter(msg => {
            const body = msg.getMessageBody().toLowerCase();
            return body.includes(this.searchQuery.toLowerCase());
          });

          if (matchingMessages.length > 0) {
            results.push({
              roomId: room.id,
              roomName: room.getDisplayName(),
              messages: matchingMessages.map(msg => ({
                eventId: msg.eventId,
                sender: msg.sender,
                body: msg.getMessageBody(),
                timestamp: msg.timestamp
              }))
            });
          }
        } catch (error) {
          this.logger.error(`Failed to search in room ${room.id}:`, error);
        }
      }

      this.searchResults = results;
    } catch (error) {
      this.logger.error('Search failed:', error);
      ToastUtils.show('Search failed');
    } finally {
      this.isSearching = false;
    }
  }

  navigateToMessage(roomId: string, eventId: string) {
    // Navigate to the room and highlight the message
    const param: Record<string, Object> = {
      "roomId": roomId,
      "roomName": '',
      "pathStack": this.pathStack,
      "highlightEventId": eventId
    };
    this.pathStack.pushPathByName('RoomDetailPage', param);
  }

  formatTimestamp(timestamp: number): string {
    const date = new Date(timestamp);
    return date.toLocaleString('zh-CN', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  build() {
    NavDestination() {
      Column() {
        // Header
        Row() {
          Button('←')
            .fontSize(18)
            .backgroundColor('transparent')
            .fontColor(getThemeColors().primary)
            .width(36)
            .height(36)
            .onClick(() => {
              this.pathStack.pop();
            });

          Text('Search Messages')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(getThemeColors().text)
            .layoutWeight(1);
        }
        .width('100%')
        .padding({ left: 10, right: 10, top: 10, bottom: 10 })
        .backgroundColor(getThemeColors().bg);

        // Search Input
        Row() {
          TextInput({ placeholder: 'Search messages...', text: this.searchQuery })
            .fontSize(16)
            .backgroundColor(getThemeColors().inputBg)
            .borderRadius(6)
            .layoutWeight(1)
            .height(40)
            .onChange((value: string) => {
              this.searchQuery = value;
            })
            .onSubmit(() => {
              this.onSearch();
            });

          Button('Search')
            .fontSize(14)
            .backgroundColor(getThemeColors().primary)
            .fontColor(getThemeColors().onPrimary)
            .borderRadius(6)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .margin({ left: 8 })
            .enabled(!this.isSearching)
            .onClick(() => {
              this.onSearch();
            });
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor(getThemeColors().bg);

        Divider().color(getThemeColors().divider);

        // Search Results
        if (this.isSearching) {
          Column() {
            LoadingProgress()
              .width(40)
              .height(40);
            Text('Searching...')
              .fontSize(14)
              .fontColor(getThemeColors().textSecondary)
              .margin({ top: 10 });
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center);
        } else if (!this.hasSearched) {
          Column() {
            Text('Search for messages across all rooms')
              .fontSize(16)
              .fontColor(getThemeColors().textSecondary);
            Text('Enter a search query to find messages')
              .fontSize(14)
              .fontColor(getThemeColors().textMute2)
              .margin({ top: 8 });
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .padding(40);
        } else if (this.searchResults.length === 0) {
          Column() {
            Text('No results found')
              .fontSize(16)
              .fontColor(getThemeColors().textSecondary);
            Text('Try a different search query')
              .fontSize(14)
              .fontColor(getThemeColors().textMute2)
              .margin({ top: 8 });
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .padding(40);
        } else {
          List() {
            ForEach(this.searchResults, (result: SearchResult) => {
              ListItem() {
                Column() {
                  // Room Header
                  Row() {
                    Text(result.roomName)
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(getThemeColors().text)
                      .layoutWeight(1);
                    Text(`${result.messages.length} messages`)
                      .fontSize(12)
                      .fontColor(getThemeColors().textSecondary);
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 12, bottom: 8 });

                  // Messages
                  ForEach(result.messages, (msg: SearchResultMessage) => {
                    Column() {
                      Row() {
                        Text(msg.sender.split(':')[0].replace('@', ''))
                          .fontSize(12)
                          .fontWeight(FontWeight.Medium)
                          .fontColor(getThemeColors().primary);
                        Blank();
                        Text(this.formatTimestamp(msg.timestamp))
                          .fontSize(11)
                          .fontColor(getThemeColors().textMute2);
                      }
                      .width('100%');

                      Text(msg.body)
                        .fontSize(14)
                        .fontColor(getThemeColors().text)
                        .margin({ top: 4 })
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis });
                    }
                    .width('100%')
                    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                    .backgroundColor(getThemeColors().bgSoft)
                    .margin({ left: 16, right: 16, bottom: 4 })
                    .borderRadius(6)
                    .onClick(() => {
                      this.navigateToMessage(result.roomId, msg.eventId);
                    });
                  });
                }
                .width('100%')
                .padding({ bottom: 8 });
              }
            });
          }
          .width('100%')
          .layoutWeight(1);
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(getThemeColors().bg);
    }
    .hideTitleBar(true);
  }
}
