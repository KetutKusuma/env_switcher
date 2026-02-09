import 'package:flutter/material.dart';
import 'package:env_switcher/src/env_config.dart';

/// Dialog for inputting environment credentials
class CredentialsInputDialog extends StatefulWidget {
  final EnvConfig environment;
  final Map<String, String>? savedCredentials;

  const CredentialsInputDialog({
    required this.environment,
    super.key,
    this.savedCredentials,
  });

  @override
  State<CredentialsInputDialog> createState() => _CredentialsInputDialogState();

  /// Show the credentials input dialog
  static Future<Map<String, String>?> show(
    BuildContext context, {
    required EnvConfig environment,
    Map<String, String>? savedCredentials,
  }) {
    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CredentialsInputDialog(
        environment: environment,
        savedCredentials: savedCredentials,
      ),
    );
  }
}

class _CredentialsInputDialogState extends State<CredentialsInputDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _passwordVisibility = {};

  @override
  void initState() {
    super.initState();

    // Initialize controllers with saved values or defaults
    for (final field in widget.environment.credentialFields) {
      final savedValue = widget.savedCredentials?[field.key];
      final initialValue = savedValue ?? field.defaultValue ?? '';

      _controllers[field.key] = TextEditingController(text: initialValue);

      if (field.isPassword) {
        _passwordVisibility[field.key] = false;
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Environment Credentials'),
          const SizedBox(height: 4),
          Text(
            widget.environment.displayName,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please enter the required credentials for this environment:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ...widget.environment.credentialFields.map(_buildField),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleSubmit,
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildField(CredentialField field) {
    final isPassword = field.isPassword;
    final isVisible = _passwordVisibility[field.key] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[field.key],
        obscureText: isPassword && !isVisible,
        decoration: InputDecoration(
          labelText: field.label,
          hintText: field.hint,
          border: const OutlineInputBorder(),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordVisibility[field.key] = !isVisible;
                    });
                  },
                )
              : null,
        ),
        validator: (value) {
          // Custom validator if provided
          if (field.validator != null) {
            return field.validator!(value);
          }

          // Default required validation
          if (field.isRequired && (value == null || value.trim().isEmpty)) {
            return '${field.label} is required';
          }

          return null;
        },
        keyboardType:
            isPassword ? TextInputType.visiblePassword : TextInputType.text,
        textInputAction: TextInputAction.next,
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final credentials = <String, String>{};

      for (final entry in _controllers.entries) {
        credentials[entry.key] = entry.value.text.trim();
      }

      Navigator.of(context).pop(credentials);
    }
  }
}
