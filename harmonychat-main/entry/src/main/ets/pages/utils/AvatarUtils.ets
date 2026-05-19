/*
 * Copyright (C) 2024  即时通讯网(52im.net) & Jack Jiang.
 * The MobileIMSDK-鸿蒙Next客户端 Project. All rights reserved.
 *
 * 联系邮件：jack.jiang@52im.net
 * 联系微信：hellojackjiang
 * 联系QQ： 413980957
 * 技术社区：http://www.52im.net
 */

/**
 * 头像信息接口。
 */
export interface AvatarInfo {
  /** 背景色 */
  color: string;
  /** 显示文字 */
  text: string;
}

/**
 * 头像工具类。
 * 用于根据用户信息生成头像颜色和文字。
 *
 * @author Jack Jiang(http://www.52im.net/thread-2792-1-1.html)
 */
export default class AvatarUtils {
  /**
   * 预定义的头像背景色数组。
   */
  private static readonly COLORS: string[] = [
    '#E53935', // 红色
    '#D81B60', // 粉红
    '#8E24AA', // 紫色
    '#5E35B1', // 深紫
    '#3949AB', // 靛蓝
    '#1E88E5', // 蓝色
    '#039BE5', // 天蓝
    '#00ACC1', // 青色
    '#00897B', // 青绿
    '#43A047', // 绿色
    '#7CB342', // 浅绿
    '#C0CA33', // 黄绿
    '#FDD835', // 黄色
    '#FFB300', // 橙黄
    '#FB8C00', // 橙色
    '#F4511E', // 深橙
  ];

  /**
   * 根据用户ID获取头像背景色。
   * 使用用户ID的哈希值来选择颜色，确保同一用户始终获得相同颜色。
   *
   * @param userId 用户ID
   * @returns 十六进制颜色字符串
   */
  static getAvatarColor(userId: string): string {
    // 计算字符串的哈希值
    let hash = 0;
    for (let i = 0; i < userId.length; i++) {
      const char = userId.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // 转换为32位整数
    }
    // 使用哈希值选择颜色
    const index = Math.abs(hash) % AvatarUtils.COLORS.length;
    return AvatarUtils.COLORS[index];
  }

  /**
   * 根据昵称获取头像显示文字。
   * 取昵称的最后一个字符作为头像文字。
   *
   * @param nickname 用户昵称
   * @returns 头像显示文字
   */
  static getAvatarText(nickname: string): string {
    if (!nickname || nickname.length === 0) {
      return '?';
    }
    // 取最后一个字符（中文名通常最后一个字比较有代表性）
    return nickname.charAt(nickname.length - 1);
  }

  /**
   * 根据用户ID和昵称获取头像信息。
   *
   * @param userId 用户ID
   * @param nickname 用户昵称
   * @returns 头像信息对象
   */
  static getAvatarInfo(userId: string, nickname: string): AvatarInfo {
    const info: AvatarInfo = {
      color: AvatarUtils.getAvatarColor(userId),
      text: AvatarUtils.getAvatarText(nickname)
    };
    return info;
  }
}
