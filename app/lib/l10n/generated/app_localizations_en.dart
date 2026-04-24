// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tågtrubbel';

  @override
  String get homeTitle => 'My Trains';

  @override
  String get noSubscriptions => 'No trains added yet';

  @override
  String get noSubscriptionsHint => 'Tap + to add a train to monitor';

  @override
  String get addSubscription => 'Add Train';

  @override
  String get editSubscription => 'Edit Train';

  @override
  String get station => 'Station';

  @override
  String get searchStation => 'Search station...';

  @override
  String get direction => 'Direction';

  @override
  String get selectDirection => 'Select direction';

  @override
  String get departureTime => 'Departure Time';

  @override
  String get activeDays => 'Active Days';

  @override
  String get monday => 'Mon';

  @override
  String get tuesday => 'Tue';

  @override
  String get wednesday => 'Wed';

  @override
  String get thursday => 'Thu';

  @override
  String get friday => 'Fri';

  @override
  String get saturday => 'Sat';

  @override
  String get sunday => 'Sun';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get enabled => 'Enabled';

  @override
  String get paused => 'Paused';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System Default';

  @override
  String get languageSwedish => 'Svenska';

  @override
  String get languageEnglish => 'English';

  @override
  String get notifications => 'Notifications';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get deleteAllData => 'Delete All My Data';

  @override
  String get deleteAllDataConfirm =>
      'This will permanently delete your device and all subscriptions from the server. This cannot be undone.';

  @override
  String get about => 'About';

  @override
  String get aboutDescription =>
      'Tågtrubbel monitors Swedish trains and notifies you when there are delays or cancellations.';

  @override
  String get statusOnTime => 'On time';

  @override
  String get statusWarning => 'Possible delays';

  @override
  String get statusDelayed => 'Delayed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusUnknown => 'Unknown';

  @override
  String get warningMessage =>
      'Disruptions on the line — your departure may be delayed';

  @override
  String delayedMinutes(int minutes) {
    return '$minutes min late';
  }

  @override
  String get confirmDelete =>
      'Are you sure you want to delete this subscription?';

  @override
  String get errorNoApiKey => 'Backend not configured. Contact support.';

  @override
  String get errorNetwork => 'Could not connect to server';

  @override
  String get pullToRefresh => 'Pull to refresh';
}
