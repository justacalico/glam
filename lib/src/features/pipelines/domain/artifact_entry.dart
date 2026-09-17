import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:equatable/equatable.dart';

/// One file inside a job's artifact zip.
class ArtifactEntry extends Equatable {
  const ArtifactEntry({required this.path, required this.size});

  final String path;
  final int size;

  @override
  List<Object?> get props => [path, size];
}

/// Lists the files inside a downloaded artifact archive.
List<ArtifactEntry> listArtifacts(Uint8List zip) {
  final archive = ZipDecoder().decodeBytes(zip);
  return [
    for (final f in archive.files)
      if (f.isFile) ArtifactEntry(path: f.name, size: f.size),
  ]..sort((a, b) => a.path.compareTo(b.path));
}
