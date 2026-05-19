/*
 * Copyright (C) 2024  即时通讯网(52im.net) & Jack Jiang.
 * The MobileIMSDK-鸿蒙Next客户端 Project. All rights reserved.
 *
 * 联系邮件：jack.jiang@52im.net
 * 联系微信：hellojackjiang
 * 联系QQ： 413980957
 * 技术社区：http://www.52im.net
 */

import { router } from '@kit.ArkUI';
import { ErrorCode, ClientCoreSDK, PKickoutInfo } from 'mobileimsdk/Index';
import Session from './model/Session';
import SessionRepository from './model/SessionRepository';
import { SessionListItem } from './components/SessionListItem';
import IMClientManager from '../IMClientManager';
import UIEvent from './constants/UIEvent';
import ToolKits from './utils/ToolKits';
import { common } from '@kit.AbilityKit';

const TAG: string = '[SessionListPage] ';

/**
 * 会话列表页面。
 * 类似微信聊天列表界面。
 *
 * @author Jack Jiang(http://www.52im.net/thread-2792-1-1.html)
 */
@Entry({ routeName: 'SessionListPage' })
@Component
struct SessionListPage {
  /** 会话数据仓库 */
  private sessionRepository: SessionRepository = SessionRepository.getInstance();
  
  /** 连接状态：false 连接断开、true 连接正常 */
  @State connectStatus: boolean = ClientCoreSDK.getInstance().connectedToServer;
  
  /** 心跳状态：true表示刚刚已发送心跳包 */
  @State keepAliveStatus: boolean = false;
  
  /** 会话列表数据 */
  @State sessions: Session[] = [];
  
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
   * 界面显示时被调用。
   */
  onPageShow(): void {
    // 设置全面屏状态栏颜色
    ToolKits.setStatusBarColor(getContext(this), '#000000', '#ededed');
    // 刷新会话列表数据（从聊天页返回时更新红点状态）
    this.loadSessions();
  }

  /**
   * 加载会话列表数据。
   */
  private loadSessions(): void {
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
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  /**
   * 点击会话项，进入聊天页面。
   */
  onSessionItemClick(session: Session) {
    // 清除未读消息并立即刷新UI
    this.sessionRepository.clearUnreadCount(session.sessionId);
    this.loadSessions();
    
    // 跳转到聊天页面，传递会话参数
    router.pushUrl({
      url: 'pages/ChatPage',
      params: {
        sessionId: session.sessionId,
        sessionType: session.sessionType,
        nickname: session.nickname
      }
    });
  }

  build() {
    Column() {
      // 标题栏
      this.TitleBar()
      
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
  }

  /**
   * 标题栏
   */
  @Builder
  TitleBar() {
    Column() {
      Row() {
        Text('HarmonyChat')
          .fontSize(22)
          .fontColor(Color.Black)
          .fontWeight(500)
        
        Text('鸿蒙')
          .fontFamily('HarmonyHeiTi')
          .fontColor(Color.White)
          .fontSize(11)
          .fontWeight(400)
          .backgroundColor(Color.Black)
          .padding({ top: 3, bottom: 3, left: 4, right: 4 })
          .borderRadius(5)
          .margin({ left: 3 })
      }
      .width('100%')
      .height(56)
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
}
