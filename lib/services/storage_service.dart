import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Handles clothing image storage.
/// Uses both local storage and Firebase Storage.
/// Local storage for offline access (mobile), Firebase Storage for cloud backup and web support.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Saves an image file to the app's documents directory and returns the local path.
  /// On web, returns a placeholder path since local storage isn't available.
  Future<String> saveImageLocally(dynamic imageFile, String itemId) async {
    // On web, we don't save locally - only use Firebase Storage
    if (kIsWeb) {
      return 'web_$itemId'; // Placeholder for web
    }

    // Mobile/Desktop: Save to local storage
    final appDir = await getApplicationDocumentsDirectory();
    final wardrobeDir = Directory('${appDir.path}/wardrobe');
    if (!await wardrobeDir.exists()) {
      await wardrobeDir.create(recursive: true);
    }

    final file = imageFile as File;
    final extension = file.path.split('.').last.toLowerCase();
    final localPath = '${wardrobeDir.path}/$itemId.$extension';
    await file.copy(localPath);
    return localPath;
  }

  /// Deletes the locally stored image for the given item.
  Future<void> deleteLocalImage(String localPath) async {
    try {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// Uploads an image to Firebase Storage and returns the download URL
  /// Works on both web and mobile
  Future<String> uploadToFirebase(dynamic imageFile, String userId, String itemId) async {
    try {
      String extension = 'jpg';

      if (kIsWeb) {
        // Web: imageFile is XFile
        final xFile = imageFile as XFile;
        extension = xFile.path.split('.').last.toLowerCase();
        final ref = _storage.ref().child('wardrobe/$userId/$itemId.$extension');

        // Upload bytes for web
        final bytes = await xFile.readAsBytes();
        final uploadTask = await ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/$extension'),
        );

        return await uploadTask.ref.getDownloadURL();
      } else {
        // Mobile: imageFile is File
        final file = imageFile as File;
        extension = file.path.split('.').last.toLowerCase();
        final ref = _storage.ref().child('wardrobe/$userId/$itemId.$extension');

        final uploadTask = await ref.putFile(
          file,
          SettableMetadata(contentType: 'image/$extension'),
        );

        return await uploadTask.ref.getDownloadURL();
      }
    } catch (e) {
      throw Exception('Failed to upload image to Firebase Storage: ${e.toString()}');
    }
  }

  /// Deletes an image from Firebase Storage
  Future<void> deleteFromFirebase(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Silently fail if image doesn't exist or can't be deleted
    }
  }

  /// Saves image both locally and to Firebase Storage
  /// Returns a tuple of (localPath, firebaseUrl)
  /// On web, localPath is a placeholder and firebaseUrl is the primary storage
  Future<({String localPath, String? firebaseUrl})> saveImage({
    required dynamic imageFile,
    required String userId,
    required String itemId,
  }) async {
    // On web, prioritize Firebase upload
    // On mobile, save locally first for immediate access
    final localPath = await saveImageLocally(imageFile, itemId);

    // Try to upload to Firebase Storage
    String? firebaseUrl;
    try {
      firebaseUrl = await uploadToFirebase(imageFile, userId, itemId);
    } catch (e) {
      // On web, this is critical - rethrow the error
      if (kIsWeb) {
        rethrow;
      }
      // On mobile, continue without Firebase URL if upload fails
      // Local image is still available
    }

    return (localPath: localPath, firebaseUrl: firebaseUrl);
  }

  /// Deletes image from both local storage and Firebase Storage
  Future<void> deleteImage({
    String? localPath,
    String? firebaseUrl,
  }) async {
    if (localPath != null) {
      await deleteLocalImage(localPath);
    }
    if (firebaseUrl != null) {
      await deleteFromFirebase(firebaseUrl);
    }
  }
}
