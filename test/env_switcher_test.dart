import 'package:flutter_test/flutter_test.dart';
import 'package:env_switcher/env_switcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EnvManager Tests', () {
    late List<EnvConfig> testEnvironments;

    setUp(() {
      EnvManager().resetForTesting();
      SharedPreferences.setMockInitialValues({});

      testEnvironments = [
        const EnvConfig(
          name: 'dev',
          displayName: 'Development',
          baseUrl: 'https://dev.example.com',
          extras: {'apiKey': 'dev-key'},
        ),
        const EnvConfig(
          name: 'staging',
          displayName: 'Staging',
          baseUrl: 'https://staging.example.com',
          extras: {'apiKey': 'staging-key'},
        ),
        const EnvConfig(
          name: 'prod',
          displayName: 'Production',
          baseUrl: 'https://api.example.com',
          extras: {'apiKey': 'prod-key'},
        ),
      ];
    });

    test('Initialize with default environment', () async {
      final envManager = EnvManager();

      await envManager.initialize(
        environments: testEnvironments,
        defaultEnvironment: testEnvironments[0],
      );

      expect(envManager.isInitialized, true);
      expect(envManager.currentEnvironment, testEnvironments[0]);
      expect(envManager.availableEnvironments.length, 3);
    });

    test('Switch environment', () async {
      final envManager = EnvManager();

      await envManager.initialize(
        environments: testEnvironments,
        defaultEnvironment: testEnvironments[0],
      );

      // Switch to staging
      await envManager.switchEnvironment(testEnvironments[1]);

      expect(envManager.currentEnvironment, testEnvironments[1]);
      expect(envManager.currentEnvironment?.name, 'staging');
    });

    test('Get extras from current environment', () async {
      final envManager = EnvManager();

      await envManager.initialize(
        environments: testEnvironments,
        defaultEnvironment: testEnvironments[0],
      );

      final apiKey = envManager.getExtra<String>('apiKey');
      expect(apiKey, 'dev-key');

      // Switch and check again
      await envManager.switchEnvironment(testEnvironments[2]);
      final prodKey = envManager.getExtra<String>('apiKey');
      expect(prodKey, 'prod-key');
    });

    test('Persist environment selection', () async {
      // First instance
      final envManager1 = EnvManager();
      await envManager1.initialize(
        environments: testEnvironments,
        defaultEnvironment: testEnvironments[0],
      );
      await envManager1.switchEnvironment(testEnvironments[1]);

      // Get saved preference
      final prefs = await SharedPreferences.getInstance();
      final savedEnv = prefs.getString('env_switcher_selected_env');
      expect(savedEnv, 'staging');
    });

    test('Notify listeners on environment change', () async {
      final envManager = EnvManager();
      await envManager.initialize(
        environments: testEnvironments,
        defaultEnvironment: testEnvironments[0],
      );

      var notificationCount = 0;
      envManager.addListener(() {
        notificationCount++;
      });

      await envManager.switchEnvironment(testEnvironments[1]);
      expect(notificationCount, 1);

      await envManager.switchEnvironment(testEnvironments[2]);
      expect(notificationCount, 2);
    });

    test('Throw error for invalid environment', () async {
      final envManager = EnvManager();
      await envManager.initialize(
        environments: testEnvironments,
        defaultEnvironment: testEnvironments[0],
      );

      const invalidEnv = EnvConfig(
        name: 'invalid',
        displayName: 'Invalid',
        baseUrl: 'https://invalid.com',
      );

      expect(
        () => envManager.switchEnvironment(invalidEnv),
        throwsArgumentError,
      );
    });

    test('Clear saved environment', () async {
      final envManager = EnvManager();
      await envManager.initialize(
        environments: testEnvironments,
        defaultEnvironment: testEnvironments[0],
      );

      await envManager.switchEnvironment(testEnvironments[1]);
      await envManager.clearSaved();

      final prefs = await SharedPreferences.getInstance();
      final savedEnv = prefs.getString('env_switcher_selected_env');
      expect(savedEnv, null);
    });

    test('Non-persistent storage', () async {
      final envManager = EnvManager();

      await envManager.initialize(
        environments: testEnvironments,
        defaultEnvironment: testEnvironments[0],
        usePersistentStorage: false,
      );

      // Switch to staging
      await envManager.switchEnvironment(testEnvironments[1]);

      // Verify that it is NOT saved in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedEnv = prefs.getString('env_switcher_selected_env');
      expect(savedEnv, null);
    });

    test('Non-persistent credentials', () async {
      final envManager = EnvManager();

      final environmentsWithCreds = [
        const EnvConfig(
          name: 'dev',
          displayName: 'Development',
          baseUrl: 'https://dev.example.com',
          requiresCredentials: true,
        ),
      ];

      await envManager.initialize(
        environments: environmentsWithCreds,
        usePersistentStorage: false,
      );

      // Save credentials
      await envManager.switchEnvironment(
        environmentsWithCreds[0],
        credentials: {'password': 'secret'},
      );

      // Verify they are in memory
      expect(envManager.getCredential('password'), 'secret');

      // Verify they are NOT in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedCreds = prefs.getString('env_switcher_credentials_dev');
      expect(savedCreds, null);
    });
  });

  group('EnvConfig Tests', () {
    test('Create EnvConfig', () {
      const config = EnvConfig(
        name: 'test',
        displayName: 'Test',
        baseUrl: 'https://test.com',
        extras: {'key': 'value'},
      );

      expect(config.name, 'test');
      expect(config.displayName, 'Test');
      expect(config.baseUrl, 'https://test.com');
      expect(config.extras['key'], 'value');
    });

    test('EnvConfig equality', () {
      const config1 = EnvConfig(
        name: 'test',
        displayName: 'Test',
        baseUrl: 'https://test.com',
      );

      const config2 = EnvConfig(
        name: 'test',
        displayName: 'Test',
        baseUrl: 'https://test.com',
      );

      expect(config1, config2);
      expect(config1.hashCode, config2.hashCode);
    });

    test('EnvConfig copyWith', () {
      const config = EnvConfig(
        name: 'test',
        displayName: 'Test',
        baseUrl: 'https://test.com',
        extras: {'key': 'value'},
      );

      final copied = config.copyWith(
        displayName: 'Updated Test',
        baseUrl: 'https://updated.com',
      );

      expect(copied.name, 'test');
      expect(copied.displayName, 'Updated Test');
      expect(copied.baseUrl, 'https://updated.com');
      expect(copied.extras['key'], 'value');
    });

    test('EnvConfig JSON serialization', () {
      const config = EnvConfig(
        name: 'test',
        displayName: 'Test',
        baseUrl: 'https://test.com',
        extras: {'key': 'value'},
      );

      final json = config.toJson();
      final restored = EnvConfig.fromJson(json);

      expect(restored.name, config.name);
      expect(restored.displayName, config.displayName);
      expect(restored.baseUrl, config.baseUrl);
      expect(restored.extras['key'], config.extras['key']);
    });
  });
}
