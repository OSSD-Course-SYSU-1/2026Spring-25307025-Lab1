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
 * 会话数据模型。
 * 用于会话列表中每个会话项的数据封装。
 *
 * @author Jack Jiang(http://www.52im.net/thread-2792-1-1.html)
 */
export default class Session {
  /** 会话ID（单聊为对方uid，群聊为gid） */
  sessionId: string = '';
  /** 会话类型：0-单聊，1-群聊 */
  sessionType: number = 0;
  /** 对方用户昵称 */
  nickname: string = '';
  /** 对方用户头像URL（本地资源或网络URL） */
  avatar: string | Resource = '';
  /** 最后一条消息内容 */
  lastMessage: string = '';
  /** 最后一条消息时间戳 */
  lastMessageTime: number = 0;
  /** 未读消息数量 */
  unreadCount: number = 0;
  /** 是否置顶 */
  isTop: boolean = false;
  /** 是否免打扰 */
  isMute: boolean = false;
  /** 会话创建时间 */
  createTime: number = 0;
  /** 会话更新时间 */
  updateTime: number = 0;

  constructor(
    sessionId: string,
    sessionType: number,
    nickname: string,
    avatar: string | Resource,
    lastMessage: string = '',
    lastMessageTime: number = 0,
    unreadCount: number = 0
  ) {
    this.sessionId = sessionId;
    this.sessionType = sessionType;
    this.nickname = nickname;
    this.avatar = avatar;
    this.lastMessage = lastMessage;
    this.lastMessageTime = lastMessageTime > 0 ? lastMessageTime : Date.now();
    this.unreadCount = unreadCount;
    this.createTime = Date.now();
    this.updateTime = Date.now();
  }

  /**
   * 获取格式化的最后消息时间。
   * @returns 格式化后的时间字符串
   */
  getFormattedTime(): string {
    if (this.lastMessageTime <= 0) {
      return '';
    }

    const now = Date.now();
    const messageDate = new Date(this.lastMessageTime);
    const today = new Date(now);

    // 判断是否是今天
    if (messageDate.toDateString() === today.toDateString()) {
      // 今天只显示时:分
      const hours = messageDate.getHours().toString().padStart(2, '0');
      const minutes = messageDate.getMinutes().toString().padStart(2, '0');
      return `${hours}:${minutes}`;
    }

    // 判断是否是昨天
    const yesterday = new Date(now);
    yesterday.setDate(yesterday.getDate() - 1);
    if (messageDate.toDateString() === yesterday.toDateString()) {
      return '昨天';
    }

    // 判断是否是本周（显示周几）
    const dayDiff = Math.floor((now - this.lastMessageTime) / (1000 * 60 * 60 * 24));
    if (dayDiff < 7) {
      const weekDays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
      return weekDays[messageDate.getDay()];
    }

    // 其他显示月/日
    const month = (messageDate.getMonth() + 1).toString();
    const day = messageDate.getDate().toString();
    return `${month}/${day}`;
  }

  /**
   * 获取显示的最后消息内容（处理消息类型）。
   * @returns 用于显示的消息内容
   */
  getDisplayMessage(): string {
    if (!this.lastMessage) {
      return '';
    }
    // 可以根据消息类型返回不同的提示文本
    // 例如：[图片]、[语音]、[视频] 等
    return this.lastMessage;
  }

  /**
   * 获取唯一的会话标识。
   * @returns 会话唯一标识
   */
  getKey(): string {
    return `${this.sessionType}_${this.sessionId}`;
  }

  /**
   * 创建单聊会话。
   */
  static createPrivateSession(
    userId: string,
    nickname: string,
    avatar: string | Resource,
    lastMessage: string = '',
    lastMessageTime: number = 0,
    unreadCount: number = 0
  ): Session {
    return new Session(userId, 0, nickname, avatar, lastMessage, lastMessageTime, unreadCount);
  }

  /**
   * 创建群聊会话。
   */
  static createGroupSession(
    groupId: string,
    groupName: string,
    avatar: string | Resource,
    lastMessage: string = '',
    lastMessageTime: number = 0,
    unreadCount: number = 0
  ): Session {
    return new Session(groupId, 1, groupName, avatar, lastMessage, lastMessageTime, unreadCount);
  }
}
