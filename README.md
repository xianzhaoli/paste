# paste

**flutter实现的增强粘贴板**
支持平台：**Linux,MacOs,Windows**

Futures:
1、系统配置
-     （1）保留时间
-     （2）开机自启
2、云同步
-     ...

## Getting Started

使用到的组件:

    window_manager 用于窗口管理，自定义初始化大小，关闭按钮最小化。
    hotkey_manager 快捷键唤起、隐藏
    sqflite 粘贴板记录存储
    timeago 时间
    super_clipboard 粘贴板读取
    tray_manager 系统托盘菜单
    launch_at_startup 开机自启
    shared_preferences 系统配置参数

由于我使用的是MacOs所有发行版只有Mac版本