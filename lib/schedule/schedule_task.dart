import 'dart:async';

import 'package:paste/services/database_service.dart';
import 'package:paste/system/sys_config.dart';

import '../models/app_setting.dart';

class ScheduleTask {
  static Future<void> initClearDataTask() async {
    Timer.periodic(Duration(minutes: 10), (timer) async {
      AppSetting systemConfig = await SystemConfig.loadSystemConfig();
      int retentionDays = systemConfig.retentionDays;
      DatabaseService.removeByTime(retentionDays);
    });
  }
}
