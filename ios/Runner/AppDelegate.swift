import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var deviceChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AirQualityDevice") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "air_quality_monitor/device", binaryMessenger: registrar.messenger())
    deviceChannel = channel
    channel.setMethodCallHandler { call, result in
      guard call.method == "getDeviceInfo" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let device = UIDevice.current
      device.isBatteryMonitoringEnabled = true
      let battery = device.batteryLevel
      let config = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist")
        .flatMap { NSDictionary(contentsOf: $0) as? [String: Any] } ?? [:]
      let firebaseConfigured = config["BUNDLE_ID"] as? String == Bundle.main.bundleIdentifier
        && !(config["GOOGLE_APP_ID"] as? String ?? "").isEmpty
        && !(config["API_KEY"] as? String ?? "").isEmpty
        && !(config["PROJECT_ID"] as? String ?? "").isEmpty
      let reversedClientID = config["REVERSED_CLIENT_ID"] as? String ?? ""
      let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes")
        as? [[String: Any]] ?? []
      let schemes = urlTypes.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
      let googleConfigured = firebaseConfigured && !reversedClientID.isEmpty
        && schemes.contains(reversedClientID)
      let info: [String: Any] = [
        "available": true,
        "platform": "iOS",
        "model": device.model,
        "osVersion": device.systemVersion,
        "battery": battery < 0 ? NSNull() : NSNumber(value: Int(battery * 100)),
        "mapsConfigured": false,
        "firebaseConfigured": firebaseConfigured,
        "googleClientId": "",
        "googleIosClientId": googleConfigured ? (config["CLIENT_ID"] as? String ?? "") : "",
        // Enable only after provisioning and the Firebase Apple provider are configured.
        "appleSignInConfigured": firebaseConfigured
          && Bundle.main.object(forInfoDictionaryKey: "AQMAppleSignInEnabled") as? Bool == true,
      ]
      result(info)
    }
  }
}
