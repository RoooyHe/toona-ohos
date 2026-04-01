import { JoinRoomPageBuilder } from "./JoinRoomPage";
import { JoinSpacePageBuilder } from "./JoinSpacePage";
import { LoginPageBuilder } from "./LoginPage";
import { MainPageBuilder } from "./MainPage";
import { RegisterPageBuilder } from "./RegisterPage";
import { RoomDetailPageBuilder } from "./RoomDetailPage";
import { RoomListPageBuilder } from "./RoomListPage";
import { SearchPageBuilder } from "./SearchPage";
import { SettingsPageBuilder } from "./SettingsPage";
import { SpaceDetailPageBuilder } from "./SpaceDetailPage";
import { SpacePageBuilder } from "./SpacePage";

@Builder
export function MainShellBuilder(name: string, param: Object) {
  MainShell();
}

@Entry
@Component
struct MainShell {
  pathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    this.pathStack.pushPathByName('LoginPage', undefined);
  }

  build() {
    Navigation(this.pathStack) {
    }
    .navDestination(this.navDestinationBuilder)
    .hideTitleBar(true)
    .mode(NavigationMode.Stack);
  }

  @Builder
  navDestinationBuilder(name: string, param: Object) {
    if (name === 'LoginPage') {
      LoginPageBuilder(name, param);
    } else if (name === 'MainPage') {
      MainPageBuilder(name, param);
    } else if (name === 'RegisterPage') {
      RegisterPageBuilder(name, param);
    } else if (name === 'RoomListPage') {
      RoomListPageBuilder(name, param);
    } else if (name === 'RoomDetailPage') {
      RoomDetailPageBuilder(name, param);
    } else if (name === 'SettingsPage') {
      SettingsPageBuilder(name, param);
    } else if (name === 'SpacePage') {
      SpacePageBuilder(name, param);
    } else if (name === 'SearchPage') {
      SearchPageBuilder(name, param);
    } else if (name === 'JoinRoomPage') {
      JoinRoomPageBuilder(name, param);
    } else if (name === 'JoinSpacePage') {
      JoinSpacePageBuilder(name, param);
    } else if (name === 'SpaceDetailPage') {
      SpaceDetailPageBuilder(name, param);
    }
  }
}