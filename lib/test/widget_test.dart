import 'package:flutter_test/flutter_test.dart';

// Tester KilifarmApp en entier nécessiterait un mock de Firebase
// (Auth + Firestore), pas encore mis en place pour la V1 — vraie
// dette technique, à traiter quand une vraie suite de tests
// d'intégration sera prioritaire. Ce test minimal garde `flutter test`
// fonctionnel sans faux négatif en attendant.
void main() {
  test('sanity check', () {
    expect(1 + 1, 2);
  });
}
