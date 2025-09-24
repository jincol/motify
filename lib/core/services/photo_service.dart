import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

class PhotoService {
  static final ImagePicker _picker = ImagePicker();

  // 1. Tomar foto con la cámara
  static Future<File?> takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo == null) return null;
    return File(photo.path);
  }

  // Subimos fotitoo
  static Future<String> uploadPhoto(File file) async {
    final dio = Dio();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: 'evidencia.jpg',
      ),
    });

    final response = await dio.post(
      'http://192.168.31.166:8000/api/v1/upload/photo',
      data: formData,
    );

    if (response.statusCode == 200 && response.data['url'] != null) {
      // Si tu backend responde con /fotos/..., agrega el host si lo necesitas:
      return 'http://192.168.31.166:8000${response.data['url']}';
    } else {
      throw Exception('Error al subir la foto');
    }
  }
}
