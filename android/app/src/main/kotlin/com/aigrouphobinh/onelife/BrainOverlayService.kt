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
        const val ACTION_REFRESH = "com.aigrouphobinh.onelife.overlay.REFRESH"
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
    private var breakAction: TextView? = null
    private var refreshVersion: Long = 0L
    private var sprite: SpriteView? = null
    private var params: WindowManager.LayoutParams? = null
    private var expanded = false
    private val refreshBehavior = object : Runnable {
        override fun run() {
            if (!isVisible) return
            val token = ++refreshVersion
            // UsageEvents and Focus SQLite stay off the WindowManager main UI.
            Thread {
                val usage = UsageInsights.snapshot(applicationContext)
                val focus = readFocusActive()
                // Reconcile time-sensitive break last so UsageEvents latency
                // cannot turn a completed clip into a stale recovery replay.
                val breakState = BrainBreaks.snapshot(applicationContext)
                handler.post {
                    if (!isVisible || token != refreshVersion) return@post
                    val phase = breakState["phase"] as? String ?: "idle"
                    val seq = breakState["sequence"] as? Long ?: 0L
                    val usageTier = usage["tier"] as? String ?: "unknown"
                    sprite?.focused = focus
                    sprite?.usageTier = usageTier
                    sprite?.setBreakPhase(phase, seq)
                    usageCaption?.text = when {
                        focus -> "Đang tập trung · Focus được ưu tiên"
                        phase == "resting" -> {
                            val seconds = breakState["remainingSeconds"] as? Int ?: 0
                            "Brain đang nghỉ · còn " + ((seconds + 59) / 60) + " phút"
                        }
                        phase == "recovering" -> "Nghỉ xong · Brain đang thư giãn"
                        usage["available"] != true -> "Chưa có dữ liệu thời gian dùng"
                        usage["goalMinutes"] !is Int -> "Chưa đặt mục tiêu hằng ngày"
                        else -> {
                            val minutes = usage["minutes"] as? Int
                            val goal = usage["goalMinutes"] as? Int
                            if (minutes == null || goal == null) "Chưa có dữ liệu"
                            else "Hôm nay ~" + minutes + "p / mục tiêu " + goal + "p"
                        }
                    }
                    breakAction?.apply {
                        isEnabled = phase != "recovering"
                        alpha = if (isEnabled) 1f else 0.6f
                        text = when (phase) {
                            "resting" -> "☀  Kết thúc nghỉ"
                            "recovering" -> "✧  Đang hồi phục"
                            else -> "☾  Nghỉ 5 phút"
                        }
                        contentDescription = text
                    }
                    val now = System.currentTimeMillis()
                    val nextDelay = when (phase) {
                        "resting" -> {
                            val deadline = breakState["deadlineMs"] as? Long ?: now
                            (deadline - now + 100L).coerceIn(250L, 5 * 60 * 1000L)
                        }
                        "recovering" -> {
                            val recoveryStart = breakState["recoveryStartMs"] as? Long ?: now
                            (recoveryStart + 12 * 125L - now + 100L)
                                .coerceIn(250L, 1_700L)
                        }
                        else -> 5 * 60 * 1000L
                    }
                    handler.postDelayed(this, nextDelay)
                }
            }.start()
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
            val power = getSystemService(Context.POWER_SERVICE) as PowerManager
            val interactive = power.isInteractive
            val motionAllowed = try {
                Settings.Global.getFloat(
                    contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f,
                ) > 0f
            } catch (_: Exception) { true }
            if (interactive && motionAllowed) sprite?.advanceFrame()
            // Reduce updates when screen off, reduced-motion enabled, or
            // battery-saver active; do not continuously animate at 140ms.
            val period = if (!interactive || !motionAllowed) 1500L else
                if (power.isPowerSaveMode) 300L else sprite?.frameDurationMs ?: FRAME_MS
            handler.postDelayed(this, period)
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
        if (intent?.action == ACTION_REFRESH) {
            // A background refresh must never create an overlay.
            if (root != null && isVisible) {
                handler.removeCallbacks(refreshBehavior)
                handler.post(refreshBehavior)
            }
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
        breakAction = addAction(menu, "☾  Nghỉ 5 phút") { performBreakAction() }
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

    private fun addAction(
        menu: LinearLayout, label: String, click: () -> Unit,
    ): TextView {
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
        return action
    }

    private fun performBreakAction() {
        val phase = BrainBreaks.snapshot(this)["phase"] as? String ?: "idle"
        when (phase) {
            "resting" -> BrainBreaks.finish(this)
            "idle" -> BrainBreaks.start(this, 5)
            else -> return
        }
        handler.removeCallbacks(refreshBehavior)
        handler.post(refreshBehavior)
        if (expanded) toggleMenu()
    }

    private fun toggleMenu() {
        expanded = !expanded
        options?.visibility = if (expanded) View.VISIBLE else View.GONE
        params?.apply {
            width = if (expanded) dp(250) else dp(94)
            height = if (expanded) dp(424) else dp(94)
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
        ++refreshVersion // discard any in-flight native UsageEvents callbacks
        val view = root
        root = null
        if (view != null) {
            try { manager.removeViewImmediate(view) } catch (_: Exception) { }
        }
        sprite?.release()
        sprite = null
        options = null
        usageCaption = null
        breakAction = null
        params = null
        super.onDestroy()
    }

    /**
     * Plays real PNG atlases already committed to Brain V2.4. Their geometry
     * and timing match state metadata; some are composited review candidates,
     * not manually approved production animations.
     */
    private inner class SpriteView(context: Context) : View(context) {
        private val idleSheet = decode("idle")
        private val focusSheet = decode("focus")
        private val master: Bitmap? = if (idleSheet == null) try {
            context.assets.open(MASTER).use { BitmapFactory.decodeStream(it) }
        } catch (_: Exception) { null } else null
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
        private val indicator = Paint(Paint.ANTI_ALIAS_FLAG)
        private var wellbeingSheet: Bitmap? = null
        private var wellbeingState: String? = null
        private var currentState: String = "idle"
        private var frameIndex = 0

        var usageTier: String = "unknown"
            set(value) {
                if (field == value) return
                field = value
                chooseClip()
            }
        private var breakPhase: String = "idle"
        private var breakSequence: Long = -1L
        var focused: Boolean = false
            set(value) {
                if (field == value) return
                field = value
                chooseClip()
            }

        val frameDurationMs: Long get() = when (currentState) {
            "focus", "strained" -> 160L
            "resting" -> 205L
            "recovering" -> 125L
            "overloaded" -> 115L
            else -> 140L
        }

        private fun frameCount(state: String): Int = when (state) {
            "strained", "resting" -> 10
            "overloaded", "recovering" -> 12
            else -> 8
        }

        fun setBreakPhase(phase: String, sequence: Long) {
            if (breakPhase == phase && breakSequence == sequence) return
            breakPhase = phase
            breakSequence = sequence
            chooseClip()
        }

        private fun decode(state: String): Bitmap? = try {
            val name = "flutter_assets/assets/characters-v2/brain/" +
                state + "/sheet.png"
            context.assets.open(name).use { BitmapFactory.decodeStream(it) }
        } catch (_: Exception) { null }

        private fun chooseClip() {
            val desired = when {
                focused && focusSheet != null -> "focus"
                breakPhase == "resting" || breakPhase == "recovering" -> breakPhase
                usageTier == "balanced" || usageTier == "strained" ||
                    usageTier == "overloaded" -> usageTier
                else -> "idle"
            }
            if (desired != "focus" && desired != "idle" &&
                wellbeingState != desired
            ) {
                wellbeingSheet?.recycle()
                wellbeingSheet = decode(desired)
                wellbeingState = desired
            }
            val available = when (desired) {
                "focus" -> focusSheet != null
                "idle" -> idleSheet != null
                else -> wellbeingSheet != null
            }
            val next = if (available) desired else "idle"
            if (currentState != next) {
                currentState = next
                frameIndex = 0
                contentDescription = when (next) {
                    "focus" -> "Brain đang tập trung"
                    "strained" -> "Brain gợi ý nghỉ mắt theo mục tiêu đã chọn"
                    "overloaded" -> "Brain báo bạn đã đạt mục tiêu sử dụng tự chọn"
                    "balanced" -> "Brain theo nhịp mục tiêu đã chọn"
                    "resting" -> "Brain đang nghỉ theo phiên bạn đã bắt đầu"
                    "recovering" -> "Brain kết thúc nghỉ, hoạt ảnh một lần"
                    else -> "Brain OneLife, chạm để mở thao tác"
                }
            }
            invalidate()
        }

        fun advanceFrame() {
            val count = frameCount(currentState)
            if (currentState == "recovering") {
                // 12-frame one-shot, hold last frame. Never loop Recovering.
                if (frameIndex < count - 1) frameIndex += 1
            } else {
                frameIndex = (frameIndex + 1) % count
            }
            invalidate()
        }

        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            val selected = when (currentState) {
                "focus" -> focusSheet
                "balanced", "strained", "overloaded", "resting", "recovering" ->
                    wellbeingSheet
                else -> idleSheet
            }
            val atlas = selected ?: idleSheet
            val bitmap = atlas ?: master ?: return
            val animated = atlas != null &&
                bitmap.width >= 1024 && bitmap.height >= 512
            val cols = if (animated) 4 else 1
            val rows = if (animated) {
                if (currentState == "strained" || currentState == "overloaded" ||
                    currentState == "resting" || currentState == "recovering") 3
                else 2
            } else 1
            val fw = bitmap.width / cols
            val fh = bitmap.height / rows
            val index = if (animated) frameIndex % frameCount(currentState) else 0
            val source = Rect(
                (index % cols) * fw, (index / cols) * fh,
                (index % cols + 1) * fw, (index / cols + 1) * fh,
            )
            val inset = dp(7).toFloat()
            canvas.drawBitmap(
                bitmap, source,
                RectF(inset, inset, width - inset, height - inset), paint,
            )
            val color = when {
                focused -> Color.rgb(120, 77, 229)
                currentState == "overloaded" -> Color.rgb(231, 85, 104)
                currentState == "strained" -> Color.rgb(246, 160, 64)
                currentState == "balanced" -> Color.rgb(79, 181, 142)
                currentState == "resting" -> Color.rgb(92, 184, 219)
                currentState == "recovering" -> Color.rgb(162, 118, 236)
                else -> Color.TRANSPARENT
            }
            if (color != Color.TRANSPARENT) {
                indicator.color = Color.WHITE
                canvas.drawCircle(
                    width - dp(15).toFloat(), dp(14).toFloat(), dp(7).toFloat(), indicator,
                )
                indicator.color = color
                canvas.drawCircle(
                    width - dp(15).toFloat(), dp(14).toFloat(), dp(5).toFloat(), indicator,
                )
            }
        }

        fun release() {
            idleSheet?.recycle()
            focusSheet?.recycle()
            wellbeingSheet?.recycle()
            master?.recycle()
        }
    }
}
