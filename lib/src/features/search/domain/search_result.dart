import 'package:equatable/equatable.dart';

/// One hit from a `blobs`/`wiki_blobs` search: file location plus the
/// matching lines.
class BlobResult extends Equatable {
  const BlobResult({
    required this.path,
    required this.data,
    this.basename,
    this.startLine,
    this.ref,
    this.projectId,
  });

  factory BlobResult.fromJson(Map<String, dynamic> json) => BlobResult(
    path: json['path'] as String? ?? '',
    basename: json['basename'] as String?,
    data: json['data'] as String? ?? '',
    startLine: json['startline'] as int?,
    ref: json['ref'] as String?,
    projectId: json['project_id'] as int?,
  );

  final String path;
  final String? basename;
  final String data;
  final int? startLine;
  final String? ref;
  final int? projectId;

  @override
  List<Object?> get props => [path, ref, startLine];
}
