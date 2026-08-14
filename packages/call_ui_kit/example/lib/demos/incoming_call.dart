import 'package:call_ui_kit/call_ui_kit.dart';
import 'package:flutter/material.dart';

class IncomingCallDemo extends StatelessWidget {
  const IncomingCallDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return IncomingCallScreen(
      callerName: 'Sarah Johnson',
      callerAvatarUrl: 'https://i.pravatar.cc/300?img=1',
      callType: CallType.video,
      onAccept: () {
        debugPrint('Accepted');
        Navigator.pop(context);
      },
      onDecline: () {
        debugPrint('Declined');
        Navigator.pop(context);
      },
    );
  }
}
