import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:env_switcher/src/env_config.dart';

/// Singleton class to manage environment configurations
class EnvManager extends ChangeNotifier {
  static final EnvManager _instance = EnvManager._internal();
  factory EnvManager() => _instance;
  EnvManager._internal();

  static const String _storageKey = 'env_switcher_selected_env';
  static const String _credentialsKeyPrefix = 'env_switcher_credentials_';

  List<EnvConfig> _availableEnvironments = [];
  EnvConfig? _currentEnvironment;
  bool _isInitialized = false;
  final Map<String, Map<String, String>> _credentials = {};

  /// Get the current selected environment
  EnvConfig? get currentEnvironment => _currentEnvironment;

  /// Get all available environments
  List<EnvConfig> get availableEnvironments => List.unmodifiable(_availableEnvironments);

  /// Check if manager is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the environment manager with available environments
  Future<void> initialize({
    required List<EnvConfig> environments,
    EnvConfig? defaultEnvironment,
  }) async {
    if (_isInitialized) {
      debugPrint('EnvManager: Already initialized');
      return;
    }

    if (environments.isEmpty) {
      throw ArgumentError('At least one environment must be provided');
    }

    _availableEnvironments = environments;

    // Try to load saved environment
    final prefs = await SharedPreferences.getInstance();
    final savedEnvName = prefs.getString(_storageKey);

    if (savedEnvName != null) {
      _currentEnvironment = _availableEnvironments.firstWhere(
        (env) => env.name == savedEnvName,
        orElse: () => defaultEnvironment ?? _availableEnvironments.first,
      );
    } else {
      _currentEnvironment = defaultEnvironment ?? _availableEnvironments.first;
    }

    // Load saved credentials for all environments
    await _loadAllCredentials();

    _isInitialized = true;
    notifyListeners();
    debugPrint('EnvManager: Initialized with ${_currentEnvironment?.name}');
  }

  /// Switch to a different environment
  Future<void> switchEnvironment(
    EnvConfig newEnvironment, {
    Map<String, String>? credentials,
  }) async {
    if (!_availableEnvironments.contains(newEnvironment)) {
      throw ArgumentError('Environment ${newEnvironment.name} is not available');
    }

    // Save credentials if provided
    if (credentials != null && credentials.isNotEmpty) {
      await _saveCredentials(newEnvironment.name, credentials);
      _credentials[newEnvironment.name] = credentials;
    }

    _currentEnvironment = newEnvironment;

    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, newEnvironment.name);

    notifyListeners();
    debugPrint('EnvManager: Switched to ${newEnvironment.name}');
  }

  /// Get an extra value from current environment
  T? getExtra<T>(String key) {
    return _currentEnvironment?.extras[key] as T?;
  }

  /// Get credentials for current environment
  Map<String, String>? getCredentials([String? envName]) {
    final name = envName ?? _currentEnvironment?.name;
    if (name == null) return null;
    return _credentials[name];
  }

  /// Get a specific credential value
  String? getCredential(String key, [String? envName]) {
    final creds = getCredentials(envName);
    return creds?[key];
  }

  /// Check if credentials are saved for an environment
  bool hasCredentials(String envName) {
    return _credentials.containsKey(envName) && 
           _credentials[envName]!.isNotEmpty;
  }

  /// Save credentials for an environment
  Future<void> _saveCredentials(
    String envName,
    Map<String, String> credentials,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_credentialsKeyPrefix$envName';
    await prefs.setString(key, jsonEncode(credentials));
    debugPrint('EnvManager: Saved credentials for $envName');
  }

  /// Load credentials for an environment
  Future<Map<String, String>?> _loadCredentials(String envName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_credentialsKeyPrefix$envName';
    final credentialsJson = prefs.getString(key);
    
    if (credentialsJson != null) {
      try {
        final decoded = jsonDecode(credentialsJson) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (e) {
        debugPrint('EnvManager: Error loading credentials for $envName: $e');
      }
    }
    
    return null;
  }

  /// Load all saved credentials
  Future<void> _loadAllCredentials() async {
    for (final env in _availableEnvironments) {
      if (env.requiresCredentials) {
        final creds = await _loadCredentials(env.name);
        if (creds != null) {
          _credentials[env.name] = creds;
        }
      }
    }
  }

  /// Clear credentials for an environment
  Future<void> clearCredentials(String envName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_credentialsKeyPrefix$envName';
    await prefs.remove(key);
    _credentials.remove(envName);
    debugPrint('EnvManager: Cleared credentials for $envName');
  }

  /// Clear all saved credentials
  Future<void> clearAllCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    for (final env in _availableEnvironments) {
      final key = '$_credentialsKeyPrefix${env.name}';
      await prefs.remove(key);
    }
    _credentials.clear();
    debugPrint('EnvManager: Cleared all credentials');
  }

  /// Reset to default environment
  Future<void> reset(EnvConfig defaultEnvironment) async {
    await switchEnvironment(defaultEnvironment);
  }

  /// Clear saved environment (will use default on next init)
  Future<void> clearSaved() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    debugPrint('EnvManager: Cleared saved environment');
  }
}
