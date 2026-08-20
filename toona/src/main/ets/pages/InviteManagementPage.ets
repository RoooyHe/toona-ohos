import { getThemeColors } from '../utils/ThemeManager';
import { InviteManagementViewModel, InviteManagementState, RoomInvite } from '../viewmodels/InviteManagementViewModel';
import { ServiceLocator } from '../services/ServiceLocator';

@Builder
export function InviteManagementPageBuilder(name: string, param: Object) {
  InviteManagementPage()
}

@Component
struct InviteManagementPage {
  @State invites: RoomInvite[] = [];
  @State isLoading: boolean = true;
  @State processingInvite: string = '';
  private viewModel: InviteManagementViewModel | null = null;
  pathStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    this.viewModel = new InviteManagementViewModel(ServiceLocator.getRoomManager());

    const self = this;
    this.viewModel.setOnStateChanged((state: InviteManagementState) => {
      self.invites = state.invites;
      self.isLoading = state.isLoading;
      self.processingInvite = state.processingInvite;
    });

    this.viewModel.setOnInviteAccepted(() => {
      self.pathStack.pop();
    });

    this.viewModel.loadInvites();
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

          Text('Invites')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(getThemeColors().text)
            .layoutWeight(1);
        }
        .width('100%')
        .padding({ left: 10, right: 10, top: 10, bottom: 10 })
        .backgroundColor(getThemeColors().bg);

        Divider().color(getThemeColors().divider);

        if (this.isLoading) {
          Column() {
            LoadingProgress()
              .width(40)
              .height(40);
            Text('Loading invites...')
              .fontSize(14)
              .fontColor(getThemeColors().textSecondary)
              .margin({ top: 10 });
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center);
        } else if (this.invites.length === 0) {
          Column() {
            Text('No pending invites')
              .fontSize(16)
              .fontColor(getThemeColors().textSecondary);
            Text('When someone invites you to a room, it will appear here.')
              .fontSize(14)
              .fontColor(getThemeColors().textMute2)
              .margin({ top: 8 })
              .textAlign(TextAlign.Center);
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .padding(40);
        } else {
          List() {
            ForEach(this.invites, (invite: RoomInvite) => {
              ListItem() {
                Column() {
                  Row() {
                    Stack() {
                      if (invite.avatarUrl) {
                        Image(ServiceLocator.getMediaManager().getHttpUrl(invite.avatarUrl))
                          .width(48)
                          .height(48)
                          .borderRadius(24);
                      } else {
                        Text(invite.name.charAt(0).toUpperCase() || '?')
                          .fontSize(20)
                          .fontWeight(FontWeight.Bold)
                          .fontColor(getThemeColors().onPrimary)
                          .width(48)
                          .height(48)
                          .borderRadius(24)
                          .backgroundColor(getThemeColors().primary)
                          .textAlign(TextAlign.Center);
                      }
                    }
                    .width(48)
                    .height(48)
                    .margin({ right: 12 });

                    Column() {
                      Text(invite.name || 'Unknown Room')
                        .fontSize(16)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(getThemeColors().text)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis });

                      if (invite.topic) {
                        Text(invite.topic)
                          .fontSize(12)
                          .fontColor(getThemeColors().textSecondary)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .margin({ top: 4 });
                      }

                      Text(`Invited by ${invite.inviter}`)
                        .fontSize(12)
                        .fontColor(getThemeColors().textMute2)
                        .margin({ top: 4 });
                    }
                    .layoutWeight(1);
                  }
                  .width('100%');

                  Row() {
                    Button('Decline')
                      .fontSize(14)
                      .backgroundColor(getThemeColors().bg)
                      .fontColor(getThemeColors().error)
                      .borderWidth(1)
                      .borderColor(getThemeColors().error)
                      .borderRadius(6)
                      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                      .enabled(this.processingInvite !== invite.roomId)
                      .onClick(() => {
                        this.viewModel?.declineInvite(invite);
                      });

                    Blank();

                    Button('Accept')
                      .fontSize(14)
                      .backgroundColor(getThemeColors().primary)
                      .fontColor(getThemeColors().onPrimary)
                      .borderRadius(6)
                      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                      .enabled(this.processingInvite !== invite.roomId)
                      .onClick(() => {
                        this.viewModel?.acceptInvite(invite);
                      });
                  }
                  .width('100%')
                  .margin({ top: 12 });
                }
                .width('100%')
                .padding(16)
                .backgroundColor(getThemeColors().surface);
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
