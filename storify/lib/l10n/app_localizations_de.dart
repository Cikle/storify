// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Storify';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navInventory => 'Inventar';

  @override
  String get navLocations => 'Standorte';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get btnSave => 'Speichern';

  @override
  String get btnCreate => 'Erstellen';

  @override
  String get btnDelete => 'Löschen';

  @override
  String get btnCancel => 'Abbrechen';

  @override
  String get btnEdit => 'Bearbeiten';

  @override
  String get btnCheckConnection => 'Verbindung prüfen';

  @override
  String get btnOpenApp => 'App öffnen';

  @override
  String get fieldName => 'Bezeichnung';

  @override
  String get fieldDescription => 'Beschreibung';

  @override
  String get fieldCategory => 'Kategorie';

  @override
  String get fieldBarcode => 'Barcode / QR-Code';

  @override
  String get fieldStock => 'Bestand';

  @override
  String get fieldLocation => 'Standort';

  @override
  String get fieldExpiry => 'Ablaufdatum (optional)';

  @override
  String get fieldApiUrl => 'API-URL';

  @override
  String get fieldApiKey => 'API-Key';

  @override
  String get labelNoDate => 'Kein Datum';

  @override
  String labelPieces(int count) {
    return '$count Stk.';
  }

  @override
  String labelItems(int count) {
    return '$count Artikel';
  }

  @override
  String labelLocations(int count) {
    return '$count Standorte';
  }

  @override
  String get sectionLowStock => 'Kritische Artikel';

  @override
  String get sectionExpiring => 'Bald ablaufend / Abgelaufen';

  @override
  String get sectionOverview => 'Übersicht';

  @override
  String get bannerOffline =>
      'Offline – Änderungen werden synchronisiert, sobald die Verbindung wiederhergestellt ist.';

  @override
  String get bannerLowStock => 'Bestand unter Mindestwert!';

  @override
  String get bannerExpired => 'Abgelaufen!';

  @override
  String get bannerExpiringSoon => 'Läuft bald ab';

  @override
  String syncPending(int count) {
    return '$count ausstehend';
  }

  @override
  String get deleteItemTitle => 'Artikel löschen?';

  @override
  String get deleteItemBody =>
      'Diesen Artikel wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get deleteLocationTitle => 'Standort löschen?';

  @override
  String get deleteLocationBody =>
      'Diesen Standort wirklich löschen? Artikel an diesem Standort müssen zuerst umgezogen werden.';

  @override
  String get barcodeAlreadyExists => 'Barcode bereits vorhanden';

  @override
  String get actionAddStock => '+1 Bestand';

  @override
  String get actionSubtractStock => '-1 Bestand';

  @override
  String get actionTransfer => 'Transferieren';

  @override
  String get actionNewLocation => 'Neuer Standort';

  @override
  String get actionCreateNew => 'Trotzdem neu erstellen';

  @override
  String get transferTitle => 'Zu welchem Standort transferieren?';

  @override
  String get settingsSectionApi => 'API-Verbindung';

  @override
  String get settingsSectionTheme => 'Design';

  @override
  String get settingsSectionLanguage => 'Sprache';

  @override
  String get settingsSectionAccounts => 'Konten';

  @override
  String get settingsSectionData => 'Daten';

  @override
  String get settingsManageAccounts => 'Konten verwalten';

  @override
  String get settingsExportImport => 'Exportieren / Importieren';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get accountsTitle => 'Konten';

  @override
  String get accountsAdd => 'Konto hinzufügen';

  @override
  String get accountsActive => 'Aktiv';

  @override
  String get accountsSwitch => 'Zu diesem Konto wechseln';

  @override
  String get accountsDelete => 'Konto löschen';

  @override
  String accountsDeleteConfirm(Object name) {
    return 'Konto \"$name\" wirklich löschen?';
  }

  @override
  String get accountsDeleteActive =>
      'Dies ist dein aktives Konto. Das Löschen meldet dich ab und löscht alle gespeicherten Daten.';

  @override
  String get accountsNoAccounts => 'Noch keine Konten konfiguriert.';

  @override
  String get accountsPendingTitle => 'Ausstehende Änderungen';

  @override
  String accountsPendingBody(int count) {
    return '$count Änderungen wurden noch nicht synchronisiert. Trotzdem wechseln?';
  }

  @override
  String get accountsSwitchAnyway => 'Trotzdem wechseln';

  @override
  String get accountsEditTitle => 'Konto bearbeiten';

  @override
  String get accountsAddTitle => 'Konto hinzufügen';

  @override
  String get accountsTestConnection => 'Verbindung testen';

  @override
  String get accountsUrlKeyRequired => 'URL und Key sind erforderlich.';

  @override
  String get accountsBtnAdd => 'Hinzufügen';

  @override
  String get accountNameField => 'Kontoname';

  @override
  String get exportTitle => 'Exportieren / Importieren';

  @override
  String get exportCsv => 'CSV exportieren';

  @override
  String get exportCsvDesc => 'Für Excel und andere Tabellenkalkulationen';

  @override
  String get exportPdf => 'PDF-Bericht exportieren';

  @override
  String get exportPdfDesc => 'Druckbarer Inventarbericht';

  @override
  String get importCsv => 'CSV importieren';

  @override
  String get importCsvDesc => 'Artikel aus CSV-Datei importieren';

  @override
  String get importPreviewTitle => 'Vorschau';

  @override
  String get importConfirm => 'Importieren';

  @override
  String importSuccess(int created, int updated) {
    return '$created erstellt, $updated aktualisiert';
  }

  @override
  String get errorSave => 'Fehler beim Speichern.';

  @override
  String get errorDelete => 'Fehler beim Löschen.';

  @override
  String get errorConnection => 'Verbindung fehlgeschlagen.';

  @override
  String get successSave => 'Erfolgreich gespeichert.';

  @override
  String get successDelete => 'Erfolgreich gelöscht.';

  @override
  String get successTransfer => 'Erfolgreich transferiert.';

  @override
  String get successConnection => 'Verbindung erfolgreich.';

  @override
  String get setupTitle => 'Storify – Inventarverwaltung';

  @override
  String get setupSubtitle =>
      'Bitte gib deine API-URL und deinen API-Key ein, um die App zu konfigurieren.';

  @override
  String get noItemsFound => 'Keine Artikel gefunden.';

  @override
  String get noLocationsFound => 'Keine Standorte gefunden.';

  @override
  String get searchHint => 'Suchen...';

  @override
  String get filterAll => 'Alle';

  @override
  String get newItem => 'Neuer Artikel';

  @override
  String get editItem => 'Artikel bearbeiten';

  @override
  String get newLocation => 'Neuer Standort';

  @override
  String get editLocation => 'Standort bearbeiten';

  @override
  String get scanBarcode => 'Barcode scannen';

  @override
  String get scanInstruction => 'Barcode oder QR-Code in den Rahmen halten';

  @override
  String get notificationLowStockTitle => 'Niedriger Bestand';

  @override
  String notificationLowStockBody(int count) {
    return 'Nur noch $count Stück verfügbar';
  }

  @override
  String get statArticles => 'Artikel';

  @override
  String get statLocations => 'Standorte';

  @override
  String get statCritical => 'Kritisch';

  @override
  String get sectionQuickActions => 'Schnellaktionen';

  @override
  String get sectionTopLocations => 'Top Standorte';

  @override
  String get sectionRecent => 'Zuletzt im Inventar';

  @override
  String get noCriticalItems =>
      'Keine kritischen Artikel – alles im grünen Bereich.';

  @override
  String get noExpiringItems => 'Keine ablaufenden Artikel – alles in Ordnung.';

  @override
  String get actionScan => 'Scannen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsAbout => 'Über die App';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsApiUrl => 'API-Basis-URL';

  @override
  String get settingsApiKey => 'API-Key';

  @override
  String get inventoryTitle => 'Inventar';

  @override
  String get locationsTitle => 'Standorte';

  @override
  String locationItemCount(int count) {
    return '$count Artikel';
  }

  @override
  String expiresOn(String date) {
    return 'Läuft ab am $date';
  }

  @override
  String expiredOn(String date) {
    return 'Abgelaufen am $date';
  }

  @override
  String get sectionExport => 'Exportieren';

  @override
  String get sectionImport => 'Importieren';

  @override
  String importFoundItems(int count) {
    return '$count Artikel gefunden.';
  }

  @override
  String importMoreItems(int count) {
    return '... und $count weitere.';
  }

  @override
  String savedAs(String name) {
    return 'Gespeichert: $name';
  }

  @override
  String get offlineBannerShort =>
      'Keine Verbindung – lokale Daten werden angezeigt';

  @override
  String get noItemsYet => 'Noch keine Artikel erfasst.';

  @override
  String get noLocationsYet => 'Noch keine Standorte erfasst.';

  @override
  String get btnSaveReload => 'Speichern & Neu laden';

  @override
  String get noItemsAtLocation => 'Keine Artikel an diesem Standort.';

  @override
  String get fieldLocationName => 'Standortbezeichnung';

  @override
  String get searchItemHint => 'Artikel suchen…';

  @override
  String get searchLocationHint => 'Standort suchen…';

  @override
  String get chooseCategory => 'Kategorie wählen';

  @override
  String get chooseLocation => 'Standort wählen';

  @override
  String get checkingConnection => 'Prüfe…';

  @override
  String get fieldRequired => 'Pflichtfeld';

  @override
  String get mustSelectLocation => 'Bitte Standort auswählen';

  @override
  String get bannerExpiredItem => 'Artikel ist abgelaufen!';

  @override
  String bannerLowStockDetail(int threshold) {
    return 'Niedriger Bestand – unter $threshold Einheiten';
  }

  @override
  String deleteItemConfirm(String name) {
    return '«$name» wird unwiderruflich gelöscht.';
  }

  @override
  String get noOtherLocations => 'Keine anderen Standorte vorhanden.';

  @override
  String get errorSaveTitle => 'Fehler beim Speichern';

  @override
  String deleteLocationConfirm(String name) {
    return '«$name» wird gelöscht. Artikel mit diesem Standort können nicht mehr zugeordnet werden.';
  }

  @override
  String get transferQuantityTitle => 'Menge wählen';

  @override
  String get transferQuantityHint => 'Wie viele möchtest du transferieren?';

  @override
  String get transferConfirmBtn => 'Transferieren';

  @override
  String get toastSaved => 'Gespeichert';

  @override
  String get toastDeleted => 'Gelöscht';

  @override
  String get toastTransferred => 'Transferiert';

  @override
  String get toastStockUpdated => 'Bestand aktualisiert';

  @override
  String get toastError => 'Fehler';

  @override
  String get toastAccountSwitched => 'Konto gewechselt';

  @override
  String get toastAccountSaved => 'Konto gespeichert';

  @override
  String toastImportResult(int created, int updated) {
    return '$created neu · $updated aktualisiert';
  }

  @override
  String toastImportErrors(int count) {
    return '$count Fehler';
  }

  @override
  String get setupTagline => 'Inventarverwaltung';

  @override
  String get setupSectionTitle => 'Verbindung einrichten';

  @override
  String get setupUrlHint => 'https://deine-domain.ch/api';

  @override
  String get setupValidUrl => 'Bitte URL eingeben';

  @override
  String get setupValidUrlHttp => 'URL muss mit http:// oder https:// beginnen';

  @override
  String get setupValidKey => 'Bitte API-Key eingeben';

  @override
  String get setupSuccessDetail => 'Verbindung erfolgreich. API erreichbar.';

  @override
  String get setupErrorInvalidKey =>
      'Ungültiger API-Key. Bitte Schlüssel prüfen.';

  @override
  String get setupInfoText =>
      'URL und API-Key können jederzeit unter Einstellungen geändert werden.';
}
