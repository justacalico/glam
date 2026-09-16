import 'dart:convert';
import 'dart:io';

/// Loads a JSON fixture from `test/fixtures/json/<name>.json`.
Object? fixtureJson(String name) {
  final file = File('test/fixtures/json/$name.json');
  return jsonDecode(file.readAsStringSync());
}

/// Loads a fixture list, or wraps a single object in a list.
List<Object?> fixtureList(String name) {
  final json = fixtureJson(name);
  return json is List ? json : [json];
}

/// Loads a fixture as a string (for raw endpoints like job traces).
String fixtureText(String name) {
  return File('test/fixtures/json/$name').readAsStringSync();
}
