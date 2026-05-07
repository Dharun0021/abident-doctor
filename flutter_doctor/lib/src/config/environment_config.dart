enum Environment {
  local,
  // production, // Commented out to force local usage
}

class EnvironmentConfig {
  final Environment environment;
  final String baseUrl;
  final bool enableLogging;
  final int timeoutSeconds;

  EnvironmentConfig({
    required this.environment,
    required this.baseUrl,
    this.enableLogging = true,
    this.timeoutSeconds = 30,
  });

  factory EnvironmentConfig.local() {
    return EnvironmentConfig(
      environment: Environment.local,
      baseUrl: 'http://localhost:5000',
      enableLogging: true,
      timeoutSeconds: 30,
    );
  }

  /*
  factory EnvironmentConfig.production() {
    return EnvironmentConfig(
      environment: Environment.production,
      baseUrl: 'https://abident-backend-1.onrender.com',
      enableLogging: false,
      timeoutSeconds: 30,
    );
  }
  */

  @override
  String toString() => '$environment - baseUrl: $baseUrl';
}
