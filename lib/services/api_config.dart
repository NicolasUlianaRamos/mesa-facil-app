import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  /// Override with: `--dart-define=API_BASE_URL=http://192.168.x.x:3000`
  /// Defaults:
  /// - Web/Chrome: `http://10.182.198.68:3000`
  /// - Android device: `http://10.182.198.68:3000`
  /// - Android emulator: use `--dart-define=API_BASE_URL=http://10.0.2.2:3000`
  static String get baseUrl {
    const env = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (env.isNotEmpty) return env;

    if (kIsWeb) return 'http://10.182.198.68:3000';

    return 'http://10.182.198.68:3000';
  }

  static String get apiBase => '$baseUrl/api';
}
