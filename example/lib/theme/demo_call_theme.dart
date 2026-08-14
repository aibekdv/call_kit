import 'package:call_engine_kit/call_engine_kit.dart';
import 'package:call_ui_kit/call_ui_kit.dart';
import 'package:flutter/material.dart';

import '../session/app_session.dart';

// Everything the user reads during a call, in one place per language.
//
// Split three ways because three different layers show text and none of them
// translates anything: the call screens (call_ui_kit), what went wrong
// (call_engine_kit), and the system call screen (call_native_kit) — the last
// of which also has to survive the app being dead.

/// Strings for the call screens.
///
/// Null for English — the screens already default to it, and handing their own
/// defaults back would just be a copy to keep in sync.
CallStrings? demoCallStrings(DemoLocale locale) => switch (locale) {
      DemoLocale.en => null,
      DemoLocale.ru => _russianCallStrings,
    };

final _russianCallStrings = CallStrings(
  calling: 'Вызов…',
  cameraIsOff: 'Камера выключена',
  you: 'Вы',
  endToEndEncrypted: 'Сквозное шифрование',
  shareScreen: 'Показать экран',
  sendMessage: 'Написать',
  participants: 'Участники',
  shareCallLink: 'Ссылка на звонок',
  cancel: 'Отмена',
  stop: 'Остановить',
  stopScreenSharing: 'Остановить показ',
  youAreSharingYourScreen: 'Вы показываете экран',
  speaking: 'Говорит',
  muted: 'Микрофон выключен',
  muteAll: 'Выключить всем',
  invite: 'Пригласить',
  mute: 'Выключить',
  unmute: 'Включить',
  removeFromCall: 'Удалить из звонка',
  pictureInPicture: 'Картинка в картинке',
  addParticipant: 'Добавить',
  flipCamera: 'Сменить камеру',
  effects: 'Эффекты',
  incomingAudioCall: 'Входящий аудиозвонок',
  incomingVideoCall: 'Входящий видеозвонок',
  decline: 'Отклонить',
  accept: 'Принять',
  callEnded: 'Звонок завершён',
  connecting: 'Соединение…',
  reconnecting: 'Переподключение…',
  endCall: 'Завершить',
  speaker: 'Динамик',
  camera: 'Камера',
  moreOptions: 'Ещё',
  isSharingScreen: (name) => '$name показывает экран',
  participantsCount: (count) => 'Участников: $count',
  moreParticipants: (count) => 'ещё $count',
);

CallEngineStrings demoEngineStrings(DemoLocale locale) => switch (locale) {
      DemoLocale.en => const CallEngineStrings.english(),
      DemoLocale.ru => const CallEngineStrings(
          you: 'Вы',
          couldNotStartCall: 'Не удалось начать звонок',
          couldNotConnect: 'Не удалось соединиться',
          noConnection: 'Нет соединения с интернетом',
          callAlreadyActive: 'Вы уже в звонке',
          noAnswer: 'Нет ответа',
          partyBusy: 'Занято',
          reconnectFailed: 'Связь потеряна',
          microphoneAccessRequired: 'Для звонка нужен доступ к микрофону',
          cameraAccessRequired: 'Для видеозвонка нужен доступ к камере',
          permissionRequestFailed: 'Не удалось запросить разрешения',
          screenShareBlocked: 'Экран уже показывает другой участник',
          screenShareNotificationTitle: 'Показ экрана',
          screenShareNotificationText: 'Ваш экран виден собеседникам',
          noParticipants: 'Некому звонить',
        ),
    };

CallNativeStrings demoNativeStrings(DemoLocale locale) => switch (locale) {
      DemoLocale.en => const CallNativeStrings.english(),
      DemoLocale.ru => const CallNativeStrings(
          audioCallHandle: 'Аудиозвонок',
          videoCallHandle: 'Видеозвонок',
          incomingCallFallbackName: 'Входящий звонок',
          acceptAction: 'Принять',
          declineAction: 'Отклонить',
          notificationPermissionTitle: 'Разрешить уведомления',
          notificationPermissionRationale:
              'Без уведомлений входящие звонки не будут показываться.',
          notificationPermissionSettings: 'Настройки',
        ),
    };

/// A theme that is visibly not the default, so it is obvious the call screens
/// are themeable rather than fixed.
const demoCallTheme = CallTheme(
  background: Color(0xFF10131A),
  barBackground: Color(0xFF1B2029),
  buttonBackground: Color(0xFF262C38),
  endCallColor: Color(0xFFE5484D),
  acceptCallColor: Color(0xFF30A46C),
  speakingColor: Color(0xFF30A46C),
  speakerActiveBackground: Color(0xFFF2F4F8),
  speakerActiveIconColor: Color(0xFF10131A),
  textPrimary: Color(0xFFF2F4F8),
  textSecondary: Color(0xFF9AA3B5),
  dividerColor: Color(0xFF2C3444),
);
