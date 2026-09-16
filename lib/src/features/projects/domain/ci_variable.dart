import 'package:equatable/equatable.dart';

/// A CI/CD variable (`/projects/:id/variables`).
class CiVariable extends Equatable {
  const CiVariable({
    required this.key,
    required this.value,
    this.variableType = 'env_var',
    this.protected_ = false,
    this.masked = false,
    this.hidden = false,
    this.environmentScope = '*',
  });

  factory CiVariable.fromJson(Map<String, dynamic> json) => CiVariable(
    key: json['key'] as String? ?? '',
    value: json['value'] as String? ?? '',
    variableType: json['variable_type'] as String? ?? 'env_var',
    protected_: json['protected'] as bool? ?? false,
    masked: json['masked'] as bool? ?? false,
    hidden: json['hidden'] as bool? ?? false,
    environmentScope: json['environment_scope'] as String? ?? '*',
  );

  final String key;
  final String value;

  /// `env_var` or `file`.
  final String variableType;
  final bool protected_;
  final bool masked;
  final bool hidden;
  final String environmentScope;

  @override
  List<Object?> get props => [key, environmentScope];
}
