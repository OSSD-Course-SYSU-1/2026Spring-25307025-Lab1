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

/**
 * 普通聊天消息内容组件（文本消息）。
 * 使用圆角矩形气泡样式。
 *
 * @author Jack Jiang(http://www.52im.net/thread-2792-1-1.html)
 */
@Component
export struct MsgContentView_text {
  // 消息数据对象
  message?: Message;

  build() {
    if(this.message) {
      Row() {
        Text(this.message.content)
          .enableDataDetector(true)
          .dataDetectorConfig({
            types: [TextDataDetectorType.URL, TextDataDetectorType.PHONE_NUMBER, TextDataDetectorType.EMAIL]
          })
          .fontSize(14)
          .fontColor(this.message.isOutgoing() ? Color.White : '#333333')
      }
      // 消息气泡四周的空白
      .padding({ top: 10, bottom: 10, left: 14, right: 14 })
      // 圆角矩形背景
      .backgroundColor(this.message.isOutgoing() ? '#95EC69' : '#FFFFFF')
      .borderRadius(8)
      // 阴影效果
      .shadow({
        radius: 2,
        color: '#1A000000',
        offsetX: 0,
        offsetY: 1
      })
      // 限制最大宽度
      .constraintSize({ maxWidth: '75%' })
    }
  }
}
