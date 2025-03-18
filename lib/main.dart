import 'dart:io';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:paste/schedule/schedule_task.dart';
import 'package:paste/services/clipboard_service.dart';
import 'package:paste/system/tray.dart';
import 'package:paste/widgets/clipboard_history_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // 必须加上这一行。
  await windowManager.ensureInitialized();
  if (Platform.isMacOS) {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    var osInfo = await deviceInfoPlugin.macOsInfo;
    if (kDebugMode) {
      print(osInfo.systemGUID);
    }
  }

  Tray.initMenu();
  ScheduleTask.initClearDataTask();
  //开机自启
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  launchAtStartup.setup(
    appName: packageInfo.appName,
    appPath: Platform.resolvedExecutable,
    packageName: 'com.quick.paste',
  );

  //第一次打开时默认开机自启
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? startOnLaunch = prefs.getBool('startOnLaunch');
  if (startOnLaunch == null) {
    await launchAtStartup.enable();
  }
  await prefs.setBool('startOnLaunch', await launchAtStartup.isEnabled());

  await hotKeyManager.unregisterAll();
  var displays = PlatformDispatcher.instance.displays;
  // 获取屏幕尺寸
  WindowOptions windowOptions = WindowOptions(
    size: Size(displays.first.size.width * 0.48, 350),
    // 设置为屏幕宽度的80%
    center: false,
    backgroundColor: Colors.transparent,
    alwaysOnTop: true,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAlignment(Alignment.bottomCenter);
    await windowManager.setResizable(false);
    await windowManager.show();
    await windowManager.setMovable(false);
    await windowManager.setClosable(false);
    await windowManager.setMinimizable(false);
    await windowManager.focus();
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(),
    );
  }

  MyApp();
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with TrayListener, WindowListener {
  bool show = true;

  //注册热键
  Future<void> _initHotkey() async {
    await hotKeyManager.register(
      HotKey(
        key: PhysicalKeyboardKey.keyV,
        modifiers: [HotKeyModifier.meta, HotKeyModifier.shift],
        scope: HotKeyScope.system,
      ),
      keyDownHandler: (_) {
        _showOverlay();
      },
    );

    await hotKeyManager.register(
      HotKey(
        key: PhysicalKeyboardKey.escape,
        scope: HotKeyScope.inapp,
      ),
      keyDownHandler: (_) {
        _showOverlay();
      },
    );
  }

  //唤起或者隐藏
  void _showOverlay() {
    if (show) {
      windowManager.hide();
    } else {
      windowManager.show();
    }
    setState(() {
      show = !show;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar( //导航栏
      //   title: Text("App Name"),
      //   actions: <Widget>[ //导航栏右侧菜单
      //     IconButton(icon: Icon(Icons.share), onPressed: () {}),
      //   ],
      // ),
      body: ClipboardHistoryView(),
    );
  }

  @override
  void initState() {
    windowManager.addListener(this);
    trayManager.addListener(this);
    super.initState();
    ClipboardService.startListening();
    _initHotkey();
  }

  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'show_window') {
      // do something
      windowManager.show();
      setState(() {
        show = true;
      });
    } else if (menuItem.key == 'exit_app') {
      // do something
      exit(0);
    } else if (menuItem.key == 'setting') {}
  }

  @override
  void onWindowEvent(String eventName) {
    if (eventName == 'blur') {
      windowManager.hide();
      setState(() {
        show = false;
      });
    }
    print('[WindowManager] onWindowEvent: $eventName');
  }
}
