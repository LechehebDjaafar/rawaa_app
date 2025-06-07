import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ImageHelper {
  // تحويل الصورة إلى Base64 مع ضغط
  static Future<String?> convertImageToBase64(File imageFile, {int quality = 70, int maxSize = 800}) async {
    try {
      // قراءة الصورة
      Uint8List imageBytes = await imageFile.readAsBytes();
      
      // فك تشفير الصورة
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return null;
      
      // تغيير حجم الصورة إذا كانت كبيرة
      if (image.width > maxSize || image.height > maxSize) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? maxSize : null,
          height: image.height > image.width ? maxSize : null,
        );
      }
      
      // ضغط الصورة وتحويلها إلى JPEG
      List<int> compressedBytes = img.encodeJpg(image, quality: quality);
      
      // التحقق من الحجم النهائي (يجب أن يكون أقل من 1MB)
      if (compressedBytes.length > 1024 * 1024) {
        // إذا كانت الصورة لا تزال كبيرة، نقلل الجودة أكثر
        compressedBytes = img.encodeJpg(image, quality: 50);
      }
      
      // تحويل إلى Base64
      return base64Encode(compressedBytes);
    } catch (e) {
      print('خطأ في تحويل الصورة إلى Base64: $e');
      return null;
    }
  }
  
  // تحويل Base64 إلى صورة
  static ImageProvider? base64ToImageProvider(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    
    try {
      Uint8List bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } catch (e) {
      print('خطأ في تحويل Base64 إلى صورة: $e');
      return null;
    }
  }
  
  // التحقق من صحة تنسيق الصورة
  static bool isValidImageFormat(String path) {
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp'];
    final extension = path.toLowerCase().split('.').last;
    return validExtensions.contains('.$extension');
  }
  
  // حساب حجم الصورة بالـ KB
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
