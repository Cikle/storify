import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:storify/models/item.dart';
import 'package:storify/models/location.dart';
import 'package:storify/services/storage_service.dart';

// Wird bei HTTP-Fehlern geworfen
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

// Alle API-Aufrufe laufen hier durch (JSON, X-Api-Key)
class ApiService {
  final StorageService _storage;

  ApiService(this._storage);

  String get _baseUrl => _storage.getApiBaseUrl();

  // Headers with API key for every request
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Api-Key': _storage.getApiKey(),
  };

  // Connection test via /health.php
  Future<void> checkConnection() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/health.php'), headers: _headers)
        .timeout(const Duration(seconds: 8));
    _handleResponse(response);
  }

  // Used during setup before credentials are saved
  static Future<void> checkConnectionWith(String baseUrl, String apiKey) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Api-Key': apiKey,
    };
    final url = baseUrl.replaceAll(RegExp(r'/$'), '');
    final client = http.Client();
    try {
      final response = await client
          .get(Uri.parse('$url/health.php'), headers: headers)
          .timeout(const Duration(seconds: 8));
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      String message = 'An error occurred.';
      try {
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        message = decoded['message'] as String? ?? message;
      } catch (_) {}
      throw ApiException(message, statusCode: response.statusCode);
    } finally {
      client.close();
    }
  }

  dynamic _handleResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body.isEmpty) return null;
      return jsonDecode(body);
    }
    // Read error message from the API response
    String message;
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      message = decoded['message'] as String? ?? 'Unknown error.';
    } catch (_) {
      // Not JSON – show raw body for debugging
      final preview = body.length > 200 ? '${body.substring(0, 200)}…' : body;
      message = 'HTTP ${response.statusCode}: $preview';
    }
    throw ApiException(message, statusCode: response.statusCode);
  }

  // ── Items ───────────────────────────────────────────────────────────────

  Future<List<Item>> getItems() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/items/'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    final data = _handleResponse(response) as List<dynamic>;
    return data.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Item> getItem(int id) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/items/$id/'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    return Item.fromJson(_handleResponse(response) as Map<String, dynamic>);
  }

  Future<Item> createItem(Item item) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/items/'),
          headers: _headers,
          body: jsonEncode(item.toJson()),
        )
        .timeout(const Duration(seconds: 10));
    return Item.fromJson(_handleResponse(response) as Map<String, dynamic>);
  }

  Future<Item> updateItem(int id, Item item) async {
    final response = await http
        .put(
          Uri.parse('$_baseUrl/items/$id/'),
          headers: _headers,
          body: jsonEncode(item.toJson()),
        )
        .timeout(const Duration(seconds: 10));
    return Item.fromJson(_handleResponse(response) as Map<String, dynamic>);
  }

  Future<void> deleteItem(int id) async {
    final response = await http
        .delete(Uri.parse('$_baseUrl/items/$id/'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    _handleResponse(response);
  }

  // Upload or replace photo for an item; returns the relative photo_url from server
  Future<String> uploadItemPhoto(int id, String filePath) async {
    final uri = Uri.parse('$_baseUrl/items/$id/photo/');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Accept': 'application/json',
      'X-Api-Key': _storage.getApiKey(),
    });
    // Read bytes directly — avoids content:// URI issues on Android
    final bytes = await File(filePath).readAsBytes();
    final filename = filePath.split(Platform.pathSeparator).last;
    request.files.add(http.MultipartFile.fromBytes('photo', bytes, filename: filename));
    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);
    final data = _handleResponse(response) as Map<String, dynamic>;
    return data['photo_url'] as String;
  }

  // Remove photo from an item
  Future<void> deleteItemPhoto(int id) async {
    final response = await http
        .delete(Uri.parse('$_baseUrl/items/$id/photo/'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    _handleResponse(response);
  }

  // ── Locations ────────────────────────────────────────────────────────────

  Future<List<Location>> getLocations() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/locations/'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    final data = _handleResponse(response) as List<dynamic>;
    return data
        .map((e) => Location.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Location> getLocation(int id) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/locations/$id/'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    return Location.fromJson(
      _handleResponse(response) as Map<String, dynamic>,
    );
  }

  Future<Location> createLocation(Location location) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/locations/'),
          headers: _headers,
          body: jsonEncode(location.toJson()),
        )
        .timeout(const Duration(seconds: 10));
    return Location.fromJson(
      _handleResponse(response) as Map<String, dynamic>,
    );
  }

  Future<Location> updateLocation(int id, Location location) async {
    final response = await http
        .put(
          Uri.parse('$_baseUrl/locations/$id/'),
          headers: _headers,
          body: jsonEncode(location.toJson()),
        )
        .timeout(const Duration(seconds: 10));
    return Location.fromJson(
      _handleResponse(response) as Map<String, dynamic>,
    );
  }

  Future<void> deleteLocation(int id) async {
    final response = await http
        .delete(Uri.parse('$_baseUrl/locations/$id/'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    _handleResponse(response);
  }

  // ── Generic HTTP request (used by sync queue) ────────────────────────────

  Future<dynamic> rawRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    http.Response response;
    switch (method.toUpperCase()) {
      case 'POST':
        response = await http
            .post(url, headers: _headers, body: body != null ? jsonEncode(body) : null)
            .timeout(const Duration(seconds: 10));
      case 'PUT':
        response = await http
            .put(url, headers: _headers, body: body != null ? jsonEncode(body) : null)
            .timeout(const Duration(seconds: 10));
      case 'DELETE':
        response = await http
            .delete(url, headers: _headers)
            .timeout(const Duration(seconds: 10));
      default:
        response = await http
            .get(url, headers: _headers)
            .timeout(const Duration(seconds: 10));
    }
    return _handleResponse(response);
  }
}
