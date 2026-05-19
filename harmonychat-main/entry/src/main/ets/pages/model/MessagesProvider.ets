/*
 * Copyright (C) 2024  即时通讯网(52im.net) & Jack Jiang.
 * The MobileIMSDK-鸿蒙Next客户端 Project. All rights reserved.
 *
 * 联系邮件：jack.jiang@52im.net
 * 联系微信：hellojackjiang
 * 联系QQ： 413980957
 * 技术社区：http://www.52im.net
 */

import { ClientCoreSDK, Protocal } from "mobileimsdk/Index";
import IMClientManager from "../../IMClientManager";
import MsgSendStatus from "../constants/MsgSendStatus";
import UIEvent from "../constants/UIEvent";
import Message from "./Message";

<<<<<<< HEAD
/** 测试消息数据接口 */
interface TestMessageData {
  content: string;
  isOutgoing: boolean;
  time: number;
}

=======
>>>>>>> b0e1655266e0814d49edf4e9ff1799d2031749ef
/**
 * 聊天消息的缓存数据管理提供者（集中管理所有的聊天消息和指令，消息来源为网络层通信数据包和本地发出的包
 * ，消息显示方式通过MessagesDataSource与UI界面进行解偶显示）。
 *
 * 代码参考自IM产品RainbowChat：http://www.52im.net/thread-19-1-1.html
 *
 * @author Jack Jiang(http://www.52im.net/thread-2792-1-1.html)
 */
export default class MessagesProvider {

  /** 聊天界面中，消息的显示时间间隔（单位：毫秒）：默认是2分钟内的消息只在第一条消息上显示时间，否则会再次显示时间 */
  // 参考资料：http://www.52im.net/thread-3008-1-1.html#40
  private static readonly CHATTING_MESSAGE_SHOW_TIME_INTERVAL: number = 2 * 60 * 1000;

<<<<<<< HEAD
  /** 按会话ID分别存储与各好友/群的聊天消息：Map<sessionId, Array<Message>> */
  private messagesMap: Map<string, Array<Message>> = new Map();

  /** 当前活动的会话ID */
  private currentSessionId: string = '';

  /** 是否已初始化测试数据 */
  private testDataInitialized: boolean = false;

  constructor() {
    // 初始化测试消息数据
    this.initTestMessages();
  }

  /**
   * 初始化测试消息数据。
   */
  private initTestMessages(): void {
    if (this.testDataInitialized) {
      return;
    }
    this.testDataInitialized = true;

    const now = Date.now();

    // 张三 (user001) 的聊天记录
    const user001Msgs: TestMessageData[] = [
      { content: '你好，在吗？', isOutgoing: false, time: now - 1000 * 60 * 10 },
      { content: '在的，有什么事吗？', isOutgoing: true, time: now - 1000 * 60 * 9 },
      { content: '想问你一下项目的事情', isOutgoing: false, time: now - 1000 * 60 * 8 },
      { content: '好的，你说', isOutgoing: true, time: now - 1000 * 60 * 7 },
      { content: '项目进度怎么样了？', isOutgoing: false, time: now - 1000 * 60 * 5 },
    ];
    this.initSessionMessages('user001', '张三', user001Msgs);

    // 李四 (user002) 的聊天记录
    const user002Msgs: TestMessageData[] = [
      { content: '明天一起吃饭吧', isOutgoing: false, time: now - 1000 * 60 * 35 },
      { content: '好啊，去哪里吃？', isOutgoing: true, time: now - 1000 * 60 * 34 },
      { content: '新开的那家川菜馆怎么样？', isOutgoing: false, time: now - 1000 * 60 * 33 },
      { content: '可以，我没问题', isOutgoing: true, time: now - 1000 * 60 * 30 },
    ];
    this.initSessionMessages('user002', '李四', user002Msgs);

    // 王五 (user003) 的聊天记录
    const user003Msgs: TestMessageData[] = [
      { content: '看这张图片怎么样', isOutgoing: false, time: now - 1000 * 60 * 60 * 2 - 1000 * 60 * 10 },
      { content: '[图片]', isOutgoing: false, time: now - 1000 * 60 * 60 * 2 },
      { content: '挺不错的！', isOutgoing: true, time: now - 1000 * 60 * 60 * 2 + 1000 * 60 },
    ];
    this.initSessionMessages('user003', '王五', user003Msgs);

    // 赵六 (user004) 的聊天记录
    const user004Msgs: TestMessageData[] = [
      { content: '文件已经发给你了', isOutgoing: true, time: now - 1000 * 60 * 60 * 24 - 1000 * 60 * 5 },
      { content: '好的，收到', isOutgoing: false, time: now - 1000 * 60 * 60 * 24 },
    ];
    this.initSessionMessages('user004', '赵六', user004Msgs);

    // 钱七 (user005) 的聊天记录
    const user005Msgs: TestMessageData[] = [
      { content: '周末有空吗？', isOutgoing: false, time: now - 1000 * 60 * 60 * 24 * 3 },
    ];
    this.initSessionMessages('user005', '钱七', user005Msgs);

    // 项目讨论群 (group001) 的聊天记录
    const group001Msgs: TestMessageData[] = [
      { content: '小王: 大家注意，今天的会议改时间了', isOutgoing: false, time: now - 1000 * 60 * 15 },
      { content: '小李: 改到什么时候？', isOutgoing: false, time: now - 1000 * 60 * 14 },
      { content: '小王: 今天的会议改到下午3点', isOutgoing: false, time: now - 1000 * 60 * 10 },
    ];
    this.initSessionMessages('group001', '项目讨论群', group001Msgs);

    // 同学群 (group002) 的聊天记录
    const group002Msgs: TestMessageData[] = [
      { content: '老张: 周末有人有空吗？', isOutgoing: false, time: now - 1000 * 60 * 60 * 5 - 1000 * 60 * 10 },
      { content: '老李: 周末聚会安排', isOutgoing: false, time: now - 1000 * 60 * 60 * 5 },
    ];
    this.initSessionMessages('group002', '同学群', group002Msgs);
  }

