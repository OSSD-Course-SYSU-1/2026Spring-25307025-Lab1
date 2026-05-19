/*
 * Copyright (C) 2024  即时通讯网(52im.net) & Jack Jiang.
 * The MobileIMSDK-鸿蒙Next客户端 Project. All rights reserved.
 *
 * 联系邮件：jack.jiang@52im.net
 * 联系微信：hellojackjiang
 * 联系QQ： 413980957
 * 技术社区：http://www.52im.net
 */

import Session from './Session';

const TAG: string = '[SessionRepository] ';

/**
 * 会话数据仓库。
 * 负责管理会话列表数据的增删改查操作。
 *
 * @author Jack Jiang(http://www.52im.net/thread-2792-1-1.html)
 */
export default class SessionRepository {
  private static instance: SessionRepository;

  /** 会话列表数据 */
  private sessions: Session[] = [];

  /** 数据变化监听器 */
  private dataChangeListener: (() => void) | null = null;

  private constructor() {
    // 初始化测试数据
    this.initTestData();
  }

  /**
   * 获取单例实例。
   */
  static getInstance(): SessionRepository {
    if (!SessionRepository.instance) {
      SessionRepository.instance = new SessionRepository();
    }
    return SessionRepository.instance;
  }

  /**
   * 初始化测试数据。
   */
  private initTestData(): void {
    const now = Date.now();
    
    // 创建测试会话数据（最后一条消息与 MessagesProvider 中的最新消息一致）
    this.sessions = [
      Session.createPrivateSession(
        'user001',
        '张三',
        $r('app.media.startIcon1'),
        '项目进度怎么样了？',
        now - 1000 * 60 * 5, // 5分钟前
        2
      ),
      Session.createPrivateSession(
        'user002',
        '李四',
        $r('app.media.startIcon1'),
        '可以，我没问题',
        now - 1000 * 60 * 30, // 30分钟前
        0
      ),
      Session.createPrivateSession(
        'user003',
        '王五',
        $r('app.media.startIcon1'),
        '挺不错的！',
        now - 1000 * 60 * 60 * 2, // 2小时前
        5
      ),
      Session.createPrivateSession(
        'user004',
        '赵六',
        $r('app.media.startIcon1'),
        '好的，收到',
        now - 1000 * 60 * 60 * 24, // 1天前
        0
      ),
      Session.createPrivateSession(
        'user005',
        '钱七',
        $r('app.media.startIcon1'),
        '周末有空吗？',
        now - 1000 * 60 * 60 * 24 * 3, // 3天前
        1
      ),
      Session.createGroupSession(
        'group001',
        '项目讨论群',
        $r('app.media.startIcon1'),
        '小王: 今天的会议改到下午3点',
        now - 1000 * 60 * 10, // 10分钟前
        3
      ),
      Session.createGroupSession(
        'group002',
        '同学群',
        $r('app.media.startIcon1'),
        '老李: 周末聚会安排',
        now - 1000 * 60 * 60 * 5, // 5小时前
        0
      ),
    ];
  }

  /**
   * 设置数据变化监听器。
   * @param listener 监听回调
   */
  setDataChangeListener(listener: (() => void) | null): void {
    this.dataChangeListener = listener;
  }

  /**
   * 通知数据变化。
   */
  private notifyDataChange(): void {
    if (this.dataChangeListener) {
      this.dataChangeListener();
    }
  }

  /**
   * 获取所有会话列表。
   * @returns 会话列表数组
   */
  getAllSessions(): Session[] {
    return this.sessions;
  }

  /**
   * 根据会话ID获取会话。
   * @param sessionId 会话ID
   * @returns 会话对象或undefined
   */
  getSessionById(sessionId: string): Session | undefined {
    return this.sessions.find(s => s.sessionId === sessionId);
  }

  /**
   * 添加或更新会话。
   * @param session 会话对象
   */
  addOrUpdateSession(session: Session): void {
    const index = this.sessions.findIndex(s => s.sessionId === session.sessionId);
    if (index >= 0) {
      // 更新现有会话
      this.sessions[index] = session;
    } else {
      // 添加新会话
      this.sessions.unshift(session);
    }
    this.notifyDataChange();
  }

  /**
   * 删除会话。
   * @param sessionId 会话ID
   */
  deleteSession(sessionId: string): void {
    const index = this.sessions.findIndex(s => s.sessionId === sessionId);
    if (index >= 0) {
      this.sessions.splice(index, 1);
      this.notifyDataChange();
    }
  }

  /**
   * 更新会话的最后一条消息。
   * @param sessionId 会话ID
   * @param message 消息内容
   * @param time 消息时间
   */
  updateLastMessage(sessionId: string, message: string, time: number): void {
    const session = this.getSessionById(sessionId);
    if (session) {
      session.lastMessage = message;
      session.lastMessageTime = time;
      session.updateTime = Date.now();
      // 将会话移到列表顶部
      this.moveSessionToTop(sessionId);
      this.notifyDataChange();
    }
  }

  /**
   * 增加未读消息数量。
   * @param sessionId 会话ID
   * @param count 增加的数量，默认为1
   */
  increaseUnreadCount(sessionId: string, count: number = 1): void {
    const session = this.getSessionById(sessionId);
    if (session) {
      session.unreadCount += count;
      this.notifyDataChange();
    }
  }

  /**
   * 清零未读消息数量。
   * @param sessionId 会话ID
   */
  clearUnreadCount(sessionId: string): void {
    const session = this.getSessionById(sessionId);
    if (session) {
      session.unreadCount = 0;
      this.notifyDataChange();
    }
  }

  /**
   * 获取总未读消息数量。
   * @returns 总未读数量
   */
  getTotalUnreadCount(): number {
    return this.sessions.reduce((total, session) => total + session.unreadCount, 0);
  }

  /**
   * 将会话置顶。
   * @param sessionId 会话ID
   * @param isTop 是否置顶
   */
  setSessionTop(sessionId: string, isTop: boolean): void {
    const session = this.getSessionById(sessionId);
    if (session) {
      session.isTop = isTop;
      this.notifyDataChange();
    }
  }

  /**
   * 将会话移到列表顶部。
   * @param sessionId 会话ID
   */
  private moveSessionToTop(sessionId: string): void {
    const index = this.sessions.findIndex(s => s.sessionId === sessionId);
    if (index > 0) {
      const session = this.sessions.splice(index, 1)[0];
      this.sessions.unshift(session);
    }
  }

  /**
   * 清空所有会话。
   */
  clearAllSessions(): void {
    this.sessions = [];
    this.notifyDataChange();
  }
}
