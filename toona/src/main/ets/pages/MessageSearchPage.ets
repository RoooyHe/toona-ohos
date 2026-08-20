import { getThemeColors } from '../utils/ThemeManager';
import { MessageSearchViewModel, MessageSearchState, SearchResult, SearchResultMessage } from '../viewmodels/MessageSearchViewModel';
import { ServiceLocator } from '../services/ServiceLocator';

@Builder
export function MessageSearchPageBuilder(name: string, param: Object) {
  MessageSearchPage()
}

@Component
struct MessageSearchPage {
  @State searchQuery: string = '';
  @State searchResults: SearchResult[] = [];
  @State isSearching: boolean = false;
  @State hasSearched: boolean = false;
  private viewModel: MessageSearchViewModel | null = null;
  pathStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    this.viewModel = new MessageSearchViewModel(
      ServiceLocator.getRoomManager(),
      ServiceLocator.getMessageManager()
    );

    const self = this;
    this.viewModel.setOnStateChanged((state: MessageSearchState) => {
      self.searchQuery = state.searchQuery;
      self.searchResults = state.searchResults;
      self.isSearching = state.isSearching;
      self.hasSearched = state.hasSearched;
    });

    this.viewModel.setOnNavigateToMessage((roomId: string, eventId: string) => {
      const param: Record<string, Object> = {
        "roomId": roomId,
        "roomName": '',
        "highlightEventId": eventId
      };
      self.pathStack.pushPathByName('RoomDetailPage', param);
    });
  }

  formatTimestamp(timestamp: number): string {
    const date: Date = new Date(timestamp);
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

        Row() {
          TextInput({ placeholder: 'Search messages...', text: this.searchQuery })
            .fontSize(16)
            .backgroundColor(getThemeColors().inputBg)
            .borderRadius(6)
            .layoutWeight(1)
            .height(40)
            .onChange((value: string) => {
              this.viewModel?.setSearchQuery(value);
            })
            .onSubmit(() => {
              this.viewModel?.search();
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
              this.viewModel?.search();
            });
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor(getThemeColors().bg);

        Divider().color(getThemeColors().divider);

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
                      this.viewModel?.navigateToMessage(result.roomId, msg.eventId);
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
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
    })
    .hideTitleBar(true);
  }
}
