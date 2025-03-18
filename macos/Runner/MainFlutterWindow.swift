import Cocoa
import FlutterMacOS
// Add the LaunchAtLogin module
import LaunchAtLogin
import window_manager
import shared_preferences_foundation
//

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Add FlutterMethodChannel platform code
    FlutterMethodChannel(
      name: "launch_at_startup", binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    .setMethodCallHandler { (_ call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "launchAtStartupIsEnabled":
        result(LaunchAtLogin.isEnabled)
      case "launchAtStartupSetEnabled":
        if let arguments = call.arguments as? [String: Any] {
          LaunchAtLogin.isEnabled = arguments["setEnabledValue"] as! Bool
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    //

    RegisterGeneratedPlugins(registry: flutterViewController)

//     FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
//        Register the plugin which you want access from other isolate.
//         WindowManagerPlugin.register(with: controller.registrar(forPlugin: "WindowManagerPlugin"))
//         ScreenRetrieverMacosPlugin.register(with: controller.registrar(forPlugin: "ScreenRetrieverPlugin"))
//         SharedPreferencesPlugin.register(with: controller.registrar(forPlugin: "SharedPreferencesPlugin"))
//     }
    super.awakeFromNib()
  }
}