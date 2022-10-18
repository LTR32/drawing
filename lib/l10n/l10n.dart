import 'dart:ui';

class L10n {
  static final all = [
    const Locale('fr'),
    const Locale('en')
  ];

  static String getFlag(String code){
    switch (code) {
      case 'en':
        return '🇬🇧';
      default:
        return '🇫🇷';
    }
  }
}