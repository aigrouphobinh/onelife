package com.aigrouphobinh.onelife

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build

/**
 * Explicit, non-exported receiver for scheduled Android notifications and
 * their two buttons. Uses goAsync so the SQLite mutation finishes before the
 * broadcast is released, even if OneLife's Flutter activity is not open.
 */
class TaskReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra(TaskReminders.EXTRA_ID) ?: return
        val pending = goAsync()
        val app = context.applicationContext
        Thread {
            try {
                when (intent.action) {
                    TaskReminders.ACTION_ALARM -> TaskReminders.deliver(app, id)
                    TaskReminders.ACTION_DONE -> TaskReminders.complete(app, id)
                    TaskReminders.ACTION_SNOOZE -> TaskReminders.snooze(app, id)
                }
            } finally {
                pending.finish()
            }
        }.start()
    }

    companion object {
        private fun replyIntent(
            context: Context, id: String, action: String,
        ): PendingIntent {
            val i = Intent(context, TaskReminderReceiver::class.java).apply {
                this.action = action
                data = Uri.parse("onelife://reminder/action/" +
                    action.substringAfterLast('.') + "/" + Uri.encode(id))
                putExtra(TaskReminders.EXTRA_ID, id)
            }
            return PendingIntent.getBroadcast(
                context, 0, i,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        }

        internal fun show(context: Context, task: TaskReminders.Task) {
            TaskReminders.channel(context)
            val open = Intent(context, MainActivity::class.java).apply {
                putExtra(MainActivity.EXTRA_TODAY_TASKS, true)
                data = Uri.parse("onelife://reminder/open/" + Uri.encode(task.id))
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            val openPending = PendingIntent.getActivity(
                context, 0, open,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            val publicBuilder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                Notification.Builder(context, TaskReminders.CHANNEL_ID)
            else Notification.Builder(context)
            val publicVersion = publicBuilder
                .setSmallIcon(R.drawable.ic_onelife_today)
                .setContentTitle("OneLife")
                .setContentText("Bạn có một việc cần làm")
                .build()

            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                Notification.Builder(context, TaskReminders.CHANNEL_ID)
            else Notification.Builder(context)
            val notification = builder
                .setSmallIcon(R.drawable.ic_onelife_today)
                .setContentTitle("OneLife · Nhắc việc")
                .setContentText(task.title)
                .setCategory(Notification.CATEGORY_REMINDER)
                .setVisibility(Notification.VISIBILITY_PRIVATE)
                .setPublicVersion(publicVersion)
                .setContentIntent(openPending)
                .setAutoCancel(true)
                .addAction(Notification.Action.Builder(
                    Icon.createWithResource(context, R.drawable.ic_onelife_today),
                    "Hoàn thành", replyIntent(context, task.id, TaskReminders.ACTION_DONE),
                ).build())
                .addAction(Notification.Action.Builder(
                    Icon.createWithResource(context, R.drawable.ic_onelife_focus),
                    "Nhắc lại 10 phút",
                    replyIntent(context, task.id, TaskReminders.ACTION_SNOOZE),
                ).build())
                .build()
            context.getSystemService(NotificationManager::class.java)
                ?.notify(task.id, TaskReminders.NOTICE_ID, notification)
        }
    }
}
