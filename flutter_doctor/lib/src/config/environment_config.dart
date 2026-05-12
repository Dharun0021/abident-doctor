enum Environment {
  local,
  // production,
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

  
  // factory EnvironmentConfig.production() {
  //   return EnvironmentConfig(
  //     environment: Environment.production,
  //    baseUrl: 'https://abident-backend-production.up.railway.app',
  //     enableLogging: false,
  //     timeoutSeconds: 30,
  //   );
  // }
  

  @override
  String toString() => '$environment - baseUrl: $baseUrl';
}
