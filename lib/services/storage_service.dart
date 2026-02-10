import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Handles clothing image storage.
/// Uses both local storage and Firebase Storage.
/// Local storage for offline access, Firebase Storage for cloud backup and web support.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  /// Saves an image file to the app's documents directory and returns the local path.
  Future<String> saveImageLocally(File imageFile, String itemId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final wardrobeDir = Directory('${appDir.path}/wardrobe');
    if (!await wardrobeDir.exists()) {
      await wardrobeDir.create(recursive: true);
    }

    final extension = imageFile.path.split('.').last.toLowerCase();
    final localPath = '${wardrobeDir.path}/$itemId.$extension';
    await imageFile.copy(localPath);
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
  Future<String> uploadToFirebase(File imageFile, String userId, String itemId) async {
    try {
      final extension = imageFile.path.split('.').last.toLowerCase();
      final ref = _storage.ref().child('wardrobe/$userId/$itemId.$extension');

      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/$extension'),
      );

      return await uploadTask.ref.getDownloadURL();
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
  Future<({String localPath, String? firebaseUrl})> saveImage({
    required File imageFile,
    required String userId,
    required String itemId,
  }) async {
    // Save locally first for immediate access
    final localPath = await saveImageLocally(imageFile, itemId);

    // Try to upload to Firebase Storage
    String? firebaseUrl;
    try {
      firebaseUrl = await uploadToFirebase(imageFile, userId, itemId);
    } catch (e) {
      // Continue without Firebase URL if upload fails
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
