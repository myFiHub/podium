package com.web3podium

import android.animation.ValueAnimator
import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.provider.Settings
import android.text.TextUtils
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.WindowManager
import android.view.animation.DecelerateInterpolator
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs

/**
 * Bridges Dart to [CallOverlayWindow] over `podium/call_overlay`. Dart shows the bubble while a
 * call runs with the app in the background; taps come back as `toggleMute`, `leave` and `open`.
 */
class CallOverlayPlugin private constructor(
    private val activity: Activity,
    private val channel: MethodChannel,
) : MethodChannel.MethodCallHandler {

    private val window = CallOverlayWindow(activity.applicationContext) { action ->
        if (action == "open") bringAppToFront()
        channel.invokeMethod(action, null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasPermission" -> result.success(Settings.canDrawOverlays(activity))
            "requestPermission" -> {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:${activity.packageName}")
                )
                activity.startActivity(intent)
                result.success(null)
            }
            "show" -> {
                if (!Settings.canDrawOverlays(activity)) {
                    result.success(false)
                    return
                }
                window.show(
                    title = call.argument<String>("title") ?: "",
                    muted = call.argument<Boolean>("muted") ?: true,
                    canTalk = call.argument<Boolean>("canTalk") ?: false,
                )
                result.success(true)
            }
            "update" -> {
                window.update(
                    muted = call.argument<Boolean>("muted") ?: true,
                    canTalk = call.argument<Boolean>("canTalk") ?: false,
                )
                result.success(null)
            }
            "hide" -> {
                window.hide()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun bringAppToFront() {
        val intent = Intent(activity.applicationContext, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
        }
        activity.applicationContext.startActivity(intent)
    }

    fun dispose() {
        window.hide()
        channel.setMethodCallHandler(null)
    }

    companion object {
        fun register(activity: Activity, messenger: BinaryMessenger): CallOverlayPlugin {
            val channel = MethodChannel(messenger, "podium/call_overlay")
            val plugin = CallOverlayPlugin(activity, channel)
            channel.setMethodCallHandler(plugin)
            return plugin
        }
    }
}

/**
 * A draggable bubble drawn over other apps. Tapping it opens a small panel with mute, open and
 * leave. Built from plain views, so it needs no Flutter engine of its own.
 */
class CallOverlayWindow(
    private val context: Context,
    private val onAction: (String) -> Unit,
) {
    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val touchSlop = ViewConfiguration.get(context).scaledTouchSlop

    private var root: LinearLayout? = null
    private var params: WindowManager.LayoutParams? = null
    private var bubble: FrameLayout? = null
    private var bubbleMuteBadge: ImageView? = null
    private var panel: LinearLayout? = null
    private var muteButton: ImageView? = null
    private var muteLabel: TextView? = null
    private var muteItem: View? = null
    private var titleView: TextView? = null

    private var expanded = false
    private var onRight = true
    private var muted = true
    private var canTalk = false
    private var savedX: Int? = null
    private var savedY: Int? = null

    private val bubbleSize get() = dp(56)
    private val margin get() = dp(8)
    private val screenWidth get() = context.resources.displayMetrics.widthPixels
    private val screenHeight get() = context.resources.displayMetrics.heightPixels

    fun show(title: String, muted: Boolean, canTalk: Boolean) {
        this.muted = muted
        this.canTalk = canTalk
        if (root == null) attach()
        titleView?.text = title
        render()
    }

    fun update(muted: Boolean, canTalk: Boolean) {
        this.muted = muted
        this.canTalk = canTalk
        render()
    }

    fun hide() {
        val view = root ?: return
        params?.let {
            savedX = if (expanded && onRight) it.x + panelWidth() else it.x
            savedY = it.y
        }
        try {
            windowManager.removeView(view)
        } catch (_: IllegalArgumentException) {
        }
        root = null
        params = null
        expanded = false
    }

    private fun attach() {
        val layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = savedX ?: (screenWidth - bubbleSize - margin)
            y = savedY ?: (screenHeight / 2)
        }
        onRight = layoutParams.x + bubbleSize / 2 > screenWidth / 2

        val container = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        val bubbleView = buildBubble()
        val panelView = buildPanel()
        panelView.visibility = View.GONE
        container.addView(bubbleView)

        root = container
        bubble = bubbleView
        panel = panelView
        params = layoutParams
        expanded = false
        windowManager.addView(container, layoutParams)
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun buildBubble(): FrameLayout {
        val frame = FrameLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(bubbleSize, bubbleSize)
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(SURFACE)
                setStroke(dp(2), VIOLET)
            }
            elevation = dp(6).toFloat()
            contentDescription = "Outpost controls"
        }
        val icon = ImageView(context).apply {
            setImageDrawable(context.packageManager.getApplicationIcon(context.packageName))
            scaleType = ImageView.ScaleType.CENTER_CROP
            clipToOutline = true
            outlineProvider = android.view.ViewOutlineProvider.BACKGROUND
            background = GradientDrawable().apply { shape = GradientDrawable.OVAL }
        }
        val inset = dp(4)
        frame.addView(
            icon,
            FrameLayout.LayoutParams(bubbleSize - inset * 2, bubbleSize - inset * 2, Gravity.CENTER)
        )
        val badge = ImageView(context).apply {
            setImageResource(R.drawable.ic_overlay_mic_off)
            setPadding(dp(3), dp(3), dp(3), dp(3))
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(SURFACE)
                setStroke(dp(1), BORDER)
            }
        }
        frame.addView(badge, FrameLayout.LayoutParams(dp(20), dp(20), Gravity.BOTTOM or Gravity.END))
        bubbleMuteBadge = badge
        frame.setOnTouchListener(DragListener())
        return frame
    }

    private fun buildPanel(): LinearLayout {
        val panelView = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(14), dp(10), dp(14), dp(10))
            background = GradientDrawable().apply {
                cornerRadius = dp(22).toFloat()
                setColor(SURFACE)
                setStroke(dp(1), BORDER)
            }
            elevation = dp(6).toFloat()
        }
        val title = TextView(context).apply {
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            maxLines = 1
            ellipsize = TextUtils.TruncateAt.END
            maxWidth = dp(190)
            paint.isFakeBoldText = true
        }
        titleView = title
        panelView.addView(title)
        val row = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(0, dp(8), 0, 0)
        }
        val (mute, muteIcon, muteText) = actionItem(R.drawable.ic_overlay_mic_off, "Unmute", Color.WHITE) {
            onAction("toggleMute")
        }
        muteItem = mute
        muteButton = muteIcon
        muteLabel = muteText
        row.addView(mute)
        row.addView(actionItem(R.drawable.ic_overlay_open, "Open", ACCENT) {
            collapse()
            onAction("open")
        }.first)
        row.addView(actionItem(R.drawable.ic_overlay_call_end, "Leave", DANGER) {
            hide()
            onAction("leave")
        }.first)
        panelView.addView(row)
        return panelView
    }

    private fun actionItem(
        iconRes: Int,
        label: String,
        color: Int,
        onClick: () -> Unit,
    ): Triple<View, ImageView, TextView> {
        val item = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(6), 0, dp(6), 0)
            isClickable = true
            setOnClickListener { onClick() }
            contentDescription = label
        }
        val icon = ImageView(context).apply {
            setImageResource(iconRes)
            setColorFilter(color)
            setPadding(dp(10), dp(10), dp(10), dp(10))
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(FILL)
                setStroke(dp(1), (color and 0x00FFFFFF) or 0x80000000.toInt())
            }
        }
        item.addView(icon, LinearLayout.LayoutParams(dp(44), dp(44)))
        val text = TextView(context).apply {
            this.text = label
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
            gravity = Gravity.CENTER
            setPadding(0, dp(3), 0, 0)
        }
        item.addView(text)
        return Triple(item, icon, text)
    }

    private fun render() {
        val live = canTalk && !muted
        bubbleMuteBadge?.visibility = if (canTalk && muted) View.VISIBLE else View.GONE
        (bubble?.background as? GradientDrawable)?.setStroke(dp(2), if (live) SUCCESS else VIOLET)
        muteItem?.visibility = if (canTalk) View.VISIBLE else View.GONE
        muteButton?.setImageResource(if (live) R.drawable.ic_overlay_mic else R.drawable.ic_overlay_mic_off)
        muteButton?.setColorFilter(if (live) SUCCESS else Color.WHITE)
        muteLabel?.text = if (live) "Mute" else "Unmute"
    }

    private fun panelWidth(): Int {
        val p = panel ?: return 0
        p.measure(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED)
        return p.measuredWidth + dp(8)
    }

    private fun toggle() {
        if (expanded) collapse() else expand()
    }

    private fun expand() {
        val container = root ?: return
        val p = params ?: return
        val panelView = panel ?: return
        val bubbleView = bubble ?: return
        expanded = true
        panelView.visibility = View.VISIBLE
        val spacing = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        )
        container.removeAllViews()
        if (onRight) {
            spacing.marginEnd = dp(8)
            container.addView(panelView, spacing)
            container.addView(bubbleView)
            p.x = (p.x - panelWidth()).coerceAtLeast(0)
        } else {
            spacing.marginStart = dp(8)
            container.addView(bubbleView)
            container.addView(panelView, spacing)
        }
        windowManager.updateViewLayout(container, p)
    }

    private fun collapse() {
        if (!expanded) return
        val container = root ?: return
        val p = params ?: return
        val bubbleView = bubble ?: return
        if (onRight) p.x += panelWidth()
        expanded = false
        container.removeAllViews()
        container.addView(bubbleView)
        windowManager.updateViewLayout(container, p)
    }

    private fun snapToEdge() {
        val container = root ?: return
        val p = params ?: return
        onRight = p.x + bubbleSize / 2 > screenWidth / 2
        val target = if (onRight) screenWidth - bubbleSize - margin else margin
        p.y = p.y.coerceIn(margin, screenHeight - bubbleSize - margin * 4)
        ValueAnimator.ofInt(p.x, target).apply {
            duration = 220
            interpolator = DecelerateInterpolator()
            addUpdateListener {
                if (root == null) return@addUpdateListener
                p.x = it.animatedValue as Int
                windowManager.updateViewLayout(container, p)
            }
            start()
        }
    }

    private inner class DragListener : View.OnTouchListener {
        private var downX = 0f
        private var downY = 0f
        private var startX = 0
        private var startY = 0
        private var dragging = false

        @SuppressLint("ClickableViewAccessibility")
        override fun onTouch(v: View, event: MotionEvent): Boolean {
            val p = params ?: return false
            val container = root ?: return false
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    downX = event.rawX
                    downY = event.rawY
                    startX = p.x
                    startY = p.y
                    dragging = false
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - downX
                    val dy = event.rawY - downY
                    if (!dragging && (abs(dx) > touchSlop || abs(dy) > touchSlop)) {
                        if (expanded) collapse()
                        startX = p.x
                        startY = p.y
                        downX = event.rawX
                        downY = event.rawY
                        dragging = true
                    }
                    if (dragging) {
                        p.x = (startX + (event.rawX - downX)).toInt()
                        p.y = (startY + (event.rawY - downY)).toInt()
                        windowManager.updateViewLayout(container, p)
                    }
                }
                MotionEvent.ACTION_UP -> {
                    if (dragging) snapToEdge() else toggle()
                }
                MotionEvent.ACTION_CANCEL -> if (dragging) snapToEdge()
            }
            return true
        }
    }

    private fun dp(value: Int): Int = (value * context.resources.displayMetrics.density).toInt()

    companion object {
        private val SURFACE = Color.parseColor("#F21B1830")
        private val FILL = Color.parseColor("#1FFFFFFF")
        private val BORDER = Color.parseColor("#33FFFFFF")
        private val VIOLET = Color.parseColor("#8B5CF6")
        private val SUCCESS = Color.parseColor("#22C55E")
        private val DANGER = Color.parseColor("#EF4444")
        private val ACCENT = Color.parseColor("#60A5FA")
    }
}
