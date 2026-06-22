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

const TAG: string = '[FileTransferService] ';

/**
 * 文件传输状态
 */
export enum TransferStatus {
  IDLE = 0,
  CONNECTING = 1,
  SENDING = 2,
  RECEIVING = 3,
  COMPLETED = 4,
  FAILED = 5,
  CANCELLED = 6
}

/**
 * 文件传输任务
 */
export class TransferTask {
  taskId: string = '';
  fileName: string = '';
  filePath: string = '';
  fileSize: number = 0;
  targetDeviceId: string = '';
  targetDeviceName: string = '';
  status: TransferStatus = TransferStatus.IDLE;
  progress: number = 0;
  transferredBytes: number = 0;
  startTime: number = 0;
  endTime: number = 0;
  errorMessage: string = '';
}

/**
 * 文件传输服务
 */
export default class FileTransferService {
  
  private static instance: FileTransferService;
  // 分布式数据服务（实际项目中应使用分布式数据传输API）
  // private kvManager: any = null;
  // private kvStore: any = null;
  private transferTasks: Map<string, TransferTask> = new Map();
  private sessionId: string = '';
  
  // 事件监听器
  private progressListeners: Map<string, (task: TransferTask) => void> = new Map();
  private statusListeners: Map<string, (task: TransferTask) => void> = new Map();
  
  /**
   * 获取单例
   */
  static getInstance(): FileTransferService {
    if (!FileTransferService.instance) {
      FileTransferService.instance = new FileTransferService();
    }
    return FileTransferService.instance;
  }
  
  private constructor() {
    this.sessionId = this.generateSessionId();
  }
  
  /**
   * 生成会话ID
   */
  private generateSessionId(): string {
    return 'file_transfer_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
  }
  
  /**
   * 初始化分布式数据服务（模拟实现）
   */
  async initDistributedData(context: common.UIAbilityContext): Promise<boolean> {
    try {
      // 模拟分布式数据服务初始化
      // 实际项目中应使用分布式数据传输API
      console.log(TAG + 'Distributed data service initialized successfully (simulated)');
      return true;
      
    } catch (error) {
      console.error(TAG + 'Failed to initialize distributed data service: ' + JSON.stringify(error));
      return false;
    }
  }
  
  /**
   * 发送文件到设备
   */
  async sendFile(filePath: string, fileName: string, targetDeviceId: string, targetDeviceName: string): Promise<string> {
    const taskId = this.generateTaskId();
    const task = new TransferTask();
    task.taskId = taskId;
    task.fileName = fileName;
    task.filePath = filePath;
    task.targetDeviceId = targetDeviceId;
    task.targetDeviceName = targetDeviceName;
    task.status = TransferStatus.CONNECTING;
    task.startTime = Date.now();
    
    // 获取文件大小
    try {
      const file = fs.openSync(filePath);
      const stat = fs.statSync(filePath);
      task.fileSize = stat.size;
      fs.closeSync(file);
    } catch (error) {
      task.status = TransferStatus.FAILED;
      task.errorMessage = '无法读取文件信息: ' + JSON.stringify(error);
      this.transferTasks.set(taskId, task);
      this.notifyStatusChange(task);
      return taskId;
    }
    
    this.transferTasks.set(taskId, task);
    this.notifyStatusChange(task);
    
    // 模拟文件传输（实际应该使用分布式数据传输）
    this.simulateFileTransfer(taskId);
    
    return taskId;
  }
  
  /**
   * 模拟文件传输（实际项目中应使用分布式数据传输API）
   */
  private async simulateFileTransfer(taskId: string) {
    const task = this.transferTasks.get(taskId);
    if (!task) return;
    
    task.status = TransferStatus.SENDING;
    this.notifyStatusChange(task);
    
    // 模拟传输进度
    const totalSize = task.fileSize;
    let transferred = 0;
    const chunkSize = 1024 * 1024; // 1MB per chunk
    
    const interval = setInterval(() => {
      if (!this.transferTasks.has(taskId)) {
        clearInterval(interval);
        return;
      }
      
      transferred += chunkSize;
      if (transferred > totalSize) {
        transferred = totalSize;
      }
      
      task.transferredBytes = transferred;
      task.progress = Math.round((transferred / totalSize) * 100);
      this.notifyProgressChange(task);
      
      if (transferred >= totalSize) {
        clearInterval(interval);
        task.status = TransferStatus.COMPLETED;
        task.endTime = Date.now();
        this.notifyStatusChange(task);
        
        // 在实际实现中，这里应该通过分布式数据传输API发送文件
        console.log(TAG + `File transfer completed: ${task.fileName} to ${task.targetDeviceName}`);
      }
    }, 100);
    
    // 模拟传输错误（10%概率）
    if (Math.random() < 0.1) {
      setTimeout(() => {
        if (this.transferTasks.has(taskId)) {
          clearInterval(interval);
          task.status = TransferStatus.FAILED;
          task.errorMessage = '传输中断，请检查网络连接';
          this.notifyStatusChange(task);
        }
      }, 3000);
    }
  }
  
