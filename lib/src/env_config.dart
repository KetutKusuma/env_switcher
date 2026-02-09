/// Represents an environment configuration with optional credentials
class EnvConfig {
  final String name;
  final String displayName;
  final String baseUrl;
  final Map<String, dynamic> extras;
  final bool requiresCredentials;
  final List<CredentialField> credentialFields;

  const EnvConfig({
    required this.name,
    required this.displayName,
    required this.baseUrl,
    this.extras = const {},
    this.requiresCredentials = false,
    this.credentialFields = const [],
  });

  /// Create a copy with some fields replaced
  EnvConfig copyWith({
    String? name,
    String? displayName,
    String? baseUrl,
    Map<String, dynamic>? extras,
    bool? requiresCredentials,
    List<CredentialField>? credentialFields,
  }) {
    return EnvConfig(
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      baseUrl: baseUrl ?? this.baseUrl,
      extras: extras ?? this.extras,
      requiresCredentials: requiresCredentials ?? this.requiresCredentials,
      credentialFields: credentialFields ?? this.credentialFields,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'displayName': displayName,
      'baseUrl': baseUrl,
      'extras': extras,
      'requiresCredentials': requiresCredentials,
      'credentialFields': credentialFields.map((e) => e.toJson()).toList(),
    };
  }

  /// Create from JSON
  factory EnvConfig.fromJson(Map<String, dynamic> json) {
    return EnvConfig(
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      baseUrl: json['baseUrl'] as String,
      extras: json['extras'] as Map<String, dynamic>? ?? {},
      requiresCredentials: json['requiresCredentials'] as bool? ?? false,
      credentialFields: (json['credentialFields'] as List?)
              ?.map((e) => CredentialField.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EnvConfig && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'EnvConfig(name: $name, displayName: $displayName, baseUrl: $baseUrl, requiresCredentials: $requiresCredentials)';
}

/// Represents a credential field for environment configuration
class CredentialField {
  final String key;
  final String label;
  final String? hint;
  final bool isPassword;
  final bool isRequired;
  final String? defaultValue;
  final String? Function(String?)? validator;

  const CredentialField({
    required this.key,
    required this.label,
    this.hint,
    this.isPassword = false,
    this.isRequired = true,
    this.defaultValue,
    this.validator,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'hint': hint,
      'isPassword': isPassword,
      'isRequired': isRequired,
      'defaultValue': defaultValue,
    };
  }

  /// Create from JSON
  factory CredentialField.fromJson(Map<String, dynamic> json) {
    return CredentialField(
      key: json['key'] as String,
      label: json['label'] as String,
      hint: json['hint'] as String?,
      isPassword: json['isPassword'] as bool? ?? false,
      isRequired: json['isRequired'] as bool? ?? true,
      defaultValue: json['defaultValue'] as String?,
    );
  }
}
