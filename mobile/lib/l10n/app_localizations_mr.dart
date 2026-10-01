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

  @override
  String get stepAnimal => 'जनावर';

  @override
  String get stepSigns => 'लक्षणे';

  @override
  String get stepPhoto => 'फोटो';

  @override
  String get stepCount => 'किती';

  @override
  String get stepCheck => 'तपासा आणि पाठवा';

  @override
  String get whichSpecies => 'कोणते जनावर आजारी आहे?';

  @override
  String get whichAnimal => 'कोणते जनावर? (ऐच्छिक)';

  @override
  String get notRegistered => 'नोंद नाही';

  @override
  String get whereIsAnimal => 'जनावर कुठे आहे?';

  @override
  String get findingLocation => 'जागा शोधत आहे';

  @override
  String get usingPhoneLocation => 'फोनची जागा वापरली';

  @override
  String get usingVillageLocation => 'गावाची जागा वापरली';

  @override
  String get changeVillage => 'गाव बदला';

  @override
  String get chooseVillage => 'गाव निवडा';

  @override
  String get signsTitle => 'तुम्हाला काय दिसते?';

  @override
  String get signsHint => 'दिसणाऱ्या प्रत्येक लक्षणावर टॅप करा.';

  @override
  String get photoTitle => 'आजारी भागाचा फोटो घ्या';

  @override
  String get photoHelp =>
      'दिवसाच्या प्रकाशात, जवळून फोटो घ्या, गाठ किंवा जखम मध्ये ठेवा. हे वगळू शकता.';

  @override
  String get takePhoto => 'फोटो घ्या';

  @override
  String get retakePhoto => 'पुन्हा घ्या';

  @override
  String get removePhoto => 'फोटो काढा';

  @override
  String get cameraDenied =>
      'कॅमेऱ्याला परवानगी नाही. फोटो जोडण्यासाठी फोनच्या सेटिंगमध्ये परवानगी द्या.';

  @override
  String get howManyTitle => 'किती जनावरे?';

  @override
  String get sickLabel => 'आजारी';

  @override
  String get deadLabel => 'मेलेली';

  @override
  String get totalLabel => 'इथे एकूण जनावरे';

  @override
  String get onsetTitle => 'कधी सुरू झाले?';

  @override
  String get onsetToday => 'आज';

  @override
  String get onsetYesterday => 'काल';

  @override
  String get onsetFewDays => '2-3 दिवसांपूर्वी';

  @override
  String get onsetLonger => '3 दिवसांपेक्षा जास्त';

  @override
  String get sendReport => 'माहिती पाठवा';

  @override
  String get back => 'मागे';

  @override
  String get next => 'पुढे';

  @override
  String get needSignOrDeath =>
      'किमान एक लक्षण निवडा, किंवा मेलेले जनावर जोडा.';

  @override
  String get totalTooSmall =>
      'एकूण जनावरे आजारी आणि मेलेल्यांपेक्षा कमी असू शकत नाहीत.';

  @override
  String get noSignsChosen => 'कोणतेही लक्षण निवडले नाही';

  @override
  String get noPhoto => 'फोटो नाही';

  @override
  String get photoAdded => 'फोटो जोडला';

  @override
  String get savedOnPhone =>
      'फोनमध्ये जतन केले. नेटवर्क आल्यावर आपोआप पाठवले जाईल.';

  @override
  String get reportSent => 'माहिती पाठवली';

  @override
  String get sendingReport => 'माहिती पाठवत आहे';

  @override
  String suspectedDisease(String disease) {
    return 'संशय: $disease';
  }

  @override
  String get noClearMatch => 'कोणत्याही आजाराशी स्पष्ट जुळत नाही';

  @override
  String get noClearMatchHelp =>
      'जनावरावर लक्ष ठेवा. प्रकृती बिघडली किंवा इतर जनावरे आजारी पडली तर पशुवैद्यकाला फोन करा.';

  @override
  String get unknownSyndrome =>
      'ही लक्षणे या अॅपमधील कोणत्याही माहीत आजाराशी जुळत नाहीत. पशुवैद्यकाला हे जनावर दाखवा.';

  @override
  String get mostLikely => 'सर्वात शक्य';

  @override
  String get whyResult => 'का';

  @override
  String get doThisNow => 'आत्ता हे करा';

  @override
  String callNumber(String number) {
    return '$number वर फोन करा';
  }

  @override
  String get zoonoticWarning =>
      'हा आजार माणसांमध्ये पसरू शकतो. मुलांना दूर ठेवा आणि जनावराला स्पर्श केल्यावर हात धुवा.';

  @override
  String get done => 'ठीक आहे';

  @override
  String countSummary(int sick, int dead, int total) {
    return '$sick आजारी, $dead मेलेली, एकूण $total';
  }

  @override
  String get tabAlerts => 'इशारे';

  @override
  String get tabCases => 'प्रकरणे';

  @override
  String get kpiActiveAlerts => 'सक्रिय इशारे';

  @override
  String get kpiMedianResponse => 'पहिली कारवाई (मध्य)';

  @override
  String get kpiSamplesPending => 'बाकी नमुने';

  @override
  String minutesShort(int count) {
    return '$count मिनिटे';
  }

  @override
  String get noAlerts =>
      'कोणताही सक्रिय इशारा नाही. जवळजवळ अनेक नोंदी आल्या की इथे इशारा दिसेल.';

  @override
  String updatedAt(String time) {
    return 'अद्ययावत: $time';
  }

  @override
  String get alertCluster => 'आजाराचा समूह';

  @override
  String get alertZoonotic => 'माणसांमध्ये पसरू शकतो';

  @override
  String get alertMortality => 'अनेक मृत्यू';

  @override
  String get acknowledge => 'स्वीकारा';

  @override
  String get acknowledged => 'स्वीकारले';

  @override
  String get sendAdvisory => 'सूचना पाठवा';

  @override
  String get casesInAlert => 'या इशाऱ्यातील प्रकरणे';

  @override
  String reportedBy(String name) {
    return 'माहिती देणारे: $name';
  }

  @override
  String get assignToMe => 'मला सोपवा';

  @override
  String get assignVet => 'पशुवैद्यक नेमा';

  @override
  String get chooseVet => 'पशुवैद्यक निवडा';

  @override
  String get requestSample => 'नमुना मागवा';

  @override
  String get chooseSampleType => 'कोणता नमुना?';

  @override
  String get sampleSkinScab => 'त्वचेची खपली';

  @override
  String get sampleBlood => 'रक्त';

  @override
  String get sampleNasalSwab => 'नाकाचा स्वॅब';

  @override
  String get sampleOralSwab => 'तोंडाचा स्वॅब';

  @override
  String get sampleTissue => 'ऊतक';

  @override
  String get sampleCarcassSwab => 'मृतदेहाचा स्वॅब';

  @override
  String get sampleOther => 'इतर';

  @override
  String get markUnderTreatment => 'उपचार सुरू';

  @override
  String get resolveCase => 'बरे झाले';

  @override
  String get ruleOut => 'आजार नाही';

  @override
  String labConfirmed(String disease) {
    return 'प्रयोगशाळेने खात्री केली: $disease';
  }

  @override
  String get whyAppSuspected => 'अॅपने असे का मानले';

  @override
  String get timelineTitle => 'वेळरेषा';

  @override
  String get samplesTitle => 'नमुने';

  @override
  String get showQrHint =>
      'हा कोड पशुसेवकाला दाखवा, किंवा नमुन्याच्या नळीवर लिहा.';

  @override
  String get reportPhoto => 'फोटो';

  @override
  String get scanSample => 'नमुना स्कॅन करा';

  @override
  String get typeCodeInstead => 'किंवा कोड लिहा';

  @override
  String get continueButton2 => 'पुढे';

  @override
  String get sampleCollected => 'नमुना घेतला';

  @override
  String get sampleReceived => 'प्रयोगशाळेला नमुना मिळाला';

  @override
  String get enterResult => 'निकाल नोंदवा';

  @override
  String get resultPositive => 'पॉझिटिव्ह';

  @override
  String get resultNegative => 'निगेटिव्ह';

  @override
  String get resultInconclusive => 'स्पष्ट नाही';

  @override
  String get whichDisease => 'कोणता आजार?';

  @override
  String get noteOptional => 'टीप (ऐच्छिक)';

  @override
  String get saveResult => 'निकाल जतन करा';

  @override
  String get resultSaved => 'निकाल जतन केला';

  @override
  String get samplesToCollect => 'घ्यायचे नमुने';

  @override
  String get samplesAtLab => 'प्रयोगशाळेतील नमुने';

  @override
  String get noSamplesToCollect =>
      'कोणताही नमुना घ्यायचा नाही. पशुवैद्यक मागतील तेव्हा इथे दिसेल.';

  @override
  String get cameraNotAllowed => 'कॅमेऱ्याला परवानगी नाही. कोड लिहा.';

  @override
  String get sampleStatusRequested => 'घ्यायचा आहे';

  @override
  String get sampleStatusCollected => 'प्रयोगशाळेकडे जात आहे';

  @override
  String get sampleStatusReceived => 'निकालाची वाट';

  @override
  String get sampleStatusResulted => 'निकाल तयार';

  @override
  String get messageLabel => 'संदेश';

  @override
  String radiusKm(String km) {
    return 'त्रिज्या: $km किमी';
  }

  @override
  String willReach(int farmers, int villages) {
    return '$villages गावांतील $farmers शेतकऱ्यांपर्यंत पोहोचेल';
  }

  @override
  String get advisoryPreview => 'पूर्वावलोकन';

  @override
  String advisorySentTo(int count) {
    return 'सूचना $count शेतकऱ्यांना पाठवली';
  }

  @override
  String get tapMapToMove => 'केंद्र बदलण्यासाठी नकाशावर टॅप करा.';

  @override
  String get villageInMessage => 'संदेशातील गाव';

  @override
  String get inAppOnly => 'अॅपच्या इनबॉक्समध्ये पाठवले. एसएमएस सुरू नाही.';

  @override
  String get uploadPhoto => 'गॅलरीतून फोटो निवडा';

  @override
  String hoursShort(int count) {
    return '$count तास';
  }

  @override
  String get photoChecking => 'फोटो याच फोनवर तपासला जात आहे';

  @override
  String get photoLooksLsd =>
      'फोटो लम्पी स्किन आजारासारखा दिसतो. फक्त संशय आहे.';

  @override
  String get photoLooksHealthy => 'फोटो लम्पी स्किन आजारासारखा दिसत नाही.';

  @override
  String get photoUnclear =>
      'फोटो स्पष्ट नाही. दिवसाच्या उजेडात, त्वचेच्या जवळून पुन्हा घ्या.';

  @override
  String get photoCheckFailed =>
      'हा फोटो तपासता आला नाही. फोटो अहवालासोबत तरीही पाठवला जाईल.';

  @override
  String get askLumps =>
      'फोटोमध्ये त्वचेवर गाठी दिसतात. तुम्हाला त्वचेवर गाठी दिसल्या का?';

  @override
  String get askLumpsYes => 'हो, जोडा';

  @override
  String get askLumpsNo => 'नाही';

  @override
  String photoResultLine(int percent) {
    return 'फोटो: $percent% लम्पी स्किन आजारासारखा';
  }

  @override
  String get aboutAi => 'एआय बद्दल';

  @override
  String get aboutAiIntro =>
      'पशुसेतु फक्त संभाव्य आजार सांगतो. तो निदान करत नाही. पशुवैद्य किंवा प्रयोगशाळा खात्री करतील.';

  @override
  String get aboutRulesTitle => '1. लक्षणांचे नियम';

  @override
  String aboutRulesBody(int count) {
    return '$count आजारांचे नियम, अधिकृत केस व्याख्यांवरून लिहिलेले. हेच नियम फोनवर आणि सर्व्हरवर चालतात, आणि सामायिक चाचणी प्रकरणे दोन्ही एकच उत्तर देतात हे सिद्ध करतात.';
  }

  @override
  String get aboutPhotoTitle => '2. लम्पी स्किन आजारासाठी फोटो तपासणी';

  @override
  String aboutPhotoBody(int imagePercent, int rulesPercent) {
    return 'एक लहान फोटो मॉडेल याच फोनवर, इंटरनेटशिवाय, फक्त गाय आणि म्हशीसाठी चालते. लम्पी स्किन आजारात फोटोचा वाटा $imagePercent% आणि तुम्ही निवडलेल्या लक्षणांचा $rulesPercent% आहे.';
  }

  @override
  String get aboutDistrictTitle => '3. जिल्ह्याची देखरेख';

  @override
  String get aboutDistrictBody =>
      'सर्व्हर प्रत्येक अहवाल पुन्हा तपासतो आणि जवळच्या गावांतील सारख्या प्रकरणांचे गट शोधतो, म्हणजे अधिकाऱ्यांना साथ लवकर दिसते.';

  @override
  String get aboutTestResults => 'फोटो मॉडेलच्या चाचणीचे निकाल';

  @override
  String aboutTestedOn(int count) {
    return '$count अशा फोटोंवर जे मॉडेलने शिकताना पाहिले नाहीत.';
  }

  @override
  String get aboutAccuracy => 'एकूण बरोबर';

  @override
  String get aboutPrecision => 'लम्पी स्किन आजार म्हणतो तेव्हा बरोबर';

  @override
  String get aboutRecall => 'लम्पी स्किन आजाराचे फोटो जे तो ओळखतो';

  @override
  String aboutDataset(String name, String licence) {
    return 'फोटो: $name ($licence).';
  }

  @override
  String get aboutLimits => 'माहीत असलेल्या मर्यादा';

  @override
  String get aboutVersions => 'आवृत्त्या';

  @override
  String get aboutNoModel => 'या ॲपमध्ये फोटो मॉडेल नाही.';

  @override
  String get speakInstead => 'बोलून सांगा';

  @override
  String get voicePreparing => 'मायक्रोफोन सुरू होत आहे';

  @override
  String get voiceListening => 'ऐकत आहोत. जे दिसते ते सांगा.';

  @override
  String get voiceExample =>
      'उदा.: \"गायीला ताप आला आहे आणि अंगावर गाठी आहेत\"';

  @override
  String get voiceStop => 'थांबवा';

  @override
  String get voiceHeard => 'आम्ही ऐकले';

  @override
  String get voiceCorrect => 'बरोबर आहे? जे चुकीचे आहे ते काढा.';

  @override
  String get voiceNothing =>
      'कोणतेही लक्षण समजले नाही. पुन्हा बोला, किंवा लक्षणे निवडा.';

  @override
  String get voiceUnavailable =>
      'या फोनवर बोलून लिहिणे उपलब्ध नाही. लक्षणे निवडा.';

  @override
  String get voiceNoPermission =>
      'मायक्रोफोनची परवानगी नाही. लक्षणे निवडा, किंवा फोनच्या सेटिंगमध्ये मायक्रोफोन सुरू करा.';

  @override
  String voiceFallback(String language) {
    return 'या फोनवर $language आवाज ओळख नाही, म्हणून इंग्रजीत ऐकत आहोत.';
  }

  @override
  String get voiceUse => 'हे जोडा';

  @override
  String get voiceAgain => 'पुन्हा बोला';

  @override
  String voiceAnimal(String name) {
    return 'प्राणी: $name';
  }

  @override
  String voiceSickCount(int count) {
    return '$count आजारी';
  }

  @override
  String voiceDeadCount(int count) {
    return '$count मेले';
  }

  @override
  String voiceTotalCount(int count) {
    return 'एकूण $count';
  }

  @override
  String get alertSpike => 'असामान्य वाढ';

  @override
  String get escalatedBadge => 'पुढे पाठवले';

  @override
  String get escalatedToBlock =>
      'वेळेत उत्तर नाही: तालुका पशुवैद्यांकडे पाठवले';

  @override
  String get escalatedToDistrict =>
      'वेळेत उत्तर नाही: जिल्हा अधिकाऱ्यांकडे पाठवले';

  @override
  String escalatedCount(int count) {
    return '$count पुढे पाठवले, उत्तर बाकी';
  }

  @override
  String get tabRisk => 'धोका';

  @override
  String get riskHigh => 'जास्त धोका';

  @override
  String get riskMedium => 'मध्यम धोका';

  @override
  String get riskLow => 'कमी धोका';

  @override
  String riskWhy(String reasons) {
    return 'का: $reasons';
  }

  @override
  String riskFactorSeason(int percent) {
    return 'ऋतू $percent%';
  }

  @override
  String riskFactorWeather(int percent) {
    return 'हवामान $percent%';
  }

  @override
  String riskFactorNearby(int percent) {
    return 'जवळची प्रकरणे $percent%';
  }

  @override
  String riskFactorImmunity(int percent) {
    return 'लसीकरणातील तूट $percent%';
  }

  @override
  String riskNearbyCases(int count, int km, int days) {
    return '$days दिवसांत $km किमीच्या आत $count संशयित प्रकरणे';
  }

  @override
  String riskCoverage(int percent) {
    return '$percent% जनावरांचे लसीकरण';
  }

  @override
  String get riskWeatherNotModelled =>
      'या आजारासाठी हवामानाचा परिणाम धरलेला नाही';

  @override
  String get riskWeatherSeeded =>
      'हवामान साठवलेल्या हंगामी आकड्यांवरून, थेट नाही';

  @override
  String districtCoverage(int percent) {
    return 'जिल्ह्यातील लसीकरण: $percent%';
  }

  @override
  String get herdsTitle => 'कळप आणि लसी';

  @override
  String get openHerds => 'सर्व जनावरे आणि लसी';

  @override
  String get vaccinatedToday => 'आज लस दिली';

  @override
  String get chooseVaccine => 'आज कोणती लस दिली?';

  @override
  String vaccinationRecorded(String vaccine, int count, String date) {
    return '$count जनावरांसाठी $vaccine नोंदवली. पुढील लस $date.';
  }

  @override
  String get vaccinationFailed =>
      'जतन झाले नाही. सिग्नल तपासून पुन्हा प्रयत्न करा.';

  @override
  String get vaccinationHistory => 'लसीकरण';

  @override
  String get noVaccinations => 'अजून कोणतीही लस नोंदवलेली नाही.';

  @override
  String givenOn(String date) {
    return '$date रोजी दिली';
  }

  @override
  String nextDueLine(String vaccine, String date) {
    return 'पुढील $vaccine: $date';
  }

  @override
  String overdueLine(String vaccine, String date) {
    return '$vaccine $date पासून बाकी';
  }

  @override
  String animalCount(int count) {
    return '$count जनावरे';
  }

  @override
  String ageMonths(int months) {
    return '$months महिन्यांचे';
  }

  @override
  String get markCollected => 'गोळा केला';

  @override
  String get sampleStatusRequestedLab => 'गोळा करणे बाकी';
}