  /**
   * 初始化单个会话的消息。
   */
  private initSessionMessages(sessionId: string, nickname: string, messages: TestMessageData[]): void {
    const msgArray: Array<Message> = [];
    
    for (let i = 0; i < messages.length; i++) {
      const msgData = messages[i];
      let m: Message;
      
      if (msgData.isOutgoing) {
        m = Message.createChatMsgEntity_OUTGO_TEXT(msgData.content, `fp_${sessionId}_${i}`);
        m.sendStatus = MsgSendStatus.beReceived;
      } else {
        m = Message.createChatMsgEntity_INCOME_TEXT(sessionId, nickname, msgData.content, msgData.time);
      }
      m.date = msgData.time;
      
      // 设置时间显示
      if (i === 0) {
        m.showTopTime = true;
      } else if (msgData.time - messages[i - 1].time > MessagesProvider.CHATTING_MESSAGE_SHOW_TIME_INTERVAL) {
        m.showTopTime = true;
      }
      
      msgArray.push(m);
    }
    
    this.messagesMap.set(sessionId, msgArray);
  }

  /**
   * 设置当前活动的会话ID。
   * @param sessionId 会话ID
   */
  setCurrentSessionId(sessionId: string): void {
    this.currentSessionId = sessionId;
  }

  /**
   * 获取当前活动的会话ID。
   * @returns 当前会话ID
   */
  getCurrentSessionId(): string {
    return this.currentSessionId;
  }

  /**
   * 获取指定会话的消息列表。
   * @param sessionId 会话ID
   * @returns 消息列表
   */
  getMessagesBySession(sessionId: string): Array<Message> {
    let messages = this.messagesMap.get(sessionId);
    if (!messages) {
      messages = [];
      this.messagesMap.set(sessionId, messages);
    }
    return messages;
  }

  /**
   * 加入一条新消息到指定会话。
   *
   * @param sessionId 会话ID
   * @param m 消息对象
   */
  putMessageToSession(sessionId: string, m: Message): void {
    let messages = this.getMessagesBySession(sessionId);
    
    // 以下代码用于判断并实现仿微信的只显示2分钟内聊天消息的时间标识（参考资料：http://www.52im.net/thread-3008-1-1.html#40）
    let previousMessage: Message | undefined = undefined;
    let messagesSize: number = messages.length;
    if (messagesSize > 0) {
      previousMessage = messages[messagesSize - 1];
    }
    MessagesProvider.setMessageShowTopTime(m, previousMessage);

    // 将此新消息对象放入数据模型(列表)
    messages.push(m);

    // 只有当前会话才通知UI更新
    if (sessionId === this.currentSessionId) {
      // 通知应用层更新ui
      IMClientManager.getInstance().getEmitter().emit(UIEvent.UIEVENT_messageAdded, messages.length - 1);
    }
  }

  /**
   * 加入一条新消息到当前会话。
=======
  /** 真正的聊天软件中，此处应改造为<key=uid, value=Array<Message> >这样的Map集合，用于按uid分别存储与各好友的聊天消息 */
  private messages: Array<Message> = [];

