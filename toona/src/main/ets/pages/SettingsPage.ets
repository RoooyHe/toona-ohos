import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AuthManager } from '../services/AuthManager';
import { UserManager } from '../services/UserManager';
import { PresenceManager } from '../services/PresenceManager';
import { DeviceManager } from '../services/DeviceManager';
import { RoomTagManager } from '../services/RoomTagManager';
import { RoomManager } from '../services/RoomManager';
import { MediaManager } from '../services/MediaManager';
import { Room } from '../models/DataModels';
import { Device } from '../models/MatrixTypes';
import { PresenceState } from '../models/MatrixTypes';
import { media } from '@kit.MediaKit';
import { fileIo } from '@kit.CoreFileKit';
import { picker } from '@kit.CoreFileKit';
import { ThemeManager, getThemeColors } from '../utils/ThemeManager';

@Entry
@Component
struct SettingsPage {
  @State userId: string = '';
  @State displayName: string = '';
  @State avatarUrl: string = '';
  @State presence: PresenceState = 'online';
  @State statusMsg: string = '';
  @State devices: Device[] = [];
  @State favoriteRooms: Room[] = [];
  @State lowPriorityRooms: Room[] = [];
  @State allRooms: Room[] = [];
  @State isLoading: boolean = true;
  @State isEditingName: boolean = false;
  @State editName: string = '';
  @State showPresenceMenu: boolean = false;
  @State showRoomTagsMenu: boolean = false;
  @State selectedRoomForTags: Room | null = null;
  @State showAboutPage: boolean = false;

  private authManager: AuthManager = AuthManager.getInstance();
  private userManager: UserManager = UserManager.getInstance();
  private presenceManager: PresenceManager = PresenceManager.getInstance();
  private deviceManager: DeviceManager = DeviceManager.getInstance();
  private roomTagManager: RoomTagManager = RoomTagManager.getInstance();
  private roomManager: RoomManager = RoomManager.getInstance();
  private mediaManager: MediaManager = MediaManager.getInstance();
  private themeManager: ThemeManager = ThemeManager.getInstance();

  aboutToAppear() {
    const session = this.authManager.getSession();
    if (session) {
      this.userId = session.userId;
    }
    this.loadUserData();
  }

  toggleDarkMode() {
    this.themeManager.toggleDarkMode();
    promptAction.showToast({ message: this.themeManager.getIsDarkMode() ? '深色模式已开启' : '浅色模式已开启' });
  }

  async loadUserData() {
    this.isLoading = true;
    try {
      const profile = await this.userManager.getUserProfile();
      this.displayName = profile.displayName || '';
      this.avatarUrl = profile.avatarUrl || '';
      this.editName = this.displayName;

      const presenceResponse = await this.presenceManager.getPresence(this.userId);
      this.presence = presenceResponse.presence as PresenceState;
      this.statusMsg = presenceResponse.status_msg || '';

      try {
        const devicesResponse = await this.deviceManager.getDevices();
        this.devices = devicesResponse.devices || [];
      } catch (e) {
        console.error('Failed to load devices:', e);
        this.devices = [];
      }

      this.allRooms = await this.roomManager.getRooms();
      this.favoriteRooms = [];
      this.lowPriorityRooms = [];

      for (let i = 0; i < this.allRooms.length; i++) {
        const room = this.allRooms[i];
        try {
          const isFav = await this.roomTagManager.isFavorite(room.id);
          if (isFav) {
            this.favoriteRooms.push(room);
          }
          const isLow = await this.roomTagManager.isLowPriority(room.id);
          if (isLow) {
            this.lowPriorityRooms.push(room);
          }
        } catch (e) {
          console.error('Failed to check room tags:', e);
        }
      }
    } catch (error) {
      console.error('Failed to load user data:', error);
    } finally {
      this.isLoading = false;
    }
  }

  async saveDisplayName() {
    if (!this.editName.trim()) {
      return;
    }
    try {
      await this.userManager.setDisplayName(this.editName.trim());
      this.displayName = this.editName.trim();
      this.isEditingName = false;
      promptAction.showToast({ message: '显示名称已更新' });
    } catch (error) {
      console.error('Failed to save display name:', error);
      promptAction.showToast({ message: '更新失败' });
    }
  }

