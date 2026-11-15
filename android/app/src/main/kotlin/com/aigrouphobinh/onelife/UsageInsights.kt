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


    /**
     * Observe the most recent 1/7/30 local calendar days. A missing day stays
     * null (unknown), never a fabricated zero. Results are never persisted.
     * One UsageEvents query covers the selected window; boundaries use Calendar
     * so daylight-saving transitions do not shift dates.
     */
    fun history(context: Context, days: Int): Map<String, Any?> {
        if (days !in setOf(1, 7, 30)) {
            return mapOf("granted" to false, "available" to false,
                "reason" to "invalid_period", "days" to emptyList<Any>())
        }
        if (!granted(context)) return historyUnavailable(false, "permission_required")
        val unlocked = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            (context.getSystemService(Context.USER_SERVICE) as? UserManager)
                ?.isUserUnlocked ?: true
        } else true
        val locked = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            (context.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager)
                ?.isDeviceLocked ?: false
        } else false
        if (!unlocked || locked) return historyUnavailable(true, "device_locked")

        return try {
            val calendar = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                add(Calendar.DAY_OF_YEAR, 1 - days)
            }
            val boundaries = LongArray(days + 1) {
                val boundary = calendar.timeInMillis
                calendar.add(Calendar.DAY_OF_YEAR, 1)
                boundary
            }
            val start = boundaries.first()
            val end = System.currentTimeMillis()
            if (end <= start) return historyUnavailable(true, "no_data")
            val manager =
                context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val events = manager.queryEvents(start, end)
                ?: return historyUnavailable(true, "no_data")

            val totalMs = LongArray(days)
            val observed = BooleanArray(days)
            val active = mutableMapOf<String, Long>()
            val event = UsageEvents.Event()

            fun addForeground(from: Long, until: Long) {
                var cursor = from.coerceAtLeast(start)
                val finish = until.coerceAtMost(end)
                while (cursor < finish) {
                    val index = (0 until days).indexOfLast { boundaries[it] <= cursor }
                    if (index < 0) break
                    val edge = minOf(finish, boundaries[index + 1])
                    if (edge <= cursor) break
                    totalMs[index] += edge - cursor
                    observed[index] = true
                    cursor = edge
                }
            }
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                val time = event.timeStamp.coerceIn(start, end)
                when (event.eventType) {
                    UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                        val pkg = event.packageName ?: continue
                        active.putIfAbsent(pkg, time)
                        // A start event counts as evidence even when < 1 minute.
                        val index = (0 until days).indexOfLast { boundaries[it] <= time }
                        if (index >= 0) observed[index] = true
                    }
                    UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                        val pkg = event.packageName ?: continue
                        active.remove(pkg)?.let { addForeground(it, time) }
                    }
                    UsageEvents.Event.SCREEN_NON_INTERACTIVE -> {
                        active.values.forEach { addForeground(it, time) }
                        active.clear()
                    }
                }
            }
            active.values.forEach { addForeground(it, end) }

            val readings = (0 until days).map { index ->
                val day = Calendar.getInstance().apply {
                    timeInMillis = boundaries[index]
                }
                val name = String.format(
                    java.util.Locale.US, "%04d-%02d-%02d",
                    day.get(Calendar.YEAR), day.get(Calendar.MONTH) + 1,
                    day.get(Calendar.DAY_OF_MONTH),
                )
                val duration = (minOf(totalMs[index],
                    minOf(end, boundaries[index + 1]) - boundaries[index])
                    .coerceAtLeast(0L) / MINUTE_MS).toInt()
                mapOf<String, Any?>(
                    "date" to name,
                    "minutes" to if (observed[index]) duration else null,
                )
            }
            mapOf(
                "granted" to true,
                "available" to observed.any { it },
                "reason" to if (observed.any { it }) "observed_foreground_events" else "no_data",
                "days" to readings,
                "observedDays" to observed.count { it },
            )
        } catch (_: SecurityException) {
            historyUnavailable(false, "permission_revoked")
        } catch (_: Exception) {
            historyUnavailable(true, "no_data")
        }
    }

    private fun historyUnavailable(permission: Boolean, reason: String): Map<String, Any?> =
        mapOf(
            "granted" to permission,
            "available" to false,
            "reason" to reason,
            "days" to emptyList<Any>(),
            "observedDays" to 0,
        )

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
