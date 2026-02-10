import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';

class FashnService {
  final _functions = FirebaseFunctions.instance;

  /// Runs virtual try-on using Fashn.ai API via Cloud Function
  ///
  /// [modelImageBytes] - User's model photo as bytes (full body photo in swimsuit/bikini)
  /// [garmentImage] - Either a URL or base64 encoded garment image
  /// [category] - One of: 'tops', 'bottoms', 'one-pieces'
  ///
  /// Returns the URL of the result image
  Future<String> runTryOn({
    required Uint8List modelImageBytes,
    required String garmentImage,
    required String category,
  }) async {
    try {
      // Convert model image to base64
      final modelImageBase64 = base64Encode(modelImageBytes);

      // Call Cloud Function
      final callable = _functions.httpsCallable('fashnTryOn');
      final result = await callable.call({
        'modelImage': modelImageBase64,
        'garmentImage': garmentImage,
        'category': category,
      });

      // Extract output URL from response
      final output = result.data['output'] as List<dynamic>;
      if (output.isEmpty) {
        throw Exception('No output image returned from Fashn.ai');
      }

      return output[0] as String;
    } catch (e) {
      throw Exception('Try-on failed: ${e.toString()}');
    }
  }

  /// Maps ClothingCategory to Fashn.ai category
  /// Returns null if category is not supported
  static String? mapCategory(String clothingCategory) {
    return switch (clothingCategory) {
      'tops' => 'tops',
      'bottoms' => 'bottoms',
      'dresses' => 'one-pieces',
      'outerwear' => 'tops', // Close match
      _ => null, // shoes, accessories not supported
    };
  }
}
