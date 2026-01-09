// lib/services/firebase/storage_service.dart

import 'package:firebase_storage/firebase_storage.dart';
import '../../utils/helpers.dart';

/// Firebase Storage Service
/// NOTE: Image upload features are disabled. 
/// This service is reserved for future functionality.
/// Currently, the app uses:
/// - Unsplash API for place images
/// - Network URLs for user profile pictures
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // All upload methods are commented out as we're not using image uploads

  /* 
  // Upload profile image - DISABLED
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      Helpers.log('Uploading profile image', tag: 'STORAGE');

      final ref = _storage.ref().child('users/$userId/profile.jpg');
      final uploadTask = ref.putFile(imageFile);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      Helpers.log('Profile image uploaded', tag: 'STORAGE');
      return downloadUrl;
    } catch (e) {
      Helpers.log('Error uploading profile image: $e', tag: 'STORAGE');
      throw 'Failed to upload image';
    }
  }
  */

  /* 
  // Upload trip image - DISABLED
  Future<String?> uploadTripImage(String userId, String tripId, File imageFile) async {
    try {
      Helpers.log('Uploading trip image', tag: 'STORAGE');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('trips/$userId/$tripId/$timestamp.jpg');
      final uploadTask = ref.putFile(imageFile);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      Helpers.log('Trip image uploaded', tag: 'STORAGE');
      return downloadUrl;
    } catch (e) {
      Helpers.log('Error uploading trip image: $e', tag: 'STORAGE');
      throw 'Failed to upload image';
    }
  }
  */

  // Delete image - Keep for cleanup if needed
  Future<void> deleteImage(String imageUrl) async {
    try {
      Helpers.log('Deleting image', tag: 'STORAGE');
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      Helpers.log('Image deleted', tag: 'STORAGE');
    } catch (e) {
      Helpers.log('Error deleting image: $e', tag: 'STORAGE');
      // Don't throw - deletion is not critical
    }
  }

  // Delete user folder - Keep for cleanup
  Future<void> deleteUserFolder(String userId) async {
    try {
      Helpers.log('Deleting user folder', tag: 'STORAGE');
      final ref = _storage.ref().child('users/$userId');
      await ref.delete();
      Helpers.log('User folder deleted', tag: 'STORAGE');
    } catch (e) {
      Helpers.log('Error deleting user folder: $e', tag: 'STORAGE');
      // Don't throw - folder might not exist
    }
  }

  // Get download URL for existing image (if needed in future)
  Future<String?> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      Helpers.log('Error getting download URL: $e', tag: 'STORAGE');
      return null;
    }
  }
}