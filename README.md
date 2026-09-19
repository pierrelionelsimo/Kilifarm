# KILIFARM V1 — Auth + fondations (version consolidée)

Cette version part du code proposé par l'autre IA (Provider, thème, constants,
splash) et corrige les points suivants pour qu'elle soit fiable en pratique.

## Corrections apportées

| Problème | Risque | Correction |
|---|---|---|
| `(map['createdAt'] as dynamic).toDate()` | Crash si le champ est absent/null | Cast explicite en `Timestamp` avec valeur de repli |
| Profil non rechargé après restart | Nom vide ("Bienvenue ") pour un utilisateur déjà connecté | `AuthProvider` recharge le profil Firestore à chaque session détectée |
| Splash à délai fixe (2s) | Peut naviguer avant que Firebase ait confirmé l'état de session | Le splash attend la vraie réponse de Firebase (`isInitialized`) |
| `main.dart` sans import de `LoginScreen`/`HomeScreen` | Ne compile pas tel quel | Imports ajoutés |
| `ColorScheme.background` | Déprécié, warning au build | Retiré (géré par `scaffoldBackgroundColor`) |
| `DropdownButtonFormField(initialValue: ...)` | API trop récente, casse sur SDK plus anciens | Revenu à `value:` |

## 1. Dépendances `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.3
  provider: ^6.1.2
```

```
flutter pub get
```

## 2. Config Firebase (si pas encore fait)

```
dart pub global activate flutterfire_cli
flutterfire configure
```

## 3. Règles de sécurité Firestore minimales

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 4. Fichiers inclus

```
lib/
├── main.dart
├── config/
│   ├── constants.dart
│   └── theme.dart
├── models/
│   ├── user_model.dart
│   ├── post_model.dart
│   └── comment_model.dart
├── services/
│   └── auth_service.dart
├── providers/
│   └── auth_provider.dart
└── screens/
    ├── splash_screen.dart
    ├── auth/
    │   ├── login_screen.dart
    │   └── register_screen.dart
    └── home/
        └── home_screen.dart
```

## 5. Vérification

```
flutter analyze
flutter run
```

Teste : inscription → déconnexion → reconnexion → **fermer et rouvrir
l'app complètement** (c'est le scénario que corrige le fix du profil au
restart — l'ancien code échouait silencieusement ici).

## 6. Icônes du logo

Place tes deux fichiers dans `assets/icon/` :
- `icon_k.png` — logo complet avec fond vert (icône d'app + utilisé
  directement dans l'UI sur fond clair, ex: écran de login)
- `icon_sf.png` — symbole seul, fond transparent (utilisé comme calque
  "foreground" de l'icône adaptative Android, et dans l'UI sur fond
  déjà coloré, ex: splash screen)

Puis génère les icônes :
```
flutter pub get
dart run flutter_launcher_icons
```

## 7. Activer Google Sign-In (obligatoire, sinon ApiException: 10)

Tu as activé le provider Google côté Firebase Authentication — bien.
Il manque une étape côté Android : Google exige que l'empreinte
numérique (SHA-1) de ta machine de dev soit déclarée sur Firebase,
sinon la connexion Google échoue silencieusement avec une erreur du
type `PlatformException: sign_in_failed, ApiException: 10`.

**1. Récupère ton SHA-1 de debug :**
```
cd android
./gradlew signingReport
```
(sous Windows, utilise `gradlew.bat signingReport` si `./gradlew` ne
fonctionne pas directement)

Cherche dans le résultat la ligne `SHA1:` sous la variante `debug`.

**2. Ajoute-la sur Firebase Console :**
Project Settings (⚙️) → onglet **Général** → section **Vos applications**
→ ton app Android → **Ajouter une empreinte** → colle le SHA-1.

**3. Retélécharge `google-services.json`** depuis cette même page et
remplace l'ancien fichier dans `android/app/google-services.json`.

**4. Relance l'app** (`flutter run`) — pas besoin de refaire
`flutterfire configure`, juste remplacer ce fichier suffit.

Sans cette étape, tout le reste du code fonctionne mais le bouton
"Continuer avec Google" échouera systématiquement.

## 9. Configurer Cloudinary (stockage des photos du Feed)

Firebase Storage exige maintenant le plan payant Blaze (carte bancaire
requise depuis février 2026, même pour un usage gratuit). Pour rester
sans carte bancaire, les photos du Feed passent par **Cloudinary**
(25 Go gratuits, pas de carte requise).

**1. Crée un compte gratuit :** https://cloudinary.com/users/register/free

**2. Récupère ton "Cloud name" :** visible en haut du Dashboard juste
après connexion (ex: `dxxxx1234`).

**3. Crée un "unsigned upload preset" :**
- Dashboard → icône ⚙️ (Settings) → onglet **Upload**
- Section "Upload presets" → **Add upload preset**
- Signing Mode : choisis **Unsigned** (essentiel — sinon l'upload
  depuis l'app échouera, un mode signé demande une clé secrète qu'on
  ne peut pas mettre dans le code d'une app mobile)
- Folder : tu peux laisser vide (le code force déjà `kilifarm/posts`)
- Donne-lui un nom mémorable, ex: `kilifarm_unsigned`
- Enregistre

**4. Renseigne ces deux valeurs** dans
`lib/services/cloudinary_service.dart` :
```dart
static const String cloudName = 'TON_CLOUD_NAME';       // étape 2
static const String uploadPreset = 'kilifarm_unsigned';  // étape 3
```

**Optionnel mais recommandé avant publication :** dans les paramètres
du preset, limite `Max file size` (ex: 5 Mo) et restreins `Allowed
formats` à `jpg, png` pour éviter les abus.

## 10. Règles Firestore mises à jour (posts + likes)

**Remplace de nouveau tes règles** — cette version ajoute la possibilité
pour n'importe quel utilisateur connecté d'aimer un post (modifier
`likesCount`), sans pour autant pouvoir modifier le reste du post
(seul son propriétaire le peut) :

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null
        && request.resource.data.userId == request.auth.uid;
      allow update: if request.auth != null && (
        resource.data.userId == request.auth.uid ||
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['likesCount'])
      );
      allow delete: if request.auth != null
        && resource.data.userId == request.auth.uid;

      match /likes/{userId} {
        allow read: if request.auth != null;
        allow create, delete: if request.auth != null
          && request.auth.uid == userId;
      }
    }
  }
}
```

**Sans cette mise à jour**, le bouton like et le double-tap échoueront
silencieusement (ou avec `PERMISSION_DENIED` dans les logs) dès que tu
essaies d'aimer un post qui n'est pas le tien.

## 11. Ce qu'il reste à faire (pas dans ce lot)

- Commentaires pas encore interactifs (icône affichée, pas cliquable)
  — prochaine étape du scope V1
- Pas de recherche/annuaire d'utilisateurs — étape "Recherche",
  après les commentaires
- Photo de profil réelle (upload) — V1 utilise un avatar par
  initiales, décision prise volontairement pour rester simple
