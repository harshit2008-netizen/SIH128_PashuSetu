import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'PashuSetu'**
  String get appName;

  /// No description provided for @notDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'This is not a diagnosis. A vet or lab must confirm.'**
  String get notDiagnosis;

  /// No description provided for @roleFarmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get roleFarmer;

  /// No description provided for @rolePashuSevak.
  ///
  /// In en, this message translates to:
  /// **'Pashu sevak'**
  String get rolePashuSevak;

  /// No description provided for @roleVet.
  ///
  /// In en, this message translates to:
  /// **'Vet'**
  String get roleVet;

  /// No description provided for @roleLab.
  ///
  /// In en, this message translates to:
  /// **'Lab'**
  String get roleLab;

  /// No description provided for @roleDistrictOfficer.
  ///
  /// In en, this message translates to:
  /// **'District officer'**
  String get roleDistrictOfficer;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Who are you?'**
  String get loginTitle;

  /// No description provided for @loginPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get loginPhoneLabel;

  /// No description provided for @loginOtpLabel.
  ///
  /// In en, this message translates to:
  /// **'OTP'**
  String get loginOtpLabel;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginButton;

  /// No description provided for @demoOtpNote.
  ///
  /// In en, this message translates to:
  /// **'Demo login. OTP is 123456.'**
  String get demoOtpNote;

  /// No description provided for @loginWorking.
  ///
  /// In en, this message translates to:
  /// **'Logging in'**
  String get loginWorking;

  /// No description provided for @serverUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check that the laptop is on the same Wi-Fi, then try again.'**
  String get serverUnreachable;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Namaste, {name}'**
  String greeting(String name);

  /// No description provided for @reportActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a sick animal'**
  String get reportActionTitle;

  /// No description provided for @reportActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Speak or tap the signs'**
  String get reportActionSubtitle;

  /// No description provided for @alertsNearYou.
  ///
  /// In en, this message translates to:
  /// **'Alerts near you'**
  String get alertsNearYou;

  /// No description provided for @noAlertsNearYou.
  ///
  /// In en, this message translates to:
  /// **'No alerts near you. When a vet sends an advisory, it appears here.'**
  String get noAlertsNearYou;

  /// No description provided for @myAnimals.
  ///
  /// In en, this message translates to:
  /// **'My animals'**
  String get myAnimals;

  /// No description provided for @noAnimals.
  ///
  /// In en, this message translates to:
  /// **'No animals registered yet. Your pashu sevak can register them with ear tags.'**
  String get noAnimals;

  /// No description provided for @vaccineDueOn.
  ///
  /// In en, this message translates to:
  /// **'{vaccine} vaccine due on {date}'**
  String vaccineDueOn(String vaccine, String date);

  /// No description provided for @myReports.
  ///
  /// In en, this message translates to:
  /// **'My reports'**
  String get myReports;

  /// No description provided for @noReports.
  ///
  /// In en, this message translates to:
  /// **'No reports yet. When you report a sick animal, it appears here.'**
  String get noReports;

  /// No description provided for @vaccinationsDue.
  ///
  /// In en, this message translates to:
  /// **'Vaccinations due'**
  String get vaccinationsDue;

  /// No description provided for @noVaccinationsDue.
  ///
  /// In en, this message translates to:
  /// **'No vaccinations due in the next 30 days.'**
  String get noVaccinationsDue;

  /// No description provided for @animalsInArea.
  ///
  /// In en, this message translates to:
  /// **'Animals in my area'**
  String get animalsInArea;

  /// No description provided for @caseQueue.
  ///
  /// In en, this message translates to:
  /// **'Cases to act on'**
  String get caseQueue;

  /// No description provided for @noCases.
  ///
  /// In en, this message translates to:
  /// **'No open cases. When a farmer reports a sick animal, it appears here.'**
  String get noCases;

  /// No description provided for @labSamples.
  ///
  /// In en, this message translates to:
  /// **'Samples'**
  String get labSamples;

  /// No description provided for @noSamples.
  ///
  /// In en, this message translates to:
  /// **'No samples waiting. When a vet requests a sample, it appears here.'**
  String get noSamples;

  /// No description provided for @notMatched.
  ///
  /// In en, this message translates to:
  /// **'Not matched to a disease'**
  String get notMatched;

  /// No description provided for @waitingForVet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a vet'**
  String get waitingForVet;

  /// No description provided for @assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Vet: {name}'**
  String assignedTo(String name);

  /// No description provided for @showingSavedData.
  ///
  /// In en, this message translates to:
  /// **'Showing data saved on this phone.'**
  String get showingSavedData;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @syncAllSent.
  ///
  /// In en, this message translates to:
  /// **'All sent'**
  String get syncAllSent;

  /// No description provided for @syncWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 waiting to send} other{{count} waiting to send}}'**
  String syncWaiting(int count);

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline, saved on phone'**
  String get syncOffline;

  /// No description provided for @severityEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get severityEmergency;

  /// No description provided for @severityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get severityUrgent;

  /// No description provided for @severityRoutine.
  ///
  /// In en, this message translates to:
  /// **'Routine'**
  String get severityRoutine;

  /// No description provided for @confidenceHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get confidenceHigh;

  /// No description provided for @confidenceModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get confidenceModerate;

  /// No description provided for @confidenceLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get confidenceLow;

  /// No description provided for @notReported.
  ///
  /// In en, this message translates to:
  /// **'Not reported: {sign}'**
  String notReported(String sign);

  /// No description provided for @photoChip.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photoChip;

  /// No description provided for @whatDoesThisMean.
  ///
  /// In en, this message translates to:
  /// **'What does this mean?'**
  String get whatDoesThisMean;

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// No description provided for @decrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get decrease;

  /// No description provided for @increase.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get increase;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @statusReported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get statusReported;

  /// No description provided for @statusTriaged.
  ///
  /// In en, this message translates to:
  /// **'Checked by the app'**
  String get statusTriaged;

  /// No description provided for @statusVetAssigned.
  ///
  /// In en, this message translates to:
  /// **'Vet assigned'**
  String get statusVetAssigned;

  /// No description provided for @statusSampleRequested.
  ///
  /// In en, this message translates to:
  /// **'Sample requested'**
  String get statusSampleRequested;

  /// No description provided for @statusSampleCollected.
  ///
  /// In en, this message translates to:
  /// **'Sample collected'**
  String get statusSampleCollected;

  /// No description provided for @statusLabReceived.
  ///
  /// In en, this message translates to:
  /// **'Lab received the sample'**
  String get statusLabReceived;

  /// No description provided for @statusLabResult.
  ///
  /// In en, this message translates to:
  /// **'Lab result'**
  String get statusLabResult;

  /// No description provided for @statusUnderTreatment.
  ///
  /// In en, this message translates to:
  /// **'Under treatment'**
  String get statusUnderTreatment;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @statusClosedRuledOut.
  ///
  /// In en, this message translates to:
  /// **'Ruled out'**
  String get statusClosedRuledOut;

  /// No description provided for @kpiOpenCases.
  ///
  /// In en, this message translates to:
  /// **'Open cases'**
  String get kpiOpenCases;

  /// No description provided for @kpiEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get kpiEmergency;

  /// No description provided for @kpiUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get kpiUrgent;

  /// No description provided for @kpiWaitingForVet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for vet'**
  String get kpiWaitingForVet;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String daysAgo(int count);

  /// No description provided for @kmAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String kmAway(String distance);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @changeRole.
  ///
  /// In en, this message translates to:
  /// **'Change role (demo)'**
  String get changeRole;

  /// No description provided for @simulateNoSignal.
  ///
  /// In en, this message translates to:
  /// **'Simulate no signal (demo)'**
  String get simulateNoSignal;

  /// No description provided for @simulateNoSignalHelp.
  ///
  /// In en, this message translates to:
  /// **'The app acts as if there is no network, so the offline path can be shown.'**
  String get simulateNoSignalHelp;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version {version}'**
  String appVersion(String version);

  /// No description provided for @engineVersion.
  ///
  /// In en, this message translates to:
  /// **'Triage engine {version}'**
  String engineVersion(String version);

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @developerOptions.
  ///
  /// In en, this message translates to:
  /// **'Developer options'**
  String get developerOptions;

  /// No description provided for @developerOptionsOn.
  ///
  /// In en, this message translates to:
  /// **'Developer options are on'**
  String get developerOptionsOn;

  /// No description provided for @apiBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'API base URL'**
  String get apiBaseUrl;

  /// No description provided for @apiBaseUrlHelp.
  ///
  /// In en, this message translates to:
  /// **'Laptop address on the same Wi-Fi, for example http://192.168.43.10:8000. With a USB cable and adb reverse, use http://127.0.0.1:8000.'**
  String get apiBaseUrlHelp;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get testConnection;

  /// No description provided for @connectionOk.
  ///
  /// In en, this message translates to:
  /// **'Server reachable'**
  String get connectionOk;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Server not reachable'**
  String get connectionFailed;

  /// No description provided for @clearLocalData.
  ///
  /// In en, this message translates to:
  /// **'Clear local data'**
  String get clearLocalData;

  /// No description provided for @clearLocalDataDone.
  ///
  /// In en, this message translates to:
  /// **'Local data cleared'**
  String get clearLocalDataDone;

  /// No description provided for @showOutbox.
  ///
  /// In en, this message translates to:
  /// **'Show outbox'**
  String get showOutbox;

  /// No description provided for @outboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'The outbox is empty.'**
  String get outboxEmpty;

  /// No description provided for @stepAnimal.
  ///
  /// In en, this message translates to:
  /// **'Animal'**
  String get stepAnimal;

  /// No description provided for @stepSigns.
  ///
  /// In en, this message translates to:
  /// **'Signs'**
  String get stepSigns;

  /// No description provided for @stepPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get stepPhoto;

  /// No description provided for @stepCount.
  ///
  /// In en, this message translates to:
  /// **'How many'**
  String get stepCount;

  /// No description provided for @stepCheck.
  ///
  /// In en, this message translates to:
  /// **'Check and send'**
  String get stepCheck;

  /// No description provided for @whichSpecies.
  ///
  /// In en, this message translates to:
  /// **'Which animal is sick?'**
  String get whichSpecies;

  /// No description provided for @whichAnimal.
  ///
  /// In en, this message translates to:
  /// **'Which animal? (optional)'**
  String get whichAnimal;

  /// No description provided for @notRegistered.
  ///
  /// In en, this message translates to:
  /// **'Not registered'**
  String get notRegistered;

  /// No description provided for @whereIsAnimal.
  ///
  /// In en, this message translates to:
  /// **'Where is the animal?'**
  String get whereIsAnimal;

  /// No description provided for @findingLocation.
  ///
  /// In en, this message translates to:
  /// **'Finding location'**
  String get findingLocation;

  /// No description provided for @usingPhoneLocation.
  ///
  /// In en, this message translates to:
  /// **'Using the phone\'s location'**
  String get usingPhoneLocation;

  /// No description provided for @usingVillageLocation.
  ///
  /// In en, this message translates to:
  /// **'Using the village location'**
  String get usingVillageLocation;

  /// No description provided for @changeVillage.
  ///
  /// In en, this message translates to:
  /// **'Change village'**
  String get changeVillage;

  /// No description provided for @chooseVillage.
  ///
  /// In en, this message translates to:
  /// **'Choose the village'**
  String get chooseVillage;

  /// No description provided for @signsTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you see?'**
  String get signsTitle;

  /// No description provided for @signsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap every sign you see.'**
  String get signsHint;

  /// No description provided for @photoTitle.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of the problem area'**
  String get photoTitle;

  /// No description provided for @photoHelp.
  ///
  /// In en, this message translates to:
  /// **'Stand close, in daylight, with the lump or sore in the middle. You can skip this.'**
  String get photoHelp;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @retakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take again'**
  String get retakePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @cameraDenied.
  ///
  /// In en, this message translates to:
  /// **'The camera is not allowed. Allow it in the phone settings to add a photo.'**
  String get cameraDenied;

  /// No description provided for @howManyTitle.
  ///
  /// In en, this message translates to:
  /// **'How many animals?'**
  String get howManyTitle;

  /// No description provided for @sickLabel.
  ///
  /// In en, this message translates to:
  /// **'Sick'**
  String get sickLabel;

  /// No description provided for @deadLabel.
  ///
  /// In en, this message translates to:
  /// **'Dead'**
  String get deadLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'All animals here'**
  String get totalLabel;

  /// No description provided for @onsetTitle.
  ///
  /// In en, this message translates to:
  /// **'When did it start?'**
  String get onsetTitle;

  /// No description provided for @onsetToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get onsetToday;

  /// No description provided for @onsetYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get onsetYesterday;

  /// No description provided for @onsetFewDays.
  ///
  /// In en, this message translates to:
  /// **'2 or 3 days ago'**
  String get onsetFewDays;

  /// No description provided for @onsetLonger.
  ///
  /// In en, this message translates to:
  /// **'More than 3 days'**
  String get onsetLonger;

  /// No description provided for @sendReport.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get sendReport;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @needSignOrDeath.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one sign, or add a dead animal.'**
  String get needSignOrDeath;

  /// No description provided for @totalTooSmall.
  ///
  /// In en, this message translates to:
  /// **'All animals cannot be fewer than sick plus dead.'**
  String get totalTooSmall;

  /// No description provided for @noSignsChosen.
  ///
  /// In en, this message translates to:
  /// **'No signs chosen'**
  String get noSignsChosen;

  /// No description provided for @noPhoto.
  ///
  /// In en, this message translates to:
  /// **'No photo'**
  String get noPhoto;

  /// No description provided for @photoAdded.
  ///
  /// In en, this message translates to:
  /// **'Photo added'**
  String get photoAdded;

  /// No description provided for @savedOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Saved on phone. It will send by itself when there is signal.'**
  String get savedOnPhone;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get reportSent;

  /// No description provided for @sendingReport.
  ///
  /// In en, this message translates to:
  /// **'Sending report'**
  String get sendingReport;

  /// No description provided for @suspectedDisease.
  ///
  /// In en, this message translates to:
  /// **'Suspected: {disease}'**
  String suspectedDisease(String disease);

  /// No description provided for @noClearMatch.
  ///
  /// In en, this message translates to:
  /// **'No clear disease match'**
  String get noClearMatch;

  /// No description provided for @noClearMatchHelp.
  ///
  /// In en, this message translates to:
  /// **'Watch the animal. If it gets worse or others fall sick, call the vet.'**
  String get noClearMatchHelp;

  /// No description provided for @unknownSyndrome.
  ///
  /// In en, this message translates to:
  /// **'Signs do not match a known disease in this app. A vet should see this animal.'**
  String get unknownSyndrome;

  /// No description provided for @mostLikely.
  ///
  /// In en, this message translates to:
  /// **'Most likely'**
  String get mostLikely;

  /// No description provided for @whyResult.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get whyResult;

  /// No description provided for @doThisNow.
  ///
  /// In en, this message translates to:
  /// **'Do this now'**
  String get doThisNow;

  /// No description provided for @callNumber.
  ///
  /// In en, this message translates to:
  /// **'Call {number}'**
  String callNumber(String number);

  /// No description provided for @zoonoticWarning.
  ///
  /// In en, this message translates to:
  /// **'This disease can spread to people. Keep children away and wash hands after touching animals.'**
  String get zoonoticWarning;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @countSummary.
  ///
  /// In en, this message translates to:
  /// **'{sick} sick, {dead} dead, {total} in all'**
  String countSummary(int sick, int dead, int total);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
