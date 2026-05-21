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
 * 新建聊天对话框组件。
 * 用于输入对方 UID 发起新会话。
 *
 * @author Jack Jiang(http://www.52im.net/thread-2792-1-1.html)
 */
@CustomDialog
export struct NewChatDialog {
  /** 对话框控制器 */
  controller: CustomDialogController;

  /** 确认回调，返回输入的 UID */
  onConfirm: (uid: string) => void = () => {};

  /** 输入的 UID */
  @State private inputUid: string = '';

  /** 输入框是否获得焦点 */
  @State private isFocused: boolean = false;

  /**
   * 处理确认按钮点击。
   */
  private handleConfirm(): void {
    const uid = this.inputUid.trim();
    if (uid.length === 0) {
      return;
    }
    // 验证是否为纯数字
    if (!/^\d+$/.test(uid)) {
      return;
    }
    this.controller.close();
    this.onConfirm(uid);
  }

  /**
   * 处理取消按钮点击。
   */
  private handleCancel(): void {
    this.controller.close();
  }

  build() {
    Column() {
      // 标题
      Text('发起新聊天')
        .fontSize(18)
        .fontColor('#1a1a1a')
        .fontWeight(500)
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 20, bottom: 16 })

      // 提示文字
      Text('输入对方 UID（用户 ID）')
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')
        .margin({ bottom: 8 })

      // 输入框
      TextInput({ placeholder: '请输入对方 UID，如：1001' })
        .type(InputType.Number)
        .height(48)
        .width('100%')
        .fontSize(16)
        .fontColor('#1a1a1a')
        .placeholderColor('#999999')
        .placeholderFont({ size: 14 })
        .backgroundColor('#f5f5f5')
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          // 只允许数字输入
          this.inputUid = value.replace(/[^\d]/g, '');
        })
        .onFocus(() => {
          this.isFocused = true;
        })
        .onBlur(() => {
          this.isFocused = false;
        })

      // 示例提示
      Text('示例：1001、2002、3003')
        .fontSize(12)
        .fontColor('#999999')
        .width('100%')
        .margin({ top: 8, bottom: 20 })

      // 按钮区域
      Row() {
        // 取消按钮
        Button('取消')
          .width('45%')
          .height(44)
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#f0f0f0')
          .borderRadius(22)
          .onClick(() => this.handleCancel())

        Blank().width('10%')

        // 确认按钮
        Button('确认')
          .width('45%')
          .height(44)
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor(this.inputUid.trim().length > 0 ? '#07c160' : '#cccccc')
          .borderRadius(22)
          .enabled(this.inputUid.trim().length > 0)
          .onClick(() => this.handleConfirm())
      }
      .width('100%')
      .margin({ bottom: 20 })
    }
    .width('100%')
    .padding({ left: 24, right: 24 })
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}