  /**
   * 取消传输
   */
  cancelTransfer(taskId: string): boolean {
    const task = this.transferTasks.get(taskId);
    if (task && (task.status === TransferStatus.SENDING || task.status === TransferStatus.RECEIVING)) {
      task.status = TransferStatus.CANCELLED;
      task.endTime = Date.now();
      this.notifyStatusChange(task);
      return true;
    }
    return false;
  }
  
  /**
   * 获取传输任务
   */
  getTransferTask(taskId: string): TransferTask | undefined {
    return this.transferTasks.get(taskId);
  }
  
  /**
   * 获取所有传输任务
   */
  getAllTransferTasks(): Array<TransferTask> {
    return Array.from(this.transferTasks.values());
  }
  
  /**
   * 生成任务ID
   */
  private generateTaskId(): string {
    return 'task_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
  }
  
  /**
   * 注册进度监听器
   */
  registerProgressListener(taskId: string, listener: (task: TransferTask) => void): void {
    this.progressListeners.set(taskId, listener);
  }
  
  /**
   * 注册状态监听器
   */
  registerStatusListener(taskId: string, listener: (task: TransferTask) => void): void {
    this.statusListeners.set(taskId, listener);
  }
  
  /**
   * 取消注册监听器
   */
  unregisterListeners(taskId: string): void {
    this.progressListeners.delete(taskId);
    this.statusListeners.delete(taskId);
  }
  
  /**
   * 通知进度变化
   */
  private notifyProgressChange(task: TransferTask): void {
    const listener = this.progressListeners.get(task.taskId);
    if (listener) {
      listener(task);
    }
  }
  
  /**
   * 通知状态变化
   */
  private notifyStatusChange(task: TransferTask): void {
    const listener = this.statusListeners.get(task.taskId);
    if (listener) {
      listener(task);
    }
  }
  
  /**
   * 保存接收到的文件
   */
  async saveReceivedFile(fileData: ArrayBuffer, fileName: string, context: common.UIAbilityContext): Promise<string> {
    try {
      // 创建保存目录
      const filesDir = context.filesDir;
      const saveDir = filesDir + '/received_files/';
      
      // 确保目录存在
      try {
        fs.mkdirSync(saveDir);
      } catch (error) {
        // 目录可能已存在
      }
      
      // 生成唯一文件名
      const timestamp = Date.now();
      const uniqueFileName = `${timestamp}_${fileName}`;
      const filePath = saveDir + uniqueFileName;
      
      // 写入文件
      const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      fs.writeSync(file.fd, fileData);
      fs.closeSync(file);
      
      console.log(TAG + `File saved: ${filePath}`);
      return filePath;
      
    } catch (error) {
      console.error(TAG + 'Failed to save received file: ' + JSON.stringify(error));
      throw new Error('Failed to save received file: ' + JSON.stringify(error));
    }
  }
  
  /**
   * 读取文件为ArrayBuffer
   */
  async readFileAsArrayBuffer(filePath: string): Promise<ArrayBuffer> {
    try {
      const file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(filePath);
      const buffer = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file);
      return buffer;
    } catch (error) {
      console.error(TAG + 'Failed to read file: ' + JSON.stringify(error));
      throw new Error('Failed to read file: ' + JSON.stringify(error));
    }
  }
  
  /**
   * 获取文件大小
   */
  getFileSize(filePath: string): number {
    try {
      const stat = fs.statSync(filePath);
      return stat.size;
    } catch (error) {
      console.error(TAG + 'Failed to get file size: ' + JSON.stringify(error));
      return 0;
    }
  }
  
  /**
   * 获取文件扩展名
   */
  getFileExtension(fileName: string): string {
    const lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex === -1) {
      return '';
    }
    return fileName.substring(lastDotIndex + 1).toLowerCase();
  }
  
  /**
   * 获取文件类型图标
   */
  getFileTypeIcon(fileName: string): string {
    const ext = this.getFileExtension(fileName);
    
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