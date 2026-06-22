/*
 * Copyright (C) 2024  即时通讯网(52im.net) & Jack Jiang.
 * The MobileIMSDK-鸿蒙Next客户端 Project. All rights reserved.
 *
 * 联系邮件：jack.jiang@52im.net
 * 联系微信：hellojackjiang
 * 联系QQ： 413980957
 * 技术社区：http://www.52im.net
 */

import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import fs from '@ohos.file.fs';

const TAG: string = '[FilePicker] ';

/**
 * 文件信息
 */
export class FileInfo {
  fileName: string = '';
  filePath: string = '';
  fileSize: number = 0;
  fileType: string = '';
  lastModified: number = 0;
}

/**
 * 模拟文件数据接口
 */
interface MockFileData {
  fileName: string;
  filePath: string;
  fileSize: number;
  fileType: string;
  lastModified: number;
}

/**
 * 文件选择器组件
 */
@Component
export struct FilePicker {
  @State selectedFiles: Array<FileInfo> = [];
  @State isSelecting: boolean = false;
  
  // 回调：文件选择完成
  onFilesSelected?: (files: Array<FileInfo>) => void;
  
  // 回调：关闭
  onClose?: () => void;
  
  /**
   * 打开文件选择器（模拟实现）
   */
  async openFilePicker() {
    try {
      this.isSelecting = true;
      
      // 模拟文件选择结果
      setTimeout(() => {
        const mockFiles: MockFileData[] = [
          {
            fileName: 'example.jpg',
            filePath: '/data/storage/el2/base/files/example.jpg',
            fileSize: 1024 * 1024, // 1MB
            fileType: 'image',
            lastModified: Date.now()
          },
          {
            fileName: 'document.txt',
            filePath: '/data/storage/el2/base/files/document.txt',
            fileSize: 1024 * 10, // 10KB
            fileType: 'text',
            lastModified: Date.now() - 3600000
          },
          {
            fileName: 'report.pdf',
            filePath: '/data/storage/el2/base/files/report.pdf',
            fileSize: 1024 * 1024 * 5, // 5MB
            fileType: 'pdf',
            lastModified: Date.now() - 86400000
          }
        ];
        
        const files: Array<FileInfo> = [];
        for (const mockFile of mockFiles) {
          const fileInfo = new FileInfo();
          fileInfo.fileName = mockFile.fileName;
          fileInfo.filePath = mockFile.filePath;
          fileInfo.fileSize = mockFile.fileSize;
          fileInfo.fileType = mockFile.fileType;
          fileInfo.lastModified = mockFile.lastModified;
          files.push(fileInfo);
        }
        
        this.selectedFiles = files;
        
        if (files.length > 0 && this.onFilesSelected) {
          // 只选择第一个文件（模拟单选）
          this.onFilesSelected([files[0]]);
        }
        
        this.isSelecting = false;
        promptAction.showToast({
          message: '已选择模拟文件（实际项目中应使用系统文件选择器）',
          duration: 2000
        });
      }, 500);
      
    } catch (error) {
      console.error(TAG + 'File picker error: ' + JSON.stringify(error));
      promptAction.showToast({
        message: '文件选择失败',
        duration: 2000
      });
      this.isSelecting = false;
    }
  }
  
  /**
   * 清除选择的文件
   */
  clearSelection() {
    this.selectedFiles = [];
  }
  
  /**
   * 获取文件大小格式化字符串
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
  getFileTypeIcon(fileType: string): string {
    switch (fileType) {
      case 'image':
        return '🖼️';
      case 'text':
        return '📝';
      case 'pdf':
        return '📄';
      default:
        return '📎';
    }
  }
  
  build() {
    Column() {
      // 标题栏
      Row() {
        Text('选择文件')
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
      
      // 文件选择区域
      Column() {
        if (this.selectedFiles.length === 0) {
          Column() {
            Image($r("app.media.ic_splash"))
              .width(120)
              .height(120)
              .margin({ bottom: 20 })
              .opacity(0.5)
            
            Text('未选择文件')
              .fontSize(16)
              .fontColor('#999')
              .margin({ bottom: 10 })
            
            Text('支持选择图片、txt、pdf文件')
              .fontSize(12)
              .fontColor('#999')
              .textAlign(TextAlign.Center)
              .maxLines(2)
              .margin({ left: 40, right: 40 })
          }
          .width('100%')
          .height(300)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          List() {
            ForEach(this.selectedFiles, (file: FileInfo, index: number) => {
              ListItem() {
                Row() {
                  // 文件类型图标
                  Text(this.getFileTypeIcon(file.fileType))
                    .fontSize(24)
                    .margin({ right: 15 })
                  
                  Column() {
                    Text(file.fileName)
                      .fontSize(16)
                      .fontColor(Color.Black)
                      .fontWeight(FontWeight.Medium)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    
                    Row() {
                      Text(this.formatFileSize(file.fileSize))
                        .fontSize(12)
                        .fontColor('#666')
                      
                      Text(file.fileType.toUpperCase())
                        .fontSize(12)
                        .fontColor('#007aff')
                        .margin({ left: 10 })
                        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                        .backgroundColor('#e6f2ff')
                        .borderRadius(4)
                    }
                    .margin({ top: 4 })
                  }
                  .layoutWeight(1)
                  
                  // 删除按钮
                  Image($r("app.media.ic_warn"))
                    .width(20)
                    .height(20)
                    .objectFit(ImageFit.Contain)
                    .onClick(() => {
                      this.selectedFiles.splice(index, 1);
                      this.selectedFiles = [...this.selectedFiles];
                    })
                }
                .width('100%')
                .height(70)
                .padding({ left: 20, right: 20 })
                .backgroundColor(Color.White)
                .borderRadius(8)
                .margin({ top: 5, bottom: 5, left: 10, right: 10 })
              }
            }, (file: FileInfo) => file.filePath)
          }
          .width('100%')
          .height(300)
          .layoutWeight(1)
        }
      }
      .layoutWeight(1)
      .backgroundColor('#f5f5f5')
      
      // 底部操作栏
      Row() {
        Button('选择文件', { type: ButtonType.Normal, stateEffect: true })
          .width(120)
          .height(40)
          .backgroundColor('#007aff')
          .fontColor(Color.White)
          .onClick(() => {
            this.openFilePicker();
          })
          .enabled(!this.isSelecting)
        
        if (this.selectedFiles.length > 0) {
          Button('确认选择', { type: ButtonType.Normal, stateEffect: true })
            .width(120)
            .height(40)
            .backgroundColor('#00de7a')
            .fontColor(Color.White)
            .margin({ left: 20 })
            .onClick(() => {
              if (this.onFilesSelected) {
                this.onFilesSelected(this.selectedFiles);
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
}