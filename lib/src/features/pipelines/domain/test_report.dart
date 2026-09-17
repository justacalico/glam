import 'package:equatable/equatable.dart';

/// A pipeline's aggregated test report (`/pipelines/:id/test_report`).
/// REST exposes suite-level counts only — individual cases come via
/// GraphQL, which the app doesn't use.
class TestReport extends Equatable {
  const TestReport({
    this.totalTime = 0,
    this.totalCount = 0,
    this.successCount = 0,
    this.failedCount = 0,
    this.skippedCount = 0,
    this.errorCount = 0,
    this.suites = const [],
  });

  factory TestReport.fromJson(Map<String, dynamic> json) {
    final suites = json['test_suites'];
    return TestReport(
      totalTime: (json['total_time'] as num?)?.toDouble() ?? 0,
      totalCount: json['total_count'] as int? ?? 0,
      successCount: json['success_count'] as int? ?? 0,
      failedCount: json['failed_count'] as int? ?? 0,
      skippedCount: json['skipped_count'] as int? ?? 0,
      errorCount: json['error_count'] as int? ?? 0,
      suites: suites is List
          ? suites
                .whereType<Map<String, dynamic>>()
                .map(TestSuite.fromJson)
                .toList()
          : const [],
    );
  }

  final double totalTime;
  final int totalCount;
  final int successCount;
  final int failedCount;
  final int skippedCount;
  final int errorCount;
  final List<TestSuite> suites;

  bool get isEmpty => totalCount == 0 && suites.isEmpty;

  @override
  List<Object?> get props => [totalCount, failedCount, suites.length];
}

/// One test suite inside a pipeline report.
class TestSuite extends Equatable {
  const TestSuite({
    required this.name,
    this.totalTime = 0,
    this.totalCount = 0,
    this.successCount = 0,
    this.failedCount = 0,
    this.skippedCount = 0,
    this.errorCount = 0,
    this.buildIds = const [],
    this.suiteError,
  });

  factory TestSuite.fromJson(Map<String, dynamic> json) {
    final buildIds = json['build_ids'];
    return TestSuite(
      name: json['name'] as String? ?? '',
      totalTime: (json['total_time'] as num?)?.toDouble() ?? 0,
      totalCount: json['total_count'] as int? ?? 0,
      successCount: json['success_count'] as int? ?? 0,
      failedCount: json['failed_count'] as int? ?? 0,
      skippedCount: json['skipped_count'] as int? ?? 0,
      errorCount: json['error_count'] as int? ?? 0,
      buildIds: buildIds is List
          ? buildIds.whereType<int>().toList()
          : const [],
      suiteError: json['suite_error'] as String?,
    );
  }

  final String name;
  final double totalTime;
  final int totalCount;
  final int successCount;
  final int failedCount;
  final int skippedCount;
  final int errorCount;

  /// Jobs that produced this suite's report.
  final List<int> buildIds;
  final String? suiteError;

  @override
  List<Object?> get props => [name, totalCount];
}
