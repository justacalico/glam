import 'package:equatable/equatable.dart';

/// One file inside a job's artifact zip.
class ArtifactEntry extends Equatable {
  const ArtifactEntry({required this.path, required this.size});

  factory ArtifactEntry.fromJson(Map<String, dynamic> json) {
    return ArtifactEntry(
      path: json['path'] as String? ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }

  final String path;
  final int size;

  @override
  List<Object?> get props => [path, size];
}
