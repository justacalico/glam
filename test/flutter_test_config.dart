import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden files were generated on Arch Linux; CI renders on Ubuntu and the
/// font rasterizers differ slightly in anti-aliasing. Allow a small pixel
/// diff so distro-level rendering drift does not fail the suite.
const double _kGoldenDiffTolerance = 0.05;

class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (!result.passed && result.diffPercent <= _kGoldenDiffTolerance) {
      return true;
    }
    if (!result.passed) {
      final error = await generateFailureOutput(result, golden, basedir);
      throw FlutterError(error);
    }
    return result.passed;
  }
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final comparator = goldenFileComparator;
  if (comparator is LocalFileComparator) {
    // LocalFileComparator treats its argument as a file path and uses its
    // parent directory, so append a dummy name to keep the test directory.
    goldenFileComparator = _TolerantComparator(
      Uri.parse('${comparator.basedir}flutter_test_config.dart'),
    );
  }
  await testMain();
}
