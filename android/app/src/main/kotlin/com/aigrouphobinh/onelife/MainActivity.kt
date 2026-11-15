package com.aigrouphobinh.onelife

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Delivers Android Quick Settings "Ghi nhanh" events to Flutter.
 *
 * Cold start: Flutter consumes a single pending launch action.
 * Warm start: an onNewIntent event opens capture without rebuilding the app.
 * Both paths use an explicit in-app action, never an untrusted external URL.
 */
class MainActivity : FlutterActivity() {
    companion object {
        const val EXTRA_QUICK_CAPTURE = "com.aigrouphobinh.onelife.extra.QUICK_CAPTURE"
        private const val CHANNEL = "onelife/quick_capture"
    }

    private var pendingCapture = false
    private var actionChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        pendingCapture = intent?.getBooleanExtra(EXTRA_QUICK_CAPTURE, false) == true
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        actionChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        actionChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "consumeLaunchAction" -> {
                    val action: String? = if (pendingCapture) "capture" else null
                    pendingCapture = false
                    result.success(action)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra(EXTRA_QUICK_CAPTURE, false)) {
            pendingCapture = true
            actionChannel?.invokeMethod("openCapture", null)
        }
    }

    override fun onDestroy() {
        actionChannel?.setMethodCallHandler(null)
        actionChannel = null
        super.onDestroy()
    }
}
