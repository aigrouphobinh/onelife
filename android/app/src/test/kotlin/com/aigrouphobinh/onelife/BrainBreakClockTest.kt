package com.aigrouphobinh.onelife

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Actual Kotlin policy tests for the native Android break engine.
 * No mocked Usage Access or invented UI state is involved.
 */
class BrainBreakClockTest {
    @Test
    fun sameBootAndAdvancingMonotonicClockAreValid() {
        assertFalse(BrainBreaks.bootInvalid(42, 42, 100_000L, 110_000L))
        assertFalse(BrainBreaks.bootInvalid(-1, null, 100_000L, 110_000L))
    }

    @Test
    fun aDifferentBootInvalidatesStoredElapsedDeadline() {
        assertTrue(BrainBreaks.bootInvalid(42, 43, 100_000L, 101_000L))
    }

    @Test
    fun elapsedRealtimeRestartBeforePreviousStartInvalidatesWithoutBootCount() {
        assertTrue(BrainBreaks.bootInvalid(-1, null, 500_000L, 100_000L))
    }

    @Test
    fun gracefulRecoveryOnlyOccursNearActualDeadline() {
        assertFalse(BrainBreaks.nearDeadline(1L)) // not finished
        assertTrue(BrainBreaks.nearDeadline(0L))
        assertTrue(BrainBreaks.nearDeadline(-100L))
        assertTrue(BrainBreaks.nearDeadline(-3_000L))
        assertFalse(BrainBreaks.nearDeadline(-3_001L)) // long overdue
        assertFalse(BrainBreaks.nearDeadline(-60_000L))
    }

    @Test
    fun wallClockEditsDoNotAffectPureMonotonicDeadlineEligibility() {
        val startElapsed = 1_000_000L
        val endElapsed = startElapsed + 5 * 60_000L
        val before = endElapsed - (startElapsed + 2 * 60_000L)
        val after = endElapsed - (startElapsed + 5 * 60_000L + 50L)
        // The value of DateTime/RTC is deliberately absent from this policy.
        assertFalse(BrainBreaks.nearDeadline(before))
        assertTrue(BrainBreaks.nearDeadline(after))
    }
}
