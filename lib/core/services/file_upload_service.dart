import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class FileUploadService {
  final Dio _dio;
  final ImagePicker _picker;

  static const String _cloudName = 'durrsmw4y';
  static const String _uploadPreset = 'ammarcloudinary';

  FileUploadService({Dio? dio, ImagePicker? picker})
      : _dio = dio ?? Dio(),
        _picker = picker ?? ImagePicker();

  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    final xFile = await _picker.pickImage(source: source, imageQuality: 85);
    if (xFile == null) return null;
    return File(xFile.path);
  }

  Future<File?> pickAudio() async {
    final xFile = await _picker.pickMedia();
    if (xFile == null) return null;
    return File(xFile.path);
  }

  Future<File?> pickVideo({ImageSource source = ImageSource.gallery}) async {
    final xFile = await _picker.pickVideo(source: source, maxDuration: const Duration(minutes: 10));
    if (xFile == null) return null;
    return File(xFile.path);
  }

  Future<File?> pickAny() async {
    final xFile = await _picker.pickMedia();
    if (xFile == null) return null;
    return File(xFile.path);
  }

  Future<CloudinaryResult?> uploadToCloudinary(
    File file, {
    String folder = 'uploads',
    String? resourceType,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      final resType = resourceType ?? _getResourceType(ext);

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'upload_preset': _uploadPreset,
        'folder': folder,
      });

      print('CLOUDINARY UPLOAD: https://api.cloudinary.com/v1_1/$_cloudName/$resType/upload');
      print('CLOUDINARY FOLDER: $folder | TYPE: $resType | EXT: $ext');

      final response = await _dio.post(
        'https://api.cloudinary.com/v1_1/$_cloudName/$resType/upload',
        data: formData,
        options: Options(
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 5),
        ),
        onSendProgress: onProgress,
      );

      final data = response.data;
      print('CLOUDINARY RESPONSE: $data');

      if (data is Map && data['secure_url'] != null) {
        return CloudinaryResult(
          url: data['secure_url'],
          publicId: data['public_id'] ?? '',
          resourceType: data['resource_type'] ?? resType,
          format: data['format'] ?? ext,
        );
      }
      return null;
    } on DioException catch (e) {
      print('CLOUDINARY ERROR: ${e.response?.statusCode} ${e.response?.data}');
      String msg = 'Upload failed';
      if (e.response?.data is Map) {
        final errData = e.response?.data;
        if (errData['error'] is Map) {
          msg = errData['error']['message'] ?? msg;
        } else {
          msg = errData.toString();
        }
      } else if (e.message != null) {
        msg = e.message!;
      }
      throw Exception(msg);
    } catch (e) {
      print('CLOUDINARY UNKNOWN ERROR: $e');
      throw Exception('Upload error: $e');
    }
  }

  Future<String?> uploadImageToGallery(File file, {String? title, String? description, String galleryType = 'general'}) async {
    final result = await uploadToCloudinary(file, folder: 'galleries');
    if (result == null) return null;
    return result.url;
  }

  String _getResourceType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
      case 'svg':
        return 'image';
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'aac':
      case 'm4a':
      case 'flac':
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
      case 'webm':
        return 'video';
      case 'pdf':
      case 'doc':
      case 'docx':
        return 'raw';
      default:
        return 'auto';
    }
  }
}

class CloudinaryResult {
  final String url;
  final String publicId;
  final String resourceType;
  final String format;

  const CloudinaryResult({
    required this.url,
    required this.publicId,
    required this.resourceType,
    required this.format,
  });
}
