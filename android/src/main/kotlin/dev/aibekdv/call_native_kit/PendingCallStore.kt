package dev.aibekdv.call_native_kit

import android.content.Context
import org.json.JSONObject

/**
 * Remembers the call the system is currently showing, so it can still be found
 * after the process dies.
 *
 * The sequence this exists for: the phone rings while the app is not running,
 * the user accepts from the lock screen, Android starts the app from scratch,
 * and by the time Dart is alive the only trace of what happened is here.
 *
 * Its own SharedPreferences file, not the app's: this is written from the
 * broadcast callback, which can run in any process state.
 */
internal object PendingCallStore {

    private const val PREFS = "dev.aibekdv.call_native_kit.pending_call"
    private const val KEY_CALL = "call"

    fun save(context: Context, call: Map<String, Any?>) {
        val payload = JSONObject(call.filterValues { it != null })
        payload.put("savedAt", System.currentTimeMillis())
        payload.put("isAccepted", false)
        prefs(context).edit().putString(KEY_CALL, payload.toString()).apply()
    }

    fun markAccepted(context: Context) {
        val stored = prefs(context).getString(KEY_CALL, null) ?: return
        val payload = runCatching { JSONObject(stored) }.getOrNull() ?: return
        payload.put("isAccepted", true)
        prefs(context).edit().putString(KEY_CALL, payload.toString()).apply()
    }

    /**
     * Returns the stored call, or null when there is none.
     *
     * Expiry is deliberately not enforced here: the TTL is configurable from
     * Dart, and one owner of that rule is better than two that can disagree.
     */
    fun get(context: Context): Map<String, Any?>? {
        val stored = prefs(context).getString(KEY_CALL, null) ?: return null
        val payload = runCatching { JSONObject(stored) }.getOrNull() ?: return null
        return payload.keys().asSequence().associateWith { key ->
            if (payload.isNull(key)) null else payload.get(key)
        }
    }

    fun clear(context: Context) {
        prefs(context).edit().remove(KEY_CALL).apply()
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
