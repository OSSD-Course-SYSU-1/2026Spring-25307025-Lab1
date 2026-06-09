/*
 * Copyright (C) 2024  即时通讯网(52im.net) & Jack Jiang.
 * The MobileIMSDK-鸿蒙Next客户端 Project. All rights reserved.
 */

import { router } from '@kit.ArkUI';
import { window } from '@kit.ArkUI';
import Session from './model/Session';
import SessionRepository from './model/SessionRepository';
import { SessionListPanel } from './components/SessionListPanel';
import { ChatPanel } from './components/ChatPanel';
import { DeviceUtil, DeviceType, LayoutMode, BreakpointUtil } from './utils/DeviceUtil';
import { FoldStatusUtil } from './utils/FoldStatusUtil';
import ToolKits from './utils/ToolKits';

const TAG: string = '[MainPage] ';

/**
 * 多端自适应主页面
 * 
 * 根据设备类型和折叠屏状态自动切换布局：
 * - 手机：单栏布局，使用页面跳转
 * - 折叠屏折叠态：单栏布局，使用页面跳转
 * - 折叠屏展开态：双栏布局，左侧会话列表，右侧聊天窗口
 * - 平板：双栏布局，30%:70%
 */
@Entry({ routeName: 'MainPage' })
@Component
struct MainPage {
  /** 设备工具类 */
  private deviceUtil: DeviceUtil = DeviceUtil.getInstance();
  
  /** 折叠屏监听工具类 */
  private foldStatusUtil: FoldStatusUtil = FoldStatusUtil.getInstance();
  
  /** 会话数据仓库 */
  private sessionRepository: SessionRepository = SessionRepository.getInstance();
  
  /** 当前布局模式 */
  @State layoutMode: LayoutMode = LayoutMode.SINGLE;
  
  /** 当前断点 */
  @State currentBreakpoint: string = 'sm';
  
  /** 左侧面板宽度 */
  @State leftPanelWidth: string = '100%';
  
  /** 当前选中的会话 */
  @State selectedSession: Session | null = null;
  
  /** 是否显示聊天面板（双栏模式） */
  @State showChatPanel: boolean = false;
  
  /** 窗口对象 */
  private mainWindow: window.Window | null = null;
  
  /** 窗口尺寸变化回调 */
  private windowSizeChangeCallback: ((size: window.Size) => void) | null = null;
  
  /** 折叠屏状态变化回调 */
  private foldStatusChangeCallback: ((foldStatus: string, layoutMode: LayoutMode) => void) | null = null;

  /**
   * 生命周期：页面即将显示
   */
  aboutToAppear() {
    // 初始化设备信息
    this.initDeviceInfo();
    
    // 注册窗口尺寸变化监听
    this.registerWindowSizeListener();
    
    // 注册折叠屏状态变化监听
    this.registerFoldStatusListener();
    
    // 输出设备信息（调试用）
    console.info(TAG + this.deviceUtil.getDeviceInfo());
  }

  /**
   * 生命周期：页面即将消失
   */
  aboutToDisappear() {
    // 取消窗口尺寸变化监听
    this.unregisterWindowSizeListener();
    
    // 取消折叠屏状态变化监听
    this.unregisterFoldStatusListener();
  }

  /**
   * 页面显示时
   */
  onPageShow(): void {
    // 设置状态栏颜色
    ToolKits.setStatusBarColor(getContext(this), '#000000', '#ededed');
    
    // 如果是单栏模式且有选中的会话，刷新会话列表（从聊天页返回时）
    if (this.layoutMode === LayoutMode.SINGLE) {
      // 单栏模式下，清空选中状态
      this.selectedSession = null;
    }
  }

  /**
   * 初始化设备信息
   */
  private initDeviceInfo(): void {
    // 更新折叠屏状态
    this.deviceUtil.updateFoldStatus();
    
    // 设置初始布局模式
    this.updateLayoutMode();
    
    // 设置左侧面板宽度
    this.leftPanelWidth = this.deviceUtil.getLeftPanelWidth();
  }

  /**
   * 更新布局模式
   */
  private updateLayoutMode(): void {
    const newLayoutMode = this.deviceUtil.getLayoutMode();
    
    if (newLayoutMode !== this.layoutMode) {
      console.info(TAG + `Layout mode changed: ${this.layoutMode} -> ${newLayoutMode}`);
      this.layoutMode = newLayoutMode;
      
      // 布局模式变化时的处理
      if (newLayoutMode === LayoutMode.SINGLE) {
        // 切换到单栏模式，清空选中状态
        this.selectedSession = null;
        this.showChatPanel = false;
      }
    }
  }

