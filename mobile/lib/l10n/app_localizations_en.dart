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

  @override
  String get stepAnimal => 'Animal';

  @override
  String get stepSigns => 'Signs';

  @override
  String get stepPhoto => 'Photo';

  @override
  String get stepCount => 'How many';

  @override
  String get stepCheck => 'Check and send';

  @override
  String get whichSpecies => 'Which animal is sick?';

  @override
  String get whichAnimal => 'Which animal? (optional)';

  @override
  String get notRegistered => 'Not registered';

  @override
  String get whereIsAnimal => 'Where is the animal?';

  @override
  String get findingLocation => 'Finding location';

  @override
  String get usingPhoneLocation => 'Using the phone\'s location';

  @override
  String get usingVillageLocation => 'Using the village location';

  @override
  String get changeVillage => 'Change village';

  @override
  String get chooseVillage => 'Choose the village';

  @override
  String get signsTitle => 'What do you see?';

  @override
  String get signsHint => 'Tap every sign you see.';

  @override
  String get photoTitle => 'Take a photo of the problem area';

  @override
  String get photoHelp =>
      'Stand close, in daylight, with the lump or sore in the middle. You can skip this.';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get retakePhoto => 'Take again';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get cameraDenied =>
      'The camera is not allowed. Allow it in the phone settings to add a photo.';

  @override
  String get howManyTitle => 'How many animals?';

  @override
  String get sickLabel => 'Sick';

  @override
  String get deadLabel => 'Dead';

  @override
  String get totalLabel => 'All animals here';

  @override
  String get onsetTitle => 'When did it start?';

  @override
  String get onsetToday => 'Today';

  @override
  String get onsetYesterday => 'Yesterday';

  @override
  String get onsetFewDays => '2 or 3 days ago';

  @override
  String get onsetLonger => 'More than 3 days';

  @override
  String get sendReport => 'Send report';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get needSignOrDeath =>
      'Choose at least one sign, or add a dead animal.';

  @override
  String get totalTooSmall =>
      'All animals cannot be fewer than sick plus dead.';

  @override
  String get noSignsChosen => 'No signs chosen';

  @override
  String get noPhoto => 'No photo';

  @override
  String get photoAdded => 'Photo added';

  @override
  String get savedOnPhone =>
      'Saved on phone. It will send by itself when there is signal.';

  @override
  String get reportSent => 'Report sent';

  @override
  String get sendingReport => 'Sending report';

  @override
  String suspectedDisease(String disease) {
    return 'Suspected: $disease';
  }

  @override
  String get noClearMatch => 'No clear disease match';

  @override
  String get noClearMatchHelp =>
      'Watch the animal. If it gets worse or others fall sick, call the vet.';

  @override
  String get unknownSyndrome =>
      'Signs do not match a known disease in this app. A vet should see this animal.';

  @override
  String get mostLikely => 'Most likely';

  @override
  String get whyResult => 'Why';

  @override
  String get doThisNow => 'Do this now';

  @override
  String callNumber(String number) {
    return 'Call $number';
  }

  @override
  String get zoonoticWarning =>
      'This disease can spread to people. Keep children away and wash hands after touching animals.';

  @override
  String get done => 'Done';

  @override
  String countSummary(int sick, int dead, int total) {
    return '$sick sick, $dead dead, $total in all';
  }

  @override
  String get tabAlerts => 'Alerts';

  @override
  String get tabCases => 'Cases';

  @override
  String get kpiActiveAlerts => 'Active alerts';

  @override
  String get kpiMedianResponse => 'Median first response';

  @override
  String get kpiSamplesPending => 'Samples pending';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get noAlerts =>
      'No active alerts. When reports cluster together, an alert appears here.';

  @override
  String updatedAt(String time) {
    return 'Updated $time';
  }

  @override
  String get alertCluster => 'Outbreak cluster';

  @override
  String get alertZoonotic => 'Can spread to people';

  @override
  String get alertMortality => 'Many deaths';

  @override
  String get acknowledge => 'Acknowledge';

  @override
  String get acknowledged => 'Acknowledged';

  @override
  String get sendAdvisory => 'Send advisory';

  @override
  String get casesInAlert => 'Cases in this alert';

  @override
  String reportedBy(String name) {
    return 'Reported by $name';
  }

  @override
  String get assignToMe => 'Assign to me';

  @override
  String get assignVet => 'Assign vet';

  @override
  String get chooseVet => 'Choose a vet';

  @override
  String get requestSample => 'Request sample';

  @override
  String get chooseSampleType => 'What sample?';

  @override
  String get sampleSkinScab => 'Skin scab';

  @override
  String get sampleBlood => 'Blood';

  @override
  String get sampleNasalSwab => 'Nose swab';

  @override
  String get sampleOralSwab => 'Mouth swab';

  @override
  String get sampleTissue => 'Tissue';

  @override
  String get sampleCarcassSwab => 'Carcass swab';

  @override
  String get sampleOther => 'Other';

  @override
  String get markUnderTreatment => 'Mark under treatment';

  @override
  String get resolveCase => 'Resolve';

  @override
  String get ruleOut => 'Rule out';

  @override
  String labConfirmed(String disease) {
    return 'Lab confirmed: $disease';
  }

  @override
  String get whyAppSuspected => 'Why the app suspected this';

  @override
  String get timelineTitle => 'Timeline';

  @override
  String get samplesTitle => 'Samples';

  @override
  String get showQrHint =>
      'Show this code to the pashu sevak, or write it on the sample tube.';

  @override
  String get reportPhoto => 'Photo';

  @override
  String get scanSample => 'Scan sample';

  @override
  String get typeCodeInstead => 'Or type the code';

  @override
  String get continueButton2 => 'Continue';

  @override
  String get sampleCollected => 'Sample collected';

  @override
  String get sampleReceived => 'Sample received at the lab';

  @override
  String get enterResult => 'Enter result';

  @override
  String get resultPositive => 'Positive';

  @override
  String get resultNegative => 'Negative';

  @override
  String get resultInconclusive => 'Inconclusive';

  @override
  String get whichDisease => 'Which disease?';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get saveResult => 'Save result';

  @override
  String get resultSaved => 'Result saved';

  @override
  String get samplesToCollect => 'Samples to collect';

  @override
  String get samplesAtLab => 'Samples at the lab';

  @override
  String get noSamplesToCollect =>
      'No samples to collect. When a vet requests one, it appears here.';

  @override
  String get cameraNotAllowed =>
      'The camera is not allowed. Type the code instead.';

  @override
  String get sampleStatusRequested => 'To collect';

  @override
  String get sampleStatusCollected => 'On the way to the lab';

  @override
  String get sampleStatusReceived => 'Waiting for result';

  @override
  String get sampleStatusResulted => 'Result ready';

  @override
  String get messageLabel => 'Message';

  @override
  String radiusKm(String km) {
    return 'Radius: $km km';
  }

  @override
  String willReach(int farmers, int villages) {
    return 'Will reach $farmers farmers in $villages villages';
  }

  @override
  String get advisoryPreview => 'Preview';

  @override
  String advisorySentTo(int count) {
    return 'Advisory sent to $count farmers';
  }

  @override
  String get tapMapToMove => 'Tap the map to move the centre.';

  @override
  String get villageInMessage => 'Village named in the message';

  @override
  String get inAppOnly => 'Sent to the in-app inbox. SMS is not set up.';

  @override
  String get uploadPhoto => 'Upload from gallery';

  @override
  String hoursShort(int count) {
    return '$count h';
  }

  @override
  String get photoChecking => 'Checking the photo on this phone';

  @override
  String get photoLooksLsd =>
      'The photo looks like lumpy skin disease. Suspected only.';

  @override
  String get photoLooksHealthy =>
      'The photo does not look like lumpy skin disease.';

  @override
  String get photoUnclear =>
      'Unclear photo. Try again in daylight, closer to the skin.';

  @override
  String get photoCheckFailed =>
      'Could not check this photo. It is still sent with the report.';

  @override
  String get askLumps =>
      'The photo looks like it has skin lumps. Did you see lumps on the skin?';

  @override
  String get askLumpsYes => 'Yes, add it';

  @override
  String get askLumpsNo => 'No';

  @override
  String photoResultLine(int percent) {
    return 'Photo: $percent% like lumpy skin disease';
  }

  @override
  String get aboutAi => 'About the AI';

  @override
  String get aboutAiIntro =>
      'PashuSetu suggests a suspected disease. It never diagnoses. A vet or lab must confirm.';

  @override
  String get aboutRulesTitle => '1. Symptom rules';

  @override
  String aboutRulesBody(int count) {
    return 'Rules for $count diseases, written from official case definitions. The same rules run on this phone and on the server, and shared test cases prove both give the same answer.';
  }

  @override
  String get aboutPhotoTitle => '2. Photo check for lumpy skin disease';

  @override
  String aboutPhotoBody(int imagePercent, int rulesPercent) {
    return 'A small image model runs on this phone, without internet, for cattle and buffalo only. For lumpy skin disease, the photo counts $imagePercent% and the signs you tick count $rulesPercent%.';
  }

  @override
  String get aboutDistrictTitle => '3. District watch';

  @override
  String get aboutDistrictBody =>
      'The server checks every report again and looks for groups of similar cases in nearby villages, so officers see an outbreak early.';

  @override
  String get aboutTestResults => 'Photo model test results';

  @override
  String aboutTestedOn(int count) {
    return 'On $count photos the model never saw while learning.';
  }

  @override
  String get aboutAccuracy => 'Right overall';

  @override
  String get aboutPrecision => 'Right when it says lumpy skin disease';

  @override
  String get aboutRecall => 'Lumpy skin disease photos it finds';

  @override
  String aboutDataset(String name, String licence) {
    return 'Photos: $name ($licence).';
  }

  @override
  String get aboutLimits => 'Known limits';

  @override
  String get aboutVersions => 'Versions';

  @override
  String get aboutNoModel => 'This app build has no photo model.';
}
