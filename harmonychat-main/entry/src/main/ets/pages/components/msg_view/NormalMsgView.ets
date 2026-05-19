/*
 * Copyright (C) 2024  即时通讯网(52im.net) & Jack Jiang.
 * The MobileIMSDK-鸿蒙Next客户端 Project. All rights reserved.
 *
 * 联系邮件：jack.jiang@52im.net
 * 联系微信：hellojackjiang
 * 联系QQ： 413980957
 * 技术社区：http://www.52im.net
 */

import Message from "../../model/Message";
import MsgType from "../../constants/MsgType";
import { MsgContentView_text } from "../msg_content_view/MsgContentView_text";
import MsgSendStatus from "../../constants/MsgSendStatus";
import ToolKits from "../../utils/ToolKits";

/**
 * 普通聊天消息UI组件。
 * 
 * 布局说明：
 * - 对方消息：头像在左，昵称+气泡在右，整体靠左
 * - 我的消息：气泡在左，头像在右，整体靠右
 *
 * @author Jack Jiang(http://www.52im.net/thread-2792-1-1.html)
 */
@Component
export struct MsgView_normal {
  message?: Message;

  /**
   * 根据发送者ID获取对应的头像资源。
   */
  getAvatarResource(senderId: string, isOutgoing: boolean): ResourceStr {
    if (isOutgoing) {
      return $r("app.media.default_avatar1");
    }
    
    const avatarList = [
      "app.media.default_avatar2",
      "app.media.startIcon",
      "app.media.startIcon1"
    ];
    
    let hash = 0;
    for (let i = 0; i < senderId.length; i++) {
      hash = (hash + senderId.charCodeAt(i)) % avatarList.length;
    }
    
    return $r(avatarList[hash]);
  }

  build() {
    Row() {
      if (this.message) {
        if (this.message.isOutgoing()) {
          // ========== 我的消息：靠右 ==========
          // 左侧空白
          Blank()
            .layoutWeight(1)
          
          // 消息内容区域
          Row({ space: 4 }) {
            // 发送状态图标
            if (this.message.sendStatus === MsgSendStatus.sendFaild) {
              Image($r('app.media.ic_warn'))
                .width(16)
                .height(16)
                .fillColor('#ff453a')
                .onClick(() => ToolKits.showToast('发送失败'))
            } else if (this.message.sendStatus === MsgSendStatus.sending) {
              LoadingProgress()
                .width(16)
                .height(16)
                .color(Color.Grey)
            }
            
            // 消息气泡
            if (this.message.msgType === MsgType.TYPE_TEXT) {
              MsgContentView_text({ message: this.message })
            }
          }
          .alignItems(VerticalAlign.Center)
          
          // 右侧头像
          Image(this.getAvatarResource(this.message.senderId, true))
            .width(40)
            .height(40)
            .borderRadius(20)
            .backgroundColor('#f0f0f0')
            .margin({ left: 8, right: 12 })
          
        } else {
          // ========== 对方消息：靠左 ==========
          // 左侧头像
          Image(this.getAvatarResource(this.message.senderId, false))
            .width(40)
            .height(40)
            .borderRadius(20)
            .backgroundColor('#f0f0f0')
            .margin({ left: 12, right: 8 })
          
          // 消息内容区域
          Column({ space: 4 }) {
            // 昵称
            Text(this.message.senderDisplayName)
              .fontSize(12)
              .fontColor('#999999')
              .margin({ left: 4 })
            
            // 消息气泡
            if (this.message.msgType === MsgType.TYPE_TEXT) {
              MsgContentView_text({ message: this.message })
            }
          }
          .alignItems(HorizontalAlign.Start)
          
          // 右侧空白
          Blank()
            .layoutWeight(1)
        }
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .margin({ top: 8, bottom: 8 })
  }
}
