/*
 * Copyright (C) 2024  即时通讯网(52im.net) & Jack Jiang.
 * The MobileIMSDK-鸿蒙Next客户端 Project. All rights reserved.
 *
 * 联系邮件：jack.jiang@52im.net
 * 联系微信：hellojackjiang
 * 联系QQ： 413980957
 * 技术社区：http://www.52im.net
 */

import { promptAction, router } from '@kit.ArkUI';
import ToolKits from '../utils/ToolKits';

const TAG: string = '[NearbyDevice] ';

/**
 * 附近设备信息
 */
export class DeviceInfo {
  deviceId: string = '';
  deviceName: string = '';
  deviceType: number = 0;
  isOnline: boolean = false;
  isTrusted: boolean = false;
}

/**
 * 模拟设备数据接口
 */
interface MockDeviceData {
  deviceId: string;
  deviceName: string;
  deviceType: number;
  isOnline: boolean;
  isTrusted: boolean;
}

/**
 * 附近设备发现和选择组件
 */
@Component
export struct NearbyDevice {
  @State deviceList: Array<DeviceInfo> = [];
  @State isScanning: boolean = false;
  @State selectedDeviceId: string = '';
  
  // 回调：选择设备
  onDeviceSelected?: (deviceId: string, deviceName: string) => void;
  
  // 回调：关闭
  onClose?: () => void;
  
  aboutToAppear() {
    this.startDeviceDiscovery();
  }
  
  aboutToDisappear() {
    this.stopDeviceDiscovery();
  }
  
  /**
   * 开始设备发现（模拟实现）
   */
  async startDeviceDiscovery() {
    try {
      this.isScanning = true;
      this.deviceList = [];
      
      // 模拟设备发现
      setTimeout(() => {
        // 添加模拟设备
        const mockDevices: MockDeviceData[] = [
          { deviceId: 'device_001', deviceName: '华为手机 P50', deviceType: 1, isOnline: true, isTrusted: true },
          { deviceId: 'device_002', deviceName: '华为平板 MatePad', deviceType: 2, isOnline: true, isTrusted: false },
          { deviceId: 'device_003', deviceName: '华为手表 Watch 3', deviceType: 3, isOnline: false, isTrusted: true },
          { deviceId: 'device_004', deviceName: '荣耀手机 Magic5', deviceType: 1, isOnline: true, isTrusted: true }
        ];
        
        for (const mockDevice of mockDevices) {
          let deviceInfo = new DeviceInfo();
          deviceInfo.deviceId = mockDevice.deviceId;
          deviceInfo.deviceName = mockDevice.deviceName;
          deviceInfo.deviceType = mockDevice.deviceType;
          deviceInfo.isOnline = mockDevice.isOnline;
          deviceInfo.isTrusted = mockDevice.isTrusted;
          this.deviceList = [...this.deviceList, deviceInfo];
        }
        
        this.isScanning = false;
        ToolKits.showToast('发现 ' + mockDevices.length + ' 个附近设备');
      }, 1000);
      
    } catch (error) {
      console.error(TAG + 'Failed to start device discovery: ' + JSON.stringify(error));
      ToolKits.showToast('设备发现启动失败');
      this.isScanning = false;
    }
  }
  
  /**
   * 停止设备发现
   */
  async stopDeviceDiscovery() {
    this.isScanning = false;
  }
  
  /**
   * 刷新设备列表
   */
  refreshDeviceList() {
    this.deviceList = [];
    this.startDeviceDiscovery();
  }
  
  /**
   * 选择设备
   */
  selectDevice(deviceId: string, deviceName: string) {
    this.selectedDeviceId = deviceId;
    
    if (this.onDeviceSelected) {
      this.onDeviceSelected(deviceId, deviceName);
    }
  }
  

  
  build() {
    Column() {
      // 标题栏
      Row() {
        Text('附近设备')
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
      
      // 设备列表
      if (this.deviceList.length === 0) {
        Column() {
          Image($r("app.media.ic_splash"))
            .width(120)
            .height(120)
            .margin({ bottom: 20 })
            .opacity(0.5)
          
          Text('未发现附近设备')
            .fontSize(16)
            .fontColor('#999')
            .margin({ bottom: 10 })
          
          Text('请确保设备已开启蓝牙和Wi-Fi，并在同一局域网内')
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
          ForEach(this.deviceList, (device: DeviceInfo) => {
            ListItem() {
              Row() {
                // 设备图标
                Image($r("app.media.default_avatar1"))
                  .width(40)
                  .height(40)
                  .borderRadius(20)
                  .margin({ right: 15 })
                
                Column() {
                  Text(device.deviceName)
                    .fontSize(16)
                    .fontColor(Color.Black)
                    .fontWeight(FontWeight.Medium)
                  
                  Row() {
                    Text(device.isTrusted ? '已信任设备' : '新设备')
                      .fontSize(12)
                      .fontColor(device.isTrusted ? '#00de7a' : '#ff9500')
                    
                    Text(device.isOnline ? '在线' : '离线')
                      .fontSize(12)
                      .fontColor(device.isOnline ? '#007aff' : '#999')
                      .margin({ left: 10 })
                  }
                }
                .layoutWeight(1)
                
                // 选择按钮
                Button(this.selectedDeviceId === device.deviceId ? '已选择' : '选择', 
                  { type: ButtonType.Normal, stateEffect: true })
                  .width(60)
                  .height(30)
                  .fontSize(12)
                  .backgroundColor(this.selectedDeviceId === device.deviceId ? '#00de7a' : '#f0f2f6')
                  .fontColor(this.selectedDeviceId === device.deviceId ? Color.White : Color.Black)
                  .onClick(() => {
                    this.selectDevice(device.deviceId, device.deviceName);
                  })
              }
              .width('100%')
              .height(70)
              .padding({ left: 20, right: 20 })
              .backgroundColor(this.selectedDeviceId === device.deviceId ? '#f0f8ff' : Color.White)
              .borderRadius(8)
              .margin({ top: 5, bottom: 5, left: 10, right: 10 })
            }
          }, (device: DeviceInfo) => device.deviceId)
        }
        .width('100%')
        .height(400)
        .layoutWeight(1)
      }
      
      // 底部操作栏
      Row() {
        Button('刷新列表', { type: ButtonType.Normal, stateEffect: true })
          .width(120)
          .height(40)
          .backgroundColor('#f0f2f6')
          .fontColor(Color.Black)
          .onClick(() => {
            this.refreshDeviceList();
          })
        
        Button('确认选择', { type: ButtonType.Normal, stateEffect: true })
          .width(120)
          .height(40)
          .backgroundColor(this.selectedDeviceId ? '#007aff' : '#cccccc')
          .fontColor(Color.White)
          .margin({ left: 20 })
          .enabled(this.selectedDeviceId !== '')
          .onClick(() => {
            if (this.selectedDeviceId && this.onDeviceSelected) {
              let device = this.deviceList.find(d => d.deviceId === this.selectedDeviceId);
              if (device) {
                this.onDeviceSelected(device.deviceId, device.deviceName);
              }
            }
          })
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