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
import ToolKits from "../../utils/ToolKits";
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import fs from '@ohos.file.fs';

const TAG: string = '[MsgContentView_file] ';

/**
 * 文件消息内容视图组件
 */
@Component
export struct MsgContentView_file {
  message?: Message;
  
  /**
   * 获取文件类型图标
   */
  getFileTypeIcon(): string {
    if (!this.message) {
      return '📎';
    }
    
    const fileName = this.message.fileName || this.message.content;
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
   * 处理文件点击
   */
  onFileClick() {
    if (!this.message || !this.message.filePath) {
      ToolKits.showToast('文件路径无效');
      return;
    }
    
    // 检查文件是否存在
    try {
      const stat = fs.statSync(this.message.filePath);
      if (stat) {
        // 文件存在，可以打开或预览
        this.previewFile();
      } else {
        ToolKits.showToast('文件不存在或已被删除');
      }
    } catch (error) {
      console.error(TAG + 'Failed to access file: ' + JSON.stringify(error));
      ToolKits.showToast('无法访问文件');
    }
  }
  
  /**
   * 预览文件
   */
  previewFile() {
    if (!this.message) {
      return;
    }
    
    // 根据文件类型显示不同的预览方式
    const fileName = this.message.fileName || this.message.content;
    const lastDotIndex = fileName.lastIndexOf('.');
    const ext = lastDotIndex !== -1 ? fileName.substring(lastDotIndex + 1).toLowerCase() : '';
    
    let message = `文件: ${fileName}\n`;
    message += `大小: ${this.formatFileSize(this.message.fileSize)}\n`;
    message += `类型: ${ext.toUpperCase()}\n`;
    message += `路径: ${this.message.filePath}`;
    
    promptAction.showDialog({
      title: '文件信息',
      message: message,
      buttons: [
        {
          text: '打开',
          color: '#007aff'
        },
        {
          text: '取消',
          color: '#999999'
        }
      ]
    }).then((result) => {
      if (result.index === 0) {
        // 打开文件
        this.openFile();
      }
    });
  }
  
  /**
   * 打开文件
   */
  openFile() {
    if (!this.message || !this.message.filePath) {
      return;
    }
    
    // TODO: 使用系统能力打开文件
    // 这里可以调用系统的文件查看器
    ToolKits.showToast('打开文件: ' + this.message.fileName);
  }
  
  build() {
    if (!this.message) {
      Blank()
    } else {
      Row({ space: 8 }) {
        // 文件图标
        Text(this.getFileTypeIcon())
          .fontSize(24)
        
        Column({ space: 4 }) {
          // 文件名
          Text(this.message.fileName || this.message.content)
            .fontSize(14)
            .fontColor(Color.Black)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .constraintSize({ maxWidth: 200 })
          
          // 文件大小和状态
          Row() {
            Text(this.formatFileSize(this.message.fileSize))
              .fontSize(12)
              .fontColor('#666666')
            
            if (this.message.transferStatus === 1) {
              // 传输中
              LoadingProgress()
                .width(12)
                .height(12)
                .color('#007aff')
                .margin({ left: 8 })
              
              Text('传输中...')
                .fontSize(12)
                .fontColor('#007aff')
                .margin({ left: 4 })
            } else if (this.message.transferStatus === 3) {
              // 传输失败
              Text('传输失败')
                .fontSize(12)
                .fontColor('#ff3b30')
                .margin({ left: 8 })
            }
          }
        }
        .layoutWeight(1)
        
        // 下载/查看按钮
        if (this.message.transferStatus === 2) {
          // 传输完成，显示查看按钮
          Image($r("app.media.ic_ok"))
            .width(20)
            .height(20)
            .fillColor('#00de7a')
        }
      }
      .padding({ top: 12, bottom: 12, left: 16, right: 16 })
      .backgroundColor(this.message.isOutgoing() ? '#e3f2fd' : '#f5f5f5')
      .borderRadius(12)
      .border({
        width: 1,
        color: this.message.isOutgoing() ? '#bbdefb' : '#e0e0e0',
        radius: 12
      })
      .onClick(() => {
        this.onFileClick();
      })
    }
  }
}