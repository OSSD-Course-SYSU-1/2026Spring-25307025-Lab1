/*
 * Copyright (C) 2024  即时通讯网(52im.net) & Jack Jiang.
 * The MobileIMSDK-鸿蒙Next客户端 Project. All rights reserved.
 *
 * 联系邮件：jack.jiang@52im.net
 * 联系微信：hellojackjiang
 * 联系QQ： 413980957
 * 技术社区：http://www.52im.net
 */

import Session from '../model/Session';

/**
 * 会话列表项组件。
 * 类似微信聊天列表的会话项样式。
 *
 * @author Jack Jiang(http://www.52im.net/thread-2792-1-1.html)
 */
@Component
export struct SessionListItem {
  /** 会话数据 */
  @Prop session: Session | null = null;
  
  /** 点击回调 */
  onItemClick?: (session: Session) => void;

  build() {
    if (this.session) {
      Row() {
        // 左侧头像区域
        this.AvatarSection()
        
        // 中间内容区域
        this.ContentSection()
        
        // 右侧时间和未读区域
        this.RightSection()
      }
      .width('100%')
      .height(72)
      .backgroundColor(Color.White)
      .onClick(() => {
        if (this.session && this.onItemClick) {
          this.onItemClick(this.session);
        }
      })
    }
  }

  /**
   * 头像区域
   */
  @Builder
  AvatarSection() {
    Stack() {
      // 头像
      if (typeof this.session?.avatar === 'string') {
        Image(this.session?.avatar)
          .width(48)
          .height(48)
          .borderRadius(6)
          .objectFit(ImageFit.Cover)
      } else {
        Image(this.session?.avatar as Resource)
          .width(48)
          .height(48)
          .borderRadius(6)
          .objectFit(ImageFit.Cover)
      }
      
      // 未读消息数量角标
      if (this.session && this.session.unreadCount > 0) {
        Text(this.session.unreadCount > 99 ? '99+' : this.session.unreadCount.toString())
          .fontSize(this.session.unreadCount > 99 ? 10 : 11)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#ff4757')
          .borderRadius(this.session.unreadCount > 99 ? 10 : 9)
          .padding({ left: 5, right: 5 })
          .height(18)
          .textAlign(TextAlign.Center)
          .position({ x: '70%', y: -4 })
      }
    }
    .width(48)
    .height(48)
    .margin({ left: 12, right: 12 })
    .alignContent(Alignment.TopStart)
  }

  /**
   * 中间内容区域
   */
  @Builder
  ContentSection() {
    Column() {
      // 用户名称
      Text(this.session?.nickname ?? '')
        .fontSize(17)
        .fontColor(Color.Black)
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .textAlign(TextAlign.Start)
      
      // 最后一条消息
      Text(this.session?.getDisplayMessage() ?? '')
        .fontSize(14)
        .fontColor('#999999')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .textAlign(TextAlign.Start)
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 右侧时间和未读区域
   */
  @Builder
  RightSection() {
    Column() {
      // 时间
      Text(this.session?.getFormattedTime() ?? '')
        .fontSize(12)
        .fontColor('#b2b2b2')
        .maxLines(1)
      
      // 占位，保持布局对齐
      Blank()
    }
    .width(60)
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.End)
    .padding({ right: 12, top: 14 })
  }
}
