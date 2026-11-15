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
 * Dispatch real OneLife Quick Settings actions to Flutter.
 *
 * Cold start: Flutter consumes a single pending launch action.
 * Warm start: onNewIntent delivers to the running Flutter page.
 * Unhandled warm actions remain pending until Flutter consumes them.
 */
class MainActivity : FlutterActivity() {
    companion object {
        const val EXTRA_QUICK_CAPTURE = "com.aigrouphobinh.onelife.extra.QUICK_CAPTURE"
        const val EXTRA_TODAY_TASKS = "com.aigrouphobinh.onelife.extra.TODAY_TASKS"
        private const val CHANNEL = "onelife/quick_capture"
    }

    private var pendingAction: String? = null
    private var actionChannel: MethodChannel? = null

    private fun actionFor(intent: Intent?): String? {
        return when {
            intent?.getBooleanExtra(EXTRA_QUICK_CAPTURE, false) == true -> "capture"
            intent?.getBooleanExtra(EXTRA_TODAY_TASKS, false) == true -> "tasks"
            else -> null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        pendingAction = actionFor(intent)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        actionChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        actionChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "consumeLaunchAction" -> {
                    val action = pendingAction
                    pendingAction = null
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
     * Android 13+ uses the official system Add Tile consent dialog.
     * On Android 7–12 users edit Quick Settings tiles manually.
     */
    private fun requestAddQuickSettingsTile(kind: String?, result: MethodChannel.Result) {
        if (kind != "focus" && kind != "capture" && kind != "today") {
            result.error("INVALID_TILE", "Unsupported OneLife tile", null)
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success("manual")
            return
        }
        val component = when (kind) {
            "focus" -> ComponentName(this, FocusTileService::class.java)
            "capture" -> ComponentName(this, QuickCaptureTileService::class.java)
            else -> ComponentName(this, TodayTasksTileService::class.java)
        }
        val label = when (kind) {
            "focus" -> "Tập trung"
            "capture" -> "Ghi nhanh"
            else -> "Việc hôm nay"
        }
        val iconId = when (kind) {
            "focus" -> R.drawable.ic_onelife_focus
            "capture" -> R.drawable.ic_onelife_capture
            else -> R.drawable.ic_onelife_today
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
        val action = actionFor(intent) ?: return
        pendingAction = action
        val method = if (action == "capture") "openCapture" else "openTasks"
        // Retain pendingAction if Flutter hasn't installed its handler yet.
        actionChannel?.invokeMethod(method, null, object : MethodChannel.Result {
            override fun success(result: Any?) {
                if (pendingAction == action) pendingAction = null
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                // Flutter may not be ready; consumeLaunchAction is the fallback.
            }

            override fun notImplemented() {
                // Flutter may not be ready; consumeLaunchAction is the fallback.
            }
        })
    }

    override fun onDestroy() {
        actionChannel?.setMethodCallHandler(null)
        actionChannel = null
        super.onDestroy()
    }
}
