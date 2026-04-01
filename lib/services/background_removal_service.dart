import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Removes backgrounds from clothing photos.
/// Local edge-flood-fill algorithm (no API key needed) is the default.
/// Optionally uses remove.bg API when an API key is configured.
class BackgroundRemovalService {
  final Dio _dio = Dio();
  static const String _apiUrl = 'https://api.remove.bg/v1.0/removebg';

  /// Removes the background from [imageFile].
  /// Pass [apiKey] to use remove.bg; leave empty for the free local algorithm.
  Future<Uint8List> removeBackground({
    required dynamic imageFile,
    String apiKey = '',
  }) async {
    final Uint8List imageBytes;
    if (kIsWeb) {
      imageBytes = await (imageFile as XFile).readAsBytes();
    } else {
      imageBytes = await (imageFile as File).readAsBytes();
    }

    if (apiKey.isNotEmpty) {
      try {
        return await _removeWithApi(imageBytes, apiKey);
      } catch (_) {
        // API failed — fall through
      }
    }

    return _removeBackgroundLocally(imageBytes);
  }

  /// Same as [removeBackground] but the local algorithm yields to the event
  /// loop periodically so the UI stays responsive on single-threaded platforms
  /// (web / dart2js).
  Future<Uint8List> removeBackgroundAsync({
    required dynamic imageFile,
    String apiKey = '',
    Uint8List? cachedBytes,
  }) async {
    final Uint8List imageBytes;
    if (cachedBytes != null) {
      imageBytes = cachedBytes;
    } else if (kIsWeb) {
      imageBytes = await (imageFile as XFile).readAsBytes();
    } else {
      imageBytes = await (imageFile as File).readAsBytes();
    }

    if (kIsWeb) {
      // Web: only use cloud API (local pixel ops block JS main thread)
      if (apiKey.isNotEmpty) {
        try {
          return await _removeWithApi(imageBytes, apiKey);
        } catch (_) {
          // API failed — return original immediately, no local processing
        }
      }
      return imageBytes; // No API key or API failed → original image
    }

    // Mobile: try API first, fall back to local BFS
    if (apiKey.isNotEmpty) {
      try {
        return await _removeWithApi(imageBytes, apiKey);
      } catch (_) {
        // API failed — fall through to local algorithm
      }
    }
    return _removeBackgroundLocallyAsync(imageBytes);
  }

  // ── remove.bg API ──────────────────────────────────────────────────────────

  Future<Uint8List> _removeWithApi(Uint8List imageBytes, String apiKey) async {
    final formData = FormData.fromMap({
      'image_file': MultipartFile.fromBytes(imageBytes, filename: 'image.jpg'),
      'size': 'auto',
      'type': 'product',
      'format': 'png',
    });

    final response = await _dio.post(
      _apiUrl,
      data: formData,
      options: Options(
        headers: {'X-Api-Key': apiKey},
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
      ),
    );

    if (response.statusCode == 200) {
      return Uint8List.fromList(response.data as List<int>);
    }
    throw Exception('remove.bg returned ${response.statusCode}');
  }

  // ── Local algorithm ────────────────────────────────────────────────────────

  /// Edge-seeded BFS flood fill.
  ///
  /// 1. Samples corner + edge-midpoint pixels to estimate background colour.
  /// 2. Flood-fills outward from every matching edge pixel.
  /// 3. Makes all reached pixels fully transparent.
  /// 4. Returns the result encoded as PNG (supports transparency).
  ///
  /// Works well for items photographed on uniform / white / light backgrounds.
  Uint8List _removeBackgroundLocally(Uint8List imageBytes) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return imageBytes;

    // On web, downscale before processing — flood-fill on 1080² freezes the browser.
    // 400px max keeps it under ~2 seconds in Dart JS.
    img.Image image = decoded;
    if (kIsWeb) {
      const maxDim = 400;
      if (image.width > maxDim || image.height > maxDim) {
        image = img.copyResize(
          image,
          width: image.width >= image.height ? maxDim : -1,
          height: image.height > image.width ? maxDim : -1,
        );
      }
    }

    final w = image.width;
    final h = image.height;

    // ── Estimate background colour ─────────────────────────────────────────
    final sampleCoords = [
      (0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1),
      (w ~/ 2, 0), (0, h ~/ 2), (w - 1, h ~/ 2), (w ~/ 2, h - 1),
    ];
    double bgR = 0, bgG = 0, bgB = 0;
    for (final (x, y) in sampleCoords) {
      final p = image.getPixel(x, y);
      bgR += p.r.toDouble();
      bgG += p.g.toDouble();
      bgB += p.b.toDouble();
    }
    bgR /= sampleCoords.length;
    bgG /= sampleCoords.length;
    bgB /= sampleCoords.length;

