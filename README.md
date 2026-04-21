#I hope I can do better
#original content:harmonychat-main
├── AppScope                # 全局配置
├── entry                   # 主模块（唯一业务模块）
│   ├── src/main/ets
│   │   ├── pages           # 页面层（UI）
│   │   ├── components      # UI组件
│   │   ├── model           # 数据模型
│   │   ├── utils           # 工具类
│   │   └── IMClientManager # IM核心逻辑

#Optimization:(引入分层架构）
UI（pages/components）
↓
ViewModel / Store
↓
Repository
↓
Service（IMClient）
#拆分IMClientManager
IMConnectionService   # 连接管理
MessageService        # 收发消息
EventBus / Dispatcher # 消息分发
