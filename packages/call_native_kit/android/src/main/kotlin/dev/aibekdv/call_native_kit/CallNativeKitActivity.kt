package dev.aibekdv.call_native_kit

import android.content.res.Configuration
import io.flutter.embedding.android.FlutterActivity

/**
 * A `FlutterActivity` that already forwards what picture-in-picture needs.
 *
 * ```kotlin
 * class MainActivity : CallNativeKitActivity()
 * ```
 *
 * These two callbacks cannot be intercepted from a plugin.
 * `FlutterActivity` extends the plain `Activity`, not `ComponentActivity`, so
 * there is no `addOnPictureInPictureModeChangedListener` to hook, and
 * `onUserLeaveHint` has no listener API at all. Extending this class is the
 * whole setup; if your Activity must extend something else, override both
 * methods yourself and forward them to `CallNativeKitPlugin.current`.
 *
 * Also remember `android:supportsPictureInPicture="true"` on the activity in
 * your manifest — without it every request to shrink is refused.
 */
open class CallNativeKitActivity : FlutterActivity() {

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        CallNativeKitPlugin.current?.onUserLeaveHint()
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration,
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        CallNativeKitPlugin.current?.onPictureInPictureModeChanged(isInPictureInPictureMode)
    }
}
