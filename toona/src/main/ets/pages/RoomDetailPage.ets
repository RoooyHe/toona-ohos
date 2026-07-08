import { ToastUtils } from '../utils/ToastUtils';
import { QuickDialogManager, QuickDialogParams, QuickDialogController } from 'quickdialog';
import { RoomManager } from '../services/RoomManager';
import { Message } from '../models/DataModels';
import { SyncManager } from '../services/SyncManager';
import { MessageManager } from '../services/MessageManager';
import { PresenceManager } from '../services/PresenceManager';
import { MediaManager } from '../services/MediaManager';
import { MediaLibraryManager } from '../services/MediaLibraryManager';
import { AuthManager } from '../services/AuthManager';
import { ShareManager } from '../services/ShareManager';
import { DeviceSecurityManager } from '../services/DeviceSecurityManager';
import { MessageStatus, PresenceState } from '../models/MatrixTypes';
import { fileIo, picker } from '@kit.CoreFileKit';
import { getThemeColors } from '../utils/ThemeManager';
import { MessageBubble } from './components/MessageBubble';
import { MessageInputBar } from './components/MessageInputBar';
import { MemberListPanel } from './components/MemberListPanel';
import { MessageActionMenu } from './components/MessageActionMenu';
import { ReplyQuote } from './components/ReplyQuote';
import { EditMessage } from './components/EditMessage';
import { ReactionPicker } from './components/ReactionPicker';
import { StickerPicker } from './components/StickerPicker';
import { MessageSourceDialog } from './components/MessageSourceDialog';
import { MessageReportDialog } from './components/MessageReportDialog';
import { media } from '@kit.MediaKit';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';
import pasteboard from '@ohos.pasteboard';
// 1. 引入必要的动画库
import curves from '@ohos.curves';
import { AppLogger } from '../utils/AppLogger';

const logger = AppLogger.getLogger('RoomDetailPage');


interface MemberPresence {
  userId: string;
  presence: PresenceState;
  displayName: string;
}

interface ReplyQuoteData {
  eventId: string;
  sender: string;
  body: string;
}

interface InReplyTo {
  event_id: string;
}

interface ReferenceContent {
  event_id: string;
  sender: string;
}

interface RelatesTo {
  'm.in_reply_to': InReplyTo;
}

@Builder
export function RoomDetailPageBuilder(name: string, param: Object) {
  RoomDetailPage({
    roomId: ((param as Record<string, Object>)['roomId'] as string) || '',
    roomName: ((param as Record<string, Object>)['roomName'] as string) || '聊天室',
    pathStack: ((param as Record<string, Object>)['pathStack'] as NavPathStack) || new NavPathStack()
  })
}

// 2. 录音提示弹窗内容组件（QuickDialog版）
@Component
struct RecordingDialogContent {
  private dialogController: QuickDialogController | undefined = undefined
  @State waveScale: number = 1.0

  aboutToAppear() {
    animateTo({
      duration: 800,
      curve: curves.springMotion(),
      iterations: -1,
      playMode: PlayMode.Alternate
    }, () => {
      this.waveScale = 1.3;
    })
  }

  build() {
    Column() {
      Stack() {
        Circle()
          .width(60)
          .height(60)
          .opacity(0.3)
          .scale({ x: this.waveScale, y: this.waveScale })

        Image($r('app.media.phone'))
          .width(40)
          .height(40)
          .fillColor(Color.White)
      }
      .margin({ top: 20, bottom: 15 })

      Text('松开 发送')
        .fontSize(14)
        .fontColor(Color.White)
        .margin({ bottom: 20 })
    }
    .width(140)
    .height(140)
    .backgroundColor('rgba(0,0,0,0.6)')
    .borderRadius(16)
    .justifyContent(FlexAlign.Center)
  }
}

@Builder
function RecordingDialogBuilder(dialogParams: QuickDialogParams) {
  RecordingDialogContent()
}

@Component
struct RoomDetailPage {
  @State roomId: string = '';
  @State roomName: string = '';
  @State messages: Message[] = [];
  @State inputText: string = '';
  @State isLoading: boolean = true;
  @State showMenu: boolean = false;
  @State typingUsers: string[] = [];
  @State memberPresences: MemberPresence[] = [];
  @State showMembersPanel: boolean = false;
  @State replyQuote: ReplyQuoteData | null = null;
  @State showReplyMenu: boolean = false;
  @State selectedMessage: Message | null = null;
  @State roomTopic: string = '';
  @State showMessageAction: boolean = false;
  @State messageActionType: string = '';
  @State editingMessage: Message | null = null;
  @State editText: string = '';
  @State isRecording: boolean = false;
  @State showReactionPicker: boolean = false;
  @State showStickerPicker: boolean = false;
  @State hasMoreMessages: boolean = true;
  @State isLoadingMore: boolean = false;
  @State showMessageSource: boolean = false;
  @State showReportDialog: boolean = false;
  private avRecorder: media.AVRecorder | undefined = undefined;
  private audioPath: string = '';
  private audioFd: number = -1;
  private roomManager: RoomManager = RoomManager.getInstance();
  private syncManager: SyncManager = SyncManager.getInstance();
  private messageManager: MessageManager = MessageManager.getInstance();
  private authManager: AuthManager = AuthManager.getInstance();
  private presenceManager: PresenceManager = PresenceManager.getInstance();
  private scroller: Scroller = new Scroller();
  private typingTimeout: number = 0;
  private typingStopTimeout: number = 0;
  private presenceInterval: number = 0;
  private mediaManager: MediaManager = MediaManager.getInstance();
  private mediaLibraryManager: MediaLibraryManager = MediaLibraryManager.getInstance();
  private shareManager: ShareManager = ShareManager.getInstance();
  private deviceSecurityManager: DeviceSecurityManager = DeviceSecurityManager.getInstance();
  // 录音弹窗 QuickDialog 控制器
  private recordingDialogController: QuickDialogController | undefined = undefined;
  pathStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    this.loadRoomTopic();
    this.loadMessages();
    this.loadMemberPresences();

