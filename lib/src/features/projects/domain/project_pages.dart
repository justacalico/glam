import 'package:equatable/equatable.dart';

/// A project's GitLab Pages config (`/projects/:id/pages`).
class ProjectPages extends Equatable {
  const ProjectPages({
    this.url = '',
    this.forceHttps = false,
    this.uniqueDomainEnabled = false,
  });

  factory ProjectPages.fromJson(Map<String, dynamic> json) => ProjectPages(
    url: json['url'] as String? ?? '',
    forceHttps: json['force_https'] as bool? ?? false,
    uniqueDomainEnabled: json['is_unique_domain_enabled'] as bool? ?? false,
  );

  final String url;
  final bool forceHttps;
  final bool uniqueDomainEnabled;

  @override
  List<Object?> get props => [url, forceHttps, uniqueDomainEnabled];
}

/// A custom domain bound to Pages (`/projects/:id/pages/domains`).
class PageDomain extends Equatable {
  const PageDomain({
    required this.domain,
    this.url = '',
    this.verified = false,
    this.autoSslEnabled = false,
    this.expiresAt,
  });

  factory PageDomain.fromJson(Map<String, dynamic> json) => PageDomain(
    domain: json['domain'] as String? ?? '',
    url: json['url'] as String? ?? '',
    verified: json['verified'] as bool? ?? false,
    autoSslEnabled: json['auto_ssl_enabled'] as bool? ?? false,
    expiresAt: json['certificate'] is Map<String, dynamic>
        ? DateTime.tryParse(
            (json['certificate']['expiration'] as String?) ?? '',
          )
        : null,
  );

  final String domain;
  final String url;
  final bool verified;
  final bool autoSslEnabled;
  final DateTime? expiresAt;

  @override
  List<Object?> get props => [domain];
}
