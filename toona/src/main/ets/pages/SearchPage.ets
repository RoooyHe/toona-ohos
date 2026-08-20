import { Room } from '../models/DataModels';
import { getThemeColors } from '../utils/ThemeManager';
import { SearchViewModel, SearchState } from '../viewmodels/SearchViewModel';
import { ServiceLocator } from '../services/ServiceLocator';

@Builder
export function SearchPageBuilder(name: string, param: Object) {
  SearchPage()
}

@Component
struct SearchPage {
  @State searchQuery: string = '';
  @State searchResults: Room[] = [];
  @State isSearching: boolean = false;
  private viewModel: SearchViewModel | null = null;
  pathStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    this.viewModel = new SearchViewModel(ServiceLocator.getRoomManager());

    const self = this;
    this.viewModel.setOnStateChanged((state: SearchState) => {
      self.searchQuery = state.searchQuery;
      self.searchResults = state.searchResults;
      self.isSearching = state.isSearching;
    });

    this.viewModel.setOnNavigateToRoom((roomId: string, roomName: string) => {
      const param: Record<string, Object> = {
        "roomId": roomId,
        "roomName": roomName
      };
      self.pathStack.pushPathByName('RoomDetailPage', param);
    });
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
            .borderRadius(6)
            .fontColor(getThemeColors().text)
            .placeholderColor(getThemeColors().textSecondary)
            .onChange((value: string) => {
              this.viewModel?.setSearchQuery(value);
            })
            .onSubmit(() => {
              this.viewModel?.search();
            });

          Button('搜索')
            .fontSize(14)
            .backgroundColor(getThemeColors().primary)
            .fontColor(getThemeColors().onPrimary)
            .width(60)
            .height(40)
            .borderRadius(6)
            .margin({ left: 10 })
            .onClick(() => {
              this.viewModel?.search();
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
                      .fontColor(getThemeColors().onPrimary)
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
                  this.viewModel?.navigateToRoom(room);
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
    .hideTitleBar(true);
  }
}
