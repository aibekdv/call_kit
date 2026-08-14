#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint call_native_kit.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'call_native_kit'
  s.version          = '0.1.0'
  s.summary          = 'Native call UI: CallKit, PushKit, picture-in-picture and audio-session control.'
  s.description      = <<-DESC
CallKit and PushKit integration, native picture-in-picture rendering of a WebRTC
video track, and manual-mode RTCAudioSession control for Flutter VoIP apps.
                       DESC
  s.homepage         = 'https://github.com/aibekdv/call_kit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Aibek Karatay' => 'aibekdv@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'flutter_callkit_incoming'
  # WebRTC-SDK provides RTCAudioSession (manual audio mode) and the RTCVideoRenderer
  # protocol used to feed picture-in-picture. flutter_webrtc itself is reached
  # through the ObjC runtime to avoid a static-link conflict, so it is not a pod
  # dependency here.
  s.dependency 'WebRTC-SDK'
  s.platform = :ios, '13.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.resource_bundles = {'call_native_kit_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