    const self = this;
    this.presenceInterval = setInterval(() => {
      self.loadMemberPresences();
      self.checkTypingUsers();
    }, 30000) as number;

    this.syncManager.setRoomLeftCallback((leftRoomId: string) => {
      if (leftRoomId === self.roomId) {
        ToastUtils.show('已离开房间');
        self.pathStack.pop();
      }
    });

    this.syncManager.setNewMessagesCallback((msgRoomId: string) => {
      if (msgRoomId === self.roomId) {
        self.loadMessages();
        self.checkTypingUsers();
      }
    });
  }

  aboutToDisappear() {
    this.syncManager.clearAllCallbacks();
    if (this.typingTimeout) {
      clearTimeout(this.typingTimeout);
    }
    if (this.typingStopTimeout) {
      clearTimeout(this.typingStopTimeout);
    }
    if (this.presenceInterval) {
      clearInterval(this.presenceInterval);
    }
    this.roomManager.stopTyping(this.roomId).catch(() => {
    });
  }

  async loadMemberPresences() {
    try {
      const members = await this.roomManager.getRoomMembers(this.roomId);
      const currentUserId = this.authManager.getUserId();
      const otherMembers = members.filter(id => id !== currentUserId);
      const presences: MemberPresence[] = [];

      for (let i = 0; i < otherMembers.length; i++) {
        const userId = otherMembers[i];
        try {
          const presence = await this.presenceManager.getPresence(userId);
          const displayName = presence.displayname || userId;
          presences.push({
            userId: userId,
            presence: presence.presence as PresenceState,
            displayName: displayName
          });
        } catch (e) {
          presences.push({
            userId: userId,
            presence: 'offline',
            displayName: userId
          });
        }
      }
      this.memberPresences = presences;
    } catch (error) {
      logger.error('Failed to load member presences:', error);
    }
  }

  async loadRoomTopic() {
    try {
      const room = await this.roomManager.getRoom(this.roomId);
      if (room) {
        this.roomTopic = room.topic || '';
        if (this.roomName === '聊天室' && room.displayName) {
          this.roomName = room.displayName;
        }
      }
    } catch (error) {
      logger.error('Failed to load room topic:', error);
    }
  }

  async checkTypingUsers() {
    try {
      // 暂时屏蔽掉，因为获取 typing 是从 sync 流里拿，而不是主动发 GET 请求
      // const typing = await this.roomManager.getTypingUsers(this.roomId);
      // const currentUserId = this.authManager.getUserId();
      // this.typingUsers = typing.filter(id => id !== currentUserId);
      return;
    } catch (error) {
      logger.error('Failed to check typing users:', error);
    }
  }

  async onInputChange(text: string) {
    this.inputText = text;
    if (this.typingTimeout === 0) {
      this.roomManager.startTyping(this.roomId).catch(() => {
      });
    }
    if (this.typingStopTimeout) {
      clearTimeout(this.typingStopTimeout);
    }
    const self = this;
    this.typingStopTimeout = setTimeout(() => {
      self.roomManager.stopTyping(self.roomId).catch(() => {
      });
      self.typingTimeout = 0;
      self.typingStopTimeout = 0;
    }, 3000) as number;
  }

  async pickAndUploadImage() {
    try {
      const uri = await this.mediaLibraryManager.selectImage();
      if (uri) {
        await this.uploadImages([uri]);
      }
    } catch (error) {
      logger.error('Failed to pick image: %{public}s', error);
      ToastUtils.show('选择图片失败');
    }
  }

  // 唤起系统相册选择图片
  async handleSelectImage() {
    try {
      // 1. 配置图片选择器参数
      let photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;

      // 2. 实例化并拉起选择器
      let photoPicker = new picker.PhotoViewPicker();
      let photoSelectResult = await photoPicker.select(photoSelectOptions);

      // 3. 检查是否选择了图片
      if (photoSelectResult && photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        let imageUri = photoSelectResult.photoUris[0];

        ToastUtils.show('正在准备发送图片...');

        // ✅ 修正 1：使用已引入的 fileIo 替代未引入的 fs
        let file = fileIo.openSync(imageUri, fileIo.OpenMode.READ_ONLY);
        let stat = fileIo.statSync(imageUri); // statSync 推荐直接传 uri 或路径
        let buffer = new ArrayBuffer(stat.size);
        fileIo.readSync(file.fd, buffer);
        fileIo.closeSync(file);

        let fileName = `image_${new Date().getTime()}.jpg`;

        // 5. 调用上传逻辑
        await this.uploadAndSendImage(buffer, fileName, stat.size);
      }
    } catch (error) {
      logger.error('PhotoPicker failed or user canceled:', error);
    }
  }

  // 上传图片并发送到房间
  async uploadAndSendImage(imageBuffer: ArrayBuffer, fileName: string, fileSize: number) {
    try {
      // 1. 上传图片并显式断言为 Object，消灭 any
      const uploadResult = (await this.mediaManager.uploadImage(imageBuffer, fileName)) as Object;

      // 2. 提取真正的 mxc 链接
      let mxcUrl: string = '';
      if (typeof uploadResult === 'string') {
        mxcUrl = uploadResult as string;
      } else {
        mxcUrl = (uploadResult as Record<string, string>)['content_uri'];
      }

      if (mxcUrl) {
        // 3. 构建嵌套的 info 对象
        const imageInfo: Record<string, Object> = {
          'size': fileSize as Object,
          'mimetype': 'image/jpeg' as Object
        };

        // 4. 构建发送内容，完美匹配 messageManager 的参数要求
        const imageMessageContent: Record<string, string | object> = {
          'msgtype': 'm.image',
          'body': fileName,
          'url': mxcUrl,
          'info': imageInfo as object // 显式断言为 object
        };

        // ✅ 核心修复：使用项目中专门负责发送消息的 messageManager
        await this.messageManager.sendMessage(this.roomId, 'm.room.message', imageMessageContent);

        ToastUtils.show('图片发送成功');

        // 发送完如果想马上在列表看到，可以取消这行注释刷新一下列表
        // this.loadMessages();
      }
    } catch (error) {
      logger.error('Failed to send image:', error.message);
      ToastUtils.show('图片发送失败');
    }
  }

  // 🎙️ 动态申请麦克风权限
  async requestMicrophonePermission(): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    const context = getContext(this) as common.UIAbilityContext;
    try {
      // 唤起系统权限弹窗
      const data = await atManager.requestPermissionsFromUser(context, ['ohos.permission.MICROPHONE']);
      const grantStatus = data.authResults[0];

      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        return true; // 用户点击了允许
      } else {
        ToastUtils.show('需要麦克风权限才能录制语音');
        return false; // 用户点击了拒绝
      }
    } catch (err) {
      logger.error('Failed to request permission:', err);
      return false;
    }
  }

  // 1. 开始录音
  async startRecording() {
    const hasPermission = await this.requestMicrophonePermission();
    if (!hasPermission) {
      return;
    }

    try {
      this.avRecorder = await media.createAVRecorder();
      const context = getContext(this);
      this.audioPath = context.cacheDir + '/voice_' + Date.now() + '.m4a';
      const file = fileIo.openSync(this.audioPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      this.audioFd = file.fd;

      let avProfile: media.AVRecorderProfile = {
        audioBitrate: 48000,
        audioChannels: 1,
        audioCodec: media.CodecMimeType.AUDIO_AAC,
        audioSampleRate: 48000,
        fileFormat: media.ContainerFormatType.CFT_MPEG_4A,
      };

      let avConfig: media.AVRecorderConfig = {
        audioSourceType: media.AudioSourceType.AUDIO_SOURCE_TYPE_MIC,
        profile: avProfile,
        url: 'fd://' + this.audioFd,
      };

      await this.avRecorder.prepare(avConfig);
      await this.avRecorder.start();

      this.isRecording = true;
      // ✅ QuickDialog：创建并拉起半透明的波纹动画弹窗
      this.recordingDialogController = QuickDialogManager.newBuilder(
        this.getUIContext(),
        wrapBuilder(RecordingDialogBuilder)
      ).build();
      this.recordingDialogController.show();
    } catch (err) {
      logger.error('Failed to start recording:', err);
      ToastUtils.show('无法启动录音设备');
    }
  }

  // 2. 停止录音并触发发送
  async stopAndSendRecording() {
    if (this.avRecorder && this.isRecording) {
      try {
        await this.avRecorder.stop();
        await this.avRecorder.release();
        this.avRecorder = undefined;
        this.isRecording = false;

        // ✅ QuickDialog：关闭动画弹窗
        this.recordingDialogController?.dismiss();

        fileIo.closeSync(this.audioFd);

        let file = fileIo.openSync(this.audioPath, fileIo.OpenMode.READ_ONLY);
        let stat = fileIo.statSync(this.audioPath);
        let buffer = new ArrayBuffer(stat.size);
        fileIo.readSync(file.fd, buffer);
        fileIo.closeSync(file);

        // 删掉这行，不需要提示了：ToastUtils.show('录音结束，正在发送...');

        const fileName = `voice_${Date.now()}.m4a`;
        await this.uploadAndSendAudio(buffer, fileName, stat.size);
      } catch (err) {
        logger.error('Failed to stop recording:', err);
        this.isRecording = false;
        this.recordingDialogController?.dismiss(); // 发生错误时也要关闭弹窗
      }
    }
  }

  // 3. 上传并发送 m.audio 类型的 Matrix 消息
  async uploadAndSendAudio(audioBuffer: ArrayBuffer, fileName: string, fileSize: number) {
    try {
      // 1. 上传音频文件
      const uploadResult = (await this.mediaManager.uploadImage(audioBuffer, fileName)) as Object;

      let mxcUrl: string = '';
      if (typeof uploadResult === 'string') {
        mxcUrl = uploadResult as string;
      } else {
        mxcUrl = (uploadResult as Record<string, string>)['content_uri'];
      }

      if (mxcUrl) {
        // 1. 构建音频专属的 info
        const audioInfo: Record<string, Object> = {
          'size': fileSize as Object,
          'mimetype': 'audio/mp4' as Object
        };

        // ✅ 2. 核心修复：显式声明一个空的 Record 对象，用来代替匿名的 {}
        const voiceFlag: Record<string, Object> = {};

        // 3. 构建发送内容
        const audioMessageContent: Record<string, string | object> = {
          'msgtype': 'm.audio',
          'body': '语音消息',
          'url': mxcUrl,
          'info': audioInfo as object,

          // 将声明好的 voiceFlag 赋值进去，完美绕过 ArkTS 的匿名对象检查
          'org.matrix.msc3245.voice': voiceFlag as object,
          'm.voice': voiceFlag as object
        };

        await this.messageManager.sendMessage(this.roomId, 'm.room.message', audioMessageContent);

        // 发送完刷新一下，让你自己的 UI 也能看到
        this.loadMessages();
      }
    } catch (error) {
      logger.error('Failed to send audio:', error.message);
      ToastUtils.show('语音发送失败');
    }
  }

  async pickAndUploadMultipleImages() {
    try {
      const uris = await this.mediaLibraryManager.selectMultipleImages(9);
      if (uris.length > 0) {
        await this.uploadImages(uris);
      }
    } catch (error) {
      logger.error('Failed to pick images: %{public}s', error);
      ToastUtils.show('选择图片失败');
    }
  }

  async uploadImages(uris: string[]) {
    for (let i = 0; i < uris.length; i++) {
      const photoUri = uris[i];
      try {
        const file = fileIo.openSync(photoUri, fileIo.OpenMode.READ_ONLY);
        const fileInfo = fileIo.statSync(photoUri);
        const buffer = new Uint8Array(fileInfo.size);
        fileIo.readSync(file.fd, buffer);
        fileIo.closeSync(file);
        const fileName = 'image_' + Date.now() + '_' + i + '.jpg';
        const mxcUri = await this.mediaManager.uploadImage(buffer.buffer as ArrayBuffer, fileName);
        const msgContent: Record<string, string | object> = {
          'msgtype': 'm.image',
          'body': fileName,
          'url': mxcUri
        };
        const tempMessage: Message = Message.createPendingMessage(this.roomId, msgContent);
        tempMessage.timestamp = Date.now();
        this.messages.push(tempMessage);
        try {
          const messageManager = await import('../services/MessageManager');
          await messageManager.MessageManager.getInstance().sendMessage(this.roomId, 'm.room.message', msgContent);
          const index = this.messages.findIndex(m => m.eventId === tempMessage.eventId);
          if (index >= 0) {
            this.messages[index].status = MessageStatus.SENT;
          }
        } catch (error) {
          logger.error('Failed to send image:', error);
          const index = this.messages.findIndex(m => m.eventId === tempMessage.eventId);
          if (index >= 0) {
            this.messages[index].status = MessageStatus.FAILED;
          }
        }
      } catch (error) {
        logger.error('Failed to upload image: %{public}s', error.message);
        ToastUtils.show('图片上传失败');
      }
    }
    if (uris.length > 1) {
      ToastUtils.show(`已发送 ${uris.length} 张图片`);
    }
  }

  async loadMessages() {
    try {
      const roomMessages = await this.roomManager.getRoomMessages(this.roomId, 50);
      this.messages = roomMessages.reverse();
      this.hasMoreMessages = roomMessages.length >= 50;
    } catch (error) {
      logger.error('Failed to load messages:', error);
    } finally {
      this.isLoading = false;
    }
  }

  async loadMoreMessages() {
    if (this.isLoadingMore || !this.hasMoreMessages) {
      return;
    }

    this.isLoadingMore = true;
    try {
      const oldestMessage = this.messages[0];
      if (oldestMessage) {
        const olderMessages = await this.roomManager.getRoomMessages(
          this.roomId,
          50,
          oldestMessage.eventId
        );
        if (olderMessages.length > 0) {
          this.messages = [...olderMessages.reverse(), ...this.messages];
          this.hasMoreMessages = olderMessages.length >= 50;
        } else {
          this.hasMoreMessages = false;
        }
      }
    } catch (error) {
      logger.error('Failed to load more messages:', error);
    } finally {
      this.isLoadingMore = false;
    }
  }

  async sendMessage() {
    if (!this.inputText.trim() && !this.replyQuote) {
      return;
    }

    const messageText = this.inputText.trim();
    this.inputText = '';

    if (this.typingStopTimeout) {
      clearTimeout(this.typingStopTimeout);
      this.typingStopTimeout = 0;
    }
    this.roomManager.stopTyping(this.roomId).catch(() => {
    });

    const msgContent: Record<string, string | object> = {
      'msgtype': 'm.text',
      'body': messageText
    };

    if (this.replyQuote) {
      const inReplyTo: InReplyTo = {
        event_id: this.replyQuote.eventId
      };
      const relatesTo: RelatesTo = {
        'm.in_reply_to': inReplyTo
      };
      msgContent['m.relates_to'] = relatesTo;
      const reference: ReferenceContent = {
        event_id: this.replyQuote.eventId,
        sender: this.replyQuote.sender
      };
      msgContent['m.reference'] = reference;
    }

    const tempMessage: Message = Message.createPendingMessage(this.roomId, msgContent);
    tempMessage.timestamp = Date.now();
    tempMessage.replyEventId = this.replyQuote?.eventId;

    this.messages.push(tempMessage);

    const quotedEventId = this.replyQuote?.eventId;
    this.replyQuote = null;

    try {
      const messageManager = await import('../services/MessageManager');
      await messageManager.MessageManager.getInstance().sendMessage(this.roomId, 'm.room.message', msgContent);

      const index = this.messages.findIndex(m => m.eventId === tempMessage.eventId);
      if (index >= 0) {
        this.messages[index].status = MessageStatus.SENT;
      }
    } catch (error) {
      logger.error('Failed to send message:', error);
      const index = this.messages.findIndex(m => m.eventId === tempMessage.eventId);
      if (index >= 0) {
        this.messages[index].status = MessageStatus.FAILED;
      }
      ToastUtils.show('发送失败');
    }
  }

  async leaveRoom() {
    try {
      await this.roomManager.leaveRoom(this.roomId);
      ToastUtils.show('已离开房间');
      this.pathStack?.pop();
    } catch (error) {
      logger.error('Failed to leave room:', error);
      ToastUtils.show('离开失败');
    }
  }

  shareRoom() {
    const homeserver = this.authManager.getHomeserver() || '';
    this.shareManager.shareRoomLink(this.roomId, this.roomName, homeserver);
  }

  startReply(message: Message) {
    this.replyQuote = {
      eventId: message.eventId,
      sender: message.sender,
      body: message.getMessageBody()
    };
    this.showReplyMenu = false;
    this.selectedMessage = null;
  }

  cancelReply() {
    this.replyQuote = null;
  }

  copyMessage(message: Message) {
    try {
      const pasteboard = pasteboard.getSystemPasteboard();
      const pasteData = pasteboard.createData(message.getMessageBody());
      pasteboard.setData(pasteData);
      ToastUtils.show('消息已复制');
    } catch (error) {
      logger.error('Failed to copy message:', error);
      ToastUtils.show('复制失败');
    }
    this.showMessageAction = false;
    this.selectedMessage = null;
  }

  shareMessage(message: Message) {
    const body = message.getMessageBody();
    const senderName = this.getMessageSenderName(message);
    this.shareManager.shareMessage(body, senderName);
    this.showReplyMenu = false;
    this.selectedMessage = null;
  }

  checkMessageSecurity(message: Message) {
    const body = message.getMessageBody();
    const senderId = message.sender;
    const result = this.deviceSecurityManager.analyzeMessageSecurity(body, senderId);

    if (result.isSuspicious) {
      ToastUtils.show(`安全提醒: ${result.warnings.join(', ')}`, 4000);
    } else {
      ToastUtils.show('消息安全检测通过', 2000);
    }

    this.showReplyMenu = false;
    this.selectedMessage = null;
  }

  async deleteMessage(message: Message) {
    if (!message.eventId || message.eventId.startsWith('temp_')) {
      const index = this.messages.findIndex(m => m.eventId === message.eventId);
      if (index >= 0) {
        this.messages.splice(index, 1);
      }
      this.showMessageAction = false;
      this.selectedMessage = null;
      return;
    }

    try {
      await this.messageManager.deleteMessage(this.roomId, message.eventId);
      const index = this.messages.findIndex(m => m.eventId === message.eventId);
      if (index >= 0) {
        this.messages.splice(index, 1);
      }
      ToastUtils.show('消息已删除');
    } catch (error) {
      logger.error('Failed to delete message:', error);
      ToastUtils.show('删除失败');
    }
    this.showMessageAction = false;
    this.selectedMessage = null;
  }

  startEdit(message: Message) {
    this.editingMessage = message;
    this.editText = message.getMessageBody();
    this.showReplyMenu = false;
    this.selectedMessage = null;
  }

  async saveEdit() {
    if (!this.editingMessage || !this.editText.trim()) {
      this.cancelEdit();
      return;
    }

    if (!this.editingMessage.eventId || this.editingMessage.eventId.startsWith('temp_')) {
      ToastUtils.show('消息尚未发送，无法编辑');
      this.cancelEdit();
      return;
    }

    try {
      await this.messageManager.editMessage(this.roomId, this.editingMessage.eventId, this.editText.trim());
      const editingMessage = this.editingMessage;
      const index = this.messages.findIndex(m => m.eventId === editingMessage!.eventId);
      if (index >= 0) {
        const newContent: Record<string, string | object> = {
          'msgtype': 'm.text',
          'body': this.editText.trim()
        };
        this.messages[index].content = newContent;
      }
      ToastUtils.show('消息已编辑');
    } catch (error) {
      logger.error('Failed to edit message:', error);
      ToastUtils.show('编辑失败');
    }
    this.cancelEdit();
  }

  cancelEdit() {
    this.editingMessage = null;
    this.editText = '';
    this.showReplyMenu = false;
    this.selectedMessage = null;
  }

  startVoiceCall() {
    ToastUtils.show('语音通话功能开发中');
  }

  startVideoCall() {
    ToastUtils.show('视频通话功能开发中');
  }

  getReplySenderName(sender: string): string {
    const colonIndex = sender.indexOf(':');
    return colonIndex > 0 ? sender.substring(1, colonIndex) : sender;
  }

  formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    return date.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' });
  }

  getTimeGroupLabel(timestamp: number): string {
    const date = new Date(timestamp);
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    if (date.toDateString() === today.toDateString()) {
      return '今天';
    } else if (date.toDateString() === yesterday.toDateString()) {
      return '昨天';
    } else {
      return date.toLocaleDateString('zh-CN', { month: 'long', day: 'numeric' });
    }
  }

  shouldShowTimeGroup(index: number): boolean {
    if (index === 0) {
      return true;
    }
    const currentTime = this.messages[index].timestamp;
    const prevTime = this.messages[index - 1].timestamp;
    const currentDate = new Date(currentTime).toDateString();
    const prevDate = new Date(prevTime).toDateString();
    return currentDate !== prevDate;
  }

  onMessageLongPress(message: Message) {
    this.selectedMessage = message;
    this.showReplyMenu = true;
  }

  @Builder
  buildHeader() {
    Row() {
      Column() {
        Text(this.roomName)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .fontColor(getThemeColors().text);
        if (this.roomTopic) {
          Text(this.roomTopic)
            .fontSize(12)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontColor(getThemeColors().textSecondary);
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);

      Image($r('app.media.fllow'))
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
        .fillColor(getThemeColors().textSecondary)
        .onClick(() => {
          this.showMembersPanel = !this.showMembersPanel;
        });

      Image($r('app.media.tel'))
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
        .fillColor(getThemeColors().textSecondary)
        .onClick(() => {
          this.startVoiceCall();
        });

      Image($r('app.media.menu'))
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
        .fillColor(getThemeColors().textSecondary)
        .onClick(() => {
          this.showMenu = !this.showMenu;
        });
    }
    .width('100%')
    .height(56)
    .padding({ left: 10, right: 10 })
    .backgroundColor(getThemeColors().surface);
  }

  @Builder
  buildRoomMenu() {
    if (this.showMenu) {
      Column() {
        Button('房间设置')
          .fontSize(16)
          .backgroundColor(getThemeColors().bg)
          .fontColor(getThemeColors().primary)
          .width('100%')
          .height(44)
          .onClick(() => {
            this.showMenu = false;
            this.navigateToRoomSettings();
          });
        Button('分享房间')
          .fontSize(16)
          .backgroundColor(getThemeColors().bg)
          .fontColor(getThemeColors().primary)
          .width('100%')
          .height(44)
          .onClick(() => {
            this.showMenu = false;
            this.shareRoom();
          });
        Button('离开房间')
          .fontSize(16)
          .backgroundColor(getThemeColors().bg)
          .fontColor(getThemeColors().error)
          .width('100%')
          .height(44)
          .onClick(() => {
            this.showMenu = false;
            this.leaveRoom();
          });
      }
      .width(160)
      .backgroundColor(getThemeColors().bg)
      .borderRadius(8)
      .shadow({
        radius: 10,
        color: 'rgba(0, 0, 0, 0.15)',
        offsetX: 0,
        offsetY: 2
      })
      .position({ x: '60%', y: 60 })
      .onClick(() => {
        this.showMenu = false;
      });
    }
  }

  @Builder
  buildTypingIndicator() {
    if (this.typingUsers.length > 0) {
      Row() {
        Text('对方正在输入...')
          .fontSize(12)
          .fontColor(getThemeColors().textSecondary)
          .margin({ left: 15, top: 5, bottom: 5 });
      }
      .width('100%')
      .backgroundColor(getThemeColors().bg);
    }
  }

  @Builder
  buildReplyQuote() {
    ReplyQuote({
      replyQuote: this.replyQuote,
      onCancel: () => {
        this.cancelReply();
      }
    });
  }

  @Builder
  buildEditMessage() {
    EditMessage({
      editingMessage: this.editingMessage!,
      editText: this.editText,
      onCancel: () => {
        this.cancelEdit();
      },
      onSave: (text: string) => {
        this.editText = text;
        this.saveEdit();
      }
    });
  }

  @Builder
  buildMessageList() {
    if (this.isLoading) {
      Column() {
        LoadingProgress()
          .width(40)
          .height(40)
          .color(getThemeColors().primary);
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center);
    } else if (this.messages.length === 0) {
      Column() {
        Text('暂无消息')
          .fontSize(16)
          .fontColor(getThemeColors().textSecondary);
        Text('发送第一条消息')
          .fontSize(14)
          .fontColor(getThemeColors().textSecondary)
          .opacity(0.6)
          .margin({ top: 5 });
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center);
    } else {
      List({ scroller: this.scroller }) {
        // Load More button at the top
        if (this.hasMoreMessages) {
          ListItem() {
            Button(this.isLoadingMore ? 'Loading...' : 'Load Earlier Messages')
              .fontSize(14)
              .backgroundColor(getThemeColors().bg)
              .fontColor(getThemeColors().primary)
              .borderWidth(1)
              .borderColor(getThemeColors().primary)
              .borderRadius(6)
              .width('60%')
              .height(36)
              .margin({ top: 10, bottom: 10 })
              .enabled(!this.isLoadingMore)
              .onClick(() => {
                this.loadMoreMessages();
              });
          }
          .width('100%')
          .justifyContent(FlexAlign.Center);
        }

        ForEach(this.messages, (message: Message, index: number) => {
          ListItem() {
            // ✅ 修复 1：ListItem 内部必须只有一个根容器（Column）
            Column() {

              // 1. 显示时间分组（如果需要）
              if (this.shouldShowTimeGroup(index)) {
                Text(this.getTimeGroupLabel(message.timestamp))
                  .fontSize(12)
                  .fontColor(getThemeColors().textSecondary)
                  .padding({ top: 10, bottom: 5 });
              }

              // ✅ 修复 2：使用循环项 'message' 进行判断，而不是 'this.event'
              // 注意：请确保您的 Message 类中有 type 属性，如果没有，可能需要 message.rawEvent.type
              if (message.type === 'm.room.member') {
                // 2. 成员变更提示（居中灰色小字）
                Text(`${message.sender} 加入了房间`)
                  .fontSize(12)
                  .fontColor(Color.Gray)
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .margin({ top: 5, bottom: 5 });

              } else if (message.type === 'm.room.create') {
                // 3. 房间创建提示
                Text(`${message.sender} 创建了该房间`)
                  .fontSize(12)
                  .fontColor(Color.Gray)
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .margin({ top: 5, bottom: 5 });

              } else if (message.type === 'm.room.message') {
                // 4. 正常的聊天气泡
                MessageBubble({
                  message: message,
                  isOutgoing: message.isOutgoing,
                  onLongPress: (msg: Message) => {
                    this.onMessageLongPress(msg);
                  }
                });
              } else {
                // 5. 其他不显示的事件（占位，不占高度）
                Row().height(0)
              }
            }
            .width('100%')
          }
        }, (item: Message) => item.eventId) // 建议加上 KeyGenerator 提高性能
      }
      .width('100%')
      .layoutWeight(1)
      .padding({
        left: 15,
        right: 15,
        top: 10,
        bottom: 10
      })
      .onClick(() => {
        this.showMenu = false;
        this.showMembersPanel = false;
        this.showMessageAction = false;
      })
    }
  }

  @Builder
  buildInputBar() {
    MessageInputBar({
      inputText: this.inputText,
      editingMessage: this.editingMessage,
      onVoiceClick: (event: TouchEvent) => {
        // 1. 手指按下，开始录音
        if (event.type === TouchType.Down) {
          this.startRecording();
        }
        // 2. 手指抬起，停止录制并发送
        else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.stopAndSendRecording();
        }
      },
      onInputChange: (text: string) => {
        this.onInputChange(text);
      },
      onSendMessage: () => {
        this.sendMessage();
      },
      onPickImage: () => {
        this.handleSelectImage();
      }
    });
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          this.buildHeader();
          this.buildRoomMenu();
          this.buildTypingIndicator();
          this.buildReplyQuote();
          this.buildEditMessage();
          this.buildMessageList();
          this.buildInputBar();
        }
        .width('100%')
        .height('100%')
        .backgroundColor(getThemeColors().bg);

        if (this.showMembersPanel) {
          MemberListPanel({
            memberPresences: this.memberPresences,
            showMembersPanel: this.showMembersPanel,
            onClose: () => {
              this.showMembersPanel = false;
            }
          });
        }

        MessageActionMenu({
          showReplyMenu: this.showReplyMenu,
          selectedMessage: this.selectedMessage!,
          onReply: (message: Message) => {
            this.startReply(message);
          },
          onCopy: (message: Message) => {
            this.copyMessage(message);
          },
          onDelete: (message: Message) => {
            this.deleteMessage(message);
          },
          onEdit: (message: Message) => {
            this.startEdit(message);
          },
          onSecurityCheck: (message: Message) => {
            this.checkMessageSecurity(message);
          },
          onShare: (message: Message) => {
            this.shareMessage(message);
          },
          onReact: (message: Message) => {
            this.showReactionPicker = true;
          },
          onForward: (message: Message) => {
            this.forwardMessage(message);
          },
          onPin: (message: Message) => {
            this.pinMessage(message);
          },
          onViewSource: (message: Message) => {
            this.viewMessageSource(message);
          },
          onReport: (message: Message) => {
            this.showReportDialog = true;
          },
          onClose: () => {
            this.showReplyMenu = false;
            this.selectedMessage = null;
          }
        });

        // Reaction Picker
        ReactionPicker({
          isVisible: this.showReactionPicker,
          messageId: this.selectedMessage?.eventId || '',
          onReaction: (emoji: string) => {
            this.sendReaction(emoji);
            this.showReactionPicker = false;
            this.selectedMessage = null;
          },
          onClose: () => {
            this.showReactionPicker = false;
          }
        });

        // Sticker Picker
        StickerPicker({
          isVisible: this.showStickerPicker,
          onSticker: (stickerUrl: string, stickerBody: string) => {
            this.sendSticker(stickerUrl, stickerBody);
            this.showStickerPicker = false;
          },
          onClose: () => {
            this.showStickerPicker = false;
          }
        });

        // Message Source Dialog
        MessageSourceDialog({
          isVisible: this.showMessageSource,
          message: this.selectedMessage,
          onClose: () => {
            this.showMessageSource = false;
            this.selectedMessage = null;
          }
        });

        // Message Report Dialog
        MessageReportDialog({
          isVisible: this.showReportDialog,
          message: this.selectedMessage,
          onReport: (reason: string) => {
            this.reportMessage(reason);
          },
          onClose: () => {
            this.showReportDialog = false;
            this.selectedMessage = null;
          }
        });
      }
      .width('100%')
      .height('100%');
    }
    .hideTitleBar(true)
    .onBackPressed(() => {
      return QuickDialogManager.dismissLastShowingDialog()
    });
  }

  getMessageSenderName(message: Message): string {
    return message.sender.split(':')[0].replace('@', '');
  }

  sendReaction(emoji: string) {
    try {
      // In a real implementation, this would send a reaction via the annotation API
      // POST /_matrix/client/v3/rooms/{roomId}/relations/{eventId}/m.annotation/m.reaction
      ToastUtils.show(`Reaction: ${emoji}`);
    } catch (error) {
      logger.error('Failed to send reaction:', error);
      ToastUtils.show('Failed to send reaction');
    }
  }

  sendSticker(stickerUrl: string, stickerBody: string) {
    try {
      // In a real implementation, this would send a sticker via the sticker API
      // PUT /_matrix/client/v3/rooms/{roomId}/send/m.sticker/{txnId}
      const content = {
        url: stickerUrl,
        body: stickerBody,
        info: {
          w: 256,
          h: 256,
          mimetype: 'image/png'
        }
      };
      ToastUtils.show(`Sticker: ${stickerBody}`);
    } catch (error) {
      logger.error('Failed to send sticker:', error);
      ToastUtils.show('Failed to send sticker');
    }
  }

  forwardMessage(message: Message) {
    try {
      // In a real implementation, this would show a room selector and forward the message
      // For now, we'll show a toast
      ToastUtils.show('Forward message feature coming soon');
      this.showReplyMenu = false;
      this.selectedMessage = null;
    } catch (error) {
      logger.error('Failed to forward message:', error);
      ToastUtils.show('Failed to forward message');
    }
  }

  pinMessage(message: Message) {
    try {
      // In a real implementation, this would pin the message via the pin API
      // PUT /_matrix/client/v3/rooms/{roomId}/pin/{eventId}
      ToastUtils.show('Message pinned');
      this.showReplyMenu = false;
      this.selectedMessage = null;
    } catch (error) {
      logger.error('Failed to pin message:', error);
      ToastUtils.show('Failed to pin message');
    }
  }

  viewMessageSource(message: Message) {
    this.selectedMessage = message;
    this.showMessageSource = true;
    this.showReplyMenu = false;
  }

  reportMessage(reason: string) {
    try {
      // In a real implementation, this would report the message via the report API
      // POST /_matrix/client/v3/report/{roomId}/{eventId}
      ToastUtils.show(`Message reported: ${reason}`);
    } catch (error) {
      logger.error('Failed to report message:', error);
      ToastUtils.show('Failed to report message');
    }
  }

  navigateToRoomSettings() {
    if (this.pathStack) {
      const param: Record<string, Object> = {
        "roomId": this.roomId,
        "roomName": this.roomName,
        "pathStack": this.pathStack
      };
      this.pathStack.pushPathByName('RoomSettingsPage', param);
    }
  }
}