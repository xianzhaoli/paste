import 'dart:ffi';

import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:paste/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_setting.dart';

class SystemConfig {

  static Future<AppSetting> loadSystemConfig() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? autoLaunchEnable = prefs.getBool('startOnLaunch');
    int? retentionDays = prefs.getInt('retentionDays');

    return AppSetting(autoLaunchEnable!, retentionDays ?? 30);
  }

  static Future<AppSetting> configLaunchEnable(bool enable) async {
    bool isEnabled = await launchAtStartup.isEnabled();
    enable && !isEnabled
        ? await launchAtStartup.enable()
        : !enable && isEnabled
            ? await launchAtStartup.disable()
            : print(0);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('startOnLaunch', await launchAtStartup.isEnabled());
    return loadSystemConfig();
  }

  static Future<AppSetting> configRetentionDays(int days) async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('retentionDays',days);
    DatabaseService.removeByTime(days);
    return loadSystemConfig();
  }
}
