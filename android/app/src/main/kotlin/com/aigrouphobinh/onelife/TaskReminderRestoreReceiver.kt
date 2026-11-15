package com.aigrouphobinh.onelife

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Enabled only after the user opts in. Android discards AlarmManager pending
 * operations at shutdown, so future due times must be restored after boot.
 */
class TaskReminderRestoreReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != Intent.ACTION_TIME_CHANGED &&
            intent.action != Intent.ACTION_TIMEZONE_CHANGED
        ) return
        val pending = goAsync()
        val app = context.applicationContext
        Thread {
            try {
                TaskReminders.sync(app)
            } finally {
                pending.finish()
            }
        }.start()
    }
}