  /**
   * 加入一条新消息。
>>>>>>> b0e1655266e0814d49edf4e9ff1799d2031749ef
   *
   * @param m 消息对象
   */
  putMessage(m: Message): void {
<<<<<<< HEAD
    this.putMessageToSession(this.currentSessionId, m);
  }

  /**
   * 获得当前会话的消息数据缓存集合。
=======
    // 以下代码用于判断并实现仿微信的只显示2分钟内聊天消息的时间标识（参考资料：http://www.52im.net/thread-3008-1-1.html#40）
    let previousMessage: Message | undefined = undefined;
    let messagesSize: number = this.messages.length;
    if (messagesSize > 0) {
      previousMessage = this.messages[messagesSize - 1];
    }
    MessagesProvider.setMessageShowTopTime(m, previousMessage);

    // 将此新消息对象放入数据模型(列表)
    this.messages.push(m);

    // 通知应用层更新ui
    IMClientManager.getInstance().getEmitter().emit(UIEvent.UIEVENT_messageAdded, this.messages.length - 1);
  }

  /**
   * 获得消息数据缓存集合。
>>>>>>> b0e1655266e0814d49edf4e9ff1799d2031749ef
   *
   * @returns 消息数据缓存集合
   */
  getMessages(): Array<Message> {
<<<<<<< HEAD
    return this.getMessagesBySession(this.currentSessionId);
  }

  /**
   * 添加一条系统消息到当前会话（显示在聊天列表中）。
=======
    return this.messages;
  }

  /**
   * 添加一条系统消息（显示在聊天列表中）。
>>>>>>> b0e1655266e0814d49edf4e9ff1799d2031749ef
   *
   * @param content 消息内容
   */
  addSystemMessage(content: string): void {
    let m: Message = Message.createChatMsgEntity_INCOME_SYSTEAMINFO('0', content, 0);
    this.putMessage(m);
  }

  /**
<<<<<<< HEAD
   * 添加一条系统消息到指定会话。
   *
   * @param sessionId 会话ID
   * @param content 消息内容
   */
  addSystemMessageToSession(sessionId: string, content: string): void {
    let m: Message = Message.createChatMsgEntity_INCOME_SYSTEAMINFO('0', content, 0);
    this.putMessageToSession(sessionId, m);
  }

  /**
   * 更新指定会话中指定指纹码的消息的发送状态（更新单条消息）。
   *
   * @param sessionId 会话ID
   * @param fingerPrint 消息指纹码（消息id）
   * @param sendStatus 发送状态，see {@link MsgSendStatus}
   */
  updateMessageSendStatusInSession(sessionId: string, fingerPrint: string, sendStatus: MsgSendStatus): void {
    let messages = this.getMessagesBySession(sessionId);
    
    // 遍历消息列表
    for(let i = 0; i < messages.length; i++) {
      let m = messages[i];
      // 对符合条件的消息对象进行消息发送状态的设置
      if(m && m.isOutgoing() && m.fingerPrintOfProtocal === fingerPrint) {
        // 更新状态
        m.sendStatus = sendStatus;
        // 只有当前会话才通知UI更新
        if (sessionId === this.currentSessionId) {
          // 通知应用层更新ui（参数就是消息所在索引）
          IMClientManager.getInstance().getEmitter().emit(UIEvent.UIEVENT_messageUpdate, i);
        }
      }
    }
  }

  /**
   * 更新当前会话中指定指纹码的消息的发送状态（更新单条消息）。
=======
   * 更新指定指纹码的消息的发送状态（更新单条消息）。
>>>>>>> b0e1655266e0814d49edf4e9ff1799d2031749ef
   *
   * @param fingerPrint 消息指纹码（消息id）
   * @param sendStatus 发送状态，see {@link MsgSendStatus}
   */
  updateMessageSendStatus(fingerPrint: string, sendStatus: MsgSendStatus): void {
<<<<<<< HEAD
    this.updateMessageSendStatusInSession(this.currentSessionId, fingerPrint, sendStatus);
  }

