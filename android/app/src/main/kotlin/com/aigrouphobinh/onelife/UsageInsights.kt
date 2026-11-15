package com.aigrouphobinh.onelife

import android.app.AppOpsManager
import android.app.KeyguardManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build
import android.os.Process
import android.os.UserManager
import java.util.Calendar

/**
 * User-defined, non-medical daily screen-use reflection.
 *
 * UsageStatsManager only works after the user separately grants special
 * Usage Access. No per-app data/history is persisted or sent off-device.
 * Daily observed foreground time is APPROXIMATE (multi-window, missing
 * events and sessions already foreground before midnight may bias it).
 */
internal object UsageInsights {
    private const val PREFS = "onelife_wellbeing_goals"
    private const val GOAL = "daily_reflection_goal_minutes"
    private const val MIN_GOAL = 30
    private const val MAX_GOAL = 720
    private const val MINUTE_MS = 60_000L

    /**
     * There is intentionally no default goal. Permission alone must never
     * label someone balanced, strained or overloaded.
     */
    fun goalMinutes(context: Context): Int? {
        val value = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getInt(GOAL, 0)
        return value.takeIf { it in MIN_GOAL..MAX_GOAL }
    }

    /** User action only; returning false means no preference was changed. */
    fun saveGoal(context: Context, minutes: Int?): Boolean {
        if (minutes != null && minutes !in MIN_GOAL..MAX_GOAL) return false
        val edit = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
        if (minutes == null) edit.remove(GOAL) else edit.putInt(GOAL, minutes)
        return edit.commit()
    }

    fun classify(minutes: Int, goal: Int?): String {
        if (goal == null || goal !in MIN_GOAL..MAX_GOAL || minutes < 0) {
            return "unknown"
        }
        return when {
            minutes >= goal -> "overloaded"
            minutes.toLong() * 5 >= goal.toLong() * 4 -> "strained"
            else -> "balanced"
        }
    }

    fun granted(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return false
        return try {
            val ops = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val result = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                ops.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName,
                )
            } else {
                @Suppress("DEPRECATION")
                ops.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName,
                )
            }
            result == AppOpsManager.MODE_ALLOWED
        } catch (_: Exception) { false }
    }

    fun snapshot(context: Context): Map<String, Any?> {
        val goal = goalMinutes(context)
        if (!granted(context)) return unavailable(false, "permission_required", goal)
        val unlocked = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            (context.getSystemService(Context.USER_SERVICE) as? UserManager)
                ?.isUserUnlocked ?: true
        } else true
        val locked = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            (context.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager)
                ?.isDeviceLocked ?: false
        } else false
        if (!unlocked || locked) return unavailable(true, "device_locked", goal)

        return try {
            val start = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }.timeInMillis
            val end = System.currentTimeMillis()
            if (end <= start) return unavailable(true, "no_data", goal)
            val usageManager =
                context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val events = usageManager.queryEvents(start, end)
                ?: return unavailable(true, "no_data", goal)
            val event = UsageEvents.Event()
            val resumed = mutableMapOf<String, Long>()
            var observed = false
            var total = 0L
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                val time = event.timeStamp.coerceIn(start, end)
                when (event.eventType) {
                    UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                        val pkg = event.packageName ?: continue
                        resumed.putIfAbsent(pkg, time)
                        observed = true
                    }
                    UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                        val pkg = event.packageName ?: continue
                        val begin = resumed.remove(pkg)
                        if (begin != null && time >= begin) total += time - begin
                    }
                    UsageEvents.Event.SCREEN_NON_INTERACTIVE -> {
                        for (begin in resumed.values) {
                            if (time >= begin) total += time - begin
                        }
                        resumed.clear()
                    }
                }
            }
            if (!observed) return unavailable(true, "no_data", goal)
            for (begin in resumed.values) {
                if (end >= begin) total += end - begin
            }
            // Multi-window observations can overlap. Never exceed wall time.
            val minutes = (total.coerceIn(0L, end - start) / MINUTE_MS).toInt()
            mapOf(
                "granted" to true, "available" to true,
                "minutes" to minutes, "goalMinutes" to goal,
                "tier" to classify(minutes, goal),
                "reason" to if (goal == null) "no_personal_goal" else "observed_foreground_events",
            )
        } catch (_: SecurityException) {
            unavailable(false, "permission_revoked", goal)
        } catch (_: Exception) {
            unavailable(true, "no_data", goal)
        }
    }

    private fun unavailable(
        permissionGranted: Boolean,
        reason: String,
        goal: Int?,
    ): Map<String, Any?> = mapOf(
        "granted" to permissionGranted, "available" to false,
        "minutes" to null, "goalMinutes" to goal,
        "tier" to "unknown", "reason" to reason,
    )
}
