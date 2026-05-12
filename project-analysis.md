# HarmonyChat 工程代码分析文档

# 一、项目概述

## 1.1 项目简介

HarmonyChat 是一个基于 HarmonyOS ArkTS 与 ArkUI 开发的即时通讯（IM）应用项目。

该项目主要实现了：
- 用户登录
- 页面跳转
- 即时聊天
- 文本消息展示
- 图片消息展示
- 文件消息展示
- 消息输入与发送
- WebSocket 即时通信

项目采用声明式 UI 开发方式，使用 DevEco Studio 作为开发工具，属于典型的 HarmonyOS 聊天类应用案例。


## 1.2 项目技术栈

本项目主要使用如下技术：
HarmonyOS——操作系统平台
ArkTS——开发语言
ArkUI——UI框架
WebSocket——即时通信
DevEco Studio——开发工具

## 1.3 项目特点

本项目具有以下特点：

### 1. 组件化开发

聊天消息、输入框等功能均进行了组件拆分。

### 2. 即时通信能力

使用 WebSocket 实现即时消息收发。

### 3. 多消息类型支持

支持：

- 文本消息
- 图片消息
- 文件消息

### 4. 基础分层结构

项目已经具备：

- 页面层
- 数据层
- 工具层

等基础结构。

---

# 二、工程目录结构分析

项目主要代码目录如下：

entry/src/main/ets/
├── entryability/EntryAbility.ets          # 应用入口
├── IMClientManager.ets                    # WebSocket通信管理
├── pages/
│   ├── SplashPage.ets                     # 启动页
│   ├── SafePage.ets                       # 隐私协议页  
│   ├── LoginPage.ets                      # 登录页
│   ├── ChatPage.ets                       # 聊天页面（当前主页面）
│   ├── model/
│   │   ├── Message.ets                    # 消息数据模型
│   │   ├── MessagesProvider.ets           # 消息数据管理
│   │   └── MessagesDataSource.ets         # 消息UI数据源
│   ├── components/                         # 组件层
│   ├── constants/                         # 常量定义
│   └── utils/                             # 工具类

整体结构如下：
UI层
│
├── pages（页面）
├── components（组件）
│
数据层
│
├── model（数据）
│
工具层
│
├── utils（工具）
│
通信层
│
└── IMClientManager（即时通信）

本项目主要问题：
1、UI与业务逻辑耦合
2、状态管理较简单
3、页面职责较重
    一个类负责过多逻辑，会导致：
        代码复杂度提高
        可维护性降低
        后期扩展困难
