import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

class Tray {
  static Future<void> initMenu() async {
    await trayManager.setIcon(
      Platform.isWindows ? 'images/favicon.ico' : 'assets/favicon.png',
    );
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: '查看',
        ),
        MenuItem(
          key: 'setting',
          label: '偏好设置',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'check_update',
          label: '检查更新',
        ),
        MenuItem(
          key: 'exit_app',
          label: '退出',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

}
