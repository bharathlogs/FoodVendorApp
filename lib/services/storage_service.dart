import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery or camera
  Future<File?> pickImage(BuildContext context) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return null;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,  // Compress to reasonable size
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      if (kDebugMode) debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Upload vendor stall photo
  /// Returns the download URL on success, null on failure
  Future<String?> uploadVendorPhoto(String vendorId, File imageFile) async {
    try {
      // Create reference with vendor ID
      final ref = _storage.ref().child('vendor_photos/$vendorId/stall_photo.jpg');

      // Upload with metadata
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for completion
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      if (kDebugMode) debugPrint('Firebase Storage error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Delete vendor stall photo
  Future<bool> deleteVendorPhoto(String vendorId) async {
    try {
      final ref = _storage.ref().child('vendor_photos/$vendorId/stall_photo.jpg');
      await ref.delete();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        // File doesn't exist, that's fine
        return true;
      }
      if (kDebugMode) debugPrint('Firebase Storage error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting image: $e');
      return false;
    }
  }

  /// Get upload progress stream (for showing progress indicator)
  Stream<TaskSnapshot> uploadVendorPhotoWithProgress(
    String vendorId,
    File imageFile,
  ) {
    final ref = _storage.ref().child('vendor_photos/$vendorId/stall_photo.jpg');
    return ref
        .putFile(
          imageFile,
          SettableMetadata(contentType: 'image/jpeg'),
        )
        .snapshotEvents;
  }
}
