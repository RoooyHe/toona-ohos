import promptAction from '@ohos.promptAction';
import { RoomManager } from '../services/RoomManager';
import { AuthManager } from '../services/AuthManager';
import { MatrixHttpClient } from '../network/MatrixHttpClient';
import { getThemeColors } from '../utils/ThemeManager';
import { common } from '@kit.AbilityKit';

interface PublicSpace {
  room_id: string;
  name?: string;
  topic?: string;
  avatar_url?: string;
  num_joined_members?: number;
}

interface PublicRoomsResponse {
  chunk: PublicSpace[];
  next_batch?: string;
  prev_batch?: string;
  total_room_count_estimate?: number;
}

@Builder
export function JoinSpacePageBuilder(name: string, param: Object) {
  JoinSpacePage()
}

@Component
struct JoinSpacePage {
  @State searchQuery: string = '';
  @State searchResults: PublicSpace[] = [];
  @State isSearching: boolean = false;
  @State spaceAddress: string = '';
  @State isJoining: boolean = false;
  @State showCreateDialog: boolean = false;
  @State newSpaceName: string = '';
  private roomManager: RoomManager = RoomManager.getInstance();
  private authManager: AuthManager = AuthManager.getInstance();
  private httpClient: MatrixHttpClient | null = null;
  @Prop pathStack: NavPathStack;

  aboutToAppear() {
    this.httpClient = this.authManager.getHttpClient();
  }

  async searchPublicSpaces() {
    if (!this.searchQuery.trim()) {
      this.searchResults = [];
      return;
    }

    this.isSearching = true;
    try {
      const response = await this.httpClient?.get<PublicRoomsResponse>(
        '/publicRooms',
        { "limit": 20 }
      );
      if (response && response.chunk) {
        const query = this.searchQuery.toLowerCase();
        this.searchResults = response.chunk.filter(space => {
          const name = space.name?.toLowerCase() || '';
          const topic = space.topic?.toLowerCase() || '';
          return name.includes(query) || topic.includes(query);
        });
      }
    } catch (error) {
      console.error('Search spaces failed:', error);
      this.searchResults = [];
    } finally {
      this.isSearching = false;
    }
  }

  joinSpace(spaceIdOrAlias: string) {
    this.doJoinSpace(spaceIdOrAlias).catch((error: Error) => {
      console.error('Failed to join space:', error);
      promptAction.showToast({ message: '加入失败' });
    });
  }

  async doJoinSpace(spaceIdOrAlias: string): Promise<void> {
    this.isJoining = true;
    try {
      let spaceId = spaceIdOrAlias.trim();
      if (!spaceId.startsWith('#') && !spaceId.includes(':')) {
        spaceId = `#${spaceId}:${this.authManager.getHomeserver()}`;
      }
      await this.roomManager.joinRoom(spaceId);
      promptAction.showToast({ message: '加入成功' });
this.pathStack.pop();
    } catch (error) {
      console.error('Failed to join space:', error);
    } finally {
      this.isJoining = false;
    }
  }

  createSpace() {
    if (!this.newSpaceName.trim()) {
      return;
    }

    this.doCreateSpace().catch((error: Error) => {
      console.error('Failed to create space:', error);
      promptAction.showToast({ message: '创建失败' });
    });
  }

  async doCreateSpace(): Promise<void> {
    await this.roomManager.createSpace(this.newSpaceName.trim());
    this.showCreateDialog = false;
    this.newSpaceName = '';
    promptAction.showToast({ message: '创建成功' });
    this.pathStack?.pop();
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Text('加入空间')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(getThemeColors().text)
            .layoutWeight(1);
        }
        .width('100%')
        .padding({ left: 10, right: 10 })
        .backgroundColor(getThemeColors().bg);

