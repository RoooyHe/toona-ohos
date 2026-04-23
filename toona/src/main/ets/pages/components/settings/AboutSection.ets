import promptAction from '@ohos.promptAction';
import { getThemeColors } from '../../../utils/ThemeManager';

@Component
export struct AboutSection {
  build() {
    Column() {
      Row() {
        Text('关于')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(getThemeColors().text);
      }
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        top: 15,
        bottom: 10
      });

      Column() {
        Row() {
          Text('应用名称')
            .fontSize(14)
            .fontColor(getThemeColors().textSecondary);
          Blank();
          Text('Toona')
            .fontSize(14)
            .fontColor(getThemeColors().text);
        }
        .width('100%')
        .padding({
          left: 20,
          right: 20,
          top: 12,
          bottom: 12
        });

        Divider().color(getThemeColors().divider);

        Row() {
          Text('版本')
            .fontSize(14)
            .fontColor(getThemeColors().textSecondary);
          Blank();
          Text('1.0.0')
            .fontSize(14)
            .fontColor(getThemeColors().text);
        }
        .width('100%')
        .padding({
          left: 20,
          right: 20,
          top: 12,
          bottom: 12
        });

        Divider().color(getThemeColors().divider);

        Row() {
          Text('基于 Matrix 协议')
            .fontSize(14)
            .fontColor(getThemeColors().textSecondary);
          Blank();
          Text('v1.11')
            .fontSize(14)
            .fontColor(getThemeColors().text);
        }
        .width('100%')
        .padding({
          left: 20,
          right: 20,
          top: 12,
          bottom: 12
        });

        Divider().color(getThemeColors().divider);

        Row() {
          Text('开源许可')
            .fontSize(14)
            .fontColor(getThemeColors().textSecondary);
          Blank();
          Text('Apache 2.0')
            .fontSize(14)
            .fontColor(getThemeColors().text);
        }
        .width('100%')
        .padding({
          left: 20,
          right: 20,
          top: 12,
          bottom: 12
        });

        Divider().color(getThemeColors().divider);

        Row() {
          Text('关于应用')
            .fontSize(14)
            .fontColor(getThemeColors().textSecondary);
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12 });

        Text('Toona 是一个基于 Matrix 协议的开源即时通讯客户端，为 HarmonyOS 设备提供安全、私密的聊天体验。')
          .fontSize(12)
          .fontColor(getThemeColors().textSecondary)
          .padding({
            left: 20,
            right: 20,
            top: 8,
            bottom: 12
          });

        Divider().color(getThemeColors().divider);

        Row() {
          Text('隐私政策')
            .fontSize(14)
            .fontColor('#10a37f');
          Blank();
          Text('→')
            .fontSize(14)
            .fontColor('#10a37f');
        }
        .width('100%')
        .padding({
          left: 20,
          right: 20,
          top: 12,
          bottom: 12
        })
        .onClick(() => {
          promptAction.showToast({ message: '隐私政策页面开发中' });
        });

        Divider().color(getThemeColors().divider);

        Row() {
          Text('服务条款')
            .fontSize(14)
            .fontColor('#10a37f');
          Blank();
          Text('→')
            .fontSize(14)
            .fontColor('#10a37f');
        }
        .width('100%')
        .padding({
          left: 20,
          right: 20,
          top: 12,
          bottom: 12
        })
        .onClick(() => {
          promptAction.showToast({ message: '服务条款页面开发中' });
        });

        Divider().color(getThemeColors().divider);

        Row() {
          Text('开放源代码')
            .fontSize(14)
            .fontColor('#10a37f');
          Blank();
          Text('→')
            .fontSize(14)
            .fontColor('#10a37f');
        }
        .width('100%')
        .padding({
          left: 20,
          right: 20,
          top: 12,
          bottom: 12
        })
        .onClick(() => {
          promptAction.showToast({ message: '开源地址开发中' });
        });
      }
      .width('100%')
      .backgroundColor(getThemeColors().surface);
    }
    .width('100%')
    .margin({ top: 10 });
  }
}