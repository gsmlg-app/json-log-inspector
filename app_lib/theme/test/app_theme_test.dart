import 'package:app_theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('provides duskmoon-derived theme options', () {
    expect(
      themeList.map((theme) => theme.name),
      containsAll(<String>['Orbit', 'Solar', 'Tide', 'Aurora']),
    );
  });
}
