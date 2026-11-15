package com.aigrouphobinh.onelife

import android.app.StatusBarManager
import android.content.ComponentName
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
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
                "requestAddTile" -> requestAddQuickSettingsTile(
                    call.argument<String>("tile"),
                    result,
                )
                else -> result.notImplemented()
            }
        }
    }


    /**
     * Android 13+ owns the Add Tile consent dialog. Older Android versions
     * require users to edit Quick Settings and drag the tiles themselves.
     */
    private fun requestAddQuickSettingsTile(kind: String?, result: MethodChannel.Result) {
        if (kind != "focus" && kind != "capture") {
            result.error("INVALID_TILE", "Unsupported OneLife tile", null)
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success("manual")
            return
        }
        val component = if (kind == "focus") {
            ComponentName(this, FocusTileService::class.java)
        } else {
            ComponentName(this, QuickCaptureTileService::class.java)
        }
        val label = if (kind == "focus") "Tập trung" else "Ghi nhanh"
        val iconId = if (kind == "focus") {
            R.drawable.ic_onelife_focus
        } else {
            R.drawable.ic_onelife_capture
        }
        try {
            val service = getSystemService(StatusBarManager::class.java)
            if (service == null) {
                result.success("manual")
                return
            }
            service.requestAddTileService(
                component,
                label,
                Icon.createWithResource(this, iconId),
                mainExecutor,
            ) { code ->
                val outcome = when (code) {
                    StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_ADDED,
                    StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_ALREADY_ADDED -> "added"
                    StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_NOT_ADDED -> "declined"
                    else -> "manual"
                }
                result.success(outcome)
            }
        } catch (_: Exception) {
            result.success("manual")
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
