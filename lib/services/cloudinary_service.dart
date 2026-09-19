import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;


class CloudinaryService {

  static const String cloudName = 'dhhiv0jdn';
  static const String uploadPreset = 'kilifarm_unsigned';

  static Uri get _uploadUrl =>
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  /// Upload une image et retourne son URL publique (secure_url).
  Future<String> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', _uploadUrl)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = 'kilifarm/posts'
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw "Échec de l'envoi de l'image (${response.statusCode}).";
      }

      final data = jsonDecode(body) as Map<String, dynamic>;
      final url = data['secure_url'] as String?;

      if (url == null) {
        throw 'Réponse Cloudinary invalide.';
      }

      return url;
    } on FormatException {
      throw 'Réponse Cloudinary invalide.';
    } catch (e) {
      if (e is String) rethrow;
      throw "Erreur lors de l'envoi de l'image. Vérifiez votre connexion.";
    }
  }

  /// Upload plusieurs images l'une après l'autre (pas en parallèle,
  /// pour rester doux sur les connexions lentes — c'est justement le
  /// public ciblé par KILIFARM en zone rurale).
  Future<List<String>> uploadImages(List<File> images) async {
    final urls = <String>[];
    for (final image in images) {
      urls.add(await uploadImage(image));
    }
    return urls;
  }
}
