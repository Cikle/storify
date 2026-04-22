import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  // Keep in sync with version: in pubspec.yaml (major.minor.patch only)
  static const String _currentVersion = '1.0.0';
  static const String _githubApiUrl =
      'https://api.github.com/repos/cikle/storify/releases/latest';
  static const String _releasesPageUrl =
      'https://github.com/cikle/storify/releases/latest';

  /// Returns the latest version string if it is newer than [_currentVersion],
  /// otherwise null. All errors return null silently.
  Future<String?> fetchLatestVersionIfNewer() async {
    try {
      final response = await http
          .get(
            Uri.parse(_githubApiUrl),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;
      final body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final tag = body['tag_name'] as String?;
      if (tag == null) return null;
      final latest = tag.startsWith('v') ? tag.substring(1) : tag;
      return _isNewer(latest, _currentVersion) ? latest : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> openReleasesPage() async {
    try {
      await launchUrl(
        Uri.parse(_releasesPageUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  bool _isNewer(String latest, String current) {
    final l = _parse(latest);
    final c = _parse(current);
    if (l == null || c == null) return false;
    for (int i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }

  List<int>? _parse(String v) {
    final parts = v.split('.');
    if (parts.length != 3) return null;
    final nums = parts.map(int.tryParse).toList();
    if (nums.contains(null)) return null;
    return nums.cast<int>();
  }
}
