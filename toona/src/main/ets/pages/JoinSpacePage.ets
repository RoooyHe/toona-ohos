import { ToastUtils } from '../utils/ToastUtils';
import { QuickDialogManager, QuickDialogParams, QuickDialogController, QuickDialogDecoratorParams } from 'quickdialog';
import { getThemeColors } from '../utils/ThemeManager';
import { common } from '@kit.AbilityKit';
import { AppLogger } from '../utils/AppLogger';
import { ServiceLocator } from '../services/ServiceLocator';

interface CreateSpaceDialogData {
  spaceName: string;
}

const logger = AppLogger.getLogger('JoinSpacePage');

// 创建空间弹窗 - 内容组件
@Component
struct CreateSpaceDialogContent {
  private dialogParams: QuickDialogParams | undefined = undefined
  private dialogController: QuickDialogController | undefined = undefined
  @State spaceName: string = ''

  aboutToAppear() {
    if (this.dialogParams) {
      this.dialogController = this.dialogParams.controller
    }
  }

  build() {
    Column() {
      Text('创建空间')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(getThemeColors().text)
        .margin({ bottom: 20 })

      TextInput({ placeholder: '空间名称' })
        .width('100%')
        .height(44)
        .fontSize(16)
        .backgroundColor(getThemeColors().inputBg)
        .borderRadius(6)
        .onChange((value: string) => {
          this.spaceName = value;
        })

      Row() {
        Button('取消')
          .fontSize(16)
          .backgroundColor(getThemeColors().inputBg)
          .fontColor(getThemeColors().text)
          .width('45%')
          .height(44)
          .borderRadius(6)
          .onClick(() => {
            this.dialogController?.dismiss()
          })

        Button('创建')
          .fontSize(16)
          .backgroundColor(getThemeColors().primary)
          .fontColor(getThemeColors().onPrimary)
          .width('45%')
          .height(44)
          .borderRadius(6)
      .onClick(() => {
            this.dialogController?.callEventFromDialog('confirm', {
              spaceName: this.spaceName
            } as CreateSpaceDialogData)
          })
      }
      .width('100%')
      .margin({ top: 20 })
    }
    .width('85%')
    .padding(20)
    .backgroundColor(getThemeColors().surface)
    .borderRadius(16)
  }
}

// 创建空间弹窗 - Builder
@Builder
function CreateSpaceDialogBuilder(dialogParams: QuickDialogParams) {
  CreateSpaceDialogContent({ dialogParams: dialogParams })
}

// 创建空间弹窗 - 装饰器（半透明背景）
@Builder
function CreateSpaceDialogDecorator(decoratorParams: QuickDialogDecoratorParams) {
  Stack() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor('rgba(0, 0, 0, 0.5)')

    NodeContainer(
      QuickDialogManager.decoratorCreateContentNodeController(decoratorParams)
    )
  }
}

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
  private roomManager = ServiceLocator.getRoomManager();
  private authManager = ServiceLocator.getAuthManager();
  private createSpaceDialogController: QuickDialogController | undefined = undefined;
  pathStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
  }

  async searchPublicSpaces() {
    if (!this.searchQuery.trim()) {
      this.searchResults = [];
      return;
    }

    this.isSearching = true;
    try {
      const response = await this.roomManager.searchPublicRooms(undefined, this.searchQuery.trim(), 20);
      this.searchResults = response.chunk || [];
    } catch (error) {
      logger.error('Search spaces failed:', error);
      this.searchResults = [];
    } finally {
      this.isSearching = false;
    }
  }

  joinSpace(spaceIdOrAlias: string) {
    this.doJoinSpace(spaceIdOrAlias).catch((error: Error) => {
      logger.error('Failed to join space:', error);
      ToastUtils.show('加入失败');
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
      ToastUtils.show('加入成功');
this.pathStack.pop();
    } catch (error) {
      logger.error('Failed to join space:', error);
    } finally {
      this.isJoining = false;
    }
  }

  createSpace() {
    const self = this;
    // 通过 QuickDialog 展示创建空间弹窗
    this.createSpaceDialogController = QuickDialogManager.newBuilder(
      this.getUIContext(),
      wrapBuilder(CreateSpaceDialogBuilder),
      wrapBuilder(CreateSpaceDialogDecorator)
    )
      .onEvent<Record<string, Object>>('confirm', (controller, param) => {
        const spaceName = param?.['spaceName'] as string || '';
        controller.dismiss();
        self.doCreateSpace(spaceName).catch((error: Error) => {
          logger.error('Failed to create space:', error);
          ToastUtils.show('创建失败');
        });
      })
      .build();
    this.createSpaceDialogController.show();
  }

  async doCreateSpace(spaceName: string): Promise<void> {
    await this.roomManager.createSpace(spaceName.trim());
    ToastUtils.show('创建成功');
    this.pathStack.pop();
  }

  build() {
    NavDestination() {
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
            .borderRadius(6)
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
            .fontColor(getThemeColors().onPrimary)
            .width('100%')
            .height(40)
            .borderRadius(6)
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
                      .fontColor(getThemeColors().onPrimary)
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
              .fontColor(getThemeColors().onPrimary)
              .width(36)
              .height(36)
              .borderRadius(18)
              .onClick(() => {
                this.createSpace();
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
            .borderRadius(6)
            .onChange((value: string) => {
              this.spaceAddress = value;
            });

          Button(this.isJoining ? '加入中...' : '加入')
            .fontSize(16)
            .backgroundColor(getThemeColors().primary)
            .fontColor(getThemeColors().onPrimary)
            .width('100%')
            .height(44)
            .borderRadius(6)
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

      // 创建空间弹窗由 QuickDialogManager 管理
    }
    .width('100%')
    .height('100%');
    }
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
    })
    .hideTitleBar(true);
  }
}