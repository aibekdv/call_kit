package dev.aibekdv.call_native_kit

import android.app.Activity
import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Android half of `call_native_kit`.
 *
 * Most of a call's system UI on Android is handled by
 * `flutter_callkit_incoming`; what is left, and what lives here, is:
 * picture-in-picture, cold-start recovery of an accepted call, and the
 * accept-simulation bridge.
 */
class CallNativeKitPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    companion object {
        /**
         * The instance bound to the UI engine, for an Activity to forward its
         * picture-in-picture callbacks to.
         *
         * Set from the *Activity* binding on purpose. FCM starts a second
         * FlutterEngine in the background, and that engine registers this
         * plugin too; an engine-scoped holder would route picture-in-picture
         * callbacks into an isolate where nothing is listening. Background
         * engines never attach to an Activity, so this always points at the
         * one the user can see.
         */
        @JvmStatic
        var current: CallNativeKitPlugin? = null
            private set
    }

    private lateinit var channel: MethodChannel
    private lateinit var pipChannel: MethodChannel
    private lateinit var pip: PipManager

    private var appContext: Context? = null
    private var activity: Activity? = null
    private var callKit: CallKitBridge? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext

        channel = MethodChannel(binding.binaryMessenger, "dev.aibekdv.call_native_kit")
        channel.setMethodCallHandler(this)

        pipChannel = MethodChannel(binding.binaryMessenger, "dev.aibekdv.call_native_kit/pip")
        pip = PipManager(pipChannel)
        pipChannel.setMethodCallHandler { call, result -> pip.handle(call, result) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        pipChannel.setMethodCallHandler(null)
        appContext = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val context = appContext
        when (call.method) {
            // Config lives in Dart on Android: the incoming-call UI is built
            // there, and the background isolate reads the persisted copy.
            "configure", "initialize" -> result.success(null)

            "savePendingCall" -> {
                val args = call.arguments<Map<String, Any?>>()
                if (context != null && args != null) {
                    PendingCallStore.save(context, args)
                }
                result.success(null)
            }

            "getPendingAcceptedCall" -> {
                val pending = context?.let { PendingCallStore.get(it) }
                result.success(
                    if (pending?.get("isAccepted") == true) pending else null,
                )
            }

            "markPendingCallAccepted" -> {
                context?.let { PendingCallStore.markAccepted(it) }
                result.success(null)
            }

            "clearPendingCall" -> {
                context?.let { PendingCallStore.clear(it) }
                result.success(null)
            }

            // The flag itself is stored by Dart, where the background isolate
            // can read it. Nothing native consumes it on Android.
            "setActiveCall" -> result.success(null)

            "simulateSystemAccept" -> {
                val callId = call.argument<String>("callId")
                val bridge = callKit
                result.success(
                    when {
                        callId.isNullOrEmpty() -> "callNotFound"
                        bridge == null -> "pluginClassMissing"
                        else -> bridge.simulateAccept(callId)
                    },
                )
            }

            // PushKit is an iOS concept.
            "getVoipPushToken" -> result.success(null)

            // Android never computes the CallKit UUID itself — the system UI
            // is driven entirely from Dart here — so there is nothing that
            // could drift, and the check is a no-op.
            "computeCallUuids" -> result.success(null)

            // Audio routing on Android is done from Dart through WebRTC's
            // Hardware API; there is no session to activate by hand.
            "activateAudio", "deactivateAudio" -> result.success(null)

            // No equivalent of CallKit's didActivateAudioSession — report
            // ready immediately so the Dart-side guard is a no-op here.
            "awaitAudioSessionActive" -> result.success(true)

            "audioDiagnostics" -> result.success(
                mapOf(
                    "isActive" to true,
                    "isAudioEnabled" to true,
                    "activationCount" to 0,
                    "category" to "n/a",
                    "mode" to "n/a",
                ),
            )

            else -> result.notImplemented()
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) = attach(binding)

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        attach(binding)

    override fun onDetachedFromActivityForConfigChanges() = detach()

    override fun onDetachedFromActivity() = detach()

    private fun attach(binding: ActivityPluginBinding) {
        activity = binding.activity
        pip.activity = binding.activity
        current = this

        val context = appContext ?: binding.activity.applicationContext
        pip.registerActionReceiver(context)
        callKit = CallKitBridge(context).apply { registerEventCallback() }
    }

    private fun detach() {
        pip.unregisterActionReceiver(appContext ?: activity?.applicationContext)
        callKit?.unregisterEventCallback()
        callKit = null
        activity = null
        pip.activity = null
        if (current === this) current = null
    }

    /** Forward from `Activity.onUserLeaveHint()`. */
    fun onUserLeaveHint() = pip.onUserLeaveHint()

    /** Forward from `Activity.onPictureInPictureModeChanged()`. */
    fun onPictureInPictureModeChanged(isInPip: Boolean) =
        pip.onPictureInPictureModeChanged(isInPip)
}
