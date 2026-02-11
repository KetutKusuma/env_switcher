import 'package:flutter/material.dart';
import 'package:env_switcher/src/env_config.dart';
import 'package:env_switcher/src/env_manager.dart';
import 'package:env_switcher/src/credentials_input_dialog.dart';

/// Bottom sheet widget for selecting environment
class EnvSelectorBottomSheet extends StatefulWidget {
  final VoidCallback? onEnvironmentChanged;
  final bool requiresRestart;
  final String title;
  final String subtitle;

  const EnvSelectorBottomSheet({
    super.key,
    this.onEnvironmentChanged,
    this.requiresRestart = true,
    this.title = 'Select Environment',
    this.subtitle = 'Choose the environment you want to use',
  });

  @override
  State<EnvSelectorBottomSheet> createState() => _EnvSelectorBottomSheetState();

  /// Show the bottom sheet
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onEnvironmentChanged,
    bool requiresRestart = true,
    String title = 'Select Environment',
    String subtitle = 'Choose the environment you want to use',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EnvSelectorBottomSheet(
        onEnvironmentChanged: onEnvironmentChanged,
        requiresRestart: requiresRestart,
        title: title,
        subtitle: subtitle,
      ),
    );
  }
}

class _EnvSelectorBottomSheetState extends State<EnvSelectorBottomSheet> {
  final EnvManager _envManager = EnvManager();
  EnvConfig? _selectedEnv;

  @override
  void initState() {
    super.initState();
    _selectedEnv = _envManager.currentEnvironment;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final environments = _envManager.availableEnvironments;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Text(
              widget.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              widget.subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Environment list
            ...environments.map((env) => _buildEnvironmentTile(env)),

            const SizedBox(height: 16),

            // Current environment info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withAlpha((0.1 * 255).toInt()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Current: ${_envManager.currentEnvironment?.displayName ?? 'None'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (widget.requiresRestart) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ App restart required after changing environment',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange[700],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 16),

            // Apply button
            ElevatedButton(
              onPressed: _selectedEnv != _envManager.currentEnvironment
                  ? () => _applyEnvironment()
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Apply Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentTile(EnvConfig env) {
    final isSelected = _selectedEnv == env;
    final isCurrent = _envManager.currentEnvironment == env;
    final hasCredentials = _envManager.hasCredentials(env.name);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? theme.primaryColor : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedEnv = env),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Radio button
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? theme.primaryColor : Colors.grey,
              ),
              const SizedBox(width: 12),

              // Environment info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      children: [
                        Text(
                          env.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        // Tambahkan badge untuk storage mode
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: env.storageMode == StorageMode.permanent
                                ? Colors.blue
                                : Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            env.storageMode == StorageMode.permanent
                                ? 'PERMANENT'
                                : 'TEMPORARY',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (env.requiresCredentials) ...[
                          const SizedBox(width: 8),
                          Icon(
                            hasCredentials ? Icons.key : Icons.key_off,
                            size: 16,
                            color:
                                hasCredentials ? Colors.green : Colors.orange,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      env.baseUrl,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    // Tambahkan info storage mode
                    const SizedBox(height: 4),
                    Text(
                      env.storageMode == StorageMode.permanent
                          ? 'Saved permanently (persists after app restart)'
                          : 'Temporary (cleared on app restart)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                      ),
                    ),
                    if (env.requiresCredentials && !hasCredentials) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Requires credentials',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyEnvironment() async {
    if (_selectedEnv == null) return;

    try {
      // Check if credentials are required
      if (_selectedEnv!.requiresCredentials) {
        final savedCredentials = _envManager.getCredentials(_selectedEnv!.name);

        // Show credentials dialog if not saved or if switching to new env
        if (savedCredentials == null || savedCredentials.isEmpty) {
          final credentials = await CredentialsInputDialog.show(
            context,
            environment: _selectedEnv!,
            savedCredentials: savedCredentials,
          );

          // User cancelled
          if (credentials == null) {
            return;
          }

          // Validate credentials if callback is provided
          if (_selectedEnv!.onValidateCredentials != null) {
            final errorMessage =
                await _selectedEnv!.onValidateCredentials!(credentials);

            if (errorMessage != null) {
              // Validation failed
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              return;
            }
          }

          // Switch with credentials
          await _envManager.switchEnvironment(
            _selectedEnv!,
            credentials: credentials,
          );
        } else {
          // Use saved credentials
          await _envManager.switchEnvironment(
            _selectedEnv!,
            credentials: savedCredentials,
          );
        }
      } else {
        // No credentials required, switch directly
        await _envManager.switchEnvironment(_selectedEnv!);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onEnvironmentChanged?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Environment switched to ${_selectedEnv!.displayName}',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch environment: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
