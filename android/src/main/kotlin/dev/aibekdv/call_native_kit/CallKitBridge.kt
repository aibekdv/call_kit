package dev.aibekdv.call_native_kit

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import java.lang.reflect.Proxy

/**
 * Everything that reaches into `flutter_callkit_incoming` by reflection.
 *
 * Two things are needed from it that its Dart API cannot give us:
 *
 * 1. accept and decline events even when no Flutter engine is running, so a
 *    call accepted on the lock screen survives to the next app start;
 * 2. a way to turn an already-showing incoming call into an ongoing one when
 *    the user accepts inside the app instead of on the system UI.
 *
 * Reflection rather than a Gradle dependency, so this plugin does not force a
 * particular version at compile time — and so a missing plugin degrades to a
 * reported failure instead of a `NoClassDefFoundError`. It is still bound to
 * that plugin's internals, which is why `call_native_kit` pins a narrow
 * version range and why every failure below is named rather than swallowed.
 */
internal class CallKitBridge(private val appContext: Context) {

    private companion object {
        const val PLUGIN = "com.hiennv.flutter_callkit_incoming.FlutterCallkitIncomingPlugin"
        const val CALLBACK = "com.hiennv.flutter_callkit_incoming.CallkitEventCallback"
        const val PREFS_UTILS = "com.hiennv.flutter_callkit_incoming.SharedPreferencesUtilsKt"
        const val DATA = "com.hiennv.flutter_callkit_incoming.Data"
        const val RECEIVER =
            "com.hiennv.flutter_callkit_incoming.CallkitIncomingBroadcastReceiver"
        const val EXTRA_KEY = "EXTRA_CALLKIT_INCOMING_DATA"
        const val ACCEPT_ACTION =
            "com.hiennv.flutter_callkit_incoming.ACTION_CALL_ACCEPT"
    }

    private var registeredProxy: Any? = null

    /**
     * Starts mirroring accept and decline into [PendingCallStore].
     *
     * Registered against the application context, never an Activity: the
     * callback list is static and outlives every configuration change, so an
     * Activity captured here would leak on every rotation.
     */
    fun registerEventCallback() {
        if (registeredProxy != null) return
        try {
            val plugin = Class.forName(PLUGIN)
            val callbackInterface = Class.forName(CALLBACK)
            val register = plugin.getMethod("registerEventCallback", callbackInterface)

            val proxy = Proxy.newProxyInstance(
                callbackInterface.classLoader,
                arrayOf(callbackInterface),
            ) { _, method, args ->
                if (method.name == "onCallEvent" && args != null && args.size >= 2) {
                    onCallEvent(args[0]?.toString(), args[1] as? Bundle)
                }
                null
            }

            register.invoke(null, proxy)
            registeredProxy = proxy
        } catch (_: Throwable) {
            // The host app does not use flutter_callkit_incoming, or its
            // internals moved. Cold-start recovery falls back to activeCalls().
        }
    }

    fun unregisterEventCallback() {
        val proxy = registeredProxy ?: return
        registeredProxy = null
        try {
            val plugin = Class.forName(PLUGIN)
            val callbackInterface = Class.forName(CALLBACK)
            plugin.getMethod("unregisterEventCallback", callbackInterface)
                .invoke(null, proxy)
        } catch (_: Throwable) {
        }
    }

    private fun onCallEvent(event: String?, data: Bundle?) {
        val name = event ?: return
        when {
            name.contains("ACCEPT", ignoreCase = true) ->
                PendingCallStore.markAccepted(appContext)

            name.contains("DECLINE", ignoreCase = true) ||
                name.contains("END", ignoreCase = true) ->
                PendingCallStore.clear(appContext)
        }
    }

    /**
     * Makes the system UI behave as if the user had pressed Accept.
     *
     * Android offers no supported way to replace an incoming-call notification
     * with an ongoing one: `setCallConnected` updates neither, so accepting
     * inside the app leaves the phone looking like it is still ringing while
     * audio already flows. Re-sending the plugin's own accept broadcast makes
     * it do the whole job — dismiss the incoming UI, start the foreground
     * service, and report the accept to Flutter.
     *
     * The original [Bundle] is reused rather than rebuilt, so the plugin gets
     * back exactly what it registered.
     *
     * Returns a name matching Dart's `SimulateAcceptResult`.
     */
    fun simulateAccept(callId: String): String {
        val activeCalls = try {
            val utils = Class.forName(PREFS_UTILS)
            val getActive = utils.getMethod("getDataActiveCalls", Context::class.java)
            @Suppress("UNCHECKED_CAST")
            getActive.invoke(null, appContext) as? List<Any?> ?: return "callNotFound"
        } catch (_: Throwable) {
            return "pluginClassMissing"
        }

        val bundle = try {
            val dataClass = Class.forName(DATA)
            val getId = runCatching { dataClass.getMethod("getId") }.getOrNull()
            val idField = runCatching {
                dataClass.getDeclaredField("id").apply { isAccessible = true }
            }.getOrNull()

            val match = activeCalls.firstOrNull { entry ->
                entry != null && idOf(entry, getId, idField) == callId
            } ?: return "callNotFound"

            dataClass.getMethod("toBundle").invoke(match) as? Bundle
                ?: return "bundleMissing"
        } catch (_: Throwable) {
            return "pluginClassMissing"
        }

        return try {
            val intent = Intent("${appContext.packageName}.$ACCEPT_ACTION").apply {
                setPackage(appContext.packageName)
                // Target the receiver explicitly — implicit broadcast
                // resolution is unreliable on stricter builds.
                component = ComponentName(appContext.packageName, RECEIVER)
                putExtra(EXTRA_KEY, bundle)
            }
            appContext.sendBroadcast(
                intent,
                "${appContext.packageName}.PERMISSION_CALL",
            )
            "ok"
        } catch (_: Throwable) {
            "broadcastFailed"
        }
    }

    private fun idOf(
        entry: Any,
        getId: java.lang.reflect.Method?,
        idField: java.lang.reflect.Field?,
    ): String? = runCatching {
        getId?.invoke(entry) as? String ?: idField?.get(entry) as? String
    }.getOrNull()
}
