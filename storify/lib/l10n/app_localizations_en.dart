// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Storify';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navInventory => 'Inventory';

  @override
  String get navLocations => 'Locations';

  @override
  String get navSettings => 'Settings';

  @override
  String get btnSave => 'Save';

  @override
  String get btnCreate => 'Create';

  @override
  String get btnDelete => 'Delete';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnEdit => 'Edit';

  @override
  String get btnCheckConnection => 'Check connection';

  @override
  String get btnOpenApp => 'Open app';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldDescription => 'Description';

  @override
  String get fieldCategory => 'Category';

  @override
  String get fieldBarcode => 'Barcode / QR code';

  @override
  String get fieldStock => 'Stock';

  @override
  String get fieldLocation => 'Location';

  @override
  String get fieldExpiry => 'Expiry date (optional)';

  @override
  String get fieldApiUrl => 'API URL';

  @override
  String get fieldApiKey => 'API key';

  @override
  String get labelNoDate => 'No date';

  @override
  String labelPieces(int count) {
    return '$count pcs.';
  }

  @override
  String labelItems(int count) {
    return '$count items';
  }

  @override
  String labelLocations(int count) {
    return '$count locations';
  }

  @override
  String get sectionLowStock => 'Low stock';

  @override
  String get sectionExpiring => 'Expiring soon / Expired';

  @override
  String get sectionOverview => 'Overview';

  @override
  String get bannerOffline =>
      'Offline – changes will sync when connection is restored.';

  @override
  String get bannerLowStock => 'Stock below minimum!';

  @override
  String get bannerExpired => 'Expired!';

  @override
  String get bannerExpiringSoon => 'Expiring soon';

  @override
  String syncPending(int count) {
    return '$count pending';
  }

  @override
  String get deleteItemTitle => 'Delete item?';

  @override
  String get deleteItemBody =>
      'Really delete this item? This action cannot be undone.';

  @override
  String get deleteLocationTitle => 'Delete location?';

  @override
  String get deleteLocationBody =>
      'Really delete this location? Items at this location must be moved first.';

  @override
  String get barcodeAlreadyExists => 'Barcode already exists';

  @override
  String get actionAddStock => '+1 stock';

  @override
  String get actionSubtractStock => '-1 stock';

  @override
  String get actionTransfer => 'Transfer';

  @override
  String get actionNewLocation => 'New location';

  @override
  String get actionCreateNew => 'Create new anyway';

  @override
  String get transferTitle => 'Transfer to which location?';

  @override
  String get settingsSectionApi => 'API connection';

  @override
  String get settingsSectionTheme => 'Appearance';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get settingsSectionAccounts => 'Accounts';

  @override
  String get settingsSectionData => 'Data';

  @override
  String get settingsManageAccounts => 'Manage accounts';

  @override
  String get settingsExportImport => 'Export / Import';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get accountsAdd => 'Add account';

  @override
  String get accountsActive => 'Active';

  @override
  String get accountsSwitch => 'Switch to this account';

  @override
  String get accountsDelete => 'Delete account';

  @override
  String accountsDeleteConfirm(Object name) {
    return 'Really delete account \"$name\"?';
  }

  @override
  String get accountsDeleteActive =>
      'This is your active account. Deleting it will log you out and clear all cached data.';

  @override
  String get accountsNoAccounts => 'No accounts configured yet.';

  @override
  String get accountsPendingTitle => 'Pending changes';

  @override
  String accountsPendingBody(int count) {
    return '$count changes have not been synced yet. Switch anyway?';
  }

  @override
  String get accountsSwitchAnyway => 'Switch anyway';

  @override
  String get accountsEditTitle => 'Edit account';

  @override
  String get accountsAddTitle => 'Add account';

  @override
  String get accountsTestConnection => 'Test connection';

  @override
  String get accountsUrlKeyRequired => 'URL and key are required.';

  @override
  String get accountsBtnAdd => 'Add';

  @override
  String get accountNameField => 'Account name';

  @override
  String get exportTitle => 'Export / Import';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportCsvDesc => 'For Excel and other spreadsheets';

  @override
  String get exportPdf => 'Export PDF report';

  @override
  String get exportPdfDesc => 'Printable inventory report';

  @override
  String get importCsv => 'Import CSV';

  @override
  String get importCsvDesc => 'Import items from a CSV file';

  @override
  String get importPreviewTitle => 'Preview';

  @override
  String get importConfirm => 'Import';

  @override
  String importSuccess(int created, int updated) {
    return '$created created, $updated updated';
  }

  @override
  String get errorSave => 'Error saving.';

  @override
  String get errorDelete => 'Error deleting.';

  @override
  String get errorConnection => 'Connection failed.';

  @override
  String get successSave => 'Saved successfully.';

  @override
  String get successDelete => 'Deleted successfully.';

  @override
  String get successTransfer => 'Transferred successfully.';

  @override
  String get successConnection => 'Connection successful.';

  @override
  String get setupTitle => 'Storify – Inventory Management';

  @override
  String get setupSubtitle =>
      'Enter your API URL and API key to configure the app.';

  @override
  String get noItemsFound => 'No items found.';

  @override
  String get noLocationsFound => 'No locations found.';

  @override
  String get searchHint => 'Search...';

  @override
  String get filterAll => 'All';

  @override
  String get newItem => 'New item';

  @override
  String get editItem => 'Edit item';

  @override
  String get newLocation => 'New location';

  @override
  String get editLocation => 'Edit location';

  @override
  String get scanBarcode => 'Scan barcode';

  @override
  String get scanInstruction => 'Hold barcode or QR code in the frame';

  @override
  String get notificationLowStockTitle => 'Low stock';

  @override
  String notificationLowStockBody(int count) {
    return 'Only $count pieces left';
  }

  @override
  String get statArticles => 'Items';

  @override
  String get statLocations => 'Locations';

  @override
  String get statCritical => 'Critical';

  @override
  String get sectionQuickActions => 'Quick Actions';

  @override
  String get sectionTopLocations => 'Top Locations';

  @override
  String get sectionRecent => 'Recently Added';

  @override
  String get noCriticalItems => 'No critical items – everything looks good.';

  @override
  String get noExpiringItems => 'No expiring items – all good.';

  @override
  String get actionScan => 'Scan';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsApiUrl => 'API Base URL';

  @override
  String get settingsApiKey => 'API Key';

  @override
  String get inventoryTitle => 'Inventory';

  @override
  String get locationsTitle => 'Locations';

  @override
  String locationItemCount(int count) {
    return '$count items';
  }

  @override
  String expiresOn(String date) {
    return 'Expires $date';
  }

  @override
  String expiredOn(String date) {
    return 'Expired $date';
  }

  @override
  String get sectionExport => 'Export';

  @override
  String get sectionImport => 'Import';

  @override
  String importFoundItems(int count) {
    return '$count items found.';
  }

  @override
  String importMoreItems(int count) {
    return '... and $count more.';
  }

  @override
  String savedAs(String name) {
    return 'Saved: $name';
  }

  @override
  String get offlineBannerShort => 'No connection – showing local data';

  @override
  String get noItemsYet => 'No items added yet.';

  @override
  String get noLocationsYet => 'No locations added yet.';

  @override
  String get btnSaveReload => 'Save & Reload';

  @override
  String get noItemsAtLocation => 'No items at this location.';

  @override
  String get fieldLocationName => 'Location name';

  @override
  String get searchItemHint => 'Search items…';

  @override
  String get searchLocationHint => 'Search location…';

  @override
  String get chooseCategory => 'Choose category';

  @override
  String get chooseLocation => 'Choose location';

  @override
  String get checkingConnection => 'Checking…';

  @override
  String get fieldRequired => 'Required field';

  @override
  String get mustSelectLocation => 'Please select a location';

  @override
  String get bannerExpiredItem => 'Item has expired!';

  @override
  String bannerLowStockDetail(int threshold) {
    return 'Low stock – under $threshold units';
  }

  @override
  String deleteItemConfirm(String name) {
    return '«$name» will be permanently deleted.';
  }

  @override
  String get noOtherLocations => 'No other locations available.';

  @override
  String get errorSaveTitle => 'Error saving';

  @override
  String deleteLocationConfirm(String name) {
    return '«$name» will be deleted. Items linked to this location can no longer be assigned.';
  }

  @override
  String get transferQuantityTitle => 'Select quantity';

  @override
  String get transferQuantityHint => 'How many do you want to transfer?';

  @override
  String get transferConfirmBtn => 'Transfer';

  @override
  String get toastSaved => 'Saved';

  @override
  String get toastDeleted => 'Deleted';

  @override
  String get toastTransferred => 'Transferred';

  @override
  String get toastStockUpdated => 'Stock updated';

  @override
  String get toastError => 'Error';

  @override
  String get toastAccountSwitched => 'Account switched';

  @override
  String get toastAccountSaved => 'Account saved';

  @override
  String toastImportResult(int created, int updated) {
    return '$created new · $updated updated';
  }

  @override
  String toastImportErrors(int count) {
    return '$count errors';
  }

  @override
  String get setupTagline => 'Inventory Management';

  @override
  String get setupSectionTitle => 'Set up connection';

  @override
  String get setupUrlHint => 'https://your-domain.com/api';

  @override
  String get setupValidUrl => 'Please enter a URL';

  @override
  String get setupValidUrlHttp => 'URL must start with http:// or https://';

  @override
  String get setupValidKey => 'Please enter an API key';

  @override
  String get setupSuccessDetail => 'Connection successful. API reachable.';

  @override
  String get setupErrorInvalidKey => 'Invalid API key. Please check your key.';

  @override
  String get setupInfoText =>
      'URL and API key can be changed anytime in Settings.';
}
