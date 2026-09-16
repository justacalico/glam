# AGENTS.md

Guidance for any agent or developer working in this repository.

## What this is

Glam is a GitLab client for desktop and mobile, written in Flutter. It talks
to the GitLab REST API (v4) and works against gitlab.com or any self-hosted
instance.

## Bar for code quality

This is an A-grade codebase. Code that lands here should read like it was
written by a senior Flutter engineer who cares:

- Feature-first layout under `lib/src/features/<name>/`, split into
  `domain` (models), `data` (repositories / API), `application`
  (Riverpod providers/controllers), `presentation` (widgets/screens).
- Shared infrastructure lives under `lib/src/core/` (API client, storage,
  utils, common widgets).
- No god files. If a widget or file grows past ~300 lines, split it. If a
  class has more than one reason to change, split it. Prefer several small
  composable pieces over one clever one.
- Immutability by default: models are const-constructed value types with
  `Equatable` equality and `copyWith`.
- State flows through Riverpod `Notifier`/`AsyncNotifier` classes. Widgets
  stay dumb; logic lives in testable providers.
- Never hardcode secrets, tokens, or instance URLs. The GitLab token only
  ever lives in secure storage or in memory.
- Follow existing conventions before inventing new ones. Match the style of
  the code around you.

## After every change

1. `flutter analyze` must pass clean (no warnings, no infos).
2. `dart format .` for anything you touched.
3. Run the tests: `flutter test`. They must all pass.
4. If you added behavior, add or update tests in the same change.
5. Check coverage did not regress:
   `flutter test --coverage` then `dart run tool/coverage_report.dart`
   prints the per-file and total line coverage.

## Coverage

The goal is full line coverage of `lib/`. Every repository, provider, model,
and widget should be exercised. Widget files get widget tests; logic gets
unit tests; screens get golden tests under `test/goldens/`.

Regenerate goldens deliberately and review the diffs:

```
flutter test test/goldens --update-goldens
```

## Testing conventions

- Mocks use `mocktail`. Shared fixtures live in `test/fixtures/`.
- API responses are mocked at the `Dio` layer via a `MockDio` adapter, so
  repositories and providers are tested against real JSON payloads from
  `test/fixtures/json/`.
- Widget tests pump `ProviderScope` with overridden providers, never real
  network.

## Commits

Small, atomic commits. One logical change per commit, message in plain
language describing the fix or feature.
