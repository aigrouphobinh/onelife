package com.aigrouphobinh.onelife

import android.content.Context
import android.os.Build
import android.os.SystemClock
import android.provider.Settings

/**
 * User-started, local-only 5/10/15-minute break session.
 *
 * New sessions use SystemClock.elapsedRealtime: it includes deep sleep and
 * cannot be changed by the user editing wall-clock time. Nothing wakes the
 * app or starts an overlay in the background. Reconciliation occurs when the
 * user opens Flutter or when an already visible, opt-in Brain refreshes.
 *
 * A reboot invalidates the monotonic deadline: skip a speculative Recovering
 * celebration rather than claim a break just finished. Legacy sessions
 * written by V3.4 before this change retain wall-clock fallback until expiry.
 */
internal object BrainBreaks {
    private const val PREFS = "onelife_brain_breaks"
    private const val PHASE = "phase"
    private const val END = "deadline_ms"
    private const val DURATION = "minutes"
    private const val SEQUENCE = "sequence"
    private const val RECOVERY_START = "recovery_start_ms"
    private const val MONO_START = "started_elapsed_ms"
    private const val MONO_END = "deadline_elapsed_ms"
    private const val RECOVERY_MONO_START = "recovery_elapsed_ms"
    private const val BOOT = "boot_count"
    private const val RECOVERY_MS = 12L * 125L // actual recovering atlas
    private const val MAX_LATE_MS = 3_000L
    private val OPTIONS = listOf(5, 10, 15)

