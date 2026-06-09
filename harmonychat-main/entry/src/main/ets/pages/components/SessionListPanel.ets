/*
 * Copyright (C) 2024  即时通讯网(52im.net) & Jack Jiang.
 * The MobileIMSDK-鸿蒙Next客户端 Project. All rights reserved.
 */

import { ErrorCode, ClientCoreSDK, PKickoutInfo } from 'mobileimsdk/Index';
import Session from '../model/Session';
import SessionRepository from '../model/SessionRepository';
import { SessionListItem } from './SessionListItem';
import { NewChatDialog } from './NewChatDialog';
import IMClientManager from '../../IMClientManager';
import UIEvent from '../constants/UIEvent';
import ToolKits from '../utils/ToolKits';
import { common } from '@kit.AbilityKit';
import { LayoutMode } from '../utils/DeviceUtil';

const TAG: string = '[SessionListPanel] ';

/**
 * 会话列表面板组件
 * 用于双栏布局的左侧，或单栏布局的全屏显示
 */
@Component
export struct SessionListPanel {
  /** 会话数据仓库 */
  private sessionRepository: SessionRepository = SessionRepository.getInstance();
  
  /** 连接状态：false 连接断开、true 连接正常 */
  @State connectStatus: boolean = ClientCoreSDK.getInstance().connectedToServer;
  
  /** 心跳状态：true表示刚刚已发送心跳包 */
  @State keepAliveStatus: boolean = false;
  
  /** 会话列表数据 */
  @State sessions: Session[] = [];
  
  /** 当前选中的会话ID */
  @Prop selectedSessionId: string = '';
  
  /** 布局模式 */
  @Prop layoutMode: LayoutMode = LayoutMode.SINGLE;
  
  /** 是否显示标题栏（双栏模式可能不需要） */
  @Prop showTitleBar: boolean = true;
  
  /** 会话选中回调 */
  onSessionSelected?: (session: Session) => void;
  