  /**
   * 更新指定会话中指定指纹码的消息的发送状态（更新多条消息）。
   * 目前用于QoS送达机制中告诉应用层有哪些原始消息报文未成功送达给对方。
   *
   * @param sessionId 会话ID
   * @param protocals 原始消息报文对象数组
   * @param sendStatus 发送状态，see {@link MsgSendStatus}
   */
  updateMessagesSendStatusInSession(sessionId: string, protocals: Protocal[], sendStatus: MsgSendStatus): void {
    let messages = this.getMessagesBySession(sessionId);
    let updateIndexes: number[] = [];

    // 遍历消息列表
    for(let mi = 0; mi < messages.length; mi++) {
      let m = messages[mi];
=======
    // 遍历消息列表
    for(let i = 0; i < this.messages.length; i++) {
      let m = this.messages[i];
      // 对符合条件的消息对象进行消息发送状态的设置
      if(m && m.isOutgoing() && m.fingerPrintOfProtocal === fingerPrint) {
        // 更新状态
        m.sendStatus = sendStatus;
        // 通知应用层更新ui（参数就是消息所在索引）
        IMClientManager.getInstance().getEmitter().emit(UIEvent.UIEVENT_messageUpdate, i);
      }
    }
  }

  /**
   * 更新指定指纹码的消息的发送状态（更新多条消息）。
   * 目前用于QoS送达机制中告诉应用层有哪些原始消息报文未成功送达给对方。
   *
   * @param  protocals 原始消息报文对象数组，数组中Protocal对象指纹码（消息id）就是本次要更新的对象，这个数组目前来自于SDK的 EventType.onMessagesLost 事件通知
   * @param sendStatus 发送状态，see {@link MsgSendStatus}
   */
  updateMessagesSendStatus(protocals: Protocal[], sendStatus: MsgSendStatus): void {
    let updateIndexes: number[] = [];

    // 遍历消息列表
    // this.messages.forEach((m: Message) => {
    for(let mi = 0; mi < this.messages.length; mi++) {
      let m = this.messages[mi];
>>>>>>> b0e1655266e0814d49edf4e9ff1799d2031749ef
      for(let i = 0; i < protocals.length; i++){
        let p = protocals[i];
        // 对符合条件的消息对象进行消息发送状态的设置
        if(m && m.isOutgoing() && m.fingerPrintOfProtocal === p.fp) {
          // 更新状态
          m.sendStatus = sendStatus;
          // 加入已更新索引列表集合
          updateIndexes.push(mi);
          break;
        }
      }
    }

<<<<<<< HEAD
    if(updateIndexes.length > 0 && sessionId === this.currentSessionId) {
=======
    if(updateIndexes.length > 0) {
>>>>>>> b0e1655266e0814d49edf4e9ff1799d2031749ef
      // 通知应用层更新ui（参数就是消息所在索引）
      IMClientManager.getInstance().getEmitter().emit(UIEvent.UIEVENT_messagesUpdate, updateIndexes);
    }
  }

  /**
<<<<<<< HEAD
   * 更新当前会话中指定指纹码的消息的发送状态（更新多条消息）。
   *
   * @param protocals 原始消息报文对象数组
   * @param sendStatus 发送状态，see {@link MsgSendStatus}
   */
  updateMessagesSendStatus(protocals: Protocal[], sendStatus: MsgSendStatus): void {
    this.updateMessagesSendStatusInSession(this.currentSessionId, protocals, sendStatus);
  }

  /**
   * 清空指定会话的所有消息。
   * @param sessionId 会话ID
   */
  clearSession(sessionId: string): void {
    this.messagesMap.delete(sessionId);
  }

  /**
   * 清空当前会话的所有消息。
   */
  clear(): void {
    this.messagesMap.delete(this.currentSessionId);
  }

  /**
   * 清空所有会话的所有消息。
   */
  clearAll(): void {
    this.messagesMap.clear();
=======
   * 清空所有消息。
   */
  clear(): void {
    this.messages = [];
>>>>>>> b0e1655266e0814d49edf4e9ff1799d2031749ef
  }

  /**
   * 为当前的消息对象，设置是否显示消息时间标识。
   *
   * 此时间显示逻辑是与微信保持一致的：即只显示5分钟内聊天消息的时间标识，参考资料：http://www.52im.net/thread-3008-1-1.html#40
   *
   * @param theMessage 当前消息对象，不可为null
   * @param previousMessage 当前消息的自然时间的上一条消息，此消息可为空（此为空即表示当前消息就是消息集合中的第一条消息）
   */
  private static setMessageShowTopTime(theMessage: Message, previousMessage: Message | undefined): void {
    if(theMessage) {
      if(previousMessage === undefined) {
        theMessage.showTopTime = true;
        return;
      }

      // 以下代码用于判断并实现仿微信的只显示5分钟内聊天消息的时间标识（参考资料：http://www.52im.net/thread-3008-1-1.html#40）
      if(theMessage.date - previousMessage.date > MessagesProvider.CHATTING_MESSAGE_SHOW_TIME_INTERVAL)
        theMessage.showTopTime = true;
    }
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> b0e1655266e0814d49edf4e9ff1799d2031749ef