    private fun prefs(c: Context) =
        c.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun bootCount(c: Context): Int? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return null
        return try {
            Settings.Global.getInt(c.contentResolver, Settings.Global.BOOT_COUNT)
        } catch (_: Exception) {
            null
        }
    }

    private fun clear(c: Context): Boolean = prefs(c).edit()
        .remove(PHASE).remove(END).remove(DURATION).remove(RECOVERY_START)
        .remove(MONO_START).remove(MONO_END).remove(RECOVERY_MONO_START)
        .remove(BOOT).commit()

    /** Pure policy functions are JVM-unit-testable, without a fake Android UI. */
    internal fun bootInvalid(
        previousBoot: Int,
        currentBoot: Int?,
        startedElapsed: Long,
        nowElapsed: Long,
    ): Boolean =
        (startedElapsed > 0L && nowElapsed < startedElapsed) ||
            (previousBoot >= 0 && currentBoot != null && previousBoot != currentBoot)

    internal fun nearDeadline(remainingMs: Long): Boolean =
        remainingMs in -MAX_LATE_MS..0L

    @Synchronized
    fun snapshot(
        c: Context,
        now: Long = System.currentTimeMillis(),
        elapsed: Long = SystemClock.elapsedRealtime(),
    ): Map<String, Any?> {
        val p = prefs(c)
        val sequence = p.getLong(SEQUENCE, 0L)
        val phase = p.getString(PHASE, "idle") ?: "idle"
        val duration = p.getInt(DURATION, 0)
        if (phase == "resting") {
            val deadline = p.getLong(END, 0L)
            if (deadline <= 0L || duration !in OPTIONS) {
                clear(c)
                return state("idle", sequence)
            }
            val monoStart = p.getLong(MONO_START, 0L)
            val monoEnd = p.getLong(MONO_END, 0L)
            val previousBoot = p.getInt(BOOT, -1)
            if (monoEnd > 0L && bootInvalid(previousBoot, bootCount(c), monoStart, elapsed)) {
                // Never carry a per-boot elapsedRealtime deadline into a new boot.
                clear(c)
                return state("idle", sequence, reason = "rebooted")
            }
            val remaining = if (monoEnd > 0L) monoEnd - elapsed else deadline - now
            if (remaining > 0L) {
                return state(
                    "resting", sequence, duration,
                    ((remaining + 999L) / 1000L).toInt(),
                    deadline, remainingMs = remaining,
                )
            }
            // A recovered interval must be observed within 3 seconds of its
            // actual deadline. If resumed much later, do not replay recovery.
            if (nearDeadline(remaining)) {
                val saved = p.edit().putString(PHASE, "recovering")
                    .putLong(RECOVERY_START, now)
                    .putLong(RECOVERY_MONO_START, elapsed)
                    .remove(END).remove(MONO_END).commit()
                if (!saved) {
                    return state("resting", sequence, duration, 0, deadline)
                }
                return state("recovering", sequence, duration,
                    recoveryStart = now, recoveryRemainingMs = RECOVERY_MS)
            }
            clear(c)
            return state("idle", sequence, reason = "expired_while_inactive")
        }
        if (phase == "recovering") {
            val beganWall = p.getLong(RECOVERY_START, 0L)
            val beganElapsed = p.getLong(RECOVERY_MONO_START, 0L)
            val previousBoot = p.getInt(BOOT, -1)
            val invalidBoot = beganElapsed > 0L &&
                bootInvalid(previousBoot, bootCount(c), beganElapsed, elapsed)
            val durationPassed = if (beganElapsed > 0L) {
                elapsed - beganElapsed
            } else {
                now - beganWall // legacy recovery record
            }
            if (beganWall <= 0L || invalidBoot ||
                durationPassed !in 0L until RECOVERY_MS
            ) {
                clear(c)
                return state("idle", sequence)
            }
            return state("recovering", sequence, duration,
                recoveryStart = beganWall,
                recoveryRemainingMs = RECOVERY_MS - durationPassed)
        }
        return state("idle", sequence)
    }

    @Synchronized
    fun start(
        c: Context,
        minutes: Int,
        now: Long = System.currentTimeMillis(),
        elapsed: Long = SystemClock.elapsedRealtime(),
    ): Map<String, Any?> {
        if (minutes !in OPTIONS) return error("unsupported_duration", c)
        if (snapshot(c, now, elapsed)["phase"] != "idle") {
            return error("already_active", c)
        }
        val p = prefs(c)
        val sequence = p.getLong(SEQUENCE, 0L) + 1L
        val interval = minutes * 60_000L
        val deadline = now + interval
        val editor = p.edit()
            .putLong(SEQUENCE, sequence)
            .putString(PHASE, "resting")
            .putInt(DURATION, minutes)
            .putLong(END, deadline)
            .putLong(MONO_START, elapsed)
            .putLong(MONO_END, elapsed + interval)
            .remove(RECOVERY_START)
            .remove(RECOVERY_MONO_START)
        val boot = bootCount(c)
        if (boot != null) editor.putInt(BOOT, boot) else editor.remove(BOOT)
        if (!editor.commit()) return error("storage_error", c)
        return state("resting", sequence, minutes, minutes * 60,
            deadline, remainingMs = interval)
    }

    /** Early finish is explicit success. Cancellation is a separate action. */
    @Synchronized
    fun finish(
        c: Context,
        now: Long = System.currentTimeMillis(),
        elapsed: Long = SystemClock.elapsedRealtime(),
    ): Map<String, Any?> {
        val current = snapshot(c, now, elapsed)
        // Duplicate rapid taps (or a button racing natural expiry) must
        // not restart or replay a 12-frame Recovering animation.
        if (current["phase"] == "recovering") return current
        if (current["phase"] != "resting") return error("not_resting", c)
        val saved = prefs(c).edit().putString(PHASE, "recovering")
            .putLong(RECOVERY_START, now)
            .putLong(RECOVERY_MONO_START, elapsed)
            .remove(END).remove(MONO_END).commit()
        if (!saved) return error("storage_error", c)
        return state("recovering", current["sequence"] as Long,
            current["durationMinutes"] as Int,
            recoveryStart = now, recoveryRemainingMs = RECOVERY_MS)
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
        remainingMs: Long = 0L, recoveryRemainingMs: Long = 0L,
        reason: String? = null,
    ): Map<String, Any?> = mapOf(
        "phase" to phase,
        "sequence" to sequence,
        "durationMinutes" to duration,
        "remainingSeconds" to seconds,
        "remainingMs" to remainingMs,
        "recoveryRemainingMs" to recoveryRemainingMs,
        "deadlineMs" to deadline,
        "recoveryStartMs" to recoveryStart,
        "recoveryDurationMs" to RECOVERY_MS,
        "reason" to reason,
    )
}
