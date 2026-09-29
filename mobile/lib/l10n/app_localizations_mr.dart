// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appName => 'पशुसेतु';

  @override
  String get notDiagnosis =>
      'हे निदान नाही. पशुवैद्यक किंवा प्रयोगशाळा खात्री करतील.';

  @override
  String get roleFarmer => 'शेतकरी';

  @override
  String get rolePashuSevak => 'पशुसेवक';

  @override
  String get roleVet => 'पशुवैद्यक';

  @override
  String get roleLab => 'प्रयोगशाळा';

  @override
  String get roleDistrictOfficer => 'जिल्हा अधिकारी';

  @override
  String get chooseLanguage => 'तुमची भाषा निवडा';

  @override
  String get continueButton => 'पुढे जा';

  @override
  String get loginTitle => 'तुम्ही कोण आहात?';

  @override
  String get loginPhoneLabel => 'फोन नंबर';

  @override
  String get loginOtpLabel => 'ओटीपी';

  @override
  String get loginButton => 'लॉग इन करा';

  @override
  String get demoOtpNote => 'डेमो लॉगिन. ओटीपी 123456 आहे.';

  @override
  String get loginWorking => 'लॉग इन होत आहे';

  @override
  String get serverUnreachable =>
      'सर्व्हरशी जोडता आले नाही. लॅपटॉप त्याच वाय-फायवर आहे का ते पहा, मग पुन्हा प्रयत्न करा.';

  @override
  String greeting(String name) {
    return 'नमस्कार, $name';
  }

  @override
  String get reportActionTitle => 'आजारी जनावराची माहिती द्या';

  @override
  String get reportComingNext =>
      'माहिती देण्याच्या पायऱ्या पुढील आवृत्तीत येतील.';

  @override
  String get reportActionSubtitle => 'बोला किंवा लक्षणे निवडा';

  @override
  String get alertsNearYou => 'तुमच्या जवळचे इशारे';

  @override
  String get noAlertsNearYou =>
      'तुमच्या जवळ कोणताही इशारा नाही. पशुवैद्यक सूचना पाठवतील तेव्हा ती इथे दिसेल.';

  @override
  String get myAnimals => 'माझी जनावरे';

  @override
  String get noAnimals =>
      'अजून कोणतेही जनावर नोंदलेले नाही. तुमचे पशुसेवक कानाच्या टॅगसह नोंद करू शकतात.';

  @override
  String vaccineDueOn(String vaccine, String date) {
    return '$vaccine लस $date रोजी';
  }

  @override
  String get myReports => 'माझ्या नोंदी';

  @override
  String get noReports =>
      'अजून कोणतीही नोंद नाही. आजारी जनावराची माहिती दिल्यावर ती इथे दिसेल.';

  @override
  String get vaccinationsDue => 'बाकी लसीकरण';

  @override
  String get noVaccinationsDue => 'पुढील 30 दिवसांत कोणतेही लसीकरण बाकी नाही.';

  @override
  String get animalsInArea => 'माझ्या भागातील जनावरे';

  @override
  String get caseQueue => 'कारवाईची प्रकरणे';

  @override
  String get noCases =>
      'कोणतेही खुले प्रकरण नाही. शेतकरी आजारी जनावराची माहिती देतील तेव्हा ते इथे दिसेल.';

  @override
  String get labSamples => 'नमुने';

  @override
  String get noSamples =>
      'कोणताही नमुना बाकी नाही. पशुवैद्यक नमुना मागतील तेव्हा तो इथे दिसेल.';

  @override
  String get notMatched => 'कोणत्याही आजाराशी जुळत नाही';

  @override
  String get waitingForVet => 'पशुवैद्यकाची वाट';

  @override
  String assignedTo(String name) {
    return 'पशुवैद्यक: $name';
  }

  @override
  String get showingSavedData => 'फोनमध्ये जतन केलेली माहिती दिसत आहे.';

  @override
  String get tryAgain => 'पुन्हा प्रयत्न करा';

  @override
  String get syncAllSent => 'सर्व पाठवले';

  @override
  String syncWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पाठवायचे बाकी',
      one: '1 पाठवायचे बाकी',
    );
    return '$_temp0';
  }

  @override
  String get syncOffline => 'ऑफलाइन, फोनमध्ये जतन';

  @override
  String get severityEmergency => 'आणीबाणी';

  @override
  String get severityUrgent => 'तातडीचे';

  @override
  String get severityRoutine => 'नेहमीचे';

  @override
  String get confidenceHigh => 'जास्त';

  @override
  String get confidenceModerate => 'मध्यम';

  @override
  String get confidenceLow => 'कमी';

  @override
  String notReported(String sign) {
    return 'सांगितले नाही: $sign';
  }

  @override
  String get photoChip => 'फोटो';

  @override
  String get whatDoesThisMean => 'याचा अर्थ काय?';

  @override
  String get listen => 'ऐका';

  @override
  String get decrease => 'कमी करा';

  @override
  String get increase => 'वाढवा';

  @override
  String get selected => 'निवडले';

  @override
  String get statusReported => 'माहिती दिली';

  @override
  String get statusTriaged => 'अॅपने तपासले';

  @override
  String get statusVetAssigned => 'पशुवैद्यक नेमले';

  @override
  String get statusSampleRequested => 'नमुना मागितला';

  @override
  String get statusSampleCollected => 'नमुना घेतला';

  @override
  String get statusLabReceived => 'प्रयोगशाळेला नमुना मिळाला';

  @override
  String get statusLabResult => 'प्रयोगशाळेचा निकाल';

  @override
  String get statusUnderTreatment => 'उपचार सुरू';

  @override
  String get statusResolved => 'बरे झाले';

  @override
  String get statusClosedRuledOut => 'आजार नाही';

  @override
  String get kpiOpenCases => 'खुली प्रकरणे';

  @override
  String get kpiEmergency => 'आणीबाणी';

  @override
  String get kpiUrgent => 'तातडीचे';

  @override
  String get kpiWaitingForVet => 'पशुवैद्यक बाकी';

  @override
  String get justNow => 'आत्ताच';

  @override
  String minutesAgo(int count) {
    return '$count मिनिटांपूर्वी';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count तासांपूर्वी',
      one: '1 तासापूर्वी',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिवसांपूर्वी',
      one: '1 दिवसापूर्वी',
    );
    return '$_temp0';
  }

  @override
  String kmAway(String distance) {
    return '$distance किमी दूर';
  }

  @override
  String get settings => 'सेटिंग्ज';

  @override
  String get language => 'भाषा';

  @override
  String get changeRole => 'भूमिका बदला (डेमो)';

  @override
  String get simulateNoSignal => 'नेटवर्क बंद समजा (डेमो)';

  @override
  String get simulateNoSignalHelp =>
      'नेटवर्क नसल्यासारखे अॅप चालेल, म्हणजे ऑफलाइन पद्धत दाखवता येईल.';

  @override
  String appVersion(String version) {
    return 'अॅप आवृत्ती $version';
  }

  @override
  String engineVersion(String version) {
    return 'तपासणी इंजिन $version';
  }

  @override
  String get logOut => 'लॉग आउट';

  @override
  String get developerOptions => 'डेव्हलपर पर्याय';

  @override
  String get developerOptionsOn => 'डेव्हलपर पर्याय सुरू आहेत';

  @override
  String get apiBaseUrl => 'एपीआय पत्ता';

  @override
  String get apiBaseUrlHelp =>
      'त्याच वाय-फायवरील लॅपटॉपचा पत्ता, उदा. http://192.168.43.10:8000. यूएसबी केबल आणि adb reverse सह http://127.0.0.1:8000 लिहा.';

  @override
  String get save => 'जतन करा';

  @override
  String get saved => 'जतन केले';

  @override
  String get testConnection => 'कनेक्शन तपासा';

  @override
  String get connectionOk => 'सर्व्हर जोडलेला आहे';

  @override
  String get connectionFailed => 'सर्व्हरशी जोडता आले नाही';

  @override
  String get clearLocalData => 'फोनमधील डेटा पुसा';

  @override
  String get clearLocalDataDone => 'फोनमधील डेटा पुसला';

  @override
  String get showOutbox => 'आउटबॉक्स पहा';

  @override
  String get outboxEmpty => 'आउटबॉक्स रिकामा आहे.';
}
