import 'dart:io';

/// Contrat pour tout service capable d'héberger des images uploadées
/// depuis l'app et de retourner leurs URLs publiques.
///
/// N'importe quelle implémentation (Cloudinary aujourd'hui, autre
/// chose demain) peut remplacer [CloudinaryMediaRepository] sans que
/// [FirestorePostRepository] ni aucun Provider n'aient besoin d'être
/// modifiés — c'est tout l'intérêt de cette interface.
abstract class MediaRepository {
  Future<String> uploadImage(File imageFile);
  Future<List<String>> uploadImages(List<File> images);
}
