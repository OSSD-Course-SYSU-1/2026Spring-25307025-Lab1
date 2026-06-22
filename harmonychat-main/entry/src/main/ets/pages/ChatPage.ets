/*
 * Copyright (C) 2024  即时通讯网(52im.net) & Jack Jiang.
 * The MobileIMSDK-鸿蒙Next客户端 Project. All rights reserved.
 *
 * 联系邮件：jack.jiang@52im.net
 * 联系微信：hellojackjiang
 * 联系QQ： 413980957
 * 技术社区：http://www.52im.net
 */

import {ErrorCode, ClientCoreSDK, PKickoutInfo} from 'mobileimsdk/Index'
import { ChatInputView } from './components/ChatInputView';
import { CustomeTitleBar } from './components/ChatTitleBar'
import { MsgView_normal } from './components/msg_view/NormalMsgView';
import { MsgView_system } from './components/msg_view/SystemMsgView';
import { MsgView_file } from './components/msg_view/MsgView_file';
import { NearbyDevice } from './components/NearbyDevice';
import { FilePicker } from './components/FilePicker';
import { FileTransferProgress } from './components/FileTransferProgress';
import { FileReceiveDialog } from './components/FileReceiveDialog';
import { DeviceInfo } from './components/NearbyDevice';
import { FileInfo } from './components/FilePicker';
import FileTransferService from './utils/FileTransferService';
import { TransferTask, TransferStatus } from './utils/FileTransferService';
import Message from './model/Message';
import MsgType from './constants/MsgType';
import MessagesDataSource from './model/MessagesDataSource';
import IMClientManager from '../IMClientManager';
import UIEvent from './constants/UIEvent';
import {router } from '@kit.ArkUI';
import ToolKits from './utils/ToolKits';
import { common } from '@kit.AbilityKit';
import { MsgTimeView } from './components/msg_view/MsgTimeView';
import SessionRepository from './model/SessionRepository';

/**
 * 待接收文件信息
 */
interface PendingFileReceive {
  fileName: string;
  fileSize: number;
  senderName: string;
  senderDevice: string;
}

const TAG: string = '[ChatPage] '

/**
 * 主界面（聊天单页）。
 *
 * @author Jack Jiang(http://www.52im.net/thread-2792-1-1.html)
 */
@Entry
@Component
struct ChatPage {
  /** 聊天列表的滚动条组件 */
  private scroller: Scroller = new Scroller();

  /** 路由参数：会话ID */
  @State sessionId: string = '';
  /** 路由参数：会话类型（0-单聊，1-群聊） */
  @State sessionType: number = 0;
  /** 路由参数：对方昵称 */
  @State nickname: string = 'HarmonyChat';

  /** 连接状态：false 连接断开、true 连接正常 */
  @State connectStatus: boolean = ClientCoreSDK.getInstance().connectedToServer;
  /** 心跳状态：true表示刚刚已发送心跳包，本心跳状态仅仅是为了在ui界面上实现心跳呼吸灯效果 */
  @State keepAliveStatus: boolean = false;

  /** 附近快传相关状态 */
  @State showNearbyDeviceList: boolean = false;
  @State showFilePicker: boolean = false;
  @State showFileTransferProgress: boolean = false;
  @State showFileReceiveDialog: boolean = false;
  @State selectedDevice: DeviceInfo | null = null;
  @State selectedFiles: Array<FileInfo> = [];
  @State currentTransferTask: TransferTask | null = null;
  @State pendingFileReceive: PendingFileReceive | null = null;

  /** 聊天消息列表对应的数据源对象（本对象与MessageProvider配合，用于实现UI界面与数据组的解偶）*/
  messagesDataSource: MessagesDataSource = new MessagesDataSource();

  /** 事件回调：增加了聊天消息 */
  meessageAddedEventCallback?: Function;
  /** 事件回调：更新了聊天消息（单条聊天消息） */
  meessageUpdateEventCallback?: Function;
  /** 事件回调：更新了聊天消息（多条聊天消息） */
  meessagesUpdateEventCallback?: Function;
  /** 事件回调：掉线重连完成 */
  loginCompleteEventCallback?: Function;
  /** 事件回调：掉线了 */
  disconnectedEventCallback?: Function;
  /** 事件回调：心跳了一次 */
  keepAliveEventCallback?: Function;
  /** 事件回调：你被踢了 */
  kickoutEventCallback?: Function;

