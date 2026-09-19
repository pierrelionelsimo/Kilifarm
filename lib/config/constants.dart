class AppConstants {
  // App Info
  static const String appName = 'KILIFARM';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Le réseau des professionnels agricoles';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String commentsCollection = 'comments';
  static const String likesCollection = 'likes';

  // Storage Paths
  static const String profileImagesPath = 'profiles/images';
  static const String postImagesPath = 'posts/images';

  // Pagination
  static const int pageSize = 10;
  static const int maxImageSize = 5; // MB
  static const int maxImagesPerPost = 4;

  // Régions du Cameroun
  static const List<String> cameroonRegions = [
    'Adamaoua',
    'Centre',
    'Est',
    'Extrême-Nord',
    'Littoral',
    'Nord',
    'Nord-Ouest',
    'Ouest',
    'Sud',
    'Sud-Ouest',
  ];

  // Types d'activité
  static const List<String> activityTypes = [
    'Agriculteur',
    'Éleveur',
    'Agriculteur & Éleveur',
    'Étudiant en agriculture',
    'Chercheur',
    'Entrepreneur agricole',
    'Autre',
  ];
}