    // ── Build RGBA output (copy source at alpha=255) ───────────────────────
    final output = img.Image(width: w, height: h, numChannels: 4);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = image.getPixel(x, y);
        output.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), 255);
      }
    }

    // ── Flood fill ─────────────────────────────────────────────────────────
    const double tolerance = 45.0;

    bool matchesBg(int x, int y) {
      final p = image.getPixel(x, y);
      return (p.r.toDouble() - bgR).abs() < tolerance &&
          (p.g.toDouble() - bgG).abs() < tolerance &&
          (p.b.toDouble() - bgB).abs() < tolerance;
    }

    final visited = List.generate(h, (_) => List.filled(w, false));
    final queue = Queue<(int, int)>();

    // Seed from all four edges
    for (int x = 0; x < w; x++) {
      if (matchesBg(x, 0)) queue.add((x, 0));
      if (matchesBg(x, h - 1)) queue.add((x, h - 1));
    }
    for (int y = 1; y < h - 1; y++) {
      if (matchesBg(0, y)) queue.add((0, y));
      if (matchesBg(w - 1, y)) queue.add((w - 1, y));
    }

    const dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)];
    while (queue.isNotEmpty) {
      final (x, y) = queue.removeFirst();
      if (visited[y][x]) continue;
      visited[y][x] = true;
      output.setPixelRgba(x, y, 0, 0, 0, 0); // transparent

      for (final (dx, dy) in dirs) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx >= 0 && nx < w && ny >= 0 && ny < h && !visited[ny][nx]) {
          if (matchesBg(nx, ny)) queue.add((nx, ny));
        }
      }
    }

    return Uint8List.fromList(img.encodePng(output));
  }

  /// Async version of [_removeBackgroundLocally] — yields to the event loop
  /// every 3 000 pixels so the UI stays responsive on web (dart2js).
  Future<Uint8List> _removeBackgroundLocallyAsync(Uint8List imageBytes) async {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return imageBytes;

    img.Image image = decoded;
    if (kIsWeb) {
      const maxDim = 200; // Smaller cap on web to keep BFS fast
      if (image.width > maxDim || image.height > maxDim) {
        image = img.copyResize(
          image,
          width: image.width >= image.height ? maxDim : -1,
          height: image.height > image.width ? maxDim : -1,
        );
      }
    }

    final w = image.width;
    final h = image.height;

    // ── Estimate background colour ─────────────────────────────────────────
    final sampleCoords = [
      (0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1),
      (w ~/ 2, 0), (0, h ~/ 2), (w - 1, h ~/ 2), (w ~/ 2, h - 1),
    ];
    double bgR = 0, bgG = 0, bgB = 0;
    for (final (x, y) in sampleCoords) {
      final p = image.getPixel(x, y);
      bgR += p.r.toDouble();
      bgG += p.g.toDouble();
      bgB += p.b.toDouble();
    }
    bgR /= sampleCoords.length;
    bgG /= sampleCoords.length;
    bgB /= sampleCoords.length;

    // ── Build RGBA output ──────────────────────────────────────────────────
    final output = img.Image(width: w, height: h, numChannels: 4);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = image.getPixel(x, y);
        output.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), 255);
      }
    }

    // ── Flood fill (async, yields every 500 steps) ─────────────────────────
    const double tolerance = 45.0;

    bool matchesBg(int x, int y) {
      final p = image.getPixel(x, y);
      return (p.r.toDouble() - bgR).abs() < tolerance &&
          (p.g.toDouble() - bgG).abs() < tolerance &&
          (p.b.toDouble() - bgB).abs() < tolerance;
    }

    final visited = List.generate(h, (_) => List.filled(w, false));
    final queue = Queue<(int, int)>();

    for (int x = 0; x < w; x++) {
      if (matchesBg(x, 0)) queue.add((x, 0));
      if (matchesBg(x, h - 1)) queue.add((x, h - 1));
    }
    for (int y = 1; y < h - 1; y++) {
      if (matchesBg(0, y)) queue.add((0, y));
      if (matchesBg(w - 1, y)) queue.add((w - 1, y));
    }

    const dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)];
    int steps = 0;
    while (queue.isNotEmpty) {
      final (x, y) = queue.removeFirst();
      if (visited[y][x]) continue;
      visited[y][x] = true;
      output.setPixelRgba(x, y, 0, 0, 0, 0);

      for (final (dx, dy) in dirs) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx >= 0 && nx < w && ny >= 0 && ny < h && !visited[ny][nx]) {
          if (matchesBg(nx, ny)) queue.add((nx, ny));
        }
      }

      steps++;
      if (steps % 500 == 0) {
        // Yield to browser event loop every 500 steps (keeps UI responsive)
        await Future.delayed(const Duration(milliseconds: 16));
      }
    }

    return Uint8List.fromList(img.encodePng(output));
  }

  /// Remove background directly from raw bytes.
  /// On web uses the async/yielding algorithm; on mobile uses the sync one.
  Future<Uint8List> removeBackgroundFromBytes(Uint8List bytes, {String apiKey = ''}) async {
    if (apiKey.isNotEmpty) {
      try { return await _removeWithApi(bytes, apiKey); } catch (_) {}
    }
    if (kIsWeb) {
      return _removeBackgroundLocallyAsync(bytes);
    }
    return _removeBackgroundLocally(bytes);
  }

  // ── Utility ────────────────────────────────────────────────────────────────

  Future<bool> validateApiKey(String apiKey) async {
    if (apiKey.isEmpty) return false;
    try {
      final response = await _dio.get(
        'https://api.remove.bg/v1.0/account',
        options: Options(headers: {'X-Api-Key': apiKey}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