  /**
   * 生命周期中只被调用一次，类似于iOS中的viewDidLoad、Android中的onCreate.
   */
  aboutToAppear() {
    // 接收路由参数
    try {
      const params = router.getParams() as Record<string, Object>;
      if (params) {
        this.sessionId = (params['sessionId'] as string) ?? '';
        this.sessionType = (params['sessionType'] as number) ?? 0;
        this.nickname = (params['nickname'] as string) ?? 'HarmonyChat';
      }
    } catch (e) {
      console.error(TAG + 'Failed to get router params: ' + JSON.stringify(e));
    }
    
    // 设置当前会话ID，加载对应会话的消息
    if (this.sessionId) {
      IMClientManager.getInstance().getMessageProvider().setCurrentSessionId(this.sessionId);
      // 刷新消息数据源
      this.messagesDataSource.refreshMessages();
      // 进入聊天页面时立即清除未读数
      SessionRepository.getInstance().clearUnreadCount(this.sessionId);
    }
    
    // 添加事件通知
    this.addEvents();
    // 添加一条预定义的系统消息在列表列表里
    IMClientManager.getInstance().getMessageProvider().addSystemMessage('当前通信层，基于鸿蒙NEXT原生WebSocket');
  }

  /**
   * 界面被销毁时被调用。
   */
  aboutToDisappear() {
    // 取消事件通知
    this.removeEvents();
  }

  /**
   * 界面显示时被调用。
   */
  onPageShow(): void {
    // 本界面显示时，将输入法软键盘避让模式设置为KeyboardAvoidMode.RESIZE（即压缩窗体，而不是将窗体整体上移）
    ToolKits.setKeyboardAvoidModeToRESIZE(this.getUIContext(), true);
    // 设置全面屏状态栏颜色
    ToolKits.setStatusBarColor(getContext(this), ToolKits.chat_page_title_color, ToolKits.chat_page_title_background_color);
  }

  /**
   * 界面隐藏时被调用。
   */
  onPageHide(): void {
    // 本界面不显示时，将输入法软键盘避让模式还原为系统默认的KeyboardAvoidMode.OFFSET
    ToolKits.setKeyboardAvoidModeToRESIZE(this.getUIContext(), false);
  }

  /**
   * 添加事件监听。
   */
  addEvents() {
    // 【1】增加了聊天消息
    IMClientManager.getInstance().getEmitter().on(UIEvent.UIEVENT_messageAdded, this.meessageAddedEventCallback = (index: number) => {
      // 通知ListView的数据源，刷新消息显示
      this.messagesDataSource.notifyDataAdd(index);
      // 滚动消息列表至底部（以备显示最新消息）
      this.scrollToBottom();
    });

    // 【2】更新了聊天消息（单条聊天消息）
    IMClientManager.getInstance().getEmitter().on(UIEvent.UIEVENT_messageUpdate, this.meessageUpdateEventCallback = (index: number) => {
      // 通知ListView的数据源，刷新消息显示
      this.messagesDataSource.notifyDataChange(index);
    });

    // 【3】更新了聊天消息（多条聊天消息）
    IMClientManager.getInstance().getEmitter().on(UIEvent.UIEVENT_messagesUpdate, this.meessagesUpdateEventCallback = (updateIndexes: number[]) => {
      // 通知ListView的数据源，刷新消息显示（多条消息就直接reload，这样简单直接）
      this.messagesDataSource.notifyDataReload();
    });

    // 【4】掉线重连完成
    IMClientManager.getInstance().getEmitter().on(UIEvent.UIEVENT_onIMAfterLoginComplete, this.loginCompleteEventCallback = (code: number) => {
      // 登陆或重连成功
      if(code == ErrorCode.COMMON_CODE_OK) {
        this.refreshConnecteStatus();
      }
    });

    // 【5】掉线了
    IMClientManager.getInstance().getEmitter().on(UIEvent.UIEVENT_onIMDisconnected, this.disconnectedEventCallback = () => {
      this.refreshConnecteStatus();
    });

    // 【6】心跳了一次
    IMClientManager.getInstance().getEmitter().on(UIEvent.UIEVENT_onIMPing, this.keepAliveEventCallback = () => {
      this.keepAliveStatus = true;
      setTimeout(() => {
        this.keepAliveStatus = false;
      }, 500);
    });

    // 【7】你被踢了
    IMClientManager.getInstance().getEmitter().on(UIEvent.UIEVENT_onKickout, this.kickoutEventCallback = (kickoutInfo: PKickoutInfo) => {
      this.beKickout(kickoutInfo);
    });
  }