  /** 新建聊天对话框控制器 */
  private newChatDialogController: CustomDialogController = new CustomDialogController({
    builder: NewChatDialog({
      onConfirm: (uid: string) => {
        this.createNewChat(uid);
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true,
    backgroundColor: Color.Transparent,
    cornerRadius: 16,
  });
  
  /** 事件回调 */
  private loginCompleteEventCallback?: Function;
  private disconnectedEventCallback?: Function;
  private keepAliveEventCallback?: Function;
  private kickoutEventCallback?: Function;

  /**
   * 生命周期中只被调用一次。
   */
  aboutToAppear() {
    // 加载会话列表数据
    this.loadSessions();
    
    // 设置数据变化监听
    this.sessionRepository.setDataChangeListener(() => {
      this.loadSessions();
    });
    
    // 添加事件监听
    this.addEvents();
  }

  /**
   * 界面被销毁时被调用。
   */
  aboutToDisappear() {
    // 移除数据变化监听
    this.sessionRepository.setDataChangeListener(null);
    
    // 取消事件监听
    this.removeEvents();
  }

  /**
   * 加载会话列表数据。
   */
  public loadSessions(): void {
    this.sessions = this.sessionRepository.getAllSessions();
  }

  /**
   * 添加事件监听。
   */
  addEvents() {
    // 掉线重连完成
    IMClientManager.getInstance().getEmitter().on(UIEvent.UIEVENT_onIMAfterLoginComplete, 
      this.loginCompleteEventCallback = (code: number) => {
        if (code == ErrorCode.COMMON_CODE_OK) {
          this.connectStatus = true;
        }
      });

    // 掉线了
    IMClientManager.getInstance().getEmitter().on(UIEvent.UIEVENT_onIMDisconnected, 
      this.disconnectedEventCallback = () => {
        this.connectStatus = false;
      });

    // 心跳了一次
    IMClientManager.getInstance().getEmitter().on(UIEvent.UIEVENT_onIMPing, 
      this.keepAliveEventCallback = () => {
        this.keepAliveStatus = true;
        setTimeout(() => {
          this.keepAliveStatus = false;
        }, 500);
      });

    // 被踢了
    IMClientManager.getInstance().getEmitter().on(UIEvent.UIEVENT_onKickout, 
      this.kickoutEventCallback = (kickoutInfo: PKickoutInfo) => {
        this.beKickout(kickoutInfo);
      });
  }

  /**
   * 取消事件监听。
   */
  removeEvents() {
    IMClientManager.getInstance().getEmitter().off(UIEvent.UIEVENT_onIMAfterLoginComplete, this.loginCompleteEventCallback);
    IMClientManager.getInstance().getEmitter().off(UIEvent.UIEVENT_onIMDisconnected, this.disconnectedEventCallback);
    IMClientManager.getInstance().getEmitter().off(UIEvent.UIEVENT_onIMPing, this.keepAliveEventCallback);
    IMClientManager.getInstance().getEmitter().off(UIEvent.UIEVENT_onKickout, this.kickoutEventCallback);
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
    // 这里不直接跳转，由外部处理
  }

  /**
   * 点击会话项。
   */
  onSessionItemClick(session: Session) {
    // 清除未读消息并立即刷新UI
    this.sessionRepository.clearUnreadCount(session.sessionId);
    this.loadSessions();
    
    // 通知外部会话被选中
    if (this.onSessionSelected) {
      this.onSessionSelected(session);
    }
  }

  /**
   * 删除会话。
   */
  onSessionDelete(session: Session) {
    AlertDialog.show({
      message: `确定删除与${session.nickname}的会话吗？`,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: '#fa5151',
        action: () => {
          this.sessionRepository.deleteSession(session.sessionId);
          this.loadSessions();
        }
      }
    });
  }

  /**
   * 创建新会话。
   */
  private createNewChat(uid: string): void {
    // 检查是否已存在该会话
    const existingSession = this.sessionRepository.getSessionById(uid);
    if (existingSession) {
      // 已存在，直接选中
      this.onSessionItemClick(existingSession);
      return;
    }

    // 创建新会话
    const newSession = Session.createPrivateSession(
      uid,
      `用户${uid}`,
      $r('app.media.startIcon1'),
      '开始聊天吧',
      Date.now(),
      0
    );

    // 添加到会话仓库
    this.sessionRepository.addOrUpdateSession(newSession);
    
    // 刷新列表
    this.loadSessions();
    
    // 自动选中新创建的会话
    this.onSessionItemClick(newSession);
  }

  /**
   * 显示新建聊天对话框。
   */
  private showNewChatDialog(): void {
    this.newChatDialogController.open();
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // 主内容区域
      Column() {
        // 标题栏（可选）
        if (this.showTitleBar) {
          this.TitleBar()
        }
        
        // 网络状态提示
        this.NetworkStatusView()
        
        // 会话列表
        if (this.sessions.length > 0) {
          List() {
            ForEach(this.sessions, (session: Session, index: number) => {
              ListItem() {
                Column() {
                  SessionListItem({
                    session: session,
                    onItemClick: (s: Session) => {
                      this.onSessionItemClick(s);
                    },
                    onDelete: (s: Session) => {
                      this.onSessionDelete(s);
                    }
                  })
                  
                  // 分隔线
                  Divider()
                    .width('100%')
                    .height(0.5)
                    .color('#f0f0f0')
                    .margin({ left: 72 })
                }
              }
              // 选中状态背景
              .backgroundColor(session.sessionId === this.selectedSessionId ? '#e8e8e8' : Color.Transparent)
            }, (session: Session) => session.getKey())
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor('#f5f5f5')
          .listDirection(Axis.Vertical)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        } else {
          // 空状态
          this.EmptyView()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#ededed')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      // 悬浮按钮（FAB）
      this.FloatingActionButton()
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 标题栏
   */
  @Builder
  TitleBar() {
    Column() {
      Row() {
        Text('HarmonyChat')
          .fontSize(this.layoutMode === LayoutMode.DOUBLE ? 18 : 22)
          .fontColor(Color.Black)
          .fontWeight(500)
        
        Text('鸿蒙')
          .fontFamily('HarmonyHeiTi')
          .fontColor(Color.White)
          .fontSize(this.layoutMode === LayoutMode.DOUBLE ? 9 : 11)
          .fontWeight(400)
          .backgroundColor(Color.Black)
          .padding({ top: 2, bottom: 2, left: 3, right: 3 })
          .borderRadius(4)
          .margin({ left: 3 })
      }
      .width('100%')
      .height(this.layoutMode === LayoutMode.DOUBLE ? 48 : 56)
      .padding({ left: 12, right: 12 })
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .backgroundColor('#ededed')
  }

  /**
   * 网络状态提示
   */
  @Builder
  NetworkStatusView() {
    Row() {
      LoadingProgress()
        .width(20)
        .height(20)
        .margin({ right: 8 })
        .color('#ff6434')
      
      Text('网络不给力，正在努力恢复中…')
        .maxLines(1)
        .fontColor('#ff6434')
        .fontSize(14)
    }
    .width('100%')
    .height(40)
    .backgroundColor('#fff0eb')
    .justifyContent(FlexAlign.Center)
    .visibility(this.connectStatus ? Visibility.None : Visibility.Visible)
    .animation({
      duration: 250,
      curve: Curve.EaseInOut,
      iterations: 1,
      playMode: PlayMode.Normal
    })
  }

  /**
   * 空状态视图
   */
  @Builder
  EmptyView() {
    Column() {
      Image($r('app.media.startIcon1'))
        .width(80)
        .height(80)
        .opacity(0.3)
      
      Text('暂无会话')
        .fontSize(16)
        .fontColor('#999999')
        .margin({ top: 16 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#f5f5f5')
  }

  /**
   * 悬浮按钮（FAB）
   */
  @Builder
  FloatingActionButton() {
    Column() {
      Button({ type: ButtonType.Circle }) {
        Text('+')
          .fontSize(28)
          .fontColor(Color.White)
          .fontWeight(500)
      }
      .width(this.layoutMode === LayoutMode.DOUBLE ? 48 : 56)
      .height(this.layoutMode === LayoutMode.DOUBLE ? 48 : 56)
      .backgroundColor('#07c160')
      .shadow({
        radius: 12,
        color: 'rgba(0, 0, 0, 0.2)',
        offsetX: 0,
        offsetY: 4
      })
      .onClick(() => {
        this.showNewChatDialog();
      })
    }
    .margin({ right: 16, bottom: 24 })
  }
}
