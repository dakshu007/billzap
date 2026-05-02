package com.billzap.app

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    private val CHANNEL = "billzap.app/back"
    private var methodChannel: MethodChannel? = null
    private var lastBackTime: Long = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Android 13+ predictive back — register native callback that handles toast logic
        if (Build.VERSION.SDK_INT >= 33) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                android.window.OnBackInvokedDispatcher.PRIORITY_DEFAULT
            ) {
                handleBack()
            }
        }
    }

    @Suppress("MissingSuperCall", "OVERRIDE_DEPRECATION")
    override fun onBackPressed() {
        handleBack()
    }

    private fun handleBack() {
        val now = System.currentTimeMillis()
        if (now - lastBackTime < 2000) {
            // Second press within 2 seconds — actually close
            finish()
            return
        }
        // First press — record time, tell Flutter to show toast
        lastBackTime = now
        methodChannel?.invokeMethod("showExitToast", null)
    }
}