  /**
   * 取消事件监听。
   */
  removeEvents() {
    // 【1】
    IMClientManager.getInstance().getEmitter().off(UIEvent.UIEVENT_messageAdded, this.meessageAddedEventCallback);
    // 【2】
    IMClientManager.getInstance().getEmitter().off(UIEvent.UIEVENT_messageUpdate, this.meessageUpdateEventCallback);
    // 【3】
    IMClientManager.getInstance().getEmitter().off(UIEvent.UIEVENT_messagesUpdate, this.meessagesUpdateEventCallback);
    // 【4】
    IMClientManager.getInstance().getEmitter().off(UIEvent.UIEVENT_onIMAfterLoginComplete, this.loginCompleteEventCallback);
    // 【5】
    IMClientManager.getInstance().getEmitter().off(UIEvent.UIEVENT_onIMDisconnected, this.disconnectedEventCallback);
    // 【6】
    IMClientManager.getInstance().getEmitter().off(UIEvent.UIEVENT_onIMPing, this.keepAliveEventCallback);
    // 【7】
    IMClientManager.getInstance().getEmitter().off(UIEvent.UIEVENT_onKickout, this.kickoutEventCallback);
  }

  /**
   * 滚动消息列表到最底部，以备显示最新消息。
   */
  scrollToBottom() {
    this.scroller.scrollEdge(Edge.Bottom);
  }

  /**
   * 刷新连接状态。
   */
  refreshConnecteStatus() {
    this.connectStatus = ClientCoreSDK.getInstance().connectedToServer;
  }

  /**
   * 被踢的处理逻辑。
   */
  beKickout(kickoutInfo: PKickoutInfo) {
    // 首先释放IM所占资源
    IMClientManager.getInstance().releaseMobileIMSDK();

    // 提示信息
    let alertContent: string = '';
    if (kickoutInfo.code === PKickoutInfo.KICKOUT_FOR_DUPLICATE_LOGIN) {
      alertContent = '账号已在其它地方登陆，当前会话已断开，请退出后重新登陆！';
    } else if (kickoutInfo.code === PKickoutInfo.KICKOUT_FOR_ADMIN) {
      alertContent = '已被管理员强行踢出聊天，当前会话已断开！';
    } else {
      alertContent = '你已被踢出聊天，当前会话已断开（kickoutInfo=' + JSON.stringify(kickoutInfo) + '）！';
    }

    ClientCoreSDK.Log.error(TAG + alertContent);

    // 确认Action
    let primaryAction: Callback<void> = () => {
      this.switchToLoginPage();
    };

    // 取消Action
    let secondaryAction: Callback<void> = () => {
      let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      ToolKits.exitSystem(context);
    };

    // 显示对话框
    ToolKits.showAlertDialog(alertContent, '重新登录', undefined, primaryAction,'退出应用', $r('sys.color.ohos_id_color_badge_red'), secondaryAction);
  }

  /**
   * 切换到登陆界面。
   */
  switchToLoginPage() {
    // init MobileIMSDK first（必须保证此代码被调用，否则IM框架无法完成IM服务器的连接等工作）
    IMClientManager.getInstance().initMobileIMSDK(getContext(this).getApplicationContext(), getContext(this).eventHub);
    // goto login page!
    router.replaceUrl({ url: 'pages/LoginPage', });
  }

  /**
   * 处理附近快传按钮点击
   */
  onNearbyClick() {
    console.log('[ChatPage] Nearby button clicked');
    this.showNearbyDeviceList = true;
  }

