package com.aigrouphobinh.onelife

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.drawable.GradientDrawable
import android.database.sqlite.SQLiteDatabase
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import kotlin.math.abs

/**
 * V3.4 Brain "outside the app" uses a real TYPE_APPLICATION_OVERLAY.
 *
 * Only started by a visible, explicit user action after SYSTEM_ALERT_WINDOW
 * consent. NOT a foreground service, boot receiver, persistent background
 * job, fake Flutter preview, or accessibility overlay. Android may stop this
 * short-lived service to reclaim memory; the user can restart it in Settings.
 */
class BrainOverlayService : Service() {
    companion object {
        private const val PREFS = "onelife_brain_overlay"
        private const val FRAME_MS = 140L
        private const val ATLAS = "flutter_assets/assets/characters-v2/brain/idle/sheet.png"
        private const val MASTER = "flutter_assets/assets/characters-v2/brain/master.png"

        @Volatile
        var isVisible: Boolean = false
            private set
    }

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var manager: WindowManager
    private var root: FrameLayout? = null
    private var options: LinearLayout? = null
    private var usageCaption: TextView? = null
    private var sprite: SpriteView? = null
    private var params: WindowManager.LayoutParams? = null
    private var expanded = false
    private var frame = 0
    private val refreshBehavior = object : Runnable {
        override fun run() {
            if (!isVisible) return
            // Heavy usage/event history and Focus SQLite are read off main UI.
            Thread {
                val snapshot = UsageInsights.snapshot(applicationContext)
                val isFocusRunning = readFocusActive()
                handler.post {
                    if (!isVisible) return@post
                    val tier = snapshot["tier"] as? String ?: "unknown"
                    sprite?.usageTier = tier
                    sprite?.focused = isFocusRunning
                    usageCaption?.text = when {
                        isFocusRunning -> "Đang tập trung · chế độ Focus"
                        snapshot["available"] != true -> "Chưa có dữ liệu thời gian dùng"
                        else -> {
                            val mins = snapshot["minutes"] as? Int ?: 0
                            "Ước tính hôm nay: ${mins / 60} giờ ${mins % 60} phút"
                        }
                    }
                }
            }.start()
            handler.postDelayed(this, 5 * 60 * 1000L)
        }
    }

    private fun readFocusActive(): Boolean {
        val dbFile = getDatabasePath("onelife_focus.db")
        if (!dbFile.exists()) return false
        return try {
            SQLiteDatabase.openDatabase(
                dbFile.path, null, SQLiteDatabase.OPEN_READONLY,
            ).use { db ->
                db.rawQuery(
                    "SELECT phase, deadline_utc FROM focus_session WHERE id=1", null,
                ).use focusRow@ { cursor ->
                    if (!cursor.moveToFirst() || cursor.getString(0) != "running" ||
                        cursor.isNull(1)
                    ) return@focusRow false
                    val deadline = TaskReminders.utcMillis(cursor.getString(1))
                    deadline != null && deadline > System.currentTimeMillis()
                }
            }
        } catch (_: Exception) { false }
    }

    private val animate = object : Runnable {
        override fun run() {
            if (!isVisible) return
            val interactive =
                (getSystemService(Context.POWER_SERVICE) as PowerManager).isInteractive
            if (interactive) {
                frame = (frame + 1) % 8
                sprite?.frame = frame
            }
            // Do not run 140ms sprite updates while the screen is off.
            handler.postDelayed(this, if (interactive) FRAME_MS else 1500L)
        }
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density + 0.5f).toInt()

