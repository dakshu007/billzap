package com.billzap.app

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {

    private val CHANNEL = "billzap.app/back"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // Listen for "exit now" requests from Flutter (when user double-taps back at root)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "exitApp" -> {
                    finish()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Android 13+ predictive back
        if (Build.VERSION.SDK_INT >= 33) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                android.window.OnBackInvokedDispatcher.PRIORITY_DEFAULT
            ) {
                forwardToFlutter()
            }
        }
    }

    @Suppress("MissingSuperCall", "OVERRIDE_DEPRECATION")
    override fun onBackPressed() {
        forwardToFlutter()
    }

    // Always forward to Flutter — Flutter decides what to do (pop route, show toast, or exit)
    private fun forwardToFlutter() {
        methodChannel?.invokeMethod("onBackPressed", null)
    }
}
