package dev.aibekdv.call_native_kit

import android.content.Context
import kotlin.test.assertEquals
import org.junit.jupiter.api.Test
import org.mockito.Mockito.mock

/// `CallKitBridge` reaches into `flutter_callkit_incoming` by reflection, so a
/// version bump can break it without breaking the build. The point of these
/// tests is not that reflection works — on the unit-test classpath that plugin
/// is deliberately absent — but that failing to find it produces a *named*
/// result.
///
/// The earlier design returned a bare `false`, which meant an upgrade degraded
/// silently: accepting a call inside the app stopped dismissing the incoming
/// notification and never started the ongoing foreground service, while audio
/// already flowed. The phone looked like it was still ringing at somebody the
/// user was already talking to.
class CallKitBridgeTest {

    private val context: Context = mock(Context::class.java)

    @Test
    fun `names the failure when the plugin is not on the classpath`() {
        val bridge = CallKitBridge(context)
        assertEquals("pluginClassMissing", bridge.simulateAccept("314"))
    }

    @Test
    fun `reports the same for any call id`() {
        val bridge = CallKitBridge(context)
        assertEquals("pluginClassMissing", bridge.simulateAccept(""))
        assertEquals("pluginClassMissing", bridge.simulateAccept("not-a-number"))
    }

    @Test
    fun `registering a callback without the plugin does not throw`() {
        // Called on every Activity attach. A host that does not use
        // flutter_callkit_incoming must still start.
        val bridge = CallKitBridge(context)
        bridge.registerEventCallback()
        bridge.unregisterEventCallback()
    }
}
