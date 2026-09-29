// Where the app sends people: language first, then login, then their role's home.
import 'package:flutter_test/flutter_test.dart';
import 'package:pashusetu/core/router/app_router.dart';
import 'package:pashusetu/core/settings/app_settings.dart';

AppSettings loggedInAs(String role) =>
    AppSettings(language: 'hi', token: 't', user: {'role': role, 'name': 'Test'});

void main() {
  test('first launch goes to the language picker', () {
    expect(redirectFor(const AppSettings(), '/'), '/language');
    expect(redirectFor(const AppSettings(), '/language'), isNull);
  });

  test('logged out users go to login, but settings stay reachable', () {
    const settings = AppSettings(language: 'en');
    expect(redirectFor(settings, '/vet'), '/login');
    expect(redirectFor(settings, '/settings/developer'), isNull);
  });

  test('each role lands on its own home and cannot open another', () {
    expect(redirectFor(loggedInAs('pashu_sevak'), '/login'), '/sevak');
    expect(redirectFor(loggedInAs('district_officer'), '/'), '/officer');
    expect(redirectFor(loggedInAs('farmer'), '/vet'), '/farmer');
    expect(redirectFor(loggedInAs('vet'), '/vet'), isNull);
  });
}
