
class AppSetting{

  final bool startOnLaunch;

  final int retentionDays;

  AppSetting(this.startOnLaunch, this.retentionDays);

  Map<String, dynamic> toMap() {
    return {
      'startOnLaunch': startOnLaunch,
      'retentionDays': retentionDays,
    };
  }
}