import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/features/pipelines/domain/artifact_entry.dart';

/// Lists the files inside a downloaded artifact archive.
///
/// A bad payload (proxy error page, truncated download) is reported as
/// an [ApiException] instead of an empty list or a raw decoder crash —
/// [ZipDecoder] returns an empty archive when it can't find the end
/// record and throws [RangeError] on a bogus one.
List<ArtifactEntry> decodeArtifactEntries(Uint8List zip) {
  if (zip.length < 4 || zip[0] != 0x50 || zip[1] != 0x4B) {
    throw const ApiException(
      kind: ApiErrorKind.unknown,
      message: 'Could not read the artifact archive',
    );
  }
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(zip);
  } on Object {
    throw const ApiException(
      kind: ApiErrorKind.unknown,
      message: 'Could not read the artifact archive',
    );
  }
  return [
    for (final f in archive.files)
      if (f.isFile) ArtifactEntry(path: f.name, size: f.size),
  ]..sort((a, b) => a.path.compareTo(b.path));
}
