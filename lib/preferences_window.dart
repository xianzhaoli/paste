import 'dart:convert';
import 'dart:ffi';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:paste/system/sys_config.dart';
import 'package:path/path.dart';
import 'package:window_manager/window_manager.dart';

class SettingsWindow extends StatefulWidget {
  final Map<String, dynamic> args;

  const SettingsWindow({super.key, required this.args});

  @override
  State<StatefulWidget> createState() {
    return _SettingsWindowState();
  }
}

class _SettingsWindowState extends State<SettingsWindow> {
  bool startOnLaunch = true;
  double retentionDays = 30;
  bool open = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey[200],
        body: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 7, 15, 0),
              child: Center(
                child: Text('偏好设置'),
              ),
            ),
            SwitchListTile(
              title: const Text('开机自启：'),
              activeColor: Colors.white,
              activeTrackColor:Color.fromRGBO(65, 134, 247, 1),
              value: startOnLaunch,
              onChanged: (value){
                DesktopMultiWindow.invokeMethod(
                    0, 'setting', {'startOnLaunch': value});
                setState(() {
                  startOnLaunch = value;
                });
              },
            ),
            // SwitchListTile(
            //   title: const Text('开机自启'),
            //   onChanged: (value) {
            //     setState(() {
            //       open = value;
            //     });
            //   },
            //   value: open,
            // ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '数据保留时间：',
                    style: TextStyle(fontSize: 16),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.blue,
                        // 选中的轨道颜色
                        inactiveTrackColor: Colors.blue.shade100,
                        // 未选中的轨道颜色
                        thumbColor: Colors.blue,
                        // 滑块颜色
                        overlayColor: Colors.blue.withOpacity(0.3),
                        // 滑块阴影颜色
                        valueIndicatorColor: Colors.blue,
                        // 显示的数值颜色
                        trackHeight: 6,
                        // 轨道高度
                        showValueIndicator: ShowValueIndicator.always, // 始终显示数值
                      ),
                      child: Slider(
                        value: retentionDays,
                        min: 1,
                        max: 365,
                        divisions: 364,
                        // 12 个月的大刻度
                        label: '${retentionDays.toInt()}天',
                        onChanged: (value) {
                          setState(() {
                            retentionDays = value;
                          });
                        },
                        onChangeEnd: (value){
                          DesktopMultiWindow.invokeMethod(
                              0, 'setting', {'retentionDays': value.toInt()});
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    '${retentionDays.toInt()} 天',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> _handleMethodCallback(
      MethodCall call, int fromWindowId) async {
    if (call.arguments.toString() == "ping") {
      return "pong";
    }
  }

  @override
  void initState() {
    super.initState();
    DesktopMultiWindow.setMethodHandler(_handleMethodCallback);
    loadSetting();
  }

  void loadSetting() async {
    var appSetting = await SystemConfig.loadSystemConfig();
    setState(() {
      retentionDays = appSetting.retentionDays.toDouble();
    });
    windowManager.show();
    // dynamic map = await DesktopMultiWindow.invokeMethod(0, 'loadSetting');
    // setState(() {
    //   settingMap = map;
    // });
  }

  @override
  void dispose() {
    DesktopMultiWindow.setMethodHandler(null);
    super.dispose();
  }
}
