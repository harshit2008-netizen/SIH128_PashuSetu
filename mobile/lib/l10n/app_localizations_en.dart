// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'PashuSetu';

  @override
  String get notDiagnosis =>
      'This is not a diagnosis. A vet or lab must confirm.';

  @override
  String get roleFarmer => 'Farmer';

  @override
  String get rolePashuSevak => 'Pashu sevak';

  @override
  String get roleVet => 'Vet';

  @override
  String get roleLab => 'Lab';

  @override
  String get roleDistrictOfficer => 'District officer';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get continueButton => 'Continue';

  @override
  String get loginTitle => 'Who are you?';

  @override
  String get loginPhoneLabel => 'Phone number';

  @override
  String get loginOtpLabel => 'OTP';

  @override
  String get loginButton => 'Log in';

  @override
  String get demoOtpNote => 'Demo login. OTP is 123456.';

  @override
  String get loginWorking => 'Logging in';

  @override
  String get serverUnreachable =>
      'Could not reach the server. Check that the laptop is on the same Wi-Fi, then try again.';

  @override
  String greeting(String name) {
    return 'Namaste, $name';
  }

  @override
  String get reportActionTitle => 'Report a sick animal';

  @override
  String get reportComingNext => 'The report steps arrive in the next build.';

  @override
  String get reportActionSubtitle => 'Speak or tap the signs';

  @override
  String get alertsNearYou => 'Alerts near you';

  @override
  String get noAlertsNearYou =>
      'No alerts near you. When a vet sends an advisory, it appears here.';

  @override
  String get myAnimals => 'My animals';

  @override
  String get noAnimals =>
      'No animals registered yet. Your pashu sevak can register them with ear tags.';

  @override
  String vaccineDueOn(String vaccine, String date) {
    return '$vaccine vaccine due on $date';
  }

  @override
  String get myReports => 'My reports';

  @override
  String get noReports =>
      'No reports yet. When you report a sick animal, it appears here.';

  @override
  String get vaccinationsDue => 'Vaccinations due';

  @override
  String get noVaccinationsDue => 'No vaccinations due in the next 30 days.';

  @override
  String get animalsInArea => 'Animals in my area';

  @override
  String get caseQueue => 'Cases to act on';

  @override
  String get noCases =>
      'No open cases. When a farmer reports a sick animal, it appears here.';

  @override
  String get labSamples => 'Samples';

  @override
  String get noSamples =>
      'No samples waiting. When a vet requests a sample, it appears here.';

  @override
  String get notMatched => 'Not matched to a disease';

  @override
  String get waitingForVet => 'Waiting for a vet';

  @override
  String assignedTo(String name) {
    return 'Vet: $name';
  }

  @override
  String get showingSavedData => 'Showing data saved on this phone.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get syncAllSent => 'All sent';

  @override
  String syncWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count waiting to send',
      one: '1 waiting to send',
    );
    return '$_temp0';
  }

  @override
  String get syncOffline => 'Offline, saved on phone';

  @override
  String get severityEmergency => 'Emergency';

  @override
  String get severityUrgent => 'Urgent';

  @override
  String get severityRoutine => 'Routine';

  @override
  String get confidenceHigh => 'High';

  @override
  String get confidenceModerate => 'Moderate';

  @override
  String get confidenceLow => 'Low';

  @override
  String notReported(String sign) {
    return 'Not reported: $sign';
  }

  @override
  String get photoChip => 'Photo';

  @override
  String get whatDoesThisMean => 'What does this mean?';

  @override
  String get listen => 'Listen';

  @override
  String get decrease => 'Decrease';

  @override
  String get increase => 'Increase';

  @override
  String get selected => 'Selected';

  @override
  String get statusReported => 'Reported';

  @override
  String get statusTriaged => 'Checked by the app';

  @override
  String get statusVetAssigned => 'Vet assigned';

  @override
  String get statusSampleRequested => 'Sample requested';

  @override
  String get statusSampleCollected => 'Sample collected';

  @override
  String get statusLabReceived => 'Lab received the sample';

  @override
  String get statusLabResult => 'Lab result';

  @override
  String get statusUnderTreatment => 'Under treatment';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get statusClosedRuledOut => 'Ruled out';

  @override
  String get kpiOpenCases => 'Open cases';

  @override
  String get kpiEmergency => 'Emergency';

  @override
  String get kpiUrgent => 'Urgent';

  @override
  String get kpiWaitingForVet => 'Waiting for vet';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String kmAway(String distance) {
    return '$distance km away';
  }

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get changeRole => 'Change role (demo)';

  @override
  String get simulateNoSignal => 'Simulate no signal (demo)';

  @override
  String get simulateNoSignalHelp =>
      'The app acts as if there is no network, so the offline path can be shown.';

  @override
  String appVersion(String version) {
    return 'App version $version';
  }

  @override
  String engineVersion(String version) {
    return 'Triage engine $version';
  }

  @override
  String get logOut => 'Log out';

  @override
  String get developerOptions => 'Developer options';

  @override
  String get developerOptionsOn => 'Developer options are on';

  @override
  String get apiBaseUrl => 'API base URL';

  @override
  String get apiBaseUrlHelp =>
      'Laptop address on the same Wi-Fi, for example http://192.168.43.10:8000. With a USB cable and adb reverse, use http://127.0.0.1:8000.';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get testConnection => 'Test connection';

  @override
  String get connectionOk => 'Server reachable';

  @override
  String get connectionFailed => 'Server not reachable';

  @override
  String get clearLocalData => 'Clear local data';

  @override
  String get clearLocalDataDone => 'Local data cleared';

  @override
  String get showOutbox => 'Show outbox';

  @override
  String get outboxEmpty => 'The outbox is empty.';
}
