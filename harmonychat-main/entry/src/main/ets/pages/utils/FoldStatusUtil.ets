/*
 * Copyright (C) 2024  即时通讯网(52im.net) & Jack Jiang.
 * The MobileIMSDK-鸿蒙Next客户端 Project. All rights reserved.
 */

import { display } from '@kit.ArkUI';
import { DeviceUtil, FoldStatus, LayoutMode } from './DeviceUtil';

/**
 * 折叠屏状态变化回调类型
 */
export type OnFoldStatusChangeCallback = (foldStatus: FoldStatus, layoutMode: LayoutMode) => void;

/**
 * 窗口尺寸变化回调类型
 */
export type OnWindowSizeChangeCallback = (width: number, height: number, breakpoint: string) => void;

/**
 * 折叠屏状态监听工具类
 * 用于监听折叠屏状态变化和窗口尺寸变化
 */
export class FoldStatusUtil {
  private static instance: FoldStatusUtil;
  
  /** 折叠屏状态变化监听器 */
  private foldStatusChangeCallbacks: Set<OnFoldStatusChangeCallback> = new Set();
  
  /** 窗口尺寸变化监听器 */
  private windowSizeChangeCallbacks: Set<OnWindowSizeChangeCallback> = new Set();
  
  /** 显示模式变化监听器 */
  private displayModeChangeCallback: ((displayMode: display.FoldDisplayMode) => void) | null = null;
  
  /** 当前窗口宽度 */
  private currentWidth: number = 0;
  
  /** 当前窗口高度 */
  private currentHeight: number = 0;
  
  /** 当前断点 */
  private currentBreakpoint: string = 'sm';

  private constructor() {}

  /**
   * 获取单例实例
   */
  public static getInstance(): FoldStatusUtil {
    if (!FoldStatusUtil.instance) {
      FoldStatusUtil.instance = new FoldStatusUtil();
    }
    return FoldStatusUtil.instance;
  }

  /**
   * 注册折叠屏状态变化监听
   */
  public registerFoldStatusListener(): void {
    const deviceUtil = DeviceUtil.getInstance();
    
    if (!deviceUtil.isFoldableDevice()) {
      return;
    }

    try {
      // 监听显示模式变化（内屏/外屏切换）
      this.displayModeChangeCallback = (displayMode: display.FoldDisplayMode) => {
        deviceUtil.updateFoldStatus();
        const foldStatus = deviceUtil.getFoldStatus();
        const layoutMode = deviceUtil.getLayoutMode();
        this.notifyFoldStatusChange(foldStatus, layoutMode);
      };
      
      display.on('foldDisplayModeChange', this.displayModeChangeCallback);
    } catch (e) {
      console.error('[FoldStatusUtil] Failed to register fold status listener: ' + JSON.stringify(e));
    }
  }

  /**
   * 取消折叠屏状态变化监听
   */
  public unregisterFoldStatusListener(): void {
    if (this.displayModeChangeCallback) {
      try {
        display.off('foldDisplayModeChange', this.displayModeChangeCallback);
        this.displayModeChangeCallback = null;
      } catch (e) {
        console.error('[FoldStatusUtil] Failed to unregister fold status listener: ' + JSON.stringify(e));
      }
    }
  }

  /**
   * 添加折叠屏状态变化回调
   */
  public addFoldStatusChangeCallback(callback: OnFoldStatusChangeCallback): void {
    this.foldStatusChangeCallbacks.add(callback);
  }

  /**
   * 移除折叠屏状态变化回调
   */
  public removeFoldStatusChangeCallback(callback: OnFoldStatusChangeCallback): void {
    this.foldStatusChangeCallbacks.delete(callback);
  }

  /**
   * 添加窗口尺寸变化回调
   */
  public addWindowSizeChangeCallback(callback: OnWindowSizeChangeCallback): void {
    this.windowSizeChangeCallbacks.add(callback);
  }

  /**
   * 移除窗口尺寸变化回调
   */
  public removeWindowSizeChangeCallback(callback: OnWindowSizeChangeCallback): void {
    this.windowSizeChangeCallbacks.delete(callback);
  }

  /**
   * 通知折叠屏状态变化
   */
  private notifyFoldStatusChange(foldStatus: FoldStatus, layoutMode: LayoutMode): void {
    this.foldStatusChangeCallbacks.forEach(callback => {
      try {
        callback(foldStatus, layoutMode);
      } catch (e) {
        console.error('[FoldStatusUtil] Callback error: ' + JSON.stringify(e));
      }
    });
  }

  /**
   * 通知窗口尺寸变化
   */
  public notifyWindowSizeChange(width: number, height: number): void {
    this.currentWidth = width;
    this.currentHeight = height;
    
    // 计算断点
    const newBreakpoint = this.calculateBreakpoint(width);
    const breakpointChanged = newBreakpoint !== this.currentBreakpoint;
    this.currentBreakpoint = newBreakpoint;
    
    this.windowSizeChangeCallbacks.forEach(callback => {
      try {
        callback(width, height, newBreakpoint);
      } catch (e) {
        console.error('[FoldStatusUtil] Window size callback error: ' + JSON.stringify(e));
      }
    });

    // 如果断点变化，也需要通知布局模式可能变化
    if (breakpointChanged) {
      const deviceUtil = DeviceUtil.getInstance();
      deviceUtil.updateFoldStatus();
    }
  }

  /**
   * 计算断点
   */
  private calculateBreakpoint(width: number): string {
    if (width >= 840) {
      return 'lg';
    } else if (width >= 600) {
      return 'md';
    } else {
      return 'sm';
    }
  }

  /**
   * 获取当前窗口宽度
   */
  public getCurrentWidth(): number {
    return this.currentWidth;
  }

  /**
   * 获取当前窗口高度
   */
  public getCurrentHeight(): number {
    return this.currentHeight;
  }

  /**
   * 获取当前断点
   */
  public getCurrentBreakpoint(): string {
    return this.currentBreakpoint;
  }

  /**
   * 清理所有监听器
   */
  public cleanup(): void {
    this.unregisterFoldStatusListener();
    this.foldStatusChangeCallbacks.clear();
    this.windowSizeChangeCallbacks.clear();
  }
}
