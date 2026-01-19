import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

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

  /// Compress image before upload to reduce bandwidth and storage costs
  /// Returns compressed file, or original if compression fails
  Future<File> compressImage(
    File imageFile, {
    int quality = 70,
    int minWidth = 800,
    int minHeight = 800,
  }) async {
    try {
      final dir = await path_provider.getTemporaryDirectory();
      final targetPath =
          '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        final compressedFile = File(result.path);
        final originalSize = await imageFile.length();
        final compressedSize = await compressedFile.length();

        if (kDebugMode) {
          final savings =
              ((originalSize - compressedSize) / originalSize * 100)
                  .toStringAsFixed(1);
          debugPrint(
              'Image compressed: ${(originalSize / 1024).toStringAsFixed(1)}KB -> ${(compressedSize / 1024).toStringAsFixed(1)}KB ($savings% reduction)');
        }

        return compressedFile;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Image compression failed: $e');
    }

    // Return original if compression fails
    return imageFile;
  }

  /// Upload vendor stall photo
  /// Returns the download URL on success, null on failure
  Future<String?> uploadVendorPhoto(String vendorId, File imageFile) async {
    try {
      // Compress image before upload
      final compressedFile = await compressImage(imageFile);

      // Create reference with vendor ID
      final ref = _storage.ref().child('vendor_photos/$vendorId/stall_photo.jpg');

      // Upload with metadata
      final uploadTask = ref.putFile(
        compressedFile,
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

  /// Upload menu item photo
  /// Returns the download URL on success, null on failure
  Future<String?> uploadMenuItemPhoto(
    String vendorId,
    String itemId,
    File imageFile,
  ) async {
    try {
      // Compress image before upload (smaller for menu items)
      final compressedFile = await compressImage(
        imageFile,
        quality: 65,
        minWidth: 600,
        minHeight: 600,
      );

      final ref = _storage
          .ref()
          .child('vendor_photos/$vendorId/menu_items/$itemId.jpg');

      final uploadTask = ref.putFile(
        compressedFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      if (kDebugMode) debugPrint('Firebase Storage error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error uploading menu item image: $e');
      return null;
    }
  }

  /// Delete menu item photo
  Future<bool> deleteMenuItemPhoto(String vendorId, String itemId) async {
    try {
      final ref = _storage
          .ref()
          .child('vendor_photos/$vendorId/menu_items/$itemId.jpg');
      await ref.delete();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return true;
      }
      if (kDebugMode) debugPrint('Firebase Storage error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting menu item image: $e');
      return false;
    }
  }
}
