package dev.aibekdv.call_native_kit

import android.app.Activity
import android.app.PictureInPictureParams
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.util.Rational
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Android system picture-in-picture.
 *
 * Unlike iOS, Android keeps rendering the app's own Flutter tree inside the
 * small window — there is no separate native surface. That single fact
 * explains the rest of this class: the Dart side has to shrink its UI itself,
 * and it has to be told about the mode change reliably enough to do so.
 */
internal class PipManager(private val channel: MethodChannel) {

    private companion object {
        const val ACTION_MUTE = "dev.aibekdv.call_native_kit.PIP_MUTE"
        const val ACTION_HANGUP = "dev.aibekdv.call_native_kit.PIP_HANGUP"
    }

    var activity: Activity? = null

    private var hasActiveVideoCall = false
    private var aspectWidth = 9
    private var aspectHeight = 16
    private var actionReceiver: BroadcastReceiver? = null

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setActiveVideoCall" -> {
                hasActiveVideoCall = call.argument<Boolean>("active") ?: false
                aspectWidth = call.argument<Int>("aspectWidth") ?: aspectWidth
                aspectHeight = call.argument<Int>("aspectHeight") ?: aspectHeight
                applyAutoEnter()
                result.success(null)
            }

            "enterPip" -> result.success(
                enterPip(
                    call.argument<Int>("aspectWidth") ?: aspectWidth,
                    call.argument<Int>("aspectHeight") ?: aspectHeight,
                ),
            )

            "closePip" -> {
                val act = activity
                if (act != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    runCatching {
                        if (act.isInPictureInPictureMode) act.moveTaskToBack(true)
                    }
                }
                result.success(null)
            }

            // Pull model. The push callback below can be missed, and a missed
            // one strands the app rendering its full UI into a thumbnail, so
            // Dart re-asks on every window-metrics change.
            "isInPip" -> result.success(isInPip())

            // iOS renders a real native surface and needs to be told which
            // track; Android has nothing to attach.
            "attachTrack" -> result.success(null)

            else -> result.notImplemented()
        }
    }

    private fun isInPip(): Boolean {
        val act = activity ?: return false
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            act.isInPictureInPictureMode
    }

    /**
     * On API 31+ the system can shrink the window by itself when the user
     * leaves, which is smoother than reacting to [onUserLeaveHint].
     */
    private fun applyAutoEnter() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        runCatching {
            activity?.setPictureInPictureParams(
                PictureInPictureParams.Builder()
                    .setAspectRatio(Rational(aspectWidth, aspectHeight))
                    .setAutoEnterEnabled(hasActiveVideoCall)
                    .build(),
            )
        }
    }

    private fun enterPip(width: Int, height: Int): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        if (!hasActiveVideoCall) return false
        val act = activity ?: return false
        return runCatching {
            act.enterPictureInPictureMode(
                PictureInPictureParams.Builder()
                    .setAspectRatio(Rational(width, height))
                    .build(),
            )
        }.getOrDefault(false)
    }

    /**
     * Forwarded from the Activity. Still required below API 31, where there is
     * no auto-enter.
     */
    fun onUserLeaveHint() {
        if (!hasActiveVideoCall) return
        // Announce the mode change *before* entering, so Dart has already
        // switched to its compact layout when the window shrinks. Rolled back
        // below if the system refuses.
        channel.invokeMethod("onPipModeChanged", true)
        if (!enterPip(aspectWidth, aspectHeight)) {
            channel.invokeMethod("onPipModeChanged", false)
        }
    }

    /** Forwarded from the Activity. */
    fun onPictureInPictureModeChanged(isInPip: Boolean) {
        channel.invokeMethod("onPipModeChanged", isInPip)
    }

    fun registerActionReceiver(context: Context) {
        if (actionReceiver != null) return
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context?, intent: Intent?) {
                when (intent?.action) {
                    ACTION_MUTE -> channel.invokeMethod("onPipAction", "mute")
                    ACTION_HANGUP -> channel.invokeMethod("onPipAction", "hangup")
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction(ACTION_MUTE)
            addAction(ACTION_HANGUP)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            context.registerReceiver(receiver, filter)
        }
        actionReceiver = receiver
    }

    fun unregisterActionReceiver(context: Context?) {
        val receiver = actionReceiver ?: return
        actionReceiver = null
        runCatching { context?.unregisterReceiver(receiver) }
    }
}
