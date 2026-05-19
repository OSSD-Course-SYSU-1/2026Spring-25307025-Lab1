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
import SessionRepository from '../model/SessionRepository';
import AvatarUtils from '../utils/AvatarUtils';

/**
 * 会话列表项组件。
 * 类似微信聊天列表的会话项样式。
 * 支持滑动清除未读功能。
 *
 * @author Jack Jiang(http://www.52im.net/thread-2792-1-1.html)
 */
@Component
export struct SessionListItem {
  /** 会话数据（使用@ObjectLink实现双向绑定，属性变化时UI自动更新） */
  @ObjectLink session: Session;
  
  /** 点击回调 */
  onItemClick?: (session: Session) => void;
  
  /** 删除回调 */
  onDelete?: (session: Session) => void;
  
  /** 滑动偏移量 */
  @State offsetX: number = 0;
  
  /** 菜单按钮宽度 */
  private readonly MENU_WIDTH: number = 80;
  
  /** 会话数据仓库 */
  private sessionRepository: SessionRepository = SessionRepository.getInstance();

  build() {
    Stack() {
      // 底层：操作按钮（标记已读、删除）
      Row() {
        // 标记已读按钮
        Column() {
          Text('标记已读')
            .fontSize(14)
            .fontColor(Color.White)
        }
        .width(this.MENU_WIDTH)
        .height('100%')
        .backgroundColor('#07c160')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.sessionRepository.clearUnreadCount(this.session.sessionId);
          this.offsetX = 0;
        })
        
        // 删除按钮
        Column() {
          Text('删除')
            .fontSize(14)
            .fontColor(Color.White)
        }
        .width(this.MENU_WIDTH)
        .height('100%')
        .backgroundColor('#fa5151')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          if (this.onDelete) {
            this.onDelete(this.session);
          }
          this.offsetX = 0;
        })
      }
      .width('100%')
      .height(72)
      .justifyContent(FlexAlign.End)
      
      // 上层：会话内容（可滑动）
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
      .translate({ x: this.offsetX })
      .gesture(
        PanGesture()
          .onActionStart(() => {
            // 开始滑动
          })
          .onActionUpdate((event: GestureEvent) => {
            // 滑动过程中
            let offsetX = event.offsetX;
            // 限制滑动范围：向左滑动最多显示两个按钮，向右滑动不能超过0
            if (offsetX < 0) {
              this.offsetX = Math.max(offsetX, -this.MENU_WIDTH * 2);
            } else {
              this.offsetX = Math.min(offsetX, 0);
            }
          })
          .onActionEnd(() => {
            // 滑动结束，根据偏移量决定是否展开菜单
            if (this.offsetX < -this.MENU_WIDTH / 2) {
              // 展开菜单
              this.offsetX = -this.MENU_WIDTH * 2;
            } else {
              // 收起菜单
              this.offsetX = 0;
            }
          })
      )
      .onClick(() => {
        if (this.offsetX < 0) {
          // 如果菜单已展开，先收起菜单
          this.offsetX = 0;
          return;
        }
        if (this.onItemClick) {
          this.onItemClick(this.session);
        }
      })
    }
    .width('100%')
    .height(72)
  }

  /**
   * 头像区域
   */
  @Builder
  AvatarSection() {
    Stack() {
      // 文字头像（根据用户ID生成不同颜色）
      Column() {
        Text(AvatarUtils.getAvatarText(this.session.nickname))
          .fontSize(20)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
      }
      .width(48)
      .height(48)
      .borderRadius(6)
      .backgroundColor(AvatarUtils.getAvatarColor(this.session.sessionId))
      .justifyContent(FlexAlign.Center)
      
      // 未读消息数量角标
      if (this.session.unreadCount > 0) {
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
      Row() {
        Text(this.session.nickname)
          .fontSize(17)
          .fontColor(Color.Black)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
        
        // 置顶标识
        if (this.session.isTop) {
          Text('置顶')
            .fontSize(10)
            .fontColor('#07c160')
            .backgroundColor('#e8f8ec')
            .padding({ left: 4, right: 4, top: 2, bottom: 2 })
            .borderRadius(2)
            .margin({ left: 4 })
        }
      }
      .width('100%')
      
      // 最后一条消息
      Text(this.session.getDisplayMessage())
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
      Text(this.session.getFormattedTime())
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
