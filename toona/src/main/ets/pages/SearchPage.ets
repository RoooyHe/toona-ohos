import { RoomManager } from '../services/RoomManager';
import { Room } from '../models/DataModels';
import { getThemeColors } from '../utils/ThemeManager';

@Builder
export function SearchPageBuilder(name: string, param: Object) {
  SearchPage()
}

@Entry
@Component
struct SearchPage {
  @State searchQuery: string = '';
  @State searchResults: Room[] = [];
  @State isSearching: boolean = false;
  private roomManager: RoomManager = RoomManager.getInstance();
  private pathStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
  }

  async onSearch() {
    if (!this.searchQuery.trim()) {
      return;
    }

    this.isSearching = true;
    try {
      const roomId = await this.roomManager.resolveRoomAlias(this.searchQuery.trim());
      const room = await this.roomManager.getRoom(roomId);
      if (room) {
        this.searchResults = [room];
      } else {
        this.searchResults = [];
      }
    } catch (error) {
      console.error('Search failed:', error);
      this.searchResults = [];
    } finally {
      this.isSearching = false;
    }
  }

  navigateToRoom(room: Room) {
    const param: Record<string, string> = {
      "roomId": room.id,
      "roomName": room.getDisplayName()
    };
    this.pathStack.pushPathByName('RoomDetailPage', param);
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          TextInput({ placeholder: '搜索房间...', text: this.searchQuery })
            .width('100%')
            .height(40)
            .fontSize(16)
            .backgroundColor(getThemeColors().inputBg)
            .borderRadius(10)
            .fontColor(getThemeColors().text)
            .placeholderColor(getThemeColors().textSecondary)
            .onChange((value: string) => {
              this.searchQuery = value;
            })
            .onSubmit(() => {
              this.onSearch();
            });

          Button('搜索')
            .fontSize(14)
            .backgroundColor(getThemeColors().primary)
            .fontColor('#ffffff')
            .width(60)
            .height(40)
            .borderRadius(10)
            .margin({ left: 10 })
            .onClick(() => {
              this.onSearch();
            });
        }
        .width('100%')
        .padding({
          left: 10,
          right: 10,
          top: 10,
          bottom: 10
        })
        .backgroundColor(getThemeColors().bg);

        Divider().color(getThemeColors().divider);

        if (this.isSearching) {
          Column() {
            LoadingProgress()
              .width(40)
              .height(40);
            Text('搜索中...')
              .fontSize(14)
              .fontColor(getThemeColors().textSecondary)
              .margin({ top: 10 });
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center);
        } else if (this.searchResults.length === 0 && this.searchQuery.length > 0) {
          Column() {
            Text('未找到房间')
              .fontSize(16)
              .fontColor(getThemeColors().textSecondary);
            Text('尝试输入完整的房间地址')
              .fontSize(14)
              .fontColor(getThemeColors().textSecondary)
              .opacity(0.7)
              .margin({ top: 5 });
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center);
        } else if (this.searchResults.length === 0) {
          Column() {
            Text('输入房间地址进行搜索')
              .fontSize(16)
              .fontColor(getThemeColors().textSecondary);
            Text('例如: #room:matrix.org')
              .fontSize(14)
              .fontColor(getThemeColors().textSecondary)
              .opacity(0.7)
              .margin({ top: 5 });
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center);
        } else {
          List() {
            ForEach(this.searchResults, (room: Room) => {
              ListItem() {
                Row() {
                  if (room.avatarUrl) {
                    Image(room.avatarUrl)
                      .width(50)
                      .height(50)
                      .borderRadius(25);
                  } else {
                    Text(room.getDisplayName().charAt(0).toUpperCase())
                      .fontSize(20)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#ffffff')
                      .width(50)
                      .height(50)
                      .borderRadius(25)
                      .backgroundColor(getThemeColors().primary)
                      .textAlign(TextAlign.Center);
                  }

                  Column() {
                    Text(room.getDisplayName())
                      .fontSize(16)
                      .fontColor(getThemeColors().text);
                    Text(room.id)
                      .fontSize(12)
                      .fontColor(getThemeColors().textSecondary);
                  }
                  .margin({ left: 12 })
                  .alignItems(HorizontalAlign.Start);
                }
                .width('100%')
                .padding({
                  top: 12,
                  bottom: 12,
                  left: 20,
                  right: 20
                })
                .backgroundColor(getThemeColors().bg)
                .onClick(() => {
                  this.navigateToRoom(room);
                });
              };
            });
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor(getThemeColors().bg);
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(getThemeColors().bg);
    }
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
    })
    .hideTitleBar(true)
  }
}