    private fun shape(color: Int, cornerDp: Int, borderColor: Int? = null): GradientDrawable =
        GradientDrawable().apply {
            setColor(color)
            cornerRadius = dp(cornerDp).toFloat()
            if (borderColor != null) setStroke(dp(1), borderColor)
        }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
            !Settings.canDrawOverlays(this)
        ) {
            stopSelf()
            return START_NOT_STICKY
        }
        if (root == null) {
            try {
                attach()
            } catch (_: Exception) {
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    private fun attach() {
        manager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        params = WindowManager.LayoutParams(
            dp(94),
            dp(94),
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            android.graphics.PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = prefs.getInt("x", (resources.displayMetrics.widthPixels - dp(102)).coerceAtLeast(0))
            y = prefs.getInt("y", dp(180))
        }

        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
        }
        val brain = SpriteView(this).apply {
            background = shape(Color.argb(235, 246, 233, 255), 47, Color.rgb(209, 175, 255))
            elevation = dp(6).toFloat()
            contentDescription = "Brain OneLife, kéo để di chuyển, chạm để mở thao tác"
        }
        sprite = brain
        container.addView(brain, LinearLayout.LayoutParams(dp(80), dp(80)).apply {
            topMargin = dp(5)
            bottomMargin = dp(5)
        })

        val menu = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = shape(Color.rgb(248, 243, 255), 22, Color.rgb(226, 205, 250))
            elevation = dp(9).toFloat()
            setPadding(dp(12), dp(10), dp(12), dp(10))
            visibility = View.GONE
            contentDescription = "Thao tác nhanh của Brain"
        }
        options = menu
        menu.addView(TextView(this).apply {
            text = "Brain · OneLife"
            setTextColor(Color.rgb(53, 30, 91))
            textSize = 15f
            gravity = Gravity.CENTER
            setTypeface(typeface, android.graphics.Typeface.BOLD)
        }, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(31)))
        usageCaption = TextView(this).apply {
            text = "Đang đọc trạng thái (nếu có quyền)"
            setTextColor(Color.rgb(112, 82, 151))
            textSize = 11f
            gravity = Gravity.CENTER
            maxLines = 2
        }.also {
            menu.addView(it, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(37),
            ))
        }
        addAction(menu, "✓  Việc hôm nay") { openTaskAction(MainActivity.EXTRA_TODAY_TASKS) }
        addAction(menu, "+  Ghi nhanh") { openTaskAction(MainActivity.EXTRA_QUICK_CAPTURE) }
        addAction(menu, "◷  Tập trung") { openTaskAction(MainActivity.EXTRA_FOCUS) }
        addAction(menu, "×  Ẩn Brain") { stopSelf() }
        container.addView(menu, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT,
        ))

        root = FrameLayout(this).apply {
            clipChildren = false
            addView(container, FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ))
        }
        // TalkBack activation opens the same menu as a user tap.
        brain.isClickable = true
        brain.isFocusable = true
        brain.setOnClickListener { toggleMenu() }
        // Only Brain itself handles drag/toggle; other screen touches pass through.
        brain.setOnTouchListener(object : View.OnTouchListener {
            var rawX = 0f
            var rawY = 0f
            var oldX = 0
            var oldY = 0
            var dragging = false

            override fun onTouch(view: View, event: MotionEvent): Boolean {
                val layout = params ?: return false
                when (event.actionMasked) {
                    MotionEvent.ACTION_DOWN -> {
                        rawX = event.rawX
                        rawY = event.rawY
                        oldX = layout.x
                        oldY = layout.y
                        dragging = false
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val dx = event.rawX - rawX
                        val dy = event.rawY - rawY
                        if (abs(dx) > dp(7) || abs(dy) > dp(7)) dragging = true
                        if (dragging) {
                            val bounds = resources.displayMetrics
                            layout.x = (oldX + dx.toInt()).coerceIn(
                                0, (bounds.widthPixels - layout.width).coerceAtLeast(0),
                            )
                            layout.y = (oldY + dy.toInt()).coerceIn(
                                0, (bounds.heightPixels - layout.height).coerceAtLeast(0),
                            )
                            safeUpdate()
                        }
                        return true
                    }
                    MotionEvent.ACTION_UP -> {
                        if (dragging) {
                            prefs.edit().putInt("x", layout.x).putInt("y", layout.y).apply()
                        } else {
                            view.performClick()
                        }
                        return true
                    }
                    MotionEvent.ACTION_CANCEL -> return true
                }
                return false
            }
        })
        manager.addView(root, params)
        isVisible = true
        handler.postDelayed(animate, FRAME_MS)
        handler.post(refreshBehavior)
    }

    private fun addAction(menu: LinearLayout, label: String, click: () -> Unit) {
        val action = TextView(this).apply {
            text = label
            textSize = 14f
            setTextColor(Color.rgb(53, 30, 91))
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(13), 0, dp(12), 0)
            background = shape(Color.WHITE, 14)
            isClickable = true
            isFocusable = true
            contentDescription = label
            setOnClickListener { click() }
        }
        menu.addView(action, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, dp(39),
        ).apply { bottomMargin = dp(5) })
    }

    private fun toggleMenu() {
        expanded = !expanded
        options?.visibility = if (expanded) View.VISIBLE else View.GONE
        params?.apply {
            width = if (expanded) dp(250) else dp(94)
            height = if (expanded) dp(384) else dp(94)
            x = x.coerceIn(
                0, (resources.displayMetrics.widthPixels - width).coerceAtLeast(0),
            )
            y = y.coerceIn(
                0, (resources.displayMetrics.heightPixels - height).coerceAtLeast(0),
            )
        }
        safeUpdate()
    }

    private fun safeUpdate() {
        val view = root ?: return
        val layout = params ?: return
        try {
            manager.updateViewLayout(view, layout)
        } catch (_: Exception) {
            // Permission revoked while overlay is visible; remove everything.
            stopSelf()
        }
    }

    private fun openTaskAction(extra: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            !Settings.canDrawOverlays(this)) {
            stopSelf()
            return
        }
        val launch = Intent(this, MainActivity::class.java).apply {
            putExtra(extra, true)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        // User explicitly tapped an overlay action; some OEMs may nonetheless
        // restrict background activity starts. This is not a bypass.
        try { startActivity(launch) } catch (_: Exception) { }
        if (expanded) toggleMenu()
    }

    override fun onDestroy() {
        isVisible = false
        handler.removeCallbacks(animate)
        handler.removeCallbacks(refreshBehavior)
        val view = root
        root = null
        if (view != null) {
            try { manager.removeViewImmediate(view) } catch (_: Exception) { }
        }
        sprite?.release()
        sprite = null
        options = null
        usageCaption = null
        params = null
        super.onDestroy()
    }

    /**
     * Draw the original 4x2 transparent Brain animation atlas from Flutter's
     * bundled assets, without eight decoded frame copies or fake artwork.
     */
    private inner class SpriteView(context: Context) : View(context) {
        private val idleSheet: Bitmap? = decode(
            "flutter_assets/assets/characters-v2/brain/idle/sheet.png"
        )
        private val focusSheet: Bitmap? = decode(
            "flutter_assets/assets/characters-v2/brain/focus/sheet.png"
        )
        private val fallbackMaster: Bitmap? = if (idleSheet == null) decode(MASTER) else null
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
        private val indicator = Paint(Paint.ANTI_ALIAS_FLAG)
        var frame: Int = 0
            set(value) { field = value; invalidate() }
        var usageTier: String = "unknown"
            set(value) { field = value; invalidate() }
        var focused: Boolean = false
            set(value) { field = value; invalidate() }

        private fun decode(path: String): Bitmap? = try {
            context.assets.open(path).use { BitmapFactory.decodeStream(it) }
        } catch (_: Exception) { null }

        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            val sheet = if (focused && focusSheet != null) focusSheet else idleSheet
            val bitmap = sheet ?: fallbackMaster ?: return
            val isAtlas = sheet != null && bitmap.width >= 1024 && bitmap.height >= 512
            val columns = if (isAtlas) 4 else 1
            val rows = if (isAtlas) 2 else 1
            val fw = bitmap.width / columns
            val fh = bitmap.height / rows
            val index = if (isAtlas) frame % 8 else 0
            val source = Rect(
                (index % columns) * fw, (index / columns) * fh,
                (index % columns + 1) * fw, (index / columns + 1) * fh,
            )
            val inset = dp(7).toFloat()
            // Uses the genuine original artist's sprites. State is communicated
            // through a small accent indicator, never replaced by fabricated art.
            canvas.drawBitmap(
                bitmap, source,
                RectF(inset, inset, width - inset, height - inset), paint,
            )
            val color = when {
                focused -> Color.rgb(120, 77, 229)
                usageTier == "high" -> Color.rgb(231, 85, 104)
                usageTier == "break" -> Color.rgb(246, 160, 64)
                usageTier == "balanced" -> Color.rgb(79, 181, 142)
                else -> Color.TRANSPARENT
            }
            if (color != Color.TRANSPARENT) {
                indicator.color = Color.WHITE
                canvas.drawCircle(width - dp(15).toFloat(), dp(14).toFloat(), dp(7).toFloat(), indicator)
                indicator.color = color
                canvas.drawCircle(width - dp(15).toFloat(), dp(14).toFloat(), dp(5).toFloat(), indicator)
            }
        }

        fun release() {
            idleSheet?.recycle()
            focusSheet?.recycle()
            fallbackMaster?.recycle()
        }
    }
}
