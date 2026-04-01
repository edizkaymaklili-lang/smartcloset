import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;

/// Result of Gemini clothing analysis.
class ClothingAnalysis {
  final String name;
  final String color;

  /// One of: tops, bottoms, dresses, shoes, accessories, outerwear
  final String category;

  const ClothingAnalysis({
    required this.name,
    required this.color,
    required this.category,
  });
}

/// Uses Google Gemini Vision API (REST) to analyse clothing images.
/// No extra package needed — Dio is already a dependency.
class GeminiService {
  final Dio _dio = Dio();
  static const _base = 'https://generativelanguage.googleapis.com/v1beta';
  static const _model = 'gemini-1.5-flash';

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Detects name, color and category for a clothing item in [imageBytes].
  /// Throws on network / API errors so callers can catch and degrade gracefully.
  Future<ClothingAnalysis> analyzeClothing(
    Uint8List imageBytes,
    String apiKey,
  ) async {
    // On web, dart2js image processing (decode/resize/encode) blocks the event
    // loop and freezes the UI. Skip resize — picker already compresses to JPEG.
    // On native, downscale to max 256 px to save tokens.
    Uint8List sendBytes = imageBytes;
    if (!kIsWeb) {
      try {
        final decoded = img.decodeImage(imageBytes);
        if (decoded != null && (decoded.width > 256 || decoded.height > 256)) {
          final resized = img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? 256 : -1,
            height: decoded.height > decoded.width ? 256 : -1,
          );
          sendBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 70));
        }
      } catch (_) {
        // resize failed — fall back to original
      }
    }
    final base64Image = base64Encode(sendBytes);

    final response = await _dio.post(
      '$_base/models/$_model:generateContent?key=$apiKey',
      options: Options(
        headers: {'Content-Type': 'application/json'},
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
      data: {
        'contents': [
          {
            'parts': [
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': base64Image,
                },
              },
              {
                'text': '''You are a fashion assistant. Analyze this clothing item and respond ONLY with a valid JSON object (no markdown, no explanation, no code fences):
{"name":"<short descriptive name in English, e.g. White Linen Blouse>","color":"<primary color(s) in English>","category":"<exactly one of: tops, bottoms, dresses, shoes, accessories, outerwear>"}''',
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 120,
        },
      },
    );

    final raw =
        response.data['candidates'][0]['content']['parts'][0]['text'] as String;

    // Strip any accidental markdown fences
    final cleaned = raw
        .trim()
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    final json = jsonDecode(cleaned) as Map<String, dynamic>;

    return ClothingAnalysis(
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'Clothing Item',
      color: (json['color'] as String?)?.trim() ?? '',
      category: _normaliseCategory(json['category'] as String? ?? ''),
    );
  }

  /// Quick probe to verify an API key is valid.
  Future<bool> validateApiKey(String apiKey) async {
    if (apiKey.isEmpty) return false;
    try {
      await _dio.post(
        '$_base/models/$_model:generateContent?key=$apiKey',
        options: Options(receiveTimeout: const Duration(seconds: 15)),
        data: {
          'contents': [
            {
              'parts': [
                {'text': 'Hi'},
              ],
            },
          ],
          'generationConfig': {'maxOutputTokens': 5},
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static const _validCategories = {
    'tops',
    'bottoms',
    'dresses',
    'shoes',
    'accessories',
    'outerwear',
  };

  String _normaliseCategory(String raw) {
    final lower = raw.toLowerCase().trim();
    if (_validCategories.contains(lower)) return lower;
    // Fuzzy fallback
    if (lower.contains('top') || lower.contains('shirt') || lower.contains('blouse')) return 'tops';
    if (lower.contains('bottom') || lower.contains('pant') || lower.contains('jean') || lower.contains('skirt')) return 'bottoms';
    if (lower.contains('dress')) return 'dresses';
    if (lower.contains('shoe') || lower.contains('boot') || lower.contains('sneaker') || lower.contains('heel')) return 'shoes';
    if (lower.contains('outer') || lower.contains('coat') || lower.contains('jacket')) return 'outerwear';
    if (lower.contains('access') || lower.contains('bag') || lower.contains('hat') || lower.contains('scarf')) return 'accessories';
    return 'tops'; // safe default
  }
}
