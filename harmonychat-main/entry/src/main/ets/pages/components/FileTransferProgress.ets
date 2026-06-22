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

const TAG: string = '[FileTransferProgress] ';

/**
 * 文件传输进度组件
 */
@Component
export struct FileTransferProgress {
  @Prop task: TransferTask = new TransferTask();
  @Prop onCancel?: (taskId: string) => void;
  @Prop onClose?: () => void;
  
  /**
   * 获取状态文本
   */
  getStatusText(status: TransferStatus): string {
    switch (status) {
      case TransferStatus.IDLE:
        return '等待中';
      case TransferStatus.CONNECTING:
        return '连接中...';
      case TransferStatus.SENDING:
        return '发送中...';
      case TransferStatus.RECEIVING:
        return '接收中...';
      case TransferStatus.COMPLETED:
        return '传输完成';
      case TransferStatus.FAILED:
        return '传输失败';
      case TransferStatus.CANCELLED:
        return '已取消';
      default:
        return '未知状态';
    }
  }
  
  /**
   * 获取状态颜色
   */
  getStatusColor(status: TransferStatus): ResourceColor {
    switch (status) {
      case TransferStatus.COMPLETED:
        return '#00de7a';
      case TransferStatus.FAILED:
        return '#ff3b30';
      case TransferStatus.CANCELLED:
        return '#999999';
      default:
        return '#007aff';
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
   * 获取传输速度
   */
  getTransferSpeed(task: TransferTask): string {
    if (task.status !== TransferStatus.SENDING && task.status !== TransferStatus.RECEIVING) {
      return '';
    }
    
    const elapsedTime = Date.now() - task.startTime;
    if (elapsedTime <= 0) {
      return '';
    }
    
    const speed = task.transferredBytes / (elapsedTime / 1000); // bytes per second
    return this.formatFileSize(speed) + '/s';
  }
  
  /**
   * 获取剩余时间
   */
  getRemainingTime(task: TransferTask): string {
    if (task.status !== TransferStatus.SENDING && task.status !== TransferStatus.RECEIVING) {
      return '';
    }
    
    if (task.progress <= 0 || task.progress >= 100) {
      return '';
    }
    
    const elapsedTime = Date.now() - task.startTime;
    const remainingBytes = task.fileSize - task.transferredBytes;
    const speed = task.transferredBytes / (elapsedTime / 1000);
    
    if (speed <= 0) {
      return '';
    }
    
    const remainingSeconds = remainingBytes / speed;
    
    if (remainingSeconds < 60) {
      return Math.ceil(remainingSeconds) + '秒';
    } else if (remainingSeconds < 3600) {
      return Math.ceil(remainingSeconds / 60) + '分钟';
    } else {
      return Math.ceil(remainingSeconds / 3600) + '小时';
    }
  }
  
  build() {
    Column() {
      // 标题栏
      Row() {
        Text('文件传输')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)
          .layoutWeight(1)
        
        // 关闭按钮
        Image($r("app.media.widget_title_btn_back_normal"))
          .width(24)
          .height(24)
          .objectFit(ImageFit.Contain)
          .onClick(() => {
            if (this.onClose) {
              this.onClose();
            }
          })
      }
      .width('100%')
      .height(60)
      .padding({ left: 20, right: 20 })
      .backgroundColor('#ffffff')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      
      // 传输信息区域
      Column() {
        // 文件信息
        Row() {
          Text(this.getFileTypeIcon(this.task.fileName))
            .fontSize(32)
            .margin({ right: 15 })
          
          Column() {
            Text(this.task.fileName)
              .fontSize(16)
              .fontColor(Color.Black)
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            
            Text(this.formatFileSize(this.task.fileSize))
              .fontSize(12)
              .fontColor('#666')
              .margin({ top: 4 })
          }
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 20, bottom: 20 })
        .backgroundColor('#ffffff')
        .borderRadius(12)
        .margin({ bottom: 20 })
        
        // 目标设备
        Row() {
          Text('发送到:')
            .fontSize(14)
            .fontColor('#666')
            .margin({ right: 10 })
          
          Text(this.task.targetDeviceName)
            .fontSize(14)
            .fontColor(Color.Black)
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
        .margin({ bottom: 20 })
        
        // 进度条
        Column() {
          Row() {
            Text('进度')
              .fontSize(14)
              .fontColor('#666')
              .layoutWeight(1)
            
            Text(`${this.task.progress}%`)
              .fontSize(14)
              .fontColor('#007aff')
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .margin({ bottom: 10 })
          
          Progress({
            value: this.task.progress,
            total: 100
          })
          .width('100%')
          .height(8)
          .color('#007aff')
          .backgroundColor('#e5e5e5')
          .borderRadius(4)
          
          // 传输详情
          Row() {
            Text(`${this.formatFileSize(this.task.transferredBytes)} / ${this.formatFileSize(this.task.fileSize)}`)
              .fontSize(12)
              .fontColor('#666')
              .layoutWeight(1)
            
            if (this.task.status === TransferStatus.SENDING || this.task.status === TransferStatus.RECEIVING) {
              Text(this.getTransferSpeed(this.task))
                .fontSize(12)
                .fontColor('#666')
                .margin({ right: 15 })
              
              Text(this.getRemainingTime(this.task))
                .fontSize(12)
                .fontColor('#666')
            }
          }
          .width('100%')
          .margin({ top: 10 })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 15, bottom: 15 })
        .backgroundColor('#ffffff')
        .borderRadius(12)
        .margin({ bottom: 20 })
        
        // 状态显示
        Row() {
          Text('状态:')
            .fontSize(14)
            .fontColor('#666')
            .margin({ right: 10 })
          
          Text(this.getStatusText(this.task.status))
            .fontSize(14)
            .fontColor(this.getStatusColor(this.task.status))
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
        .margin({ bottom: 30 })
      }
      .layoutWeight(1)
      .backgroundColor('#f5f5f5')
      
      // 底部操作栏
      Row() {
        if (this.task.status === TransferStatus.SENDING || this.task.status === TransferStatus.RECEIVING) {
          Button('取消传输', { type: ButtonType.Normal, stateEffect: true })
            .width(140)
            .height(40)
            .backgroundColor('#ff3b30')
            .fontColor(Color.White)
            .onClick(() => {
              if (this.onCancel) {
                this.onCancel(this.task.taskId);
              }
            })
        } else if (this.task.status === TransferStatus.COMPLETED) {
          Button('完成', { type: ButtonType.Normal, stateEffect: true })
            .width(140)
            .height(40)
            .backgroundColor('#00de7a')
            .fontColor(Color.White)
            .onClick(() => {
              if (this.onClose) {
                this.onClose();
              }
            })
        } else if (this.task.status === TransferStatus.FAILED) {
          Button('重试', { type: ButtonType.Normal, stateEffect: true })
            .width(140)
            .height(40)
            .backgroundColor('#007aff')
            .fontColor(Color.White)
            .onClick(() => {
              // TODO: 实现重试逻辑
            })
        } else {
          Button('关闭', { type: ButtonType.Normal, stateEffect: true })
            .width(140)
            .height(40)
            .backgroundColor('#999999')
            .fontColor(Color.White)
            .onClick(() => {
              if (this.onClose) {
                this.onClose();
              }
            })
        }
      }
      .width('100%')
      .height(80)
      .justifyContent(FlexAlign.Center)
      .padding({ left: 20, right: 20 })
      .backgroundColor('#ffffff')
      .border({ width: { top: 1 }, color: '#e5e5e5' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
  
  /**
   * 获取文件类型图标
   */
  private getFileTypeIcon(fileName: string): string {
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
}