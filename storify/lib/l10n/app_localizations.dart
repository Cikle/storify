import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('de'),
    Locale('en')
  ];

  /// App-Titel
  ///
  /// In de, this message translates to:
  /// **'Storify'**
  String get appTitle;

  /// Navigation: Dashboard-Tab
  ///
  /// In de, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// Navigation: Inventar-Tab
  ///
  /// In de, this message translates to:
  /// **'Inventar'**
  String get navInventory;

  /// Navigation: Standorte-Tab
  ///
  /// In de, this message translates to:
  /// **'Standorte'**
  String get navLocations;

  /// Navigation: Einstellungen-Tab
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get navSettings;

  /// Speichern-Button
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get btnSave;

  /// Erstellen-Button
  ///
  /// In de, this message translates to:
  /// **'Erstellen'**
  String get btnCreate;

  /// Löschen-Button
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get btnDelete;

  /// Abbrechen-Button
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get btnCancel;

  /// Bearbeiten-Button
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get btnEdit;

  /// Verbindungstest-Button
  ///
  /// In de, this message translates to:
  /// **'Verbindung prüfen'**
  String get btnCheckConnection;

  /// App öffnen-Button nach Setup
  ///
  /// In de, this message translates to:
  /// **'App öffnen'**
  String get btnOpenApp;

  /// Feldbezeichnung: Artikelname
  ///
  /// In de, this message translates to:
  /// **'Bezeichnung'**
  String get fieldName;

  /// Feldbezeichnung: Beschreibung
  ///
  /// In de, this message translates to:
  /// **'Beschreibung'**
  String get fieldDescription;

  /// Feldbezeichnung: Kategorie
  ///
  /// In de, this message translates to:
  /// **'Kategorie'**
  String get fieldCategory;

  /// Feldbezeichnung: Barcode
  ///
  /// In de, this message translates to:
  /// **'Barcode / QR-Code'**
  String get fieldBarcode;

  /// Feldbezeichnung: Lagerbestand
  ///
  /// In de, this message translates to:
  /// **'Bestand'**
  String get fieldStock;

  /// Feldbezeichnung: Standort
  ///
  /// In de, this message translates to:
  /// **'Standort'**
  String get fieldLocation;

  /// Feldbezeichnung: Ablaufdatum
  ///
  /// In de, this message translates to:
  /// **'Ablaufdatum (optional)'**
  String get fieldExpiry;

  /// Feldbezeichnung: API-Basis-URL
  ///
  /// In de, this message translates to:
  /// **'API-URL'**
  String get fieldApiUrl;

  /// Feldbezeichnung: API-Schlüssel
  ///
  /// In de, this message translates to:
  /// **'API-Key'**
  String get fieldApiKey;

  /// Platzhalter wenn kein Ablaufdatum gesetzt
  ///
  /// In de, this message translates to:
  /// **'Kein Datum'**
  String get labelNoDate;

  /// Stückzahl
  ///
  /// In de, this message translates to:
  /// **'{count} Stk.'**
  String labelPieces(int count);

  /// Artikelanzahl
  ///
  /// In de, this message translates to:
  /// **'{count} Artikel'**
  String labelItems(int count);

  /// Standortanzahl
  ///
  /// In de, this message translates to:
  /// **'{count} Standorte'**
  String labelLocations(int count);

  /// Dashboard-Abschnitt: Kritische Artikel
  ///
  /// In de, this message translates to:
  /// **'Kritische Artikel'**
  String get sectionLowStock;

  /// Dashboard-Abschnitt: Ablaufende Artikel
  ///
  /// In de, this message translates to:
  /// **'Bald ablaufend / Abgelaufen'**
  String get sectionExpiring;

  /// Dashboard-Abschnitt: Übersicht
  ///
  /// In de, this message translates to:
  /// **'Übersicht'**
  String get sectionOverview;

  /// Offline-Banner-Text
  ///
  /// In de, this message translates to:
  /// **'Offline – Änderungen werden synchronisiert, sobald die Verbindung wiederhergestellt ist.'**
  String get bannerOffline;

  /// Low-Stock-Warnbanner
  ///
  /// In de, this message translates to:
  /// **'Bestand unter Mindestwert!'**
  String get bannerLowStock;

  /// Abgelaufen-Banner
  ///
  /// In de, this message translates to:
  /// **'Abgelaufen!'**
  String get bannerExpired;

  /// Bald-ablaufend-Badge
  ///
  /// In de, this message translates to:
  /// **'Läuft bald ab'**
  String get bannerExpiringSoon;

  /// Anzahl ausstehender Sync-Operationen
  ///
  /// In de, this message translates to:
  /// **'{count} ausstehend'**
  String syncPending(int count);

  /// Dialog-Titel: Artikel löschen
  ///
  /// In de, this message translates to:
  /// **'Artikel löschen?'**
  String get deleteItemTitle;

  /// Dialog-Text: Artikel löschen
  ///
  /// In de, this message translates to:
  /// **'Diesen Artikel wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.'**
  String get deleteItemBody;

  /// Dialog-Titel: Standort löschen
  ///
  /// In de, this message translates to:
  /// **'Standort löschen?'**
  String get deleteLocationTitle;

  /// Dialog-Text: Standort löschen
  ///
  /// In de, this message translates to:
  /// **'Diesen Standort wirklich löschen? Artikel an diesem Standort müssen zuerst umgezogen werden.'**
  String get deleteLocationBody;

  /// Barcode-Match-Sheet Titel
  ///
  /// In de, this message translates to:
  /// **'Barcode bereits vorhanden'**
  String get barcodeAlreadyExists;

  /// Scan-Aktion: Bestand erhöhen
  ///
  /// In de, this message translates to:
  /// **'+1 Bestand'**
  String get actionAddStock;

  /// Scan-Aktion: Bestand verringern
  ///
  /// In de, this message translates to:
  /// **'-1 Bestand'**
  String get actionSubtractStock;

  /// Scan-Aktion: Standort wechseln
  ///
  /// In de, this message translates to:
  /// **'Transferieren'**
  String get actionTransfer;

  /// Scan-Aktion: Neuer Standort für Artikel
  ///
  /// In de, this message translates to:
  /// **'Neuer Standort'**
  String get actionNewLocation;

  /// Scan-Aktion: Neuen Artikel erstellen
  ///
  /// In de, this message translates to:
  /// **'Trotzdem neu erstellen'**
  String get actionCreateNew;

  /// Transfer-Sheet Titel
  ///
  /// In de, this message translates to:
  /// **'Zu welchem Standort transferieren?'**
  String get transferTitle;

  /// Einstellungen-Abschnitt: API
  ///
  /// In de, this message translates to:
  /// **'API-Verbindung'**
  String get settingsSectionApi;

  /// Einstellungen-Abschnitt: Design
  ///
  /// In de, this message translates to:
  /// **'Design'**
  String get settingsSectionTheme;

  /// Einstellungen-Abschnitt: Sprache
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get settingsSectionLanguage;

  /// Einstellungen-Abschnitt: Konten
  ///
  /// In de, this message translates to:
  /// **'Konten'**
  String get settingsSectionAccounts;

  /// Einstellungen-Abschnitt: Daten
  ///
  /// In de, this message translates to:
  /// **'Daten'**
  String get settingsSectionData;

  /// Einstellungen: Konten verwalten
  ///
  /// In de, this message translates to:
  /// **'Konten verwalten'**
  String get settingsManageAccounts;

  /// Einstellungen: Export/Import
  ///
  /// In de, this message translates to:
  /// **'Exportieren / Importieren'**
  String get settingsExportImport;

  /// Theme-Option: Systemstandard
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Theme-Option: Helles Design
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get themeLight;

  /// Theme-Option: Dunkles Design
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get themeDark;

  /// Sprache: Deutsch
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// Sprache: Englisch
  ///
  /// In de, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Konten-Screen Titel
  ///
  /// In de, this message translates to:
  /// **'Konten'**
  String get accountsTitle;

  /// Button: Konto hinzufügen
  ///
  /// In de, this message translates to:
  /// **'Konto hinzufügen'**
  String get accountsAdd;

  /// Badge: Aktives Konto
  ///
  /// In de, this message translates to:
  /// **'Aktiv'**
  String get accountsActive;

  /// Button: Konto wechseln
  ///
  /// In de, this message translates to:
  /// **'Zu diesem Konto wechseln'**
  String get accountsSwitch;

  /// Button: Konto löschen
  ///
  /// In de, this message translates to:
  /// **'Konto löschen'**
  String get accountsDelete;

  /// Dialog: Konto löschen bestätigen
  ///
  /// In de, this message translates to:
  /// **'Konto wirklich löschen?'**
  String get accountsDeleteConfirm;

  /// Feld: Kontoname
  ///
  /// In de, this message translates to:
  /// **'Kontoname'**
  String get accountNameField;

  /// Export-Screen Titel
  ///
  /// In de, this message translates to:
  /// **'Exportieren / Importieren'**
  String get exportTitle;

  /// Button: CSV exportieren
  ///
  /// In de, this message translates to:
  /// **'CSV exportieren'**
  String get exportCsv;

  /// CSV-Export Beschreibung
  ///
  /// In de, this message translates to:
  /// **'Für Excel und andere Tabellenkalkulationen'**
  String get exportCsvDesc;

  /// Button: PDF exportieren
  ///
  /// In de, this message translates to:
  /// **'PDF-Bericht exportieren'**
  String get exportPdf;

  /// PDF-Export Beschreibung
  ///
  /// In de, this message translates to:
  /// **'Druckbarer Inventarbericht'**
  String get exportPdfDesc;

  /// Button: CSV importieren
  ///
  /// In de, this message translates to:
  /// **'CSV importieren'**
  String get importCsv;

  /// CSV-Import Beschreibung
  ///
  /// In de, this message translates to:
  /// **'Artikel aus CSV-Datei importieren'**
  String get importCsvDesc;

  /// Import-Vorschau Dialog Titel
  ///
  /// In de, this message translates to:
  /// **'Vorschau'**
  String get importPreviewTitle;

  /// Import bestätigen
  ///
  /// In de, this message translates to:
  /// **'Importieren'**
  String get importConfirm;

  /// Import-Ergebnis
  ///
  /// In de, this message translates to:
  /// **'{created} erstellt, {updated} aktualisiert'**
  String importSuccess(int created, int updated);

  /// Fehlermeldung: Speichern
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Speichern.'**
  String get errorSave;

  /// Fehlermeldung: Löschen
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Löschen.'**
  String get errorDelete;

  /// Fehlermeldung: Verbindung
  ///
  /// In de, this message translates to:
  /// **'Verbindung fehlgeschlagen.'**
  String get errorConnection;

  /// Erfolgsmeldung: Gespeichert
  ///
  /// In de, this message translates to:
  /// **'Erfolgreich gespeichert.'**
  String get successSave;

  /// Erfolgsmeldung: Gelöscht
  ///
  /// In de, this message translates to:
  /// **'Erfolgreich gelöscht.'**
  String get successDelete;

  /// Erfolgsmeldung: Transfer
  ///
  /// In de, this message translates to:
  /// **'Erfolgreich transferiert.'**
  String get successTransfer;

  /// Erfolgsmeldung: Verbindung
  ///
  /// In de, this message translates to:
  /// **'Verbindung erfolgreich.'**
  String get successConnection;

  /// Setup-Screen Titel
  ///
  /// In de, this message translates to:
  /// **'Storify – Inventarverwaltung'**
  String get setupTitle;

  /// Setup-Screen Untertitel
  ///
  /// In de, this message translates to:
  /// **'Bitte gib deine API-URL und deinen API-Key ein, um die App zu konfigurieren.'**
  String get setupSubtitle;

  /// Leer-Zustand: Keine Artikel
  ///
  /// In de, this message translates to:
  /// **'Keine Artikel gefunden.'**
  String get noItemsFound;

  /// Leer-Zustand: Keine Standorte
  ///
  /// In de, this message translates to:
  /// **'Keine Standorte gefunden.'**
  String get noLocationsFound;

  /// Suchfeld Platzhalter
  ///
  /// In de, this message translates to:
  /// **'Suchen...'**
  String get searchHint;

  /// Filter: Alle Kategorien
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get filterAll;

  /// Neuen Artikel erstellen
  ///
  /// In de, this message translates to:
  /// **'Neuer Artikel'**
  String get newItem;

  /// Artikel bearbeiten
  ///
  /// In de, this message translates to:
  /// **'Artikel bearbeiten'**
  String get editItem;

  /// Neuen Standort erstellen
  ///
  /// In de, this message translates to:
  /// **'Neuer Standort'**
  String get newLocation;

  /// Standort bearbeiten
  ///
  /// In de, this message translates to:
  /// **'Standort bearbeiten'**
  String get editLocation;

  /// Button: Barcode scannen
  ///
  /// In de, this message translates to:
  /// **'Barcode scannen'**
  String get scanBarcode;

  /// Scanner-Hinweistext
  ///
  /// In de, this message translates to:
  /// **'Barcode oder QR-Code in den Rahmen halten'**
  String get scanInstruction;

  /// Benachrichtigungs-Titel: Niedriger Bestand
  ///
  /// In de, this message translates to:
  /// **'Niedriger Bestand'**
  String get notificationLowStockTitle;

  /// Benachrichtigungs-Text: Bestand
  ///
  /// In de, this message translates to:
  /// **'Nur noch {count} Stück verfügbar'**
  String notificationLowStockBody(int count);

  /// Statistik-Karte: Artikelanzahl
  ///
  /// In de, this message translates to:
  /// **'Artikel'**
  String get statArticles;

  /// Statistik-Karte: Standortanzahl
  ///
  /// In de, this message translates to:
  /// **'Standorte'**
  String get statLocations;

  /// Statistik-Karte: Kritische Artikel
  ///
  /// In de, this message translates to:
  /// **'Kritisch'**
  String get statCritical;

  /// Dashboard-Abschnitt: Schnellaktionen
  ///
  /// In de, this message translates to:
  /// **'Schnellaktionen'**
  String get sectionQuickActions;

  /// Dashboard-Abschnitt: Top Standorte
  ///
  /// In de, this message translates to:
  /// **'Top Standorte'**
  String get sectionTopLocations;

  /// Dashboard-Abschnitt: Zuletzt hinzugefügt
  ///
  /// In de, this message translates to:
  /// **'Zuletzt im Inventar'**
  String get sectionRecent;

  /// Leer-Zustand: Keine kritischen Artikel
  ///
  /// In de, this message translates to:
  /// **'Keine kritischen Artikel – alles im grünen Bereich.'**
  String get noCriticalItems;

  /// Leer-Zustand: Keine ablaufenden Artikel
  ///
  /// In de, this message translates to:
  /// **'Keine ablaufenden Artikel – alles in Ordnung.'**
  String get noExpiringItems;

  /// Button: Scannen
  ///
  /// In de, this message translates to:
  /// **'Scannen'**
  String get actionScan;

  /// Settings-Screen Titel
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// Einstellungen: Über die App
  ///
  /// In de, this message translates to:
  /// **'Über die App'**
  String get settingsAbout;

  /// Einstellungen: Versionsbezeichnung
  ///
  /// In de, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// Einstellungen: API-URL Feldbezeichnung
  ///
  /// In de, this message translates to:
  /// **'API-Basis-URL'**
  String get settingsApiUrl;

  /// Einstellungen: API-Key Feldbezeichnung
  ///
  /// In de, this message translates to:
  /// **'API-Key'**
  String get settingsApiKey;

  /// Inventar-Screen Titel
  ///
  /// In de, this message translates to:
  /// **'Inventar'**
  String get inventoryTitle;

  /// Standorte-Screen Titel
  ///
  /// In de, this message translates to:
  /// **'Standorte'**
  String get locationsTitle;

  /// Anzahl Artikel an einem Standort
  ///
  /// In de, this message translates to:
  /// **'{count} Artikel'**
  String locationItemCount(int count);

  /// Ablaufdatum-Zeile: läuft ab
  ///
  /// In de, this message translates to:
  /// **'Läuft ab am {date}'**
  String expiresOn(String date);

  /// Ablaufdatum-Zeile: abgelaufen
  ///
  /// In de, this message translates to:
  /// **'Abgelaufen am {date}'**
  String expiredOn(String date);

  /// Export-Screen Abschnitt: Export
  ///
  /// In de, this message translates to:
  /// **'Exportieren'**
  String get sectionExport;

  /// Export-Screen Abschnitt: Import
  ///
  /// In de, this message translates to:
  /// **'Importieren'**
  String get sectionImport;

  /// Import-Vorschau: Anzahl gefundener Artikel
  ///
  /// In de, this message translates to:
  /// **'{count} Artikel gefunden.'**
  String importFoundItems(int count);

  /// Import-Vorschau: weitere Artikel
  ///
  /// In de, this message translates to:
  /// **'... und {count} weitere.'**
  String importMoreItems(int count);

  /// Erfolgsmeldung nach Datei-Speicherung
  ///
  /// In de, this message translates to:
  /// **'Gespeichert: {name}'**
  String savedAs(String name);

  /// Kurzer Offline-Banner auf dem Dashboard
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung – lokale Daten werden angezeigt'**
  String get offlineBannerShort;

  /// Dashboard: Noch keine Artikel
  ///
  /// In de, this message translates to:
  /// **'Noch keine Artikel erfasst.'**
  String get noItemsYet;

  /// Dashboard: Noch keine Standorte
  ///
  /// In de, this message translates to:
  /// **'Noch keine Standorte erfasst.'**
  String get noLocationsYet;

  /// Einstellungen: Speichern und Daten neu laden
  ///
  /// In de, this message translates to:
  /// **'Speichern & Neu laden'**
  String get btnSaveReload;

  /// Leer-Zustand: Keine Artikel am Standort
  ///
  /// In de, this message translates to:
  /// **'Keine Artikel an diesem Standort.'**
  String get noItemsAtLocation;

  /// Feldbezeichnung: Name des Standorts
  ///
  /// In de, this message translates to:
  /// **'Standortbezeichnung'**
  String get fieldLocationName;

  /// Suchfeld Platzhalter im Inventar
  ///
  /// In de, this message translates to:
  /// **'Artikel suchen…'**
  String get searchItemHint;

  /// Suchfeld Platzhalter in Standortliste
  ///
  /// In de, this message translates to:
  /// **'Standort suchen…'**
  String get searchLocationHint;

  /// Filter-Sheet Titel: Kategorie wählen
  ///
  /// In de, this message translates to:
  /// **'Kategorie wählen'**
  String get chooseCategory;

  /// Filter-Sheet Titel: Standort wählen
  ///
  /// In de, this message translates to:
  /// **'Standort wählen'**
  String get chooseLocation;

  /// Verbindungstest läuft
  ///
  /// In de, this message translates to:
  /// **'Prüfe…'**
  String get checkingConnection;

  /// Validierungsfehler: Pflichtfeld
  ///
  /// In de, this message translates to:
  /// **'Pflichtfeld'**
  String get fieldRequired;

  /// Validierungsfehler: Standort fehlt
  ///
  /// In de, this message translates to:
  /// **'Bitte Standort auswählen'**
  String get mustSelectLocation;

  /// Banner: Artikel abgelaufen
  ///
  /// In de, this message translates to:
  /// **'Artikel ist abgelaufen!'**
  String get bannerExpiredItem;

  /// Banner: Niedriger Bestand mit Schwellenwert
  ///
  /// In de, this message translates to:
  /// **'Niedriger Bestand – unter {threshold} Einheiten'**
  String bannerLowStockDetail(int threshold);

  /// Bestätigungstext: Artikel löschen
  ///
  /// In de, this message translates to:
  /// **'«{name}» wird unwiderruflich gelöscht.'**
  String deleteItemConfirm(String name);

  /// Transfer-Sheet: Keine anderen Standorte
  ///
  /// In de, this message translates to:
  /// **'Keine anderen Standorte vorhanden.'**
  String get noOtherLocations;

  /// Dialog-Titel: Fehler beim Speichern
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Speichern'**
  String get errorSaveTitle;

  /// Bestätigungstext: Standort löschen
  ///
  /// In de, this message translates to:
  /// **'«{name}» wird gelöscht. Artikel mit diesem Standort können nicht mehr zugeordnet werden.'**
  String deleteLocationConfirm(String name);

  /// Dialog-Titel: Transfermenge auswählen
  ///
  /// In de, this message translates to:
  /// **'Menge wählen'**
  String get transferQuantityTitle;

  /// Dialog-Untertitel: Menge bei Transfer
  ///
  /// In de, this message translates to:
  /// **'Wie viele möchtest du transferieren?'**
  String get transferQuantityHint;

  /// Button: Transfer bestätigen
  ///
  /// In de, this message translates to:
  /// **'Transferieren'**
  String get transferConfirmBtn;

  /// Toast: Gespeichert
  ///
  /// In de, this message translates to:
  /// **'Gespeichert'**
  String get toastSaved;

  /// Toast: Gelöscht
  ///
  /// In de, this message translates to:
  /// **'Gelöscht'**
  String get toastDeleted;

  /// Toast: Transferiert
  ///
  /// In de, this message translates to:
  /// **'Transferiert'**
  String get toastTransferred;

  /// Toast: Bestand geändert
  ///
  /// In de, this message translates to:
  /// **'Bestand aktualisiert'**
  String get toastStockUpdated;

  /// Toast: Fehler
  ///
  /// In de, this message translates to:
  /// **'Fehler'**
  String get toastError;

  /// Toast: Konto gewechselt
  ///
  /// In de, this message translates to:
  /// **'Konto gewechselt'**
  String get toastAccountSwitched;

  /// Toast: Konto gespeichert
  ///
  /// In de, this message translates to:
  /// **'Konto gespeichert'**
  String get toastAccountSaved;

  /// Toast: Import-Ergebnis
  ///
  /// In de, this message translates to:
  /// **'{created} neu · {updated} aktualisiert'**
  String toastImportResult(int created, int updated);

  /// Toast: Import-Fehler
  ///
  /// In de, this message translates to:
  /// **'{count} Fehler'**
  String toastImportErrors(int count);

  /// Setup-Screen Tagline unter dem Logo
  ///
  /// In de, this message translates to:
  /// **'Inventarverwaltung'**
  String get setupTagline;

  /// Setup-Screen Abschnittstitel
  ///
  /// In de, this message translates to:
  /// **'Verbindung einrichten'**
  String get setupSectionTitle;

  /// Platzhalter für API-URL
  ///
  /// In de, this message translates to:
  /// **'https://deine-domain.ch/api'**
  String get setupUrlHint;

  /// Validierungsfehler: URL fehlt
  ///
  /// In de, this message translates to:
  /// **'Bitte URL eingeben'**
  String get setupValidUrl;

  /// Validierungsfehler: URL-Schema ungültig
  ///
  /// In de, this message translates to:
  /// **'URL muss mit http:// oder https:// beginnen'**
  String get setupValidUrlHttp;

  /// Validierungsfehler: API-Key fehlt
  ///
  /// In de, this message translates to:
  /// **'Bitte API-Key eingeben'**
  String get setupValidKey;

  /// Erfolgsmeldung im Setup-Screen
  ///
  /// In de, this message translates to:
  /// **'Verbindung erfolgreich. API erreichbar.'**
  String get setupSuccessDetail;

  /// Fehlermeldung: API-Key ungültig
  ///
  /// In de, this message translates to:
  /// **'Ungültiger API-Key. Bitte Schlüssel prüfen.'**
  String get setupErrorInvalidKey;

  /// Info-Hinweis im Setup-Screen
  ///
  /// In de, this message translates to:
  /// **'URL und API-Key können jederzeit unter Einstellungen geändert werden.'**
  String get setupInfoText;
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
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
