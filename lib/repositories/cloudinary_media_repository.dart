import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'media_repository.dart';

/// Implémentation Cloudinary de [MediaRepository] — stockage tiers
/// gratuit, sans carte bancaire requise (contrairement à Firebase
/// Storage, qui exige le plan Blaze depuis février 2026).
///
/// Utilise un "unsigned upload preset" : upload direct depuis l'app
/// mobile sans exposer de clé secrète. Voir le README pour la
/// procédure de création du compte et du preset.
class CloudinaryMediaRepository implements MediaRepository {
  // TODO: remplace ces deux valeurs par les tiennes après création de
  // ton compte Cloudinary. Voir README section "Configurer Cloudinary".
  static const String cloudName = 'TON_CLOUD_NAME';
  static const String uploadPreset = 'kilifarm_unsigned';

  static Uri get _uploadUrl =>
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  @override
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

  @override
  Future<List<String>> uploadImages(List<File> images) async {
    final urls = <String>[];
    for (final image in images) {
      urls.add(await uploadImage(image));
    }
    return urls;
  }
}
