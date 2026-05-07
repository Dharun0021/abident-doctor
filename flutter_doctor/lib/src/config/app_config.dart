import 'environment_config.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static final EnvironmentConfig _config = EnvironmentConfig.local();

  static String get baseUrl => _config.baseUrl;
  static bool get enableLogging => _config.enableLogging;
  static int get timeoutSeconds => _config.timeoutSeconds;
  static Environment get environment => _config.environment;

  static const String doctorRegisterEndpoint = '/api/doctor/register';
  static const String doctorLoginEndpoint = '/api/doctor/login';
  static const String doctorProfileEndpoint = '/api/doctor/profile';
  static const String availabilityCreateEndpoint = '/api/availability/create';
  static const String availabilityBulkCreateEndpoint = '/api/availability/bulk-create';
  static const String availabilityListEndpoint = '/api/availability/my-availabilities';

  static String get doctorRegisterUrl => '$baseUrl$doctorRegisterEndpoint';
  static String get doctorLoginUrl => '$baseUrl$doctorLoginEndpoint';
  static String get doctorProfileUrl => '$baseUrl$doctorProfileEndpoint';
  static String get availabilityCreateUrl => '$baseUrl$availabilityCreateEndpoint';
  static String get availabilityBulkCreateUrl => '$baseUrl$availabilityBulkCreateEndpoint';
  static String get availabilityListUrl => '$baseUrl$availabilityListEndpoint';

  static void printConfig() {
    if (enableLogging) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('🩺 ABIDENT Doctor App (LOCAL MODE)');
      debugPrint('═══════════════════════════════════════');
      debugPrint('🌍 Environment: $environment');
      debugPrint('🔗 Base URL: $baseUrl');
      debugPrint('⏱️  Timeout: ${timeoutSeconds}s');
      debugPrint('📝 Logging: ${enableLogging ? 'Enabled' : 'Disabled'}');
      debugPrint('═══════════════════════════════════════');
    }
  }
}
