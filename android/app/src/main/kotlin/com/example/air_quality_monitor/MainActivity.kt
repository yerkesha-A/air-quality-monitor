package com.example.air_quality_monitor

import android.os.BatteryManager
import android.os.Build
import android.content.Context
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "air_quality_monitor/device")
            .setMethodCallHandler { call, result ->
                if (call.method != "getDeviceInfo") {
                    result.notImplemented()
                } else {
                    val battery = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
                    val level = battery.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
                    @Suppress("DEPRECATION")
                    val info = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
                    val mapsKey = info.metaData?.getString("com.google.android.geo.API_KEY") ?: ""
                    val firebaseId = resources.getIdentifier("google_app_id", "string", packageName)
                    val webClientId = resources.getIdentifier("default_web_client_id", "string", packageName)
                    result.success(mapOf(
                        "battery" to if (level in 0..100) level else null,
                        "model" to Build.MODEL,
                        "sdk" to Build.VERSION.SDK_INT,
                        "mapsConfigured" to mapsKey.isNotBlank(),
                        "firebaseConfigured" to (firebaseId != 0),
                        "googleClientId" to if (webClientId != 0) resources.getString(webClientId) else ""
                    ))
                }
            }
    }
}