  async setPresence(state: PresenceState) {
    try {
      await this.presenceManager.setPresence(this.userId, state, this.statusMsg);
      this.presence = state;
      this.showPresenceMenu = false;
      promptAction.showToast({ message: '状态已更新' });
    } catch (error) {
      console.error('Failed to set presence:', error);
      promptAction.showToast({ message: '更新失败' });
    }
  }

  async setStatusMessage() {
    try {
      await this.presenceManager.setPresence(this.userId, this.presence, this.statusMsg);
      promptAction.showToast({ message: '状态消息已更新' });
    } catch (error) {
      console.error('Failed to set status message:', error);
      promptAction.showToast({ message: '更新失败' });
    }
  }

  async pickAndUploadAvatar() {
    try {
      const photoPicker = new picker.PhotoViewPicker();
      const result = await photoPicker.select({
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      });
      if (result && result.photoUris && result.photoUris.length > 0) {
        const photoUri = result.photoUris[0];
        const file = fileIo.openSync(photoUri, fileIo.OpenMode.READ_ONLY);
        const fileInfo = fileIo.statSync(photoUri);
        const buffer = new Uint8Array(fileInfo.size);
        fileIo.readSync(file.fd, buffer);
        fileIo.closeSync(file);
        const fileName = 'avatar_' + Date.now() + '.jpg';
        const mxcUri = await this.mediaManager.uploadImage(buffer.buffer as ArrayBuffer, fileName);
        await this.userManager.setAvatarUrl(mxcUri);
        this.avatarUrl = this.mediaManager.getHttpUrl(mxcUri);
        promptAction.showToast({ message: '头像已更新' });
      }
    } catch (error) {
      console.error('Failed to upload avatar:', error);
      promptAction.showToast({ message: '头像上传失败' });
    }
  }

  async toggleFavorite(room: Room) {
    try {
      const isFav = await this.roomTagManager.isFavorite(room.id);
      if (isFav) {
        await this.roomTagManager.removeFavorite(room.id);
        const index = this.favoriteRooms.findIndex(r => r.id === room.id);
        if (index >= 0) {
          this.favoriteRooms.splice(index, 1);
        }
      } else {
        await this.roomTagManager.addFavorite(room.id);
        this.favoriteRooms.push(room);
      }
      promptAction.showToast({ message: isFav ? '已取消收藏' : '已添加收藏' });
    } catch (error) {
      console.error('Failed to toggle favorite:', error);
      promptAction.showToast({ message: '操作失败' });
    }
  }

  async toggleLowPriority(room: Room) {
    try {
      const isLow = await this.roomTagManager.isLowPriority(room.id);
      if (isLow) {
        await this.roomTagManager.removeLowPriority(room.id);
        const index = this.lowPriorityRooms.findIndex(r => r.id === room.id);
        if (index >= 0) {
          this.lowPriorityRooms.splice(index, 1);
        }
      } else {
        await this.roomTagManager.addLowPriority(room.id);
        this.lowPriorityRooms.push(room);
      }
      promptAction.showToast({ message: isLow ? '已取消低优先级' : '已设为低优先级' });
    } catch (error) {
      console.error('Failed to toggle low priority:', error);
      promptAction.showToast({ message: '操作失败' });
    }
  }

  async deleteDevice(deviceId: string) {
    try {
      await this.deviceManager.deleteDevice(deviceId);
      const index = this.devices.findIndex(d => d.device_id === deviceId);
      if (index >= 0) {
        this.devices.splice(index, 1);
      }
      promptAction.showToast({ message: '设备已删除' });
    } catch (error) {
      console.error('Failed to delete device:', error);
      promptAction.showToast({ message: '删除失败' });
    }
  }

  getPresenceText(state: PresenceState): string {
    switch (state) {
      case 'online':
        return '在线';
      case 'offline':
        return '离线';
      case 'unavailable':
        return '离开';
      default:
        return '未知';
    }
  }

  getPresenceColor(state: PresenceState): string {
    switch (state) {
      case 'online':
        return '#4CAF50';
      case 'offline':
        return '#9E9E9E';
      case 'unavailable':
        return '#FF9800';
      default:
        return '#9E9E9E';
    }
  }

