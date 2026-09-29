// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'पशुसेतु';

  @override
  String get notDiagnosis =>
      'यह जांच का पक्का नतीजा नहीं है। पशु डॉक्टर या लैब पुष्टि करेंगे।';

  @override
  String get roleFarmer => 'किसान';

  @override
  String get rolePashuSevak => 'पशु सेवक';

  @override
  String get roleVet => 'पशु डॉक्टर';

  @override
  String get roleLab => 'लैब';

  @override
  String get roleDistrictOfficer => 'जिला अधिकारी';

  @override
  String get chooseLanguage => 'अपनी भाषा चुनें';

  @override
  String get continueButton => 'आगे बढ़ें';

  @override
  String get loginTitle => 'आप कौन हैं?';

  @override
  String get loginPhoneLabel => 'फ़ोन नंबर';

  @override
  String get loginOtpLabel => 'ओटीपी';

  @override
  String get loginButton => 'लॉग इन करें';

  @override
  String get demoOtpNote => 'डेमो लॉगिन। ओटीपी 123456 है।';

  @override
  String get loginWorking => 'लॉग इन हो रहा है';

  @override
  String get serverUnreachable =>
      'सर्वर से जुड़ नहीं पाए। देखें कि लैपटॉप उसी वाई-फ़ाई पर है, फिर दोबारा कोशिश करें।';

  @override
  String greeting(String name) {
    return 'नमस्ते, $name जी';
  }

  @override
  String get reportActionTitle => 'बीमार पशु की सूचना दें';

  @override
  String get reportComingNext => 'सूचना देने के चरण अगले संस्करण में आएंगे।';

  @override
  String get reportActionSubtitle => 'बोलें या लक्षण चुनें';

  @override
  String get alertsNearYou => 'आपके पास की चेतावनियां';

  @override
  String get noAlertsNearYou =>
      'आपके पास कोई चेतावनी नहीं है। पशु डॉक्टर सलाह भेजेंगे तो यहां दिखेगी।';

  @override
  String get myAnimals => 'मेरे पशु';

  @override
  String get noAnimals =>
      'अभी कोई पशु दर्ज नहीं है। आपके पशु सेवक कान के टैग के साथ दर्ज कर सकते हैं।';

  @override
  String vaccineDueOn(String vaccine, String date) {
    return '$vaccine टीका $date को';
  }

  @override
  String get myReports => 'मेरी सूचनाएं';

  @override
  String get noReports =>
      'अभी कोई सूचना नहीं। बीमार पशु की सूचना देंगे तो यहां दिखेगी।';

  @override
  String get vaccinationsDue => 'बकाया टीके';

  @override
  String get noVaccinationsDue => 'अगले 30 दिन में कोई टीका बकाया नहीं है।';

  @override
  String get animalsInArea => 'मेरे क्षेत्र के पशु';

  @override
  String get caseQueue => 'कार्रवाई के मामले';

  @override
  String get noCases =>
      'कोई खुला मामला नहीं। किसान बीमार पशु की सूचना देंगे तो यहां दिखेगा।';

  @override
  String get labSamples => 'नमूने';

  @override
  String get noSamples =>
      'कोई नमूना बाकी नहीं। पशु डॉक्टर नमूना मांगेंगे तो यहां दिखेगा।';

  @override
  String get notMatched => 'किसी बीमारी से मेल नहीं';

  @override
  String get waitingForVet => 'पशु डॉक्टर का इंतज़ार';

  @override
  String assignedTo(String name) {
    return 'डॉक्टर: $name';
  }

  @override
  String get showingSavedData => 'फ़ोन में सहेजी जानकारी दिख रही है।';

  @override
  String get tryAgain => 'दोबारा कोशिश करें';

  @override
  String get syncAllSent => 'सब भेज दिया';

  @override
  String syncWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count भेजना बाकी',
      one: '1 भेजना बाकी',
    );
    return '$_temp0';
  }

  @override
  String get syncOffline => 'ऑफ़लाइन, फ़ोन में सहेजा';

  @override
  String get severityEmergency => 'आपातकाल';

  @override
  String get severityUrgent => 'तुरंत';

  @override
  String get severityRoutine => 'सामान्य';

  @override
  String get confidenceHigh => 'ज़्यादा';

  @override
  String get confidenceModerate => 'मध्यम';

  @override
  String get confidenceLow => 'कम';

  @override
  String notReported(String sign) {
    return 'नहीं बताया: $sign';
  }

  @override
  String get photoChip => 'फ़ोटो';

  @override
  String get whatDoesThisMean => 'इसका क्या मतलब है?';

  @override
  String get listen => 'सुनें';

  @override
  String get decrease => 'कम करें';

  @override
  String get increase => 'बढ़ाएं';

  @override
  String get selected => 'चुना गया';

  @override
  String get statusReported => 'सूचना दी';

  @override
  String get statusTriaged => 'ऐप ने जांचा';

  @override
  String get statusVetAssigned => 'पशु डॉक्टर तय';

  @override
  String get statusSampleRequested => 'नमूना मांगा';

  @override
  String get statusSampleCollected => 'नमूना लिया';

  @override
  String get statusLabReceived => 'लैब को नमूना मिला';

  @override
  String get statusLabResult => 'लैब का नतीजा';

  @override
  String get statusUnderTreatment => 'इलाज जारी';

  @override
  String get statusResolved => 'ठीक हुआ';

  @override
  String get statusClosedRuledOut => 'बीमारी नहीं निकली';

  @override
  String get kpiOpenCases => 'खुले मामले';

  @override
  String get kpiEmergency => 'आपातकाल';

  @override
  String get kpiUrgent => 'तुरंत';

  @override
  String get kpiWaitingForVet => 'डॉक्टर बाकी';

  @override
  String get justNow => 'अभी';

  @override
  String minutesAgo(int count) {
    return '$count मिनट पहले';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count घंटे पहले',
      one: '1 घंटा पहले',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन पहले',
      one: '1 दिन पहले',
    );
    return '$_temp0';
  }

  @override
  String kmAway(String distance) {
    return '$distance किमी दूर';
  }

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get language => 'भाषा';

  @override
  String get changeRole => 'भूमिका बदलें (डेमो)';

  @override
  String get simulateNoSignal => 'नेटवर्क बंद मानें (डेमो)';

  @override
  String get simulateNoSignalHelp =>
      'ऐप ऐसे चलेगा जैसे नेटवर्क नहीं है, ताकि ऑफ़लाइन तरीका दिखाया जा सके।';

  @override
  String appVersion(String version) {
    return 'ऐप संस्करण $version';
  }

  @override
  String engineVersion(String version) {
    return 'जांच इंजन $version';
  }

  @override
  String get logOut => 'लॉग आउट';

  @override
  String get developerOptions => 'डेवलपर विकल्प';

  @override
  String get developerOptionsOn => 'डेवलपर विकल्प चालू हैं';

  @override
  String get apiBaseUrl => 'एपीआई पता';

  @override
  String get apiBaseUrlHelp =>
      'उसी वाई-फ़ाई पर लैपटॉप का पता, जैसे http://192.168.43.10:8000। यूएसबी केबल और adb reverse के साथ http://127.0.0.1:8000 लिखें।';

  @override
  String get save => 'सहेजें';

  @override
  String get saved => 'सहेजा गया';

  @override
  String get testConnection => 'कनेक्शन जांचें';

  @override
  String get connectionOk => 'सर्वर जुड़ा है';

  @override
  String get connectionFailed => 'सर्वर से नहीं जुड़ पाए';

  @override
  String get clearLocalData => 'फ़ोन का डेटा मिटाएं';

  @override
  String get clearLocalDataDone => 'फ़ोन का डेटा मिटा दिया';

  @override
  String get showOutbox => 'आउटबॉक्स देखें';

  @override
  String get outboxEmpty => 'आउटबॉक्स खाली है।';
}
