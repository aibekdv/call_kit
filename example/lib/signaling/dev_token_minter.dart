import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Signs a LiveKit access token on the device.
///
/// ## Read this before copying it
///
/// **A real app must never do this.** Minting a token needs the API secret,
/// and an API secret inside an app is an API secret you have given away —
/// anyone who unpacks the binary can create tokens for any room, as any
/// identity, forever. In production a token comes from your server, which is
/// what `CallSignalingClient` exists to talk to.
///
/// It is here for exactly one reason: so this example runs against
/// `livekit-server --dev` with a single command instead of making you paste
/// tokens by hand on two devices. That server's key and secret (`devkey` /
/// `secret`) are published defaults that grant nothing anywhere real.
///
/// [mint] throws in release builds rather than trusting a comment to stop
/// anyone.
class DevTokenMinter {
  const DevTokenMinter({
    this.apiKey = _defaultKey,
    this.apiSecret = _defaultSecret,
    this.ttl = const Duration(hours: 6),
  });

  /// Defaults of `livekit-server --dev`.
  static const _defaultKey = String.fromEnvironment(
    'LIVEKIT_DEV_KEY',
    defaultValue: 'devkey',
  );
  static const _defaultSecret = String.fromEnvironment(
    'LIVEKIT_DEV_SECRET',
    defaultValue: 'secret',
  );

  final String apiKey;
  final String apiSecret;
  final Duration ttl;

  /// A join token for [identity] in [room].
  String mint({
    required String room,
    required String identity,
    String? name,
    DateTime? now,
  }) {
    if (kReleaseMode) {
      throw StateError(
        'DevTokenMinter is a development shortcut and refuses to run in a '
        'release build. Get tokens from your server instead — see '
        'CallSignalingClient.',
      );
    }

    final issuedAt = (now ?? DateTime.now()).toUtc();
    final claims = <String, Object?>{
      'iss': apiKey,
      'sub': identity,
      if (name != null) 'name': name,
      'nbf': _epochSeconds(issuedAt),
      'exp': _epochSeconds(issuedAt.add(ttl)),
      'video': {
        'room': room,
        'roomJoin': true,
        'canPublish': true,
        'canSubscribe': true,
        'canPublishData': true,
      },
    };

    final header = _segment({'alg': 'HS256', 'typ': 'JWT'});
    final payload = _segment(claims);
    final signature = Hmac(
      sha256,
      utf8.encode(apiSecret),
    ).convert(utf8.encode('$header.$payload'));

    return '$header.$payload.${_base64Url(signature.bytes)}';
  }

  static int _epochSeconds(DateTime time) =>
      time.millisecondsSinceEpoch ~/ 1000;

  static String _segment(Map<String, Object?> value) =>
      _base64Url(utf8.encode(jsonEncode(value)));

  /// base64url without padding, as JWT requires.
  static String _base64Url(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
}
