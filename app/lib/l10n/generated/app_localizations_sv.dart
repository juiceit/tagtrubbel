// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'Tågtrubbel';

  @override
  String get homeTitle => 'Mina tåg';

  @override
  String get noSubscriptions => 'Inga tåg tillagda ännu';

  @override
  String get noSubscriptionsHint =>
      'Tryck + för att lägga till ett tåg att bevaka';

  @override
  String get addSubscription => 'Lägg till tåg';

  @override
  String get editSubscription => 'Redigera tåg';

  @override
  String get station => 'Station';

  @override
  String get searchStation => 'Sök station...';

  @override
  String get direction => 'Riktning';

  @override
  String get selectDirection => 'Välj riktning';

  @override
  String get departureTime => 'Avgångstid';

  @override
  String get activeDays => 'Aktiva dagar';

  @override
  String get monday => 'Mån';

  @override
  String get tuesday => 'Tis';

  @override
  String get wednesday => 'Ons';

  @override
  String get thursday => 'Tor';

  @override
  String get friday => 'Fre';

  @override
  String get saturday => 'Lör';

  @override
  String get sunday => 'Sön';

  @override
  String get save => 'Spara';

  @override
  String get delete => 'Ta bort';

  @override
  String get cancel => 'Avbryt';

  @override
  String get enabled => 'Aktiverad';

  @override
  String get paused => 'Pausad';

  @override
  String get settings => 'Inställningar';

  @override
  String get language => 'Språk';

  @override
  String get languageSystem => 'Systemstandard';

  @override
  String get languageSwedish => 'Svenska';

  @override
  String get languageEnglish => 'English';

  @override
  String get notifications => 'Aviseringar';

  @override
  String get privacy => 'Integritet';

  @override
  String get privacyPolicy => 'Integritetspolicy';

  @override
  String get deleteAllData => 'Radera all min data';

  @override
  String get deleteAllDataConfirm =>
      'Detta raderar permanent din enhet och alla prenumerationer från servern. Det går inte att ångra.';

  @override
  String get about => 'Om';

  @override
  String get aboutDescription =>
      'Tågtrubbel bevakar svenska tåg och meddelar dig vid förseningar eller inställda avgångar.';

  @override
  String get statusOnTime => 'I tid';

  @override
  String get statusWarning => 'Möjliga förseningar';

  @override
  String get statusDelayed => 'Försenad';

  @override
  String get statusCancelled => 'Inställt';

  @override
  String get statusPaused => 'Pausad';

  @override
  String get statusUnknown => 'Okänd';

  @override
  String get warningMessage =>
      'Störningar på sträckan — din avgång kan bli försenad';

  @override
  String delayedMinutes(int minutes) {
    return '$minutes min sen';
  }

  @override
  String get confirmDelete =>
      'Är du säker på att du vill ta bort denna bevakning?';

  @override
  String get errorNoApiKey => 'Servern är inte konfigurerad. Kontakta support.';

  @override
  String get errorNetwork => 'Kunde inte ansluta till servern';

  @override
  String get pullToRefresh => 'Dra för att uppdatera';
}