  /**
   * 注册窗口尺寸变化监听
   */
  private registerWindowSizeListener(): void {
    try {
      // 获取主窗口（异步）
      window.getLastWindow(getContext(this)).then((windowObj: window.Window) => {
        this.mainWindow = windowObj;
        
        // 设置窗口尺寸变化回调
        this.windowSizeChangeCallback = (size: window.Size) => {
          const width = size.width;
          const height = size.height;
          
          // 更新屏幕方向
          this.deviceUtil.updateScreenOrientation(width, height);
          
          // 更新断点
          this.currentBreakpoint = BreakpointUtil.getBreakpoint(width);
          
          // 通知 FoldStatusUtil
          this.foldStatusUtil.notifyWindowSizeChange(width, height);
          
          // 根据断点判断是否需要切换布局模式
          // 对于非折叠屏设备，使用断点来判断布局模式
          if (this.deviceUtil.getDeviceType() !== DeviceType.FOLDABLE) {
            const shouldUseDouble = BreakpointUtil.shouldUseDoubleColumn(this.currentBreakpoint);
            const newLayoutMode = shouldUseDouble ? LayoutMode.DOUBLE : LayoutMode.SINGLE;
            
            if (newLayoutMode !== this.layoutMode) {
              this.layoutMode = newLayoutMode;
              this.leftPanelWidth = this.deviceUtil.getLeftPanelWidth();
            }
          }
          
          // 更新左侧面板宽度（考虑屏幕方向）
          this.leftPanelWidth = this.deviceUtil.getLeftPanelWidth();
        };
        
        // 注册监听
        this.mainWindow.on('windowSizeChange', this.windowSizeChangeCallback);
        
        // 立即获取一次当前窗口尺寸
        const properties = this.mainWindow.getWindowProperties();
        const initialWidth = properties.windowRect.width;
        const initialHeight = properties.windowRect.height;
        this.currentBreakpoint = BreakpointUtil.getBreakpoint(initialWidth);
        
        // 初始化屏幕方向
        this.deviceUtil.updateScreenOrientation(initialWidth, initialHeight);
        this.leftPanelWidth = this.deviceUtil.getLeftPanelWidth();
      }).catch((e: Error) => {
        console.error(TAG + 'Failed to get window: ' + JSON.stringify(e));
      });
    } catch (e) {
      console.error(TAG + 'Failed to register window size listener: ' + JSON.stringify(e));
    }
  }

  /**
   * 取消窗口尺寸变化监听
   */
  private unregisterWindowSizeListener(): void {
    if (this.mainWindow && this.windowSizeChangeCallback) {
      try {
        this.mainWindow.off('windowSizeChange', this.windowSizeChangeCallback);
      } catch (e) {
        console.error(TAG + 'Failed to unregister window size listener: ' + JSON.stringify(e));
      }
    }
  }

  /**
   * 注册折叠屏状态变化监听
   */
  private registerFoldStatusListener(): void {
    // 注册系统级监听
    this.foldStatusUtil.registerFoldStatusListener();
    
    // 设置回调
    this.foldStatusChangeCallback = (foldStatus: string, layoutMode: LayoutMode) => {
      console.info(TAG + `Fold status changed: ${foldStatus}, layout mode: ${layoutMode}`);
      
      // 更新设备信息
      this.deviceUtil.updateFoldStatus();
      
      // 更新布局模式
      this.updateLayoutMode();
      
      // 更新左侧面板宽度
      this.leftPanelWidth = this.deviceUtil.getLeftPanelWidth();
    };
    
    this.foldStatusUtil.addFoldStatusChangeCallback(this.foldStatusChangeCallback);
  }

  /**
   * 取消折叠屏状态变化监听
   */
  private unregisterFoldStatusListener(): void {
    if (this.foldStatusChangeCallback) {
      this.foldStatusUtil.removeFoldStatusChangeCallback(this.foldStatusChangeCallback);
    }
    this.foldStatusUtil.unregisterFoldStatusListener();
  }

  build() {
    if (this.layoutMode === LayoutMode.DOUBLE) {
      // 双栏布局
      this.DoubleColumnLayout()
    } else {
      // 单栏布局
      this.SingleColumnLayout()
    }
  }

  /**
   * 单栏布局（手机、折叠屏折叠态）
   */
  @Builder
  SingleColumnLayout() {
    // 单栏模式直接显示会话列表
    SessionListPanel({
      selectedSessionId: this.selectedSession?.sessionId ?? '',
      layoutMode: LayoutMode.SINGLE,
      showTitleBar: true,
      onSessionSelected: (session: Session) => {
        // 单栏模式：跳转到聊天页面
        this.sessionRepository.clearUnreadCount(session.sessionId);
        router.pushUrl({
          url: 'pages/ChatPage',
          params: {
            sessionId: session.sessionId,
            sessionType: session.sessionType,
            nickname: session.nickname
          }
        });
      }
    })
  }

  /**
   * 双栏布局（平板、折叠屏展开态）
   */
  @Builder
  DoubleColumnLayout() {
    Row() {
      // 左侧：会话列表
      Column() {
        SessionListPanel({
          selectedSessionId: this.selectedSession?.sessionId ?? '',
          layoutMode: LayoutMode.DOUBLE,
          showTitleBar: true,
          onSessionSelected: (session: Session) => {
            // 双栏模式：在右侧显示聊天面板
            this.selectedSession = session;
            this.showChatPanel = true;
          }
        })
      }
      .width(this.leftPanelWidth)
      .height('100%')
      
      // 分隔线
      Divider()
        .vertical(true)
        .width(0.5)
        .color('#e0e0e0')
        .height('100%')
      
      // 右侧：聊天面板
      Column() {
        if (this.showChatPanel && this.selectedSession) {
          ChatPanel({
            sessionId: this.selectedSession.sessionId,
            sessionType: this.selectedSession.sessionType,
            nickname: this.selectedSession.nickname,
            layoutMode: LayoutMode.DOUBLE,
            showBackButton: false
          })
        } else {
          // 未选择会话时的空状态
          this.EmptyChatView()
        }
      }
      .layoutWeight(1)
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 空聊天视图（未选择会话时）
   */
  @Builder
  EmptyChatView() {
    Column() {
      Image($r('app.media.startIcon1'))
        .width(100)
        .height(100)
        .opacity(0.3)
      
      Text('请选择一个聊天')
        .fontSize(18)
        .fontColor('#999999')
        .margin({ top: 20 })
      
      Text('从左侧列表选择会话开始聊天')
        .fontSize(14)
        .fontColor('#cccccc')
        .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#f5f5f5')
  }
}
