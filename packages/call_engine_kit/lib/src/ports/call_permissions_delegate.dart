import 'package:permission_handler/permission_handler.dart';

/// Microphone, camera and screen-capture access.
///
/// A port because permission handling is often already owned by the host app —
/// with its own rationale dialogs, its own onboarding, its own telemetry — and
/// a package that pops its own prompts fights all of that.
abstract interface class CallPermissionsDelegate {
  /// Returns whether the microphone may be used. Called before every call.
  Future<bool> ensureMicrophone();

  /// Returns whether the camera may be used. Called before video calls, and
  /// again when the camera is switched on mid-call.
  Future<bool> ensureCamera();

  /// Opens the system settings page for this app.
  Future<void> openSettings();
}

/// Default implementation on `permission_handler`.
class PermissionHandlerDelegate implements CallPermissionsDelegate {
  const PermissionHandlerDelegate();

  @override
  Future<bool> ensureMicrophone() => _ensure(Permission.microphone);

  @override
  Future<bool> ensureCamera() => _ensure(Permission.camera);

  @override
  Future<void> openSettings() => openAppSettings();

  Future<bool> _ensure(Permission permission) async {
    final status = await permission.status;
    if (status.isGranted) return true;
    // A permanently denied permission cannot be requested again — the system
    // returns denied without showing anything, so asking looks like a freeze.
    if (status.isPermanentlyDenied) return false;
    return (await permission.request()).isGranted;
  }
}

/// Grants everything. For tests and for the example app.
class AlwaysGrantedPermissions implements CallPermissionsDelegate {
  const AlwaysGrantedPermissions();

  @override
  Future<bool> ensureMicrophone() async => true;

  @override
  Future<bool> ensureCamera() async => true;

  @override
  Future<void> openSettings() async {}
}
