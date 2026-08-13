import 'package:flutter/material.dart';

import 'demos/audio_screen_share.dart';
import 'demos/custom_dimensions.dart';
import 'demos/group_audio_call.dart';
import 'demos/group_screen_share.dart';
import 'demos/group_video_call.dart';
import 'demos/incoming_call.dart';
import 'demos/outgoing_call.dart';
import 'demos/personal_audio_call.dart';
import 'demos/personal_screen_share.dart';
import 'demos/personal_video_call.dart';

void main() => runApp(const CallUiKitExample());

class CallUiKitExample extends StatelessWidget {
  const CallUiKitExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Call UI Kit Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const DemoHomeScreen(),
    );
  }
}

class DemoHomeScreen extends StatelessWidget {
  const DemoHomeScreen({super.key});

  static const _demos = <_DemoItem>[
    _DemoItem(
      icon: Icons.phone,
      title: 'Personal Audio Call',
      subtitle: 'WhatsApp theme — active audio call',
    ),
    _DemoItem(
      icon: Icons.videocam,
      title: 'Personal Video Call',
      subtitle: 'WhatsApp theme — active video call',
    ),
    _DemoItem(
      icon: Icons.group,
      title: 'Group Video Call (8 people)',
      subtitle: 'WhatsApp theme — random speaking',
    ),
    _DemoItem(
      icon: Icons.screen_share,
      title: 'Personal Call + Screen Share',
      subtitle: 'WhatsApp theme — screen share in 1-on-1',
    ),
    _DemoItem(
      icon: Icons.screen_share,
      title: 'Group Call + Screen Share',
      subtitle: 'WhatsApp theme — screen share layout',
    ),
    _DemoItem(
      icon: Icons.groups,
      title: 'Group Audio Call (5 people)',
      subtitle: 'WhatsApp theme — audio group call',
    ),
    _DemoItem(
      icon: Icons.screen_share_outlined,
      title: 'Audio Call + Screen Share',
      subtitle: 'WhatsApp theme — audio with screen share',
    ),
    _DemoItem(
      icon: Icons.aspect_ratio,
      title: 'Custom Dimensions',
      subtitle: 'Presets, per-metric tokens and scale',
    ),
    _DemoItem(
      icon: Icons.call_received,
      title: 'Incoming Video Call',
      subtitle: 'WhatsApp theme — accept / decline',
    ),
    _DemoItem(
      icon: Icons.call_made,
      title: 'Outgoing Video Call',
      subtitle: 'WhatsApp theme — calling with toggles',
    ),
  ];

  static final _screens = <Widget Function()>[
    PersonalAudioCallDemo.new,
    PersonalVideoCallDemo.new,
    GroupVideoCallDemo.new,
    PersonalScreenShareDemo.new,
    GroupScreenShareDemo.new,
    GroupAudioCallDemo.new,
    AudioScreenShareDemo.new,
    CustomDimensionsDemo.new,
    IncomingCallDemo.new,
    OutgoingCallDemo.new,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Call UI Kit Demo')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: _demos.length,
        itemBuilder: (context, index) {
          final demo = _demos[index];
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => _screens[index]()),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(demo.icon, size: 36),
                    const SizedBox(height: 10),
                    Text(
                      demo.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      demo.subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DemoItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DemoItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
