package com.aigrouphobinh.onelife

import android.content.Context

/**
 * Deliberate, local-only 5/10/15-minute break sessions.
 *
 * No Usage Access, overlay permission, notification, wake lock, background
 * scheduler, network or clock-tick process is needed. A persisted wall-clock
 * deadline is reconciled whenever the Flutter page / visible overlay reads it.
 * After a very late resume, skip Recovering rather than invent a recent break.
 */
internal object BrainBreaks {
    private const val PREFS = "onelife_brain_breaks"
    private const val PHASE = "phase"
    private const val END = "deadline_ms"
    private const val DURATION = "minutes"
    private const val SEQUENCE = "sequence"
    private const val RECOVERY_START = "recovery_start_ms"
    private const val RECOVERY_MS = 12L * 125L // actual recovering atlas
    private const val MAX_LATE_MS = 3_000L

    private fun prefs(c: Context) =
        c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun clear(c: Context): Boolean = prefs(c).edit()
        .remove(PHASE).remove(END).remove(DURATION).remove(RECOVERY_START)
        .commit()

    @Synchronized
    fun snapshot(c: Context, now: Long = System.currentTimeMillis()): Map<String, Any?> {
        val p = prefs(c)
        val sequence = p.getLong(SEQUENCE, 0L)
        val phase = p.getString(PHASE, "idle") ?: "idle"
        val duration = p.getInt(DURATION, 0)
        if (phase == "resting") {
            val deadline = p.getLong(END, 0L)
            if (deadline <= 0L || duration !in listOf(5, 10, 15)) {
                clear(c)
                return state("idle", sequence)
            }
            if (now < deadline) {
                return state(
                    "resting", sequence, duration,
                    ((deadline - now + 999L) / 1000L).coerceAtLeast(0L).toInt(),
                    deadline,
                )
            }
            // Only a real observed completion near the actual deadline
            // may trigger the one-shot Recovering animation.
            if (now - deadline in 0L..MAX_LATE_MS) {
                if (!p.edit().putString(PHASE, "recovering")
                        .putLong(RECOVERY_START, now).remove(END).commit()) {
                    return state("resting", sequence, duration, 0, deadline)
                }
                return state("recovering", sequence, duration, 0, 0L, now)
            }
            clear(c)
            return state("idle", sequence)
        }
        if (phase == "recovering") {
            val began = p.getLong(RECOVERY_START, 0L)
            if (began <= 0L || now < began || now - began >= RECOVERY_MS) {
                clear(c)
                return state("idle", sequence)
            }
            return state("recovering", sequence, duration, 0, 0L, began)
        }
        return state("idle", sequence)
    }

    @Synchronized
    fun start(c: Context, minutes: Int, now: Long = System.currentTimeMillis()): Map<String, Any?> {
        if (minutes !in listOf(5, 10, 15)) return error("unsupported_duration", c)
        if (snapshot(c, now)["phase"] != "idle") return error("already_active", c)
        val p = prefs(c)
        val sequence = p.getLong(SEQUENCE, 0L) + 1L
        val deadline = now + minutes * 60_000L
        val committed = p.edit().putLong(SEQUENCE, sequence)
            .putString(PHASE, "resting")
            .putInt(DURATION, minutes)
            .putLong(END, deadline)
            .remove(RECOVERY_START).commit()
        if (!committed) return error("storage_error", c)
        return state("resting", sequence, minutes, minutes * 60, deadline)
    }

    /** User explicitly finishes early. Cancellation is a different action. */
    @Synchronized
    fun finish(c: Context, now: Long = System.currentTimeMillis()): Map<String, Any?> {
        val current = snapshot(c, now)
        if (current["phase"] != "resting") return error("not_resting", c)
        val done = prefs(c).edit().putString(PHASE, "recovering")
            .putLong(RECOVERY_START, now).remove(END).commit()
        if (!done) return error("storage_error", c)
        return state("recovering", current["sequence"] as Long,
            current["durationMinutes"] as Int, 0, 0L, now)
    }

    @Synchronized
    fun cancel(c: Context): Map<String, Any?> {
        val seq = prefs(c).getLong(SEQUENCE, 0L)
        if (!clear(c)) return error("storage_error", c)
        return state("idle", seq)
    }

    private fun error(reason: String, c: Context): Map<String, Any?> =
        snapshot(c) + ("error" to reason)

    private fun state(
        phase: String, sequence: Long, duration: Int = 0,
        seconds: Int = 0, deadline: Long = 0L, recoveryStart: Long = 0L,
    ): Map<String, Any?> = mapOf(
        "phase" to phase,
        "sequence" to sequence,
        "durationMinutes" to duration,
        "remainingSeconds" to seconds,
        "deadlineMs" to deadline,
        "recoveryStartMs" to recoveryStart,
        "recoveryDurationMs" to RECOVERY_MS,
    )
}
