package com.aigrouphobinh.onelife

import android.app.KeyguardManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

/**
 * Real V3.4 Android home-screen widget. The launcher renders RemoteViews;
 * Flutter doesn't draw the home screen. Data comes from the same private
 * SQLite databases as the in-app tasks and 25-minute Focus session.
 *
 * The widget never copies a task title to the launcher. Counts are hidden
 * while the phone is locked, with no sample or invented data.
 */
class OneLifeHomeWidgetProvider : AppWidgetProvider() {
    companion object {
        private const val REFRESH_ACTION = "com.aigrouphobinh.onelife.WIDGET_REFRESH"
        private const val BRAIN_ASSET = "flutter_assets/assets/characters-v2/brain/master.png"

        /** Called after local task/Focus mutations; no external services. */
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, OneLifeHomeWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            if (ids.isNotEmpty()) {
                val receiver = OneLifeHomeWidgetProvider()
                receiver.updateWidgets(context, manager, ids)
            }
        }

        private fun nextLocalMidnightUtc(): String {
            val next = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                add(Calendar.DATE, 1)
            }
            return SimpleDateFormat(
                "yyyy-MM-dd'T'HH:mm:ss", Locale.US,
            ).apply { timeZone = TimeZone.getTimeZone("UTC") }
                .format(next.time)
        }

        /**
         * Ignore ISO's optional .SSS/.SSSSSS fraction when checking a day
         * boundary: a task at exactly tomorrow's midnight is NOT today.
         */
        internal fun todayCount(context: Context): Int? {
            val file = context.getDatabasePath("onelife_ui.db")
            if (!file.exists()) return 0
            return try {
                SQLiteDatabase.openDatabase(
                    file.path, null, SQLiteDatabase.OPEN_READONLY,
                ).use { db ->
                    db.rawQuery(
                        "SELECT COUNT(*) FROM tasks " +
                            "WHERE completed = 0 AND " +
                            "(due_at_utc IS NULL OR substr(due_at_utc, 1, 19) < ?)",
                        arrayOf(nextLocalMidnightUtc()),
                    ).use { cursor ->
                        if (cursor.moveToFirst()) cursor.getInt(0) else 0
                    }
                }
            } catch (_: Exception) {
                null
            }
        }

        internal fun focusLabel(context: Context): String {
            val file = context.getDatabasePath("onelife_focus.db")
            if (!file.exists()) return "Tập trung 25 phút"
            return try {
                SQLiteDatabase.openDatabase(
                    file.path, null, SQLiteDatabase.OPEN_READONLY,
                ).use { db ->
                    db.rawQuery(
                        "SELECT phase, deadline_utc FROM focus_session " +
                            "WHERE id = 1 LIMIT 1", null,
                    ).use { cursor ->
                        if (!cursor.moveToFirst()) return@use "Tập trung 25 phút"
                        when (cursor.getString(0)) {
                            "paused" -> "Tập trung đã tạm dừng"
                            "running" -> {
                                val deadline = if (cursor.isNull(1)) "" else cursor.getString(1)
                                val normalized = deadline.replace(
                                    Regex("\\.(\\d{3})\\d+Z$"), ".$1Z",
                                )
                                val parsed = SimpleDateFormat(
                                    "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US,
                                ).apply {
                                    timeZone = TimeZone.getTimeZone("UTC")
                                }.parse(normalized)?.time
                                when {
                                    parsed == null -> "Kiểm tra phiên tập trung"
                                    parsed <= System.currentTimeMillis() ->
                                        "Phiên tập trung đã kết thúc"
                                    else -> "Đang tập trung"
                                }
                            }
                            else -> "Tập trung 25 phút"
                        }
                    }
                }
            } catch (_: Exception) {
                "Mở OneLife để xem Focus"
            }
        }

        private fun brainBitmap(context: Context): Bitmap? = try {
            val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            context.assets.open(BRAIN_ASSET).use { BitmapFactory.decodeStream(it, null, options) }
            val largest = maxOf(options.outWidth, options.outHeight)
            if (largest <= 0) return null
            var sample = 1
            while (largest / sample > 160) sample *= 2
            val sampled = BitmapFactory.Options().apply { inSampleSize = sample }
            context.assets.open(BRAIN_ASSET).use { BitmapFactory.decodeStream(it, null, sampled) }
        } catch (_: Exception) {
            null
        }

        private fun launch(
            context: Context,
            action: String,
            requestCode: Int,
        ): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                when (action) {
                    "capture" -> putExtra(MainActivity.EXTRA_QUICK_CAPTURE, true)
                    "focus" -> putExtra(MainActivity.EXTRA_FOCUS, true)
                    else -> putExtra(MainActivity.EXTRA_TODAY_TASKS, true)
                }
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            return PendingIntent.getActivity(
                context, requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        updateWidgets(context, appWidgetManager, appWidgetIds)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == REFRESH_ACTION) refresh(context)
    }

    private fun updateWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        ids: IntArray,
    ) {
        val locked = (context.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager)
            ?.isDeviceLocked ?: false
        val count = if (locked) null else todayCount(context)
        val focus = if (locked) "Mở khóa để xem" else focusLabel(context)
        val art = brainBitmap(context)
        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.onelife_home_widget)
            views.setTextViewText(R.id.widget_count, when {
                locked -> "Đang khóa"
                count == null -> "Chưa có dữ liệu"
                count == 0 -> "Hôm nay không có việc đang chờ"
                else -> "Hôm nay còn $count việc"
            })
            views.setTextViewText(R.id.widget_focus_state, focus)
            if (art != null) views.setImageViewBitmap(R.id.widget_brain, art)
            views.setOnClickPendingIntent(
                R.id.widget_tasks, launch(context, "tasks", id * 10 + 1),
            )
            views.setOnClickPendingIntent(
                R.id.widget_capture, launch(context, "capture", id * 10 + 2),
            )
            views.setOnClickPendingIntent(
                R.id.widget_focus, launch(context, "focus", id * 10 + 3),
            )
            val refresh = Intent(context, OneLifeHomeWidgetProvider::class.java).apply {
                action = REFRESH_ACTION
            }
            views.setOnClickPendingIntent(
                R.id.widget_refresh,
                PendingIntent.getBroadcast(
                    context, id * 10 + 4, refresh,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