  /**
   * 处理设备选择
   */
  onDeviceSelected(deviceId: string, deviceName: string) {
    console.log(`[ChatPage] Device selected: ${deviceName} (${deviceId})`);
    this.selectedDevice = { deviceId, deviceName, deviceType: 0, isOnline: true, isTrusted: true };
    this.showNearbyDeviceList = false;
    this.showFilePicker = true;
  }

  /**
   * 处理文件选择
   */
  onFilesSelected(files: Array<FileInfo>) {
    console.log(`[ChatPage] Files selected: ${files.length} files`);
    this.selectedFiles = files;
    this.showFilePicker = false;
    
    if (files.length > 0 && this.selectedDevice) {
      this.startFileTransfer(files[0]);
    }
  }

  /**
   * 开始文件传输
   */
  async startFileTransfer(fileInfo: FileInfo) {
    try {
      const fileTransferService = FileTransferService.getInstance();
      
      // 初始化分布式数据服务
      const context = getContext(this) as common.UIAbilityContext;
      const initialized = await fileTransferService.initDistributedData(context);
      
      if (!initialized) {
        ToolKits.showToast('分布式服务初始化失败');
        return;
      }
      
      // 开始文件传输
      const taskId = await fileTransferService.sendFile(
        fileInfo.filePath,
        fileInfo.fileName,
        this.selectedDevice!.deviceId,
        this.selectedDevice!.deviceName
      );
      
      // 获取传输任务并显示进度
      const task = fileTransferService.getTransferTask(taskId);
      if (task) {
        this.currentTransferTask = task;
        this.showFileTransferProgress = true;
        
        // 注册进度监听
        fileTransferService.registerProgressListener(taskId, (updatedTask: TransferTask) => {
          this.currentTransferTask = updatedTask;
        });
        
        // 注册状态监听
        fileTransferService.registerStatusListener(taskId, (updatedTask: TransferTask) => {
          this.currentTransferTask = updatedTask;
          
          if (updatedTask.status === TransferStatus.COMPLETED) {
            // 传输完成，添加到聊天记录
            this.addFileMessageToChat(fileInfo, true);
          } else if (updatedTask.status === TransferStatus.FAILED) {
            ToolKits.showToast(`文件传输失败: ${updatedTask.errorMessage}`);
          }
        });
      }
      
    } catch (error) {
      console.error('[ChatPage] Failed to start file transfer: ' + JSON.stringify(error));
      ToolKits.showToast('文件传输启动失败');
    }
  }

  /**
   * 添加文件消息到聊天记录
   */
  addFileMessageToChat(fileInfo: FileInfo, isOutgoing: boolean) {
    const messageProvider = IMClientManager.getInstance().getMessageProvider();
    
    if (isOutgoing) {
      // 发送的文件消息
      const message = Message.createChatMsgEntity_OUTGO_FILE(
        fileInfo.fileName,
        fileInfo.fileSize,
        fileInfo.filePath,
        fileInfo.fileType,
        `file_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
      );
      message.transferStatus = 2; // 传输完成
      messageProvider.putMessage(message);
      
      // 更新会话列表中的最后一条消息
      if (this.sessionId.length > 0) {
        SessionRepository.getInstance().updateLastMessage(this.sessionId, `[文件] ${fileInfo.fileName}`, Date.now());
      }
    } else {
      // 接收的文件消息
      // TODO: 从接收的文件信息中获取发送者信息
      const senderId = 'nearby_device_' + this.selectedDevice?.deviceId || 'unknown';
      const senderName = this.selectedDevice?.deviceName || '附近设备';
      
      const message = Message.createChatMsgEntity_INCOME_FILE(
        senderId,
        senderName,
        fileInfo.fileName,
        fileInfo.fileSize,
        fileInfo.filePath,
        fileInfo.fileType,
        Date.now()
      );
      messageProvider.putMessage(message);
      
      // 更新会话列表中的最后一条消息
      if (this.sessionId.length > 0) {
        SessionRepository.getInstance().updateLastMessage(this.sessionId, `[文件] ${fileInfo.fileName}`, Date.now());
      }
    }
    
    // 滚动到底部显示新消息
    this.scrollToBottom();
  }

  /**
   * 处理文件接收请求
   */
  onFileReceiveRequest(fileName: string, fileSize: number, senderName: string, senderDevice: string) {
    this.pendingFileReceive = {
      fileName,
      fileSize,
      senderName,
      senderDevice
    };
    this.showFileReceiveDialog = true;
  }

  /**
   * 接受文件
   */
  async acceptFile(fileName: string, fileSize: number) {
    try {
      const fileTransferService = FileTransferService.getInstance();
      
      // 模拟接收文件（实际应该从分布式数据服务接收）
      // 这里模拟接收一个文件
      const context = getContext(this) as common.UIAbilityContext;
      
      // 创建模拟文件数据
      const fileData = new ArrayBuffer(1024); // 模拟1KB文件
      
      // 保存文件
      const savedFilePath = await fileTransferService.saveReceivedFile(fileData, fileName, context);
      
      // 添加到聊天记录
      const fileInfo = new FileInfo();
      fileInfo.fileName = fileName;
      fileInfo.fileSize = fileSize;
      fileInfo.filePath = savedFilePath;
      fileInfo.fileType = this.getFileTypeFromName(fileName);
      
      this.addFileMessageToChat(fileInfo, false);
      
      ToolKits.showToast(`文件 ${fileName} 接收成功`);
      
    } catch (error) {
      console.error('[ChatPage] Failed to accept file: ' + JSON.stringify(error));
      ToolKits.showToast('文件接收失败');
    } finally {
      this.showFileReceiveDialog = false;
      this.pendingFileReceive = null;
    }
  }

  /**
   * 拒绝文件接收
   */
  rejectFile() {
    ToolKits.showToast('已拒绝文件接收');
    this.showFileReceiveDialog = false;
    this.pendingFileReceive = null;
  }

  /**
   * 根据文件名获取文件类型
   */
  getFileTypeFromName(fileName: string): string {
    const lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex === -1) {
      return 'other';
    }
    
    const ext = fileName.substring(lastDotIndex + 1).toLowerCase();
    
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].includes(ext)) {
      return 'image';
    } else if (ext === 'txt') {
      return 'text';
    } else if (ext === 'pdf') {
      return 'pdf';
    } else {
      return 'other';
    }
  }

  /**
   * 取消文件传输
   */
  cancelFileTransfer(taskId: string) {
    const fileTransferService = FileTransferService.getInstance();
    const cancelled = fileTransferService.cancelTransfer(taskId);
    
    if (cancelled) {
      ToolKits.showToast('文件传输已取消');
    }
    
    this.showFileTransferProgress = false;
    this.currentTransferTask = null;
  }

  /**
   * 关闭文件传输进度窗口
   */
  closeFileTransferProgress() {
    this.showFileTransferProgress = false;
    this.currentTransferTask = null;
  }

  /**
   * 关闭设备列表
   */
  closeDeviceList() {
    this.showNearbyDeviceList = false;
    this.selectedDevice = null;
  }

  /**
   * 关闭文件选择器
   */
  closeFilePicker() {
    this.showFilePicker = false;
    this.selectedFiles = [];
  }

  /**
   * 关闭文件接收对话框
   */
  closeFileReceiveDialog() {
    this.showFileReceiveDialog = false;
    this.pendingFileReceive = null;
  }


  build() {
    Stack() {
      Column() {
        // 聊天界面自定义标题栏
        CustomeTitleBar({ 
          connectStatus: this.connectStatus, 
          keepAliveStatus: this.keepAliveStatus,
          titleName: this.nickname,
          showBackButton: true,
          onBackClick: () => {
            router.back();
          },
          onNearbyClick: () => {
            this.onNearbyClick();
          }
        })

        // 聊天界面内容区
        Column() {
        // List性能需极致优化的情况下，还可使用“组件复用”技术，详见官方资料：
        // https://developer.huawei.com/consumer/cn/doc/best-practices-V5/bpta-best-practices-long-list-V5#section36781044162218
        List({ scroller: this.scroller }) {
          LazyForEach(this.messagesDataSource, (m: Message, index: number) => {
            ListItem() {
              // 消息item的整体布局
              Column() {
                /* 显示消息时间 */
                MsgTimeView({ message: m })

                /* 显示消息内容 */
                if (m.msgType === MsgType.TYPE_SYSTEAM$INFO) {
                  MsgView_system({ message: m })
                } else if (m.msgType === MsgType.TYPE_TEXT) {
                  MsgView_normal({ message: m })
                } else if (m.msgType === MsgType.TYPE_FILE_IMAGE || 
                          m.msgType === MsgType.TYPE_FILE_TEXT || 
                          m.msgType === MsgType.TYPE_FILE_PDF || 
                          m.msgType === MsgType.TYPE_FILE_OTHER) {
                  MsgView_file({ message: m })
                } else {
                  // TODO: 更多消息类型支持。。。
                }
              }
            }
            // 列表顶部和底部的的空白间隔
            .margin({top: index === 0 ? 8 : 0, bottom: 8})
          }, (m: Message) => MessagesDataSource.messageItemKey(m))// 提示：在List中使用LazyForEach时，响应式ui需要key变化才会更新
        }
        // 监听组件触屏事件，确保触碰聊天列表时，能自动收起输入法软键盘，提升用户体验
        .onTouch((event: TouchEvent) => {
          // 收起软键盘
          ToolKits.hideSoftInputMethod(this.getUIContext());
        })
        // 监听组件大小变化事件（用于实现当软键盘显示时，列表高度被压缩后，消息不能自动显示最后一条的问题）
        .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions) => {
          let oldHeight = oldValue.height, newHeight = newValue.height;
          oldHeight = (oldHeight === undefined ? 0 : oldHeight);
          newHeight = (newHeight === undefined ? 0 : newHeight);
          // 列表高度变小，可以认为是软键盘显示了
          let toBeSmall = (newHeight >0 && newHeight < oldHeight);
          if(toBeSmall) {
            // 消息列表滚动到底部，确保最新一条消息被显示
            this.scrollToBottom();
          }
        })
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .width("100%")
        .layoutWeight(1)
        .listDirection(Axis.Vertical)
      }
      .backgroundColor("#F5F5F5")
      .layoutWeight(1)

      // 底部消息输入区
      ChatInputView({ 
        sessionId: this.sessionId, 
        receiverId: this.sessionId 
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
    // 适配流海屏（顶部状态栏透明并穿过，并透过底部上划操作区）
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

    // 附近设备列表弹窗
    if (this.showNearbyDeviceList) {
      Stack() {
        Column() {
          NearbyDevice({
            onDeviceSelected: (deviceId: string, deviceName: string) => {
              this.onDeviceSelected(deviceId, deviceName);
            },
            onClose: () => {
              this.closeDeviceList();
            }
          })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#00000033')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
    }

    // 文件选择器弹窗
    if (this.showFilePicker) {
      Stack() {
        Column() {
          FilePicker({
            onFilesSelected: (files: Array<FileInfo>) => {
              this.onFilesSelected(files);
            },
            onClose: () => {
              this.closeFilePicker();
            }
          })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#00000033')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
    }

    // 文件传输进度弹窗
    if (this.showFileTransferProgress && this.currentTransferTask) {
      Stack() {
        Column() {
          FileTransferProgress({
            task: this.currentTransferTask,
            onCancel: (taskId: string) => {
              this.cancelFileTransfer(taskId);
            },
            onClose: () => {
              this.closeFileTransferProgress();
            }
          })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#00000033')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
    }

    // 文件接收确认对话框
    if (this.showFileReceiveDialog && this.pendingFileReceive) {
      Stack() {
        Column() {
          FileReceiveDialog({
            showDialog: this.showFileReceiveDialog,
            fileName: this.pendingFileReceive.fileName,
            fileSize: this.pendingFileReceive.fileSize,
            senderName: this.pendingFileReceive.senderName,
            senderDevice: this.pendingFileReceive.senderDevice,
            onAccept: (fileName: string, fileSize: number) => {
              this.acceptFile(fileName, fileSize);
            },
            onReject: () => {
              this.rejectFile();
            },
            onClose: () => {
              this.closeFileReceiveDialog();
            }
          })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#00000033')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
    }
  }
  }


}
