/*
 * Copyright (C) 2024  即时通讯网(52im.net) & Jack Jiang.
 * The MobileIMSDK-鸿蒙Next客户端 Project. All rights reserved.
 */

import { ErrorCode, ClientCoreSDK, PKickoutInfo } from 'mobileimsdk/Index'
import { ChatInputView } from './ChatInputView';
import { CustomeTitleBar } from './ChatTitleBar'
import { MsgView_normal } from './msg_view/NormalMsgView';
import { MsgView_system } from './msg_view/SystemMsgView';
import Message from '../model/Message';
import MsgType from '../constants/MsgType';
import MessagesDataSource from '../model/MessagesDataSource';
import IMClientManager from '../../IMClientManager';
import UIEvent from '../constants/UIEvent';
import ToolKits from '../utils/ToolKits';
import { common } from '@kit.AbilityKit';
import { MsgTimeView } from './msg_view/MsgTimeView';
import SessionRepository from '../model/SessionRepository';
import { LayoutMode } from '../utils/DeviceUtil';

const TAG: string = '[ChatPanel] '

/**
 * 聊天面板组件
 * 用于双栏布局的右侧，或单栏布局的全屏显示
 */
@Component
export struct ChatPanel {
  /** 聊天列表的滚动条组件 */
  private scroller: Scroller = new Scroller();

  /** 会话ID */
  @Prop sessionId: string = '';
  
  /** 会话类型（0-单聊，1-群聊） */
  @Prop sessionType: number = 0;
  
  /** 对方昵称 */
  @Prop nickname: string = 'HarmonyChat';
  
  /** 布局模式 */
  @Prop layoutMode: LayoutMode = LayoutMode.SINGLE;
  
  /** 是否显示返回按钮 */
  @Prop showBackButton: boolean = true;
  
  /** 返回按钮点击回调 */
  private onBackClick?: () => void;

  /** 连接状态：false 连接断开、true 连接正常 */
  @State connectStatus: boolean = ClientCoreSDK.getInstance().connectedToServer;
  
  /** 心跳状态 */
  @State keepAliveStatus: boolean = false;

  /** 聊天消息列表对应的数据源对象 */
  messagesDataSource: MessagesDataSource = new MessagesDataSource();

  /** 事件回调 */
  private meessageAddedEventCallback?: Function;
  private meessageUpdateEventCallback?: Function;
  private meessagesUpdateEventCallback?: Function;
  private loginCompleteEventCallback?: Function;
  private disconnectedEventCallback?: Function;
  private keepAliveEventCallback?: Function;
  private kickoutEventCallback?: Function;

  /**
   * 设置返回按钮点击回调
   */
  public setOnBackClick(callback: () => void): void {
    this.onBackClick = callback;
  }

  /**
   * 初始化会话
   */
  public initSession(sessionId: string, sessionType: number, nickname: string): void {
    this.sessionId = sessionId;
    this.sessionType = sessionType;
    this.nickname = nickname;
    
    // 设置当前会话ID，加载对应会话的消息
    if (this.sessionId) {
      IMClientManager.getInstance().getMessageProvider().setCurrentSessionId(this.sessionId);
      // 刷新消息数据源
      this.messagesDataSource.refreshMessages();
      // 进入聊天页面时立即清除未读数
      SessionRepository.getInstance().clearUnreadCount(this.sessionId);
    }
  }

