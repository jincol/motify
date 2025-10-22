import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:motify/core/constants/api_config.dart';

class PhotoService {
  static final ImagePicker _picker = ImagePicker();

  // Tomar foto con la cámara
  static Future<File?> takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo == null) return null;
    return File(photo.path);
  }

  // Subir foto al backend
  static Future<String> uploadPhoto(
    File file, {
    String tipo = 'attendance',
    String? token,
  }) async {
    final dio = Dio();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: 'evidencia.jpg',
      ),
      'tipo': tipo,
    });

    final uploadUrl = '${ApiConfig.baseUrl}/upload/photo';

    final response = await dio.post(
      uploadUrl,
      data: formData,
      options: Options(
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      ),
    );

    if (response.statusCode == 200 &&
        response.data != null &&
        response.data['url'] != null) {
      final host = ApiConfig.baseHost;
      return '$host${response.data['url']}';
    }

    throw Exception('Error al subir la foto');
  }
}