        Column() {
          TextInput({ placeholder: '搜索公开空间', text: this.searchQuery })
            .width('100%')
            .height(44)
            .fontSize(16)
            .backgroundColor(getThemeColors().inputBg)
            .borderRadius(10)
            .margin({ bottom: 10 })
            .onChange((value: string) => {
              this.searchQuery = value;
            })
            .onSubmit(() => {
              this.searchPublicSpaces();
            });

          Button('搜索')
            .fontSize(14)
            .backgroundColor(getThemeColors().primary)
            .fontColor('#ffffff')
            .width('100%')
            .height(40)
            .borderRadius(10)
            .onClick(() => {
              this.searchPublicSpaces();
            });

          if (this.isSearching) {
            LoadingProgress()
              .width(30)
              .height(30)
              .margin({ top: 10 });
          } else if (this.searchResults.length > 0) {
            List() {
              ForEach(this.searchResults, (space: PublicSpace) => {
                ListItem() {
                  Row() {
                    Text(space.name?.charAt(0).toUpperCase() || '#')
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#ffffff')
                      .width(40)
                      .height(40)
                      .borderRadius(20)
                      .backgroundColor(getThemeColors().primary)
                      .textAlign(TextAlign.Center);

                    Column() {
                      Text(space.name || space.room_id)
                        .fontSize(16)
                        .fontColor(getThemeColors().text);
                      if (space.topic) {
                        Text(space.topic)
                          .fontSize(12)
                          .fontColor(getThemeColors().textSecondary)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis });
                      }
                      if (space.num_joined_members !== undefined) {
                        Text(`${space.num_joined_members} 成员`)
                          .fontSize(11)
                          .fontColor(getThemeColors().textSecondary);
                      }
                    }
                    .margin({ left: 12 })
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1);
                  }
                  .width('100%')
                  .padding({ top: 10, bottom: 10 })
                  .onClick(() => {
                    this.joinSpace(space.room_id);
                  });
                };
              });
            }
            .width('100%')
            .layoutWeight(1);
          } else if (this.searchQuery.trim() && !this.isSearching) {
            Text('未找到匹配的空间')
              .fontSize(14)
              .fontColor(getThemeColors().textSecondary)
              .margin({ top: 20 });
          }
        }
        .width('90%')
        .padding({ top: 15, bottom: 15 });

        Divider().color(getThemeColors().divider);

        Column() {
          Row() {
            Text('创建新空间')
              .fontSize(16)
              .fontColor(getThemeColors().text);
            Blank();
            Button('+')
              .fontSize(24)
              .backgroundColor(getThemeColors().primary)
              .fontColor('#ffffff')
              .width(36)
              .height(36)
              .borderRadius(18)
              .onClick(() => {
                this.showCreateDialog = true;
              });
          }
          .width('100%')
          .padding({ top: 15, bottom: 15 });
        }
        .width('90%');

        Divider().color(getThemeColors().divider);

        Column() {
          Text('通过地址加入')
            .fontSize(16)
            .fontColor(getThemeColors().text)
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 10 });

          TextInput({ placeholder: '输入 space ID 或地址', text: this.spaceAddress })
            .width('100%')
            .height(44)
            .fontSize(16)
            .backgroundColor(getThemeColors().inputBg)
            .borderRadius(10)
            .onChange((value: string) => {
              this.spaceAddress = value;
            });

          Button(this.isJoining ? '加入中...' : '加入')
            .fontSize(16)
            .backgroundColor(getThemeColors().primary)
            .fontColor('#ffffff')
            .width('100%')
            .height(44)
            .borderRadius(10)
            .margin({ top: 10 })
            .enabled(!this.isJoining)
            .onClick(() => {
              this.joinSpace(this.spaceAddress);
            });
        }
        .width('90%')
        .padding({ top: 15, bottom: 30 });
      }
      .width('100%')
      .height('100%')
      .backgroundColor(getThemeColors().bg);

      if (this.showCreateDialog) {
        Column() {
          Column() {
            Text('创建空间')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(getThemeColors().text)
              .margin({ bottom: 20 });

            TextInput({ placeholder: '空间名称' })
              .width('100%')
              .height(44)
              .fontSize(16)
              .backgroundColor(getThemeColors().inputBg)
              .borderRadius(8)
              .onChange((value: string) => {
                this.newSpaceName = value;
              });

            Row() {
              Button('取消')
                .fontSize(16)
                .backgroundColor(getThemeColors().inputBg)
                .fontColor(getThemeColors().text)
                .width('45%')
                .height(44)
                .borderRadius(8)
                .onClick(() => {
                  this.showCreateDialog = false;
                  this.newSpaceName = '';
                });

              Button('创建')
                .fontSize(16)
                .backgroundColor(getThemeColors().primary)
                .fontColor('#ffffff')
                .width('45%')
                .height(44)
                .borderRadius(8)
                .onClick(() => {
                  this.createSpace();
                });
            }
            .width('100%')
            .margin({ top: 20 });
          }
          .width('85%')
          .padding(20)
          .backgroundColor(getThemeColors().surface)
          .borderRadius(16);
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .justifyContent(FlexAlign.Center);
      }
    }
    .width('100%')
    .height('100%');
  }
}