import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  static const String _githubApiUrl =
      'https://api.github.com/repos/cikle/storify/releases/latest';
  static const String _releasesPageUrl =
      'https://github.com/cikle/storify/releases/latest';

  /// Returns the latest version string if it is newer than the installed version,
  /// otherwise null. All errors return null silently.
  Future<String?> fetchLatestVersionIfNewer() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version; // read automatically from pubspec.yaml

      final response = await http.get(
        Uri.parse(_githubApiUrl),
        headers: {'Accept': 'application/vnd.github+json'},
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;
      final body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final tag = body['tag_name'] as String?;
      if (tag == null) return null;
      final latest = tag.startsWith('v') ? tag.substring(1) : tag;
      return _isNewer(latest, currentVersion) ? latest : null;
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
    // Strip build number (e.g. "1.0.0+1" → "1.0.0")
    final base = v.split('+').first;
    final parts = base.split('.');
    if (parts.length != 3) return null;
    final nums = parts.map(int.tryParse).toList();
    if (nums.contains(null)) return null;
    return nums.cast<int>();
  }
}
