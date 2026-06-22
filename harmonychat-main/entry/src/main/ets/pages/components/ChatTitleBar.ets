/*
 * Copyright (C) 2024  即时通讯网(52im.net) & Jack Jiang.
 * The MobileIMSDK-鸿蒙Next客户端 Project. All rights reserved.
 *
 * 联系邮件：jack.jiang@52im.net
 * 联系微信：hellojackjiang
 * 联系QQ： 413980957
 * 技术社区：http://www.52im.net
 */

import { ClientCoreSDK } from "mobileimsdk/Index";
import ToolKits from "../utils/ToolKits";

/**
 * 聊天界面的自定义标题栏组件。
 *
 * @author Jack Jiang(http://www.52im.net/thread-2792-1-1.html)
 */
@Preview
@Component
export struct CustomeTitleBar {

  // 连接状态：false 连接断开、true 连接正常
  @Prop connectStatus: boolean;

  @Prop keepAliveStatus: boolean;

  // 会话名称（用于显示在标题栏）
  @Prop titleName: string = 'HarmonyChat';

  // 是否显示返回按钮
  @Prop showBackButton: boolean = false;

  // 返回按钮点击回调
  onBackClick?: () => void;

  // 附近快传按钮点击回调
  onNearbyClick?: () => void;

  // 返回按钮图片
  backImg: Resource = $r("app.media.widget_title_btn_back_normal");

  build() {

    Column() {
      Row() {
        // 返回按钮
        if (this.showBackButton) {
          Row() {
            Image(this.backImg)
              .width(24)
              .height(24)
              .objectFit(ImageFit.Contain)
          }
          .width(40)
          .height(40)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            if (this.onBackClick) {
              this.onBackClick();
            }
          })
        }

        Row() {
          Text(this.titleName)
            .textAlign(TextAlign.Start)
            .fontSize(18)
            .maxLines(1)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Medium)
            .ellipsisMode(EllipsisMode.CENTER)
            .textOverflow({overflow: TextOverflow.Ellipsis})
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

        Row() {
          // 网络状态指示器
          Text()
            .width(8)
            .height(8)
            .borderRadius(4)
            .margin({right: 12})
            .backgroundColor(this.connectStatus ? (this.keepAliveStatus ? '#07C160' : '#07C160') : '#FA5151')
            .border({width: 1, color: this.connectStatus ? (this.keepAliveStatus ? '#07C160' : '#07C160') : '#FA5151', radius: 4})

          // 附近快传按钮
          Row() {
            Image($r("app.media.widget_title_btn_mpre_normal"))
              .width(24)
              .height(24)
              .objectFit(ImageFit.Contain)
          }
          .width(40)
          .height(40)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            if (this.onNearbyClick) {
              this.onNearbyClick();
            }
          })
        }
      }
      .height(56)
      .padding({left: 16, right: 16})

      this.BottomLine()

      // if(!this.connectStatus) {
        Row() {
          LoadingProgress().width(16).height(16).margin({ right: 8 }).color('#FA5151')
          Text('网络连接异常，正在重连…')
            .maxLines(1)
            .ellipsisMode(EllipsisMode.CENTER)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .fontColor('#FA5151')
            .fontSize(13)
        }
        .width('100%')
        .height(32)
        .backgroundColor('#FFF5F5')
        .justifyContent(FlexAlign.Center)
        .visibility(this.connectStatus ? Visibility.None : Visibility.Visible)
        .animation({
          duration: 250,
          curve: Curve.EaseInOut,
          iterations: 1,
          playMode: PlayMode.Normal
        })
      // }
    }
    .width('100%')
    .backgroundColor(ToolKits.chat_page_title_background_color)//'#2e3746')
    // .linearGradient({
    //   direction:GradientDirection.Right,// 渐变方向
    //   colors:[['#2e3746',0],['#0e1a26',1]]
    // })
    // .shadow({
    //   radius: 6, // 模糊半径
    //   color: "#ffff0000", // 阴影颜色
    //   offsetX: 0, // X轴偏移量
    //   offsetY: 10 // Y轴偏移量
    // })
  }


  @Builder
  BottomLine() {
    Line()
      .height('0.5px')
      .width('100%')
      .backgroundColor('#e5e5e5')
  }
}
