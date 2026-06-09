/*
 * Copyright (C) 2024  即时通讯网(52im.net) & Jack Jiang.
 * The MobileIMSDK-鸿蒙Next客户端 Project. All rights reserved.
 */

import { deviceInfo } from '@kit.BasicServicesKit';
import { display } from '@kit.ArkUI';

/**
 * 屏幕方向枚举
 */
export enum ScreenOrientation {
  PORTRAIT = 'portrait',      // 竖屏
  LANDSCAPE = 'landscape',    // 横屏
  UNKNOWN = 'unknown'         // 未知
}

/**
 * 设备类型枚举
 */
export enum DeviceType {
  PHONE = 'phone',        // 手机
  TABLET = 'tablet',      // 平板
  FOLDABLE = 'foldable',  // 折叠屏
  PC = '2in1',           // PC/2in1
  UNKNOWN = 'unknown'     // 未知
}

/**
 * 折叠屏状态枚举
 */
export enum FoldStatus {
  FOLDED = 'folded',      // 折叠态
  UNFOLDED = 'unfolded',  // 展开态
  HALF_FOLDED = 'half',   // 半折态（悬停）
  UNKNOWN = 'unknown'     // 未知（非折叠屏）
}

/**
 * 布局模式枚举
 */
export enum LayoutMode {
  SINGLE = 'single',      // 单栏布局（手机模式）
  DOUBLE = 'double'       // 双栏布局（平板/折叠屏展开态）
}

/**
 * 设备检测工具类
 * 用于检测设备类型、折叠屏状态，并决定布局模式
 */
export class DeviceUtil {
  private static instance: DeviceUtil;
  private currentDeviceType: DeviceType = DeviceType.UNKNOWN;
  private currentFoldStatus: FoldStatus = FoldStatus.UNKNOWN;
  private isFoldable: boolean = false;
  private screenOrientation: ScreenOrientation = ScreenOrientation.UNKNOWN;

  private constructor() {
    this.initDeviceType();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): DeviceUtil {
    if (!DeviceUtil.instance) {
      DeviceUtil.instance = new DeviceUtil();
    }
    return DeviceUtil.instance;
  }

  /**
   * 初始化设备类型
   */
  private initDeviceType(): void {
    const type = deviceInfo.deviceType;
    
    // 检测是否为折叠屏设备
    try {
      this.isFoldable = display.isFoldable();
    } catch (e) {
      this.isFoldable = false;
    }

    if (this.isFoldable) {
      this.currentDeviceType = DeviceType.FOLDABLE;
      this.updateFoldStatus();
    } else if (type === 'phone') {
      this.currentDeviceType = DeviceType.PHONE;
    } else if (type === 'tablet') {
      this.currentDeviceType = DeviceType.TABLET;
    } else if (type === '2in1') {
      this.currentDeviceType = DeviceType.PC;
    } else {
      this.currentDeviceType = DeviceType.UNKNOWN;
    }
  }

  /**
   * 更新折叠屏状态
   */
  public updateFoldStatus(): void {
    if (!this.isFoldable) {
      this.currentFoldStatus = FoldStatus.UNKNOWN;
      return;
    }

    try {
      const status = display.getFoldStatus();
      switch (status) {
        case display.FoldStatus.FOLD_STATUS_FOLDED:
          this.currentFoldStatus = FoldStatus.FOLDED;
          break;
        case display.FoldStatus.FOLD_STATUS_EXPANDED:
          this.currentFoldStatus = FoldStatus.UNFOLDED;
          break;
        case display.FoldStatus.FOLD_STATUS_HALF_FOLDED:
          this.currentFoldStatus = FoldStatus.HALF_FOLDED;
          break;
        default:
          this.currentFoldStatus = FoldStatus.UNKNOWN;
      }
    } catch (e) {
      this.currentFoldStatus = FoldStatus.UNKNOWN;
    }
  }

  /**
   * 获取当前设备类型
   */
  public getDeviceType(): DeviceType {
    return this.currentDeviceType;
  }

  /**
   * 获取当前折叠屏状态
   */
  public getFoldStatus(): FoldStatus {
    return this.currentFoldStatus;
  }

  /**
   * 是否为折叠屏设备
   */
  public isFoldableDevice(): boolean {
    return this.isFoldable;
  }

