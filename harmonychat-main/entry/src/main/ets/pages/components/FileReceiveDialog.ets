/*
 * Copyright (C) 2024  即时通讯网(52im.net) & Jack Jiang.
 * The MobileIMSDK-鸿蒙Next客户端 Project. All rights reserved.
 *
 * 联系邮件：jack.jiang@52im.net
 * 联系微信：hellojackjiang
 * 联系QQ： 413980957
 * 技术社区：http://www.52im.net
 */

import { TransferTask, TransferStatus } from '../utils/FileTransferService';

const TAG: string = '[FileReceiveDialog] ';

/**
 * 文件接收对话框组件
 */
@Component
export struct FileReceiveDialog {
  @Prop showDialog: boolean = false;
  @Prop fileName: string = '';
  @Prop fileSize: number = 0;
  @Prop senderName: string = '';
  @Prop senderDevice: string = '';
  
  // 回调：接受文件
  onAccept?: (fileName: string, fileSize: number) => void;
  
  // 回调：拒绝文件
  onReject?: () => void;
  
  // 回调：关闭对话框
  onClose?: () => void;
  
  /**
   * 格式化文件大小
   */
  formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 B';
    
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }
  
  /**
   * 获取文件类型图标
   */
  getFileTypeIcon(fileName: string): string {
    const lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex === -1) {
      return '📎';
    }
    
    const ext = fileName.substring(lastDotIndex + 1).toLowerCase();
    
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return '🖼️';
      case 'txt':
      case 'md':
      case 'log':
        return '📝';
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📋';
      case 'xls':
      case 'xlsx':
        return '📊';
      case 'zip':
      case 'rar':
      case '7z':
        return '📦';
      default:
        return '📎';
    }
  }
  
  build() {
    if (!this.showDialog) {
      // 不显示对话框时返回空
      Blank()
    } else {
      // 半透明背景
      Column() {
        // 背景遮罩
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#000000')
          .opacity(0.5)
          .onClick(() => {
            if (this.onClose) {
              this.onClose();
            }
          })
        
        // 对话框内容
        Column() {
          // 对话框标题
          Text('文件接收请求')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.Black)
            .margin({ top: 20, bottom: 10 })
          
          // 发送者信息
          Row() {
            Text('来自:')
              .fontSize(14)
              .fontColor('#666')
              .margin({ right: 8 })
            
            Column() {
              Text(this.senderName)
                .fontSize(14)
                .fontColor(Color.Black)
                .fontWeight(FontWeight.Medium)
              
              Text(this.senderDevice)
                .fontSize(12)
                .fontColor('#999')
                .margin({ top: 2 })
            }
          }
          .width('100%')
          .padding({ left: 24, right: 24 })
          .margin({ bottom: 20 })
          
          // 文件信息卡片
          Column() {
            Row() {
              Text(this.getFileTypeIcon(this.fileName))
                .fontSize(36)
                .margin({ right: 15 })
              
              Column() {
                Text(this.fileName)
                  .fontSize(16)
                  .fontColor(Color.Black)
                  .fontWeight(FontWeight.Medium)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                
                Text(this.formatFileSize(this.fileSize))
                  .fontSize(12)
                  .fontColor('#666')
                  .margin({ top: 6 })
              }
              .layoutWeight(1)
            }
            .width('100%')
            .padding({ top: 20, bottom: 20, left: 20, right: 20 })
          }
          .width('90%')
          .backgroundColor('#ffffff')
          .borderRadius(12)
          .shadow({
            radius: 10,
            color: '#1a000000',
            offsetX: 0,
            offsetY: 2
          })
          .margin({ bottom: 30 })
          
          // 提示信息
          Text('是否接收此文件？')
            .fontSize(14)
            .fontColor('#666')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 30 })
          
          // 按钮区域
          Row() {
            // 拒绝按钮
            Button('拒绝', { type: ButtonType.Normal, stateEffect: true })
              .width(120)
              .height(44)
              .backgroundColor('#f0f2f6')
              .fontColor('#ff3b30')
              .fontWeight(FontWeight.Medium)
              .onClick(() => {
                if (this.onReject) {
                  this.onReject();
                }
                if (this.onClose) {
                  this.onClose();
                }
              })
            
            // 接受按钮
            Button('接受', { type: ButtonType.Normal, stateEffect: true })
              .width(120)
              .height(44)
              .backgroundColor('#007aff')
              .fontColor(Color.White)
              .fontWeight(FontWeight.Medium)
              .margin({ left: 20 })
              .onClick(() => {
                if (this.onAccept) {
                  this.onAccept(this.fileName, this.fileSize);
                }
                if (this.onClose) {
                  this.onClose();
                }
              })
          }
          .margin({ bottom: 20 })
        }
        .width('80%')
        .backgroundColor('#f5f5f5')
        .borderRadius(16)
        .padding({ bottom: 20 })
        .alignItems(HorizontalAlign.Center)
        .shadow({
          radius: 20,
          color: '#1a000000',
          offsetX: 0,
          offsetY: 4
        })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
  }
}