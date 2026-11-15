package com.aigrouphobinh.onelife

import android.Manifest
import android.app.StatusBarManager
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.drawable.Icon
import android.net.Uri
import android.provider.Settings
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
        const val EXTRA_FOCUS = "com.aigrouphobinh.onelife.extra.FOCUS"
        private const val CHANNEL = "onelife/quick_capture"
        private const val PERMISSION_REQUEST_NOTIFICATIONS = 3411
    }

    private var pendingAction: String? = null
    private var actionChannel: MethodChannel? = null
    private var pendingNotificationResult: MethodChannel.Result? = null

    private fun actionFor(intent: Intent?): String? {
        return when {
            intent?.getBooleanExtra(EXTRA_QUICK_CAPTURE, false) == true -> "capture"
            intent?.getBooleanExtra(EXTRA_TODAY_TASKS, false) == true -> "tasks"
            intent?.getBooleanExtra(EXTRA_FOCUS, false) == true -> "focus"
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
                "requestPinWidget" -> requestPinWidget(result)
                "refreshWidgets" -> {
                    OneLifeHomeWidgetProvider.refresh(this)
                    result.success(true)
                }
                "remindersStatus" -> result.success(TaskReminders.enabled(this))
                "syncReminders" -> {
                    TaskReminders.sync(this)
                    result.success(TaskReminders.enabled(this))
                }
                "disableReminders" -> {
                    TaskReminders.disable(this)
                    result.success(false)
                }
                "enableReminders" -> requestReminderPermission(result)
                "overlayStatus" -> result.success(
                    mapOf(
                        "supported" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O),
                        "permissionGranted" to overlayAllowed(),
                        "running" to (overlayAllowed() && BrainOverlayService.isVisible),
                    ),
                )
                "requestOverlayPermission" -> requestOverlayPermission(result)
                "startBrainOverlay" -> startBrainOverlay(result)
                "stopBrainOverlay" -> {
                    stopService(Intent(this, BrainOverlayService::class.java))
                    result.success("requested")
                }
                "usageSnapshot" -> {
                    // UsageEvents may contain many events: never query on UI thread.
                    Thread {
                        val snapshot = UsageInsights.snapshot(applicationContext)
                        runOnUiThread { result.success(snapshot) }
                    }.start()
                }
                "setUsageDailyGoal" -> {
                    val minutes = call.argument<Int>("minutes")
                    val valid = UsageInsights.saveGoal(this, minutes)
                    if (valid && BrainOverlayService.isVisible) {
                        // Refresh the visible Brain, never start a new overlay.
                        startService(Intent(this, BrainOverlayService::class.java).apply {
                            action = BrainOverlayService.ACTION_REFRESH
                        })
                    }
                    result.success(valid)
                }
                "openUsageAccessSettings" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success("opened")
                    } catch (_: Exception) {
                        result.success("unavailable")
                    }
                }
                "breakSnapshot" -> result.success(BrainBreaks.snapshot(this))
                "startBrainBreak" -> {
                    val minutes = call.argument<Int>("minutes") ?: 0
                    result.success(BrainBreaks.start(this, minutes).also {
                        refreshActiveBrainBreak()
                    })
                }
                "finishBrainBreak" -> result.success(BrainBreaks.finish(this).also {
                    refreshActiveBrainBreak()
                })
                "cancelBrainBreak" -> result.success(BrainBreaks.cancel(this).also {
                    refreshActiveBrainBreak()
                })
                else -> result.notImplemented()
            }
        }
    }

    /** An existing user-started Brain can redraw, but this never starts it. */
    private fun refreshActiveBrainBreak() {
        if (!BrainOverlayService.isVisible || !overlayAllowed()) return
        try {
            startService(Intent(this, BrainOverlayService::class.java).apply {
                action = BrainOverlayService.ACTION_REFRESH
            })
        } catch (_: Exception) {
            // A break session works without the optional overlay.
        }
    }

    private fun overlayAllowed(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            Settings.canDrawOverlays(this)

    /** Opens Android's own special-app-access page; no silent permission grant. */
    private fun requestOverlayPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.success("unsupported")
            return
        }
        if (overlayAllowed()) {
            result.success("granted")
            return
        }
        try {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:" + packageName),
            )
            startActivity(intent)
            result.success("opened")
        } catch (_: Exception) {
            result.success("unavailable")
        }
    }

    /** Only called from the user's visible Flutter settings page. */
    private fun startBrainOverlay(result: MethodChannel.Result) {
        if (!overlayAllowed()) {
            result.success("permission_required")
            return
        }
        if (BrainOverlayService.isVisible) {
            result.success("running")
            return
        }
        try {
            val component = startService(Intent(this, BrainOverlayService::class.java))
            // "requested" only: the service must still add its actual window.
            result.success(if (component != null) "requested" else "unavailable")
        } catch (_: Exception) {
            result.success("unavailable")
        }
    }

    private fun requestReminderPermission(result: MethodChannel.Result) {
        if (pendingNotificationResult != null) {
            result.error("BUSY", "Notification permission prompt already open", null)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                PackageManager.PERMISSION_GRANTED
        ) {
            pendingNotificationResult = result
            requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                PERMISSION_REQUEST_NOTIFICATIONS,
            )
        } else {
            result.success(TaskReminders.enable(this))
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != PERMISSION_REQUEST_NOTIFICATIONS) return
        val result = pendingNotificationResult ?: return
        pendingNotificationResult = null
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        result.success(granted && TaskReminders.enable(this))
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

    /**
     * Only the launcher/system can pin a widget; this requests the official
     * UI, never silently places a widget on the user's home screen.
     */
    private fun requestPinWidget(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.success("manual")
            return
        }
        val manager = AppWidgetManager.getInstance(this)
        if (!manager.isRequestPinAppWidgetSupported) {
            result.success("manual")
            return
        }
        try {
            val component = ComponentName(this, OneLifeHomeWidgetProvider::class.java)
            val accepted = manager.requestPinAppWidget(component, null, null)
            // 'requested' means the system accepted a request, not pinned.
            result.success(if (accepted) "requested" else "manual")
        } catch (_: Exception) {
            result.success("manual")
        }
    }

    override fun onResume() {
        super.onResume()
        // Special access can be revoked outside the app while Brain is shown.
        if (!overlayAllowed() && BrainOverlayService.isVisible) {
            stopService(Intent(this, BrainOverlayService::class.java))
        }
        OneLifeHomeWidgetProvider.refresh(this)
        // Reconcile future alarms if task status changed via native actions.
        if (TaskReminders.optedIn(this)) TaskReminders.sync(this)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val action = actionFor(intent) ?: return
        pendingAction = action
        val method = when (action) {
            "capture" -> "openCapture"
            "focus" -> "openFocus"
            else -> "openTasks"
        }
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
        pendingNotificationResult?.error(
            "CANCELLED", "Activity was destroyed during the permission request", null,
        )
        pendingNotificationResult = null
        actionChannel?.setMethodCallHandler(null)
        actionChannel = null
        super.onDestroy()
    }
}
