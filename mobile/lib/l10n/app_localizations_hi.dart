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

  @override
  String get stepAnimal => 'पशु';

  @override
  String get stepSigns => 'लक्षण';

  @override
  String get stepPhoto => 'फ़ोटो';

  @override
  String get stepCount => 'कितने';

  @override
  String get stepCheck => 'जांचें और भेजें';

  @override
  String get whichSpecies => 'कौन सा पशु बीमार है?';

  @override
  String get whichAnimal => 'कौन सा पशु? (ज़रूरी नहीं)';

  @override
  String get notRegistered => 'दर्ज नहीं है';

  @override
  String get whereIsAnimal => 'पशु कहां है?';

  @override
  String get findingLocation => 'जगह ढूंढ रहे हैं';

  @override
  String get usingPhoneLocation => 'फ़ोन की जगह ली गई';

  @override
  String get usingVillageLocation => 'गांव की जगह ली गई';

  @override
  String get changeVillage => 'गांव बदलें';

  @override
  String get chooseVillage => 'गांव चुनें';

  @override
  String get signsTitle => 'आपको क्या दिख रहा है?';

  @override
  String get signsHint => 'जो भी लक्षण दिखे, सब पर टैप करें।';

  @override
  String get photoTitle => 'बीमारी वाली जगह की फ़ोटो लें';

  @override
  String get photoHelp =>
      'दिन की रोशनी में, पास से फ़ोटो लें, गांठ या घाव बीच में रखें। यह छोड़ भी सकते हैं।';

  @override
  String get takePhoto => 'फ़ोटो लें';

  @override
  String get retakePhoto => 'फिर से लें';

  @override
  String get removePhoto => 'फ़ोटो हटाएं';

  @override
  String get cameraDenied =>
      'कैमरे की अनुमति नहीं है। फ़ोटो जोड़ने के लिए फ़ोन की सेटिंग में अनुमति दें।';

  @override
  String get howManyTitle => 'कितने पशु?';

  @override
  String get sickLabel => 'बीमार';

  @override
  String get deadLabel => 'मरे';

  @override
  String get totalLabel => 'यहां कुल पशु';

  @override
  String get onsetTitle => 'कब शुरू हुआ?';

  @override
  String get onsetToday => 'आज';

  @override
  String get onsetYesterday => 'कल';

  @override
  String get onsetFewDays => '2-3 दिन पहले';

  @override
  String get onsetLonger => '3 दिन से ज़्यादा';

  @override
  String get sendReport => 'सूचना भेजें';

  @override
  String get back => 'पीछे';

  @override
  String get next => 'आगे';

  @override
  String get needSignOrDeath =>
      'कम से कम एक लक्षण चुनें, या मरा हुआ पशु जोड़ें।';

  @override
  String get totalTooSmall => 'कुल पशु बीमार और मरे पशुओं से कम नहीं हो सकते।';

  @override
  String get noSignsChosen => 'कोई लक्षण नहीं चुना';

  @override
  String get noPhoto => 'फ़ोटो नहीं';

  @override
  String get photoAdded => 'फ़ोटो जोड़ी';

  @override
  String get savedOnPhone =>
      'फ़ोन में सहेजा गया। नेटवर्क आने पर अपने आप चला जाएगा।';

  @override
  String get reportSent => 'सूचना भेज दी';

  @override
  String get sendingReport => 'सूचना भेज रहे हैं';

  @override
  String suspectedDisease(String disease) {
    return 'आशंका: $disease';
  }

  @override
  String get noClearMatch => 'किसी बीमारी से साफ़ मेल नहीं';

  @override
  String get noClearMatchHelp =>
      'पशु पर नज़र रखें। हालत बिगड़े या दूसरे पशु बीमार हों तो पशु डॉक्टर को फ़ोन करें।';

  @override
  String get unknownSyndrome =>
      'ये लक्षण इस ऐप की किसी जानी हुई बीमारी से मेल नहीं खाते। पशु डॉक्टर को यह पशु दिखाएं।';

  @override
  String get mostLikely => 'सबसे संभावित';

  @override
  String get whyResult => 'क्यों';

  @override
  String get doThisNow => 'अभी यह करें';

  @override
  String callNumber(String number) {
    return '$number पर कॉल करें';
  }

  @override
  String get zoonoticWarning =>
      'यह बीमारी इंसानों में फैल सकती है। बच्चों को दूर रखें और पशु छूने के बाद हाथ धोएं।';

  @override
  String get done => 'ठीक है';

  @override
  String countSummary(int sick, int dead, int total) {
    return '$sick बीमार, $dead मरे, कुल $total';
  }

  @override
  String get tabAlerts => 'चेतावनियां';

  @override
  String get tabCases => 'मामले';

  @override
  String get kpiActiveAlerts => 'सक्रिय चेतावनियां';

  @override
  String get kpiMedianResponse => 'पहली कार्रवाई (मध्य)';

  @override
  String get kpiSamplesPending => 'बाकी नमूने';

  @override
  String minutesShort(int count) {
    return '$count मिनट';
  }

  @override
  String get noAlerts =>
      'कोई सक्रिय चेतावनी नहीं। पास-पास कई सूचनाएं आएंगी तो यहां चेतावनी दिखेगी।';

  @override
  String updatedAt(String time) {
    return 'अपडेट: $time';
  }

  @override
  String get alertCluster => 'बीमारी का समूह';

  @override
  String get alertZoonotic => 'इंसानों में फैल सकता है';

  @override
  String get alertMortality => 'कई मौतें';

  @override
  String get acknowledge => 'स्वीकार करें';

  @override
  String get acknowledged => 'स्वीकार किया';

  @override
  String get sendAdvisory => 'सलाह भेजें';

  @override
  String get casesInAlert => 'इस चेतावनी के मामले';

  @override
  String reportedBy(String name) {
    return 'सूचना देने वाले: $name';
  }

  @override
  String get assignToMe => 'मुझे सौंपें';

  @override
  String get assignVet => 'पशु डॉक्टर सौंपें';

  @override
  String get chooseVet => 'पशु डॉक्टर चुनें';

  @override
  String get requestSample => 'नमूना मांगें';

  @override
  String get chooseSampleType => 'कौन सा नमूना?';

  @override
  String get sampleSkinScab => 'त्वचा की पपड़ी';

  @override
  String get sampleBlood => 'खून';

  @override
  String get sampleNasalSwab => 'नाक का स्वाब';

  @override
  String get sampleOralSwab => 'मुंह का स्वाब';

  @override
  String get sampleTissue => 'ऊतक';

  @override
  String get sampleCarcassSwab => 'शव का स्वाब';

  @override
  String get sampleOther => 'अन्य';

  @override
  String get markUnderTreatment => 'इलाज शुरू';

  @override
  String get resolveCase => 'ठीक हुआ';

  @override
  String get ruleOut => 'बीमारी नहीं';

  @override
  String labConfirmed(String disease) {
    return 'लैब ने पुष्टि की: $disease';
  }

  @override
  String get whyAppSuspected => 'ऐप ने यह क्यों माना';

  @override
  String get timelineTitle => 'समय-रेखा';

  @override
  String get samplesTitle => 'नमूने';

  @override
  String get showQrHint =>
      'यह कोड पशु सेवक को दिखाएं, या नमूने की ट्यूब पर लिखें।';

  @override
  String get reportPhoto => 'फ़ोटो';

  @override
  String get scanSample => 'नमूना स्कैन करें';

  @override
  String get typeCodeInstead => 'या कोड लिखें';

  @override
  String get continueButton2 => 'आगे';

  @override
  String get sampleCollected => 'नमूना लिया गया';

  @override
  String get sampleReceived => 'लैब को नमूना मिला';

  @override
  String get enterResult => 'नतीजा लिखें';

  @override
  String get resultPositive => 'पॉज़िटिव';

  @override
  String get resultNegative => 'नेगेटिव';

  @override
  String get resultInconclusive => 'साफ़ नहीं';

  @override
  String get whichDisease => 'कौन सी बीमारी?';

  @override
  String get noteOptional => 'टिप्पणी (ज़रूरी नहीं)';

  @override
  String get saveResult => 'नतीजा सहेजें';

  @override
  String get resultSaved => 'नतीजा सहेजा गया';

  @override
  String get samplesToCollect => 'लेने वाले नमूने';

  @override
  String get samplesAtLab => 'लैब के नमूने';

  @override
  String get noSamplesToCollect =>
      'कोई नमूना लेना बाकी नहीं। पशु डॉक्टर मांगेंगे तो यहां दिखेगा।';

  @override
  String get cameraNotAllowed => 'कैमरे की अनुमति नहीं है। कोड लिखें।';

  @override
  String get sampleStatusRequested => 'लेना है';

  @override
  String get sampleStatusCollected => 'लैब जा रहा है';

  @override
  String get sampleStatusReceived => 'नतीजे का इंतज़ार';

  @override
  String get sampleStatusResulted => 'नतीजा तैयार';

  @override
  String get messageLabel => 'संदेश';

  @override
  String radiusKm(String km) {
    return 'दायरा: $km किमी';
  }

  @override
  String willReach(int farmers, int villages) {
    return '$villages गांवों के $farmers किसानों तक पहुंचेगा';
  }

  @override
  String get advisoryPreview => 'झलक';

  @override
  String advisorySentTo(int count) {
    return 'सलाह $count किसानों को भेजी गई';
  }

  @override
  String get tapMapToMove => 'केंद्र बदलने के लिए नक्शे पर टैप करें।';

  @override
  String get villageInMessage => 'संदेश में गांव';

  @override
  String get inAppOnly => 'ऐप के इनबॉक्स में भेजा। एसएमएस चालू नहीं है।';

  @override
  String get uploadPhoto => 'गैलरी से फ़ोटो चुनें';
}
