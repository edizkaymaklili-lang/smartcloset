import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

/// Service for removing backgrounds from clothing images
/// Uses remove.bg API (https://www.remove.bg/)
class BackgroundRemovalService {
  final Dio _dio = Dio();

  // To get your API key:
  // 1. Go to https://www.remove.bg/users/sign_up
  // 2. Sign up for a free account (50 API calls/month free)
  // 3. Get your API key from https://www.remove.bg/api
  // 4. Add it to your app settings or environment variables
  static const String _apiUrl = 'https://api.remove.bg/v1.0/removebg';

  /// Removes background from an image
  /// Returns the processed image bytes
  /// [imageFile] can be File (mobile) or XFile (web)
  /// [apiKey] is your remove.bg API key
  Future<Uint8List?> removeBackground({
    required dynamic imageFile,
    required String apiKey,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('Remove.bg API key is required');
    }

    try {
      Uint8List imageBytes;
      String fileName;

      // Get image bytes based on platform
      if (kIsWeb) {
        final xFile = imageFile as XFile;
        imageBytes = await xFile.readAsBytes();
        fileName = xFile.name;
      } else {
        final file = imageFile as File;
        imageBytes = await file.readAsBytes();
        fileName = file.path.split('/').last;
      }

      // Prepare form data
      final formData = FormData.fromMap({
        'image_file': MultipartFile.fromBytes(
          imageBytes,
          filename: fileName,
        ),
        'size': 'auto', // Auto-detect best size
        'type': 'product', // Optimized for product/clothing photos
        'format': 'png', // PNG for transparency
      });

      // Make API request
      final response = await _dio.post(
        _apiUrl,
        data: formData,
        options: Options(
          headers: {
            'X-Api-Key': apiKey,
          },
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data as List<int>);
      } else {
        throw Exception('Failed to remove background: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Invalid API key. Please check your remove.bg API key.');
      } else if (e.response?.statusCode == 402) {
        throw Exception('API quota exceeded. Please upgrade your remove.bg plan.');
      } else {
        throw Exception('Failed to remove background: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error removing background: $e');
    }
  }

  /// Checks if the API key is valid by making a test request
  Future<bool> validateApiKey(String apiKey) async {
    if (apiKey.isEmpty) return false;

    try {
      final response = await _dio.get(
        'https://api.remove.bg/v1.0/account',
        options: Options(
          headers: {'X-Api-Key': apiKey},
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