  /**
   * 判断是否应该使用双栏布局
   * 规则：
   * - 平板：始终使用双栏布局
   * - 折叠屏：展开态使用双栏布局，折叠态使用单栏布局
   * - 手机：始终使用单栏布局
   */
  public shouldUseDoubleColumn(): boolean {
    switch (this.currentDeviceType) {
      case DeviceType.TABLET:
        return true;
      case DeviceType.PC:
        return true;
      case DeviceType.FOLDABLE:
        // 折叠屏展开态使用双栏布局
        return this.currentFoldStatus === FoldStatus.UNFOLDED || 
               this.currentFoldStatus === FoldStatus.HALF_FOLDED;
      case DeviceType.PHONE:
      default:
        return false;
    }
  }

  /**
   * 获取当前布局模式
   */
  public getLayoutMode(): LayoutMode {
    return this.shouldUseDoubleColumn() ? LayoutMode.DOUBLE : LayoutMode.SINGLE;
  }

  /**
   * 更新屏幕方向
   * @param width 屏幕宽度
   * @param height 屏幕高度
   */
  public updateScreenOrientation(width: number, height: number): void {
    if (width > height) {
      this.screenOrientation = ScreenOrientation.LANDSCAPE;
    } else {
      this.screenOrientation = ScreenOrientation.PORTRAIT;
    }
  }

  /**
   * 获取当前屏幕方向
   */
  public getScreenOrientation(): ScreenOrientation {
    return this.screenOrientation;
  }

  /**
   * 获取左侧面板宽度比例（双栏布局时）
   * - 平板横屏：25%（更窄，因为横屏宽度更大）
   * - 平板竖屏：30%
   * - 折叠屏展开态：35%
   * - PC：25%
   */
  public getLeftPanelWidth(): string {
    switch (this.currentDeviceType) {
      case DeviceType.TABLET:
        // 平板横屏时左侧面板更窄，竖屏时保持30%
        if (this.screenOrientation === ScreenOrientation.LANDSCAPE) {
          return '25%';
        } else {
          return '30%';
        }
      case DeviceType.PC:
        return '25%';
      case DeviceType.FOLDABLE:
        return '35%';
      default:
        return '100%';
    }
  }

  /**
   * 获取设备描述信息（用于调试）
   */
  public getDeviceInfo(): string {
    return `DeviceType: ${this.currentDeviceType}, FoldStatus: ${this.currentFoldStatus}, ` +
           `IsFoldable: ${this.isFoldable}, LayoutMode: ${this.getLayoutMode()}, ` +
           `Orientation: ${this.screenOrientation}`;
  }
}

/**
 * 断点类型工具类
 * 用于根据窗口宽度判断当前断点
 */
export class BreakpointUtil {
  /**
   * 断点类型
   */
  static readonly BREAKPOINT_SM = 'sm';  // [320, 600) 小屏
  static readonly BREAKPOINT_MD = 'md';  // [600, 840) 中屏
  static readonly BREAKPOINT_LG = 'lg';  // [840, +∞) 大屏

  /**
   * 根据窗口宽度获取断点类型
   * @param width 窗口宽度（vp）
   */
  static getBreakpoint(width: number): string {
    if (width >= 840) {
      return BreakpointUtil.BREAKPOINT_LG;
    } else if (width >= 600) {
      return BreakpointUtil.BREAKPOINT_MD;
    } else {
      return BreakpointUtil.BREAKPOINT_SM;
    }
  }

  /**
   * 判断是否为大屏断点
   */
  static isLargeBreakpoint(breakpoint: string): boolean {
    return breakpoint === BreakpointUtil.BREAKPOINT_LG;
  }

  /**
   * 判断是否为中等屏断点
   */
  static isMediumBreakpoint(breakpoint: string): boolean {
    return breakpoint === BreakpointUtil.BREAKPOINT_MD;
  }

  /**
   * 判断是否应该使用双栏布局（基于断点）
   */
  static shouldUseDoubleColumn(breakpoint: string): boolean {
    return breakpoint === BreakpointUtil.BREAKPOINT_LG || 
           breakpoint === BreakpointUtil.BREAKPOINT_MD;
  }
}