  getAvatarInitials(): string {
    if (this.displayName) {
      return this.displayName.charAt(0).toUpperCase();
    }
    if (this.userId) {
      return this.userId.charAt(0).toUpperCase();
    }
    return 'U';
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          Button('←')
            .fontSize(24)
            .backgroundColor('transparent')
            .fontColor('#333333')
            .width(44)
            .height(44)
            .onClick(() => {
              router.back();
            });

          Text('设置')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1);
        }
        .width('100%')
        .padding({ left: 10, right: 10 })
        .backgroundColor('#ffffff');

        Divider().color('#f0f0f0');

        if (this.isLoading) {
          Column() {
            LoadingProgress()
              .width(40)
              .height(40);
            Text('加载中...')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 10 });
          }
          .width('100%')
          .padding({ top: 100 });
        } else {
          this.buildUserSection();
          this.buildThemeSection();
          this.buildPresenceSection();
          this.buildRoomTagsSection();
          this.buildDevicesSection();
          this.buildLogoutSection();
          this.buildAboutSection();
        }
      }
      .width('100%')
      .backgroundColor(getThemeColors().bg);
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  buildThemeSection() {
    Column() {
      Row() {
        Text('外观设置')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(getThemeColors().text);
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 15, bottom: 10 });

      Column() {
        Row() {
          Column() {
            Text('深色模式')
              .fontSize(14)
              .fontColor(getThemeColors().text);
            Text(this.themeManager.getIsDarkMode() ? '已开启' : '已关闭')
              .fontSize(12)
              .fontColor(getThemeColors().textSecondary)
              .margin({ top: 2 });
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1);

          if (this.themeManager.getIsDarkMode()) {
            Image($r('app.media.dark'))
              .width(24)
              .height(24);
          } else {
            Image($r('app.media.light'))
              .width(24)
              .height(24);
          }

          Blank().width(10);

          Toggle({ type: ToggleType.Switch, isOn: this.themeManager.getIsDarkMode() })
            .selectedColor('#10a37f')
            .onChange((isOn: boolean) => {
              this.toggleDarkMode();
            });
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 12 });
      }
      .width('100%')
      .backgroundColor(getThemeColors().surface);
    }
    .width('100%')
    .margin({ top: 10 });
  }

  @Builder
  buildUserSection() {
    Column() {
      Row() {
        Text('用户资料')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(getThemeColors().text);
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 15, bottom: 10 });

      Column() {
        Row() {
          Stack() {
            if (this.avatarUrl) {
              Image(this.avatarUrl)
                .width(60)
                .height(60)
                .borderRadius(30);
            } else {
              Text(this.getAvatarInitials())
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#ffffff')
                .width(60)
                .height(60)
                .borderRadius(30)
                .backgroundColor('#10a37f')
                .textAlign(TextAlign.Center);
            }

            Row() {
              Circle()
                .width(14)
                .height(14)
                .fill(this.getPresenceColor(this.presence))
                .stroke('#ffffff')
                .strokeWidth(2);
            }
            .width(14)
            .height(14)
            .position({ x: 42, y: 42 });

            Row() {
              Text('✎')
                .fontSize(10)
                .fontColor('#ffffff')
                .width(18)
                .height(18)
                .borderRadius(9)
                .backgroundColor('#10a37f')
                .textAlign(TextAlign.Center)
                .onClick(() => {
                  this.pickAndUploadAvatar();
                });
            }
            .width(18)
            .height(18)
            .position({ x: 42, y: 42 });
          }
          .width(60)
          .height(60)
          .margin({ right: 15 });

          Column() {
            if (this.isEditingName) {
              Row() {
                TextInput({ text: this.editName })
                  .width(150)
                  .height(36)
                  .fontSize(16)
                  .backgroundColor(getThemeColors().bg)
                  .borderRadius(8)
                  .onChange((value: string) => {
                    this.editName = value;
                  });

                Button('保存')
                  .fontSize(12)
                  .backgroundColor('#10a37f')
                  .fontColor('#ffffff')
                  .width(50)
                  .height(30)
                  .borderRadius(6)
                  .margin({ left: 8 })
                  .onClick(() => {
                    this.saveDisplayName();
                  });

                Button('取消')
                  .fontSize(12)
                  .backgroundColor(getThemeColors().bg)
                  .fontColor(getThemeColors().textSecondary)
                  .width(50)
                  .height(30)
                  .borderRadius(6)
                  .margin({ left: 5 })
                  .onClick(() => {
                    this.isEditingName = false;
                    this.editName = this.displayName;
                  });
              }
            } else {
              Text(this.displayName || '未设置名称')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(getThemeColors().text)
                .onClick(() => {
                  this.isEditingName = true;
                });

              Text(this.userId)
                .fontSize(12)
                .fontColor(getThemeColors().textSecondary)
                .margin({ top: 2 });
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1);
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 15, bottom: 15 });
      }
      .width('100%')
      .backgroundColor(getThemeColors().surface);
    }
    .width('100%');
  }

  @Builder
  buildPresenceSection() {
    Column() {
      Row() {
        Text('在线状态')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(getThemeColors().text);
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 15, bottom: 10 });

      Column() {
        Row() {
          Text('当前状态')
            .fontSize(14)
            .fontColor(getThemeColors().textSecondary);

          Blank();

          Row() {
            Circle()
              .width(10)
              .height(10)
              .fill(this.getPresenceColor(this.presence));
            Text(this.getPresenceText(this.presence))
              .fontSize(14)
              .fontColor(getThemeColors().text)
              .margin({ left: 6 });
          }
          .onClick(() => {
            this.showPresenceMenu = !this.showPresenceMenu;
          });
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 12 });

        if (this.showPresenceMenu) {
          Column() {
            ForEach(['online', 'unavailable', 'offline'] as PresenceState[], (state: PresenceState) => {
              Row() {
                Circle()
                  .width(10)
                  .height(10)
                  .fill(this.getPresenceColor(state));
                Text(this.getPresenceText(state))
                  .fontSize(14)
                  .fontColor(getThemeColors().text)
                  .margin({ left: 8 });
                Blank();
                if (this.presence === state) {
                  Text('✓')
                    .fontSize(14)
                    .fontColor('#10a37f');
                }
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 10, bottom: 10 })
              .onClick(() => {
                this.setPresence(state);
              });
            });
          }
          .width('100%')
          .backgroundColor(getThemeColors().bg);
        }

        Divider().color(getThemeColors().divider);

        Row() {
          Text('状态消息')
            .fontSize(14)
            .fontColor(getThemeColors().textSecondary);
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12 });

        TextInput({ text: this.statusMsg, placeholder: '设置状态消息' })
          .width('calc(100% - 40)')
          .height(36)
          .fontSize(14)
          .backgroundColor(getThemeColors().bg)
          .borderRadius(8)
          .margin({ left: 20, right: 20, top: 8, bottom: 12 })
          .onChange((value: string) => {
            this.statusMsg = value;
          })
          .onSubmit(() => {
            this.setStatusMessage();
          });

        Button('保存状态消息')
          .fontSize(14)
          .backgroundColor('#10a37f')
          .fontColor('#ffffff')
          .width('calc(100% - 40)')
          .height(36)
          .borderRadius(8)
          .margin({ left: 20, right: 20, bottom: 12 })
          .onClick(() => {
            this.setStatusMessage();
          });
      }
      .width('100%')
      .backgroundColor(getThemeColors().surface);
    }
    .width('100%')
    .margin({ top: 10 });
  }

  @Builder
  buildRoomTagsSection() {
    Column() {
      Row() {
        Text('房间标签')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333');
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 15, bottom: 10 });

      Column() {
        Row() {
          Text('收藏的房间')
            .fontSize(14)
            .fontColor('#666666');
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 8 });

        if (this.favoriteRooms.length === 0) {
          Text('暂无收藏的房间')
            .fontSize(12)
            .fontColor('#999999')
            .padding({ left: 20, bottom: 12 });
        } else {
          Column() {
            ForEach(this.favoriteRooms, (room: Room) => {
              Row() {
                Text(room.getDisplayName())
                  .fontSize(14)
                  .fontColor('#333333')
                  .layoutWeight(1);
                Text('★')
                  .fontSize(14)
                  .fontColor('#FF9800');
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 8, bottom: 8 })
              .onClick(() => {
                this.toggleFavorite(room);
              });
            });
          }
          .width('100%')
          .backgroundColor('#fafafa');
        }

        Divider().color('#f0f0f0').margin({ top: 8 });

        Row() {
          Text('低优先级的房间')
            .fontSize(14)
            .fontColor('#666666');
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 8 });

        if (this.lowPriorityRooms.length === 0) {
          Text('暂无低优先级的房间')
            .fontSize(12)
            .fontColor('#999999')
            .padding({ left: 20, bottom: 12 });
        } else {
          Column() {
            ForEach(this.lowPriorityRooms, (room: Room) => {
              Row() {
                Text(room.getDisplayName())
                  .fontSize(14)
                  .fontColor('#333333')
                  .layoutWeight(1);
                Text('▼')
                  .fontSize(14)
                  .fontColor('#9E9E9E');
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 8, bottom: 8 })
              .onClick(() => {
                this.toggleLowPriority(room);
              });
            });
          }
          .width('100%')
          .backgroundColor('#fafafa');
        }

        Divider().color('#f0f0f0').margin({ top: 8 });

        Row() {
          Text('管理所有房间标签')
            .fontSize(14)
            .fontColor('#10a37f');
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 12 })
        .onClick(() => {
          this.showRoomTagsMenu = !this.showRoomTagsMenu;
        });

        if (this.showRoomTagsMenu) {
          Column() {
            ForEach(this.allRooms, (room: Room) => {
              Row() {
                Text(room.getDisplayName())
                  .fontSize(14)
                  .fontColor('#333333')
                  .layoutWeight(1);

                Text(this.favoriteRooms.some(r => r.id === room.id) ? '★' : '☆')
                  .fontSize(14)
                  .fontColor(this.favoriteRooms.some(r => r.id === room.id) ? '#FF9800' : '#CCCCCC')
                  .onClick(() => {
                    this.toggleFavorite(room);
                  });

                Text(this.lowPriorityRooms.some(r => r.id === room.id) ? '▼' : '▽')
                  .fontSize(14)
                  .fontColor(this.lowPriorityRooms.some(r => r.id === room.id) ? '#9E9E9E' : '#CCCCCC')
                  .margin({ left: 12 })
                  .onClick(() => {
                    this.toggleLowPriority(room);
                  });
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 10, bottom: 10 });
            });
          }
          .width('100%')
          .backgroundColor('#fafafa');
        }
      }
      .width('100%')
      .backgroundColor('#ffffff');
    }
    .width('100%')
    .margin({ top: 10 });
  }

  @Builder
  buildDevicesSection() {
    Column() {
      Row() {
        Text('设备管理')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333');
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 15, bottom: 10 });

      Column() {
        if (this.devices.length === 0) {
          Text('暂无设备信息')
            .fontSize(14)
            .fontColor('#999999')
            .padding({ left: 20, right: 20, top: 12, bottom: 12 });
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

              if (device.device_id === this.authManager.getSession()?.deviceId) {
                Text('当前设备')
                  .fontSize(12)
                  .fontColor('#10a37f')
                  .backgroundColor('#e8f5e9')
                  .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                  .borderRadius(4);
              } else {
                Button('删除')
                  .fontSize(12)
                  .backgroundColor('#ffebee')
                  .fontColor('#e53935')
                  .height(28)
                  .borderRadius(6)
                  .onClick(() => {
                    this.deleteDevice(device.device_id || '');
                  });
              }
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 12, bottom: 12 });
          });
        }
      }
      .width('100%')
      .backgroundColor('#ffffff');
    }
    .width('100%')
    .margin({ top: 10 });
  }

  @Builder
  buildAboutSection() {
    Column() {
      Row() {
        Text('关于')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(getThemeColors().text);
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 15, bottom: 10 });

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
        .padding({ left: 20, right: 20, top: 12, bottom: 12 });

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
        .padding({ left: 20, right: 20, top: 12, bottom: 12 });

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
        .padding({ left: 20, right: 20, top: 12, bottom: 12 });

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
        .padding({ left: 20, right: 20, top: 12, bottom: 12 });

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
          .padding({ left: 20, right: 20, top: 8, bottom: 12 });

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
        .padding({ left: 20, right: 20, top: 12, bottom: 12 })
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
        .padding({ left: 20, right: 20, top: 12, bottom: 12 })
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
        .padding({ left: 20, right: 20, top: 12, bottom: 12 })
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

  @Builder
  buildLogoutSection() {
    Column() {
      Button('退出登录')
        .fontSize(16)
        .fontColor('#e53935')
        .backgroundColor('#ffffff')
        .width('100%')
        .height(48)
        .borderRadius(8)
        .margin({ top: 20, left: 20, right: 20, bottom: 30 })
        .onClick(() => {
          this.handleLogout();
        });
    }
    .width('100%')
    .backgroundColor('#ffffff')
    .margin({ top: 10 });
  }

  async handleLogout() {
    try {
      await this.authManager.logout();
      router.replaceUrl({ url: 'pages/LoginPage' }).catch(() => {
      });
    } catch (error) {
      console.error('Logout failed:', error);
      promptAction.showToast({ message: '退出失败' });
    }
  }
}
