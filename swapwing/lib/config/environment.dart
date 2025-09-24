class EnvironmentConfig {
  const EnvironmentConfig._();

  /// Base URL for API requests.
  static const String apiBaseUrl = String.fromEnvironment(
    'SWAPWING_API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Toggle for continuing to use mock/sample data.
  static const bool useMockData = bool.fromEnvironment(
    'SWAPWING_USE_MOCK_DATA',
    defaultValue: true,
  );
}
