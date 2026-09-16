import 'dart:io';

void main(List<String> args) {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    stderr.writeln(
      'coverage/lcov.info not found. Run flutter test --coverage.',
    );
    exit(1);
  }

  final uncoveredOnly = args.contains('--uncovered');
  final entries = <String, _FileCoverage>{};

  String? current;
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      current = line.substring(3);
      entries[current] = _FileCoverage();
    } else if (current != null) {
      if (line.startsWith('LF:')) {
        entries[current]!.total = int.parse(line.substring(3));
      } else if (line.startsWith('LH:')) {
        entries[current]!.hit = int.parse(line.substring(3));
      }
    }
  }

  var totalLines = 0;
  var totalHit = 0;
  final rows = <_FileCoverage>[];
  entries.forEach((path, cov) {
    totalLines += cov.total;
    totalHit += cov.hit;
    cov.path = path;
    rows.add(cov);
  });
  rows.sort((a, b) => a.percent.compareTo(b.percent));

  for (final row in rows) {
    if (uncoveredOnly && row.percent >= 100) {
      continue;
    }
    final pct = row.percent.toStringAsFixed(1).padLeft(6);
    stdout.writeln('$pct%  ${row.hit}/${row.total}  ${row.path}');
  }

  final overall = totalLines == 0 ? 0.0 : totalHit / totalLines * 100;
  stdout
    ..writeln('-' * 72)
    ..writeln(
      'TOTAL: ${overall.toStringAsFixed(2)}% ($totalHit/$totalLines lines)',
    );
  if (overall < 100) {
    exitCode = 2;
  }
}

class _FileCoverage {
  String path = '';
  int total = 0;
  int hit = 0;
  double get percent => total == 0 ? 100 : hit / total * 100;
}
