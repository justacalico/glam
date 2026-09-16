import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in the system browser. Silently ignores malformed URLs.
Future<void> launchExternal(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) {
    return;
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