  /**
   * 生命周期中只被调用一次。
   */
  aboutToAppear() {
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
    // 添加一条预定义的系统消息
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
   * 添加事件监听。
   */
  addEvents() {
    // 增加了聊天消息
    IMClientManager.getInstance().getEmitter().on(UIEvent.UIEVENT_messageAdded, this.meessageAddedEventCallback = (index: number) => {
      this.messagesDataSource.notifyDataAdd(index);
      this.scrollToBottom();
    });

    // 更新了聊天消息（单条）
    IMClientManager.getInstance().getEmitter().on(UIEvent.UIEVENT_messageUpdate, this.meessageUpdateEventCallback = (index: number) => {
      this.messagesDataSource.notifyDataChange(index);
    });

    // 更新了聊天消息（多条）
    IMClientManager.getInstance().getEmitter().on(UIEvent.UIEVENT_messagesUpdate, this.meessagesUpdateEventCallback = (updateIndexes: number[]) => {
      this.messagesDataSource.notifyDataReload();
    });

    // 掉线重连完成
    IMClientManager.getInstance().getEmitter().on(UIEvent.UIEVENT_onIMAfterLoginComplete, this.loginCompleteEventCallback = (code: number) => {
      if (code == ErrorCode.COMMON_CODE_OK) {
        this.refreshConnecteStatus();
      }
    });

    // 掉线了
    IMClientManager.getInstance().getEmitter().on(UIEvent.UIEVENT_onIMDisconnected, this.disconnectedEventCallback = () => {
      this.refreshConnecteStatus();
    });

    // 心跳了一次
    IMClientManager.getInstance().getEmitter().on(UIEvent.UIEVENT_onIMPing, this.keepAliveEventCallback = () => {
      this.keepAliveStatus = true;
      setTimeout(() => {
        this.keepAliveStatus = false;
      }, 500);
    });

    // 被踢了
    IMClientManager.getInstance().getEmitter().on(UIEvent.UIEVENT_onKickout, this.kickoutEventCallback = (kickoutInfo: PKickoutInfo) => {
      this.beKickout(kickoutInfo);
    });
  }

  /**
   * 取消事件监听。
   */
  removeEvents() {
    IMClientManager.getInstance().getEmitter().off(UIEvent.UIEVENT_messageAdded, this.meessageAddedEventCallback);
    IMClientManager.getInstance().getEmitter().off(UIEvent.UIEVENT_messageUpdate, this.meessageUpdateEventCallback);
    IMClientManager.getInstance().getEmitter().off(UIEvent.UIEVENT_messagesUpdate, this.meessagesUpdateEventCallback);
    IMClientManager.getInstance().getEmitter().off(UIEvent.UIEVENT_onIMAfterLoginComplete, this.loginCompleteEventCallback);
    IMClientManager.getInstance().getEmitter().off(UIEvent.UIEVENT_onIMDisconnected, this.disconnectedEventCallback);
    IMClientManager.getInstance().getEmitter().off(UIEvent.UIEVENT_onIMPing, this.keepAliveEventCallback);
    IMClientManager.getInstance().getEmitter().off(UIEvent.UIEVENT_onKickout, this.kickoutEventCallback);
  }

  /**
   * 滚动消息列表到最底部。
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
    IMClientManager.getInstance().releaseMobileIMSDK();

    let alertContent: string = '';
    if (kickoutInfo.code === PKickoutInfo.KICKOUT_FOR_DUPLICATE_LOGIN) {
      alertContent = '账号已在其它地方登陆，当前会话已断开，请退出后重新登陆！';
    } else if (kickoutInfo.code === PKickoutInfo.KICKOUT_FOR_ADMIN) {
      alertContent = '已被管理员强行踢出聊天，当前会话已断开！';
    } else {
      alertContent = '你已被踢出聊天，当前会话已断开！';
    }

    ClientCoreSDK.Log.error(TAG + alertContent);

    let primaryAction: Callback<void> = () => {
      this.switchToLoginPage();
    };

    let secondaryAction: Callback<void> = () => {
      let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      ToolKits.exitSystem(context);
    };

    ToolKits.showAlertDialog(alertContent, '重新登录', undefined, primaryAction, '退出应用', $r('sys.color.ohos_id_color_badge_red'), secondaryAction);
  }

  /**
   * 切换到登陆界面。
   */
  switchToLoginPage() {
    IMClientManager.getInstance().initMobileIMSDK(getContext(this).getApplicationContext(), getContext(this).eventHub);
  }

  build() {
    Column() {
      if (this.sessionId) {
        // 有会话时显示聊天界面
        // 聊天界面自定义标题栏
        CustomeTitleBar({ 
          connectStatus: this.connectStatus, 
          keepAliveStatus: this.keepAliveStatus,
          titleName: this.nickname,
          showBackButton: this.showBackButton,
          onBackClick: () => {
            if (this.onBackClick) {
              this.onBackClick();
            }
          }
        })

        // 聊天界面内容区
        Column() {
          List({ scroller: this.scroller }) {
            LazyForEach(this.messagesDataSource, (m: Message, index: number) => {
              ListItem() {
                Column() {
                  MsgTimeView({ message: m })

                  if (m.msgType === MsgType.TYPE_SYSTEAM$INFO) {
                    MsgView_system({ message: m })
                  } else if (m.msgType === MsgType.TYPE_TEXT) {
                    MsgView_normal({ message: m })
                  }
                }
              }
              .margin({ top: index === 0 ? 15 : 0, bottom: 15 })
            }, (m: Message) => MessagesDataSource.messageItemKey(m))
          }
          .onTouch((event: TouchEvent) => {
            ToolKits.hideSoftInputMethod(this.getUIContext());
          })
          .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions) => {
            let oldHeight = oldValue.height, newHeight = newValue.height;
            oldHeight = (oldHeight === undefined ? 0 : oldHeight);
            newHeight = (newHeight === undefined ? 0 : newHeight);
            let toBeSmall = (newHeight > 0 && newHeight < oldHeight);
            if (toBeSmall) {
              this.scrollToBottom();
            }
          })
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          .width("100%")
          .height('100%')
          .layoutWeight(1)
          .listDirection(Axis.Vertical)
        }
        .backgroundColor("#f0f2f6")
        .layoutWeight(1)

        // 底部消息输入区
        ChatInputView({ 
          sessionId: this.sessionId, 
          receiverId: this.sessionId 
        })
      } else {
        // 无会话时显示空状态
        this.EmptyStateView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  /**
   * 空状态视图（未选择会话时显示）
   */
  @Builder
  EmptyStateView() {
    Column() {
      Image($r('app.media.startIcon1'))
        .width(80)
        .height(80)
        .opacity(0.3)
      
      Text('请选择一个聊天')
        .fontSize(16)
        .fontColor('#999999')
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#f5f5f5')
  }
}
