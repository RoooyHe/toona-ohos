import { Device } from '../../../models/MatrixTypes';
import { getThemeColors } from '../../../utils/ThemeManager';

@Component
export struct DeviceManagement {
  @Prop devices: Device[] = [];
  @Prop currentDeviceId: string = '';
  onDeleteDevice: (deviceId: string) => void = () => {};

  build() {
    Column() {
      Row() {
        Text('设备管理')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333');
      }
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        top: 15,
        bottom: 10
      });

      Column() {
        if (this.devices.length === 0) {
          Text('暂无设备信息')
            .fontSize(14)
            .fontColor('#999999')
            .padding({
              left: 20,
              right: 20,
              top: 12,
              bottom: 12
            });
        } else {
          ForEach(this.devices, (device: Device) => {
            Row() {
              Column() {
                Text(device.display_name || '未知设备')
                  .fontSize(14)
                  .fontColor('#333333');
                Text(device.device_id || '')
                  .fontSize(11)
                  .fontColor('#999999')
                  .margin({ top: 2 });
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1);

              if (device.device_id === this.currentDeviceId) {
                Text('当前设备')
                  .fontSize(12)
                  .fontColor('#10a37f')
                  .backgroundColor('#e8f5e9')
                  .padding({
                    left: 8,
                    right: 8,
                    top: 2,
                    bottom: 2
                  })
                  .borderRadius(4);
              } else {
                Button('删除')
                  .fontSize(12)
                  .backgroundColor('#ffebee')
                  .fontColor('#e53935')
                  .height(28)
                  .borderRadius(6)
                  .onClick(() => {
                    this.onDeleteDevice(device.device_id || '');
                  });
              }
            }
            .width('100%')
            .padding({
              left: 20,
              right: 20,
              top: 12,
              bottom: 12
            });
          });
        }
      }
      .width('100%')
      .backgroundColor('#ffffff');
    }
    .width('100%')
    .margin({ top: 10 });
  }
}