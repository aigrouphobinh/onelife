package com.aigrouphobinh.onelife

import android.Manifest
import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build
import android.os.Process
import android.os.UserManager
import java.util.Calendar

/**
 * Opt-in Android device usage data. No app/package names or event logs leave
 * this class, no database is created and there is no external transmission.
 *
 * Today's value is an APPROXIMATION of observed foreground app intervals:
 * multi-window overlap, OEM event retention, sessions begun before midnight,
 * clock changes and locked profiles can make it incomplete.
 * Never interpret it as medical brain damage, diagnosis or precise screen time.
 */
internal object UsageInsights {
    private const val NINETY_MINUTES = 90L
    private const val THREE_HOURS = 180L
    private const val MINUTE = 60_000L

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
        } catch (_: Exception) {
            false
        }
    }

    fun snapshot(context: Context): Map<String, Any?> {
        if (!granted(context)) return mapOf(
            "granted" to false, "available" to false,
            "minutes" to null, "tier" to "unknown",
            "reason" to "permission_required",
        )
        val unlocked = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            (context.getSystemService(Context.USER_SERVICE) as? UserManager)
                ?.isUserUnlocked ?: true
        } else {
            true
        }
        if (!unlocked) return mapOf(
            "granted" to true, "available" to false,
            "minutes" to null, "tier" to "unknown",
            "reason" to "device_locked",
        )
        return try {
            val startOfToday = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }.timeInMillis
            val end = System.currentTimeMillis()
            if (end <= startOfToday) return unknown("no_data")

            val manager =
                context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val events = manager.queryEvents(startOfToday, end) ?: return unknown("no_data")
            val evt = UsageEvents.Event()
            val resumed = mutableMapOf<String, Long>()
            var observed = false
            var total = 0L
            while (events.hasNextEvent()) {
                events.getNextEvent(evt)
                val stamp = evt.timeStamp.coerceIn(startOfToday, end)
                when (evt.eventType) {
                    UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                        val pkg = evt.packageName ?: continue
                        resumed.putIfAbsent(pkg, stamp)
                        observed = true
                    }
                    UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                        val pkg = evt.packageName ?: continue
                        val start = resumed.remove(pkg)
                        if (start != null && stamp >= start) total += stamp - start
                    }
                    UsageEvents.Event.SCREEN_NON_INTERACTIVE -> {
                        for (begin in resumed.values) {
                            if (stamp >= begin) total += stamp - begin
                        }
                        resumed.clear()
                    }
                }
            }
            if (!observed) return unknown("no_data")
            for (begin in resumed.values) {
                if (end >= begin) total += end - begin
            }
            // Parallel multi-window apps may overlap; do not exceed wall time.
            val bounded = total.coerceIn(0L, end - startOfToday)
            val minutes = (bounded / MINUTE).toInt()
            mapOf(
                "granted" to true,
                "available" to true,
                "minutes" to minutes,
                "tier" to tier(minutes),
                "reason" to "observed_foreground_events",
            )
        } catch (_: SecurityException) {
            unknown("permission_revoked")
        } catch (_: Exception) {
            unknown("no_data")
        }
    }

    private fun tier(minutes: Int): String = when {
        minutes >= THREE_HOURS -> "high"
        minutes >= NINETY_MINUTES -> "break"
        else -> "balanced"
    }

    private fun unknown(reason: String): Map<String, Any?> = mapOf(
        "granted" to true,
        "available" to false,
        "minutes" to null,
        "tier" to "unknown",
        "reason" to reason,
    )
}
