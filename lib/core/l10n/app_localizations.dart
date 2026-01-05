import 'package:flutter/material.dart';

/// Supported locales for the app
class AppLocales {
  AppLocales._();

  static const Locale romanian = Locale('ro', 'RO');
  static const Locale english = Locale('en', 'US');

  /// List of all supported locales
  static const List<Locale> supportedLocales = [
    english,
    romanian,
  ];

  /// Default locale
  static const Locale defaultLocale = english;

  /// Get locale from language code
  static Locale fromLanguageCode(String code) {
    switch (code) {
      case 'ro':
        return romanian;
      case 'en':
      default:
        return english;
    }
  }

  /// Get language name from locale
  static String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'ro':
      default:
        return 'Română';
    }
  }

  /// Get native language name
  static String getNativeLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'ro':
      default:
        return 'Română';
    }
  }

  /// Get flag emoji for locale
  static String getFlagEmoji(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return '🇺🇸';
      case 'ro':
      default:
        return '🇷🇴';
    }
  }
}

/// App Localizations - Main class for accessing translations
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  /// Get the current instance from context
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// Localization delegate
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Check if locale is supported
  static bool isSupported(Locale locale) {
    return AppLocales.supportedLocales
        .any((l) => l.languageCode == locale.languageCode);
  }

  /// Get translations map based on current locale
  Map<String, String> get _localizedStrings {
    switch (locale.languageCode) {
      case 'en':
        return _enStrings;
      case 'ro':
      default:
        return _roStrings;
    }
  }

  /// Get a translated string by key
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // ============================================
  // APP GENERAL
  // ============================================

  String get appName => translate('app_name');
  String get appNameFull => translate('app_name_full');
  String get appTagline => translate('app_tagline');

  // ============================================
  // COMMON ACTIONS
  // ============================================

  String get save => translate('save');
  String get cancel => translate('cancel');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get add => translate('add');
  String get create => translate('create');
  String get update => translate('update');
  String get confirm => translate('confirm');
  String get close => translate('close');
  String get back => translate('back');
  String get next => translate('next');
  String get done => translate('done');
  String get submit => translate('submit');
  String get retry => translate('retry');
  String get refresh => translate('refresh');
  String get search => translate('search');
  String get filter => translate('filter');
  String get sort => translate('sort');
  String get view => translate('view');
  String get viewAll => translate('view_all');
  String get seeMore => translate('see_more');
  String get seeLess => translate('see_less');
  String get loading => translate('loading');
  String get yes => translate('yes');
  String get no => translate('no');
  String get ok => translate('ok');
  String get apply => translate('apply');
  String get reset => translate('reset');
  String get clear => translate('clear');
  String get select => translate('select');
  String get selectAll => translate('select_all');
  String get deselectAll => translate('deselect_all');
  String get share => translate('share');
  String get download => translate('download');
  String get upload => translate('upload');
  String get copy => translate('copy');
  String get paste => translate('paste');

  // ============================================
  // AUTHENTICATION
  // ============================================

  String get login => translate('login');
  String get logout => translate('logout');
  String get register => translate('register');
  String get signIn => translate('sign_in');
  String get signUp => translate('sign_up');
  String get signOut => translate('sign_out');
  String get forgotPassword => translate('forgot_password');
  String get resetPassword => translate('reset_password');
  String get changePassword => translate('change_password');
  String get email => translate('email');
  String get password => translate('password');
  String get confirmPassword => translate('confirm_password');
  String get currentPassword => translate('current_password');
  String get newPassword => translate('new_password');
  String get rememberMe => translate('remember_me');
  String get stayLoggedIn => translate('stay_logged_in');
  String get signInWithGoogle => translate('sign_in_with_google');
  String get dontHaveAccount => translate('dont_have_account');
  String get alreadyHaveAccount => translate('already_have_account');
  String get createAccount => translate('create_account');
  String get verifyEmail => translate('verify_email');
  String get emailSent => translate('email_sent');
  String get checkEmail => translate('check_email');

  // ============================================
  // USER PROFILE
  // ============================================

  String get profile => translate('profile');
  String get editProfile => translate('edit_profile');
  String get myProfile => translate('my_profile');
  String get firstName => translate('first_name');
  String get lastName => translate('last_name');
  String get fullName => translate('full_name');
  String get phone => translate('phone');
  String get phoneNumber => translate('phone_number');
  String get dateOfBirth => translate('date_of_birth');
  String get gender => translate('gender');
  String get male => translate('male');
  String get female => translate('female');
  String get other => translate('other');
  String get bio => translate('bio');
  String get about => translate('about');
  String get profilePhoto => translate('profile_photo');
  String get changePhoto => translate('change_photo');
  String get removePhoto => translate('remove_photo');

  // ============================================
  // NAVIGATION & SECTIONS
  // ============================================

  String get home => translate('home');
  String get dashboard => translate('dashboard');
  String get announcements => translate('announcements');
  String get meetings => translate('meetings');
  String get initiatives => translate('initiatives');
  String get documents => translate('documents');
  String get polls => translate('polls');
  String get calendar => translate('calendar');
  String get notifications => translate('notifications');
  String get settings => translate('settings');
  String get admin => translate('admin');
  String get help => translate('help');
  String get support => translate('support');
  String get feedback => translate('feedback');

  // ============================================
  // ANNOUNCEMENTS
  // ============================================

  String get announcement => translate('announcement');
  String get newAnnouncement => translate('new_announcement');
  String get createAnnouncement => translate('create_announcement');
  String get editAnnouncement => translate('edit_announcement');
  String get announcementTitle => translate('announcement_title');
  String get announcementContent => translate('announcement_content');
  String get announcementType => translate('announcement_type');
  String get publishAnnouncement => translate('publish_announcement');
  String get pinned => translate('pinned');
  String get unpinned => translate('unpinned');
  String get priority => translate('priority');
  String get urgent => translate('urgent');
  String get important => translate('important');
  String get normal => translate('normal');
  String get info => translate('info');

  // ============================================
  // MEETINGS
  // ============================================

  String get meeting => translate('meeting');
  String get newMeeting => translate('new_meeting');
  String get createMeeting => translate('create_meeting');
  String get editMeeting => translate('edit_meeting');
  String get meetingTitle => translate('meeting_title');
  String get meetingDescription => translate('meeting_description');
  String get meetingDate => translate('meeting_date');
  String get meetingTime => translate('meeting_time');
  String get meetingLocation => translate('meeting_location');
  String get meetingType => translate('meeting_type');
  String get online => translate('online');
  String get inPerson => translate('in_person');
  String get hybrid => translate('hybrid');
  String get agenda => translate('agenda');
  String get agendaItem => translate('agenda_item');
  String get addAgendaItem => translate('add_agenda_item');
  String get attendees => translate('attendees');
  String get attendance => translate('attendance');
  String get present => translate('present');
  String get absent => translate('absent');
  String get excused => translate('excused');
  String get pending => translate('pending');
  String get confirmAttendance => translate('confirm_attendance');
  String get joinMeeting => translate('join_meeting');
  String get meetingLink => translate('meeting_link');
  String get duration => translate('duration');
  String get minutes => translate('minutes');

  // ============================================
  // INITIATIVES
  // ============================================

  String get initiative => translate('initiative');
  String get newInitiative => translate('new_initiative');
  String get createInitiative => translate('create_initiative');
  String get editInitiative => translate('edit_initiative');
  String get initiativeTitle => translate('initiative_title');
  String get initiativeDescription => translate('initiative_description');
  String get initiativeStatus => translate('initiative_status');
  String get proposed => translate('proposed');
  String get inDiscussion => translate('in_discussion');
  String get approved => translate('approved');
  String get rejected => translate('rejected');
  String get inProgress => translate('in_progress');
  String get completed => translate('completed');
  String get onHold => translate('on_hold');
  String get cancelled => translate('cancelled');
  String get vote => translate('vote');
  String get voteFor => translate('vote_for');
  String get voteAgainst => translate('vote_against');
  String get abstain => translate('abstain');
  String get comments => translate('comments');
  String get addComment => translate('add_comment');

  // ============================================
  // DOCUMENTS
  // ============================================

  String get document => translate('document');
  String get newDocument => translate('new_document');
  String get uploadDocument => translate('upload_document');
  String get documentTitle => translate('document_title');
  String get documentDescription => translate('document_description');
  String get documentCategory => translate('document_category');
  String get fileType => translate('file_type');
  String get fileSize => translate('file_size');
  String get uploadedBy => translate('uploaded_by');
  String get uploadedAt => translate('uploaded_at');
  String get downloadDocument => translate('download_document');
  String get viewDocument => translate('view_document');
  String get regulations => translate('regulations');
  String get protocols => translate('protocols');
  String get reports => translate('reports');
  String get templates => translate('templates');
  String get forms => translate('forms');

  // ============================================
  // POLLS
  // ============================================

  String get poll => translate('poll');
  String get newPoll => translate('new_poll');
  String get createPoll => translate('create_poll');
  String get editPoll => translate('edit_poll');
  String get pollQuestion => translate('poll_question');
  String get pollOptions => translate('poll_options');
  String get addOption => translate('add_option');
  String get removeOption => translate('remove_option');
  String get votePoll => translate('vote_poll');
  String get pollResults => translate('poll_results');
  String get votes => translate('votes');
  String get totalVotes => translate('total_votes');
  String get endDate => translate('end_date');
  String get pollEnded => translate('poll_ended');
  String get pollActive => translate('poll_active');
  String get anonymous => translate('anonymous');
  String get multipleChoice => translate('multiple_choice');
  String get singleChoice => translate('single_choice');

  // ============================================
  // SCHOOLS & ORGANIZATIONS
  // ============================================

  String get school => translate('school');
  String get schools => translate('schools');
  String get schoolName => translate('school_name');
  String get schoolAddress => translate('school_address');
  String get city => translate('city');
  String get county => translate('county');
  String get region => translate('region');
  String get organization => translate('organization');
  String get department => translate('department');
  String get gds => translate('gds');
  String get bex => translate('bex');

  // ============================================
  // USER ROLES
  // ============================================

  String get role => translate('role');
  String get student => translate('student');
  String get classRepresentative => translate('class_representative');
  String get schoolRepresentative => translate('school_representative');
  String get departmentMember => translate('department_member');
  String get bexMember => translate('bex_member');
  String get superAdmin => translate('super_admin');
  String get administrator => translate('administrator');
  String get member => translate('member');
  String get guest => translate('guest');

  // ============================================
  // SETTINGS
  // ============================================

  String get generalSettings => translate('general_settings');
  String get accountSettings => translate('account_settings');
  String get notificationSettings => translate('notification_settings');
  String get privacySettings => translate('privacy_settings');
  String get appearance => translate('appearance');
  String get theme => translate('theme');
  String get lightTheme => translate('light_theme');
  String get darkTheme => translate('dark_theme');
  String get systemTheme => translate('system_theme');
  String get language => translate('language');
  String get selectLanguage => translate('select_language');
  String get pushNotifications => translate('push_notifications');
  String get emailNotifications => translate('email_notifications');
  String get soundNotifications => translate('sound_notifications');
  String get vibration => translate('vibration');
  String get privacyPolicy => translate('privacy_policy');
  String get termsOfService => translate('terms_of_service');
  String get aboutApp => translate('about_app');
  String get version => translate('version');
  String get deleteAccount => translate('delete_account');

  // ============================================
  // TIME & DATE
  // ============================================

  String get today => translate('today');
  String get yesterday => translate('yesterday');
  String get tomorrow => translate('tomorrow');
  String get thisWeek => translate('this_week');
  String get lastWeek => translate('last_week');
  String get nextWeek => translate('next_week');
  String get thisMonth => translate('this_month');
  String get lastMonth => translate('last_month');
  String get nextMonth => translate('next_month');
  String get date => translate('date');
  String get time => translate('time');
  String get startDate => translate('start_date');
  String get startTime => translate('start_time');
  String get now => translate('now');
  String get ago => translate('ago');
  String get inTime => translate('in_time');

  // ============================================
  // STATUS & STATES
  // ============================================

  String get active => translate('active');
  String get inactive => translate('inactive');
  String get enabled => translate('enabled');
  String get disabled => translate('disabled');
  String get verified => translate('verified');
  String get unverified => translate('unverified');
  String get published => translate('published');
  String get draft => translate('draft');
  String get archived => translate('archived');
  String get deleted => translate('deleted');
  String get open => translate('open');
  String get closed => translate('closed');
  String get new_ => translate('new');
  String get read => translate('read');
  String get unread => translate('unread');

  // ============================================
  // MESSAGES & FEEDBACK
  // ============================================

  String get success => translate('success');
  String get error => translate('error');
  String get warning => translate('warning');
  String get information => translate('information');
  String get savedSuccessfully => translate('saved_successfully');
  String get deletedSuccessfully => translate('deleted_successfully');
  String get updatedSuccessfully => translate('updated_successfully');
  String get createdSuccessfully => translate('created_successfully');
  String get somethingWentWrong => translate('something_went_wrong');
  String get tryAgain => translate('try_again');
  String get noDataFound => translate('no_data_found');
  String get noResultsFound => translate('no_results_found');
  String get noItemsYet => translate('no_items_yet');
  String get noNotifications => translate('no_notifications');
  String get noAnnouncements => translate('no_announcements');
  String get noMeetings => translate('no_meetings');
  String get noInitiatives => translate('no_initiatives');
  String get noDocuments => translate('no_documents');
  String get noPolls => translate('no_polls');
  String get connectionError => translate('connection_error');
  String get checkConnection => translate('check_connection');
  String get sessionExpired => translate('session_expired');
  String get pleaseLoginAgain => translate('please_login_again');
  String get areYouSure => translate('are_you_sure');
  String get cannotBeUndone => translate('cannot_be_undone');
  String get confirmDelete => translate('confirm_delete');
  String get confirmLogout => translate('confirm_logout');

  // ============================================
  // VALIDATION MESSAGES
  // ============================================

  String get required => translate('required');
  String get fieldRequired => translate('field_required');
  String get invalidEmail => translate('invalid_email');
  String get invalidPhone => translate('invalid_phone');
  String get invalidPassword => translate('invalid_password');
  String get passwordTooShort => translate('password_too_short');
  String get passwordsDoNotMatch => translate('passwords_do_not_match');
  String get invalidCredentials => translate('invalid_credentials');
  String get emailAlreadyExists => translate('email_already_exists');
  String get weakPassword => translate('weak_password');
  String get tooShort => translate('too_short');
  String get tooLong => translate('too_long');
  String get invalidFormat => translate('invalid_format');
  String get minCharacters => translate('min_characters');
  String get maxCharacters => translate('max_characters');

  // ============================================
  // EMPTY STATES
  // ============================================

  String get emptyAnnouncements => translate('empty_announcements');
  String get emptyMeetings => translate('empty_meetings');
  String get emptyInitiatives => translate('empty_initiatives');
  String get emptyDocuments => translate('empty_documents');
  String get emptyPolls => translate('empty_polls');
  String get emptyNotifications => translate('empty_notifications');
  String get emptySearch => translate('empty_search');
  String get emptyCalendar => translate('empty_calendar');

  // ============================================
  // PERMISSIONS
  // ============================================

  String get permissionDenied => translate('permission_denied');
  String get cameraPermission => translate('camera_permission');
  String get storagePermission => translate('storage_permission');
  String get notificationPermission => translate('notification_permission');
  String get locationPermission => translate('location_permission');
  String get grantPermission => translate('grant_permission');
  String get openSettings => translate('open_settings');
}

/// Localization delegate
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.isSupported(locale);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// ============================================
// ROMANIAN TRANSLATIONS
// ============================================

const Map<String, String> _roStrings = {
  // App General
  'app_name': 'CJE',
  'app_name_full': 'Consiliul Județean al Elevilor',
  'app_tagline': 'Vocea elevilor',

  // Common Actions
  'save': 'Salvează',
  'cancel': 'Anulează',
  'delete': 'Șterge',
  'edit': 'Editează',
  'add': 'Adaugă',
  'create': 'Creează',
  'publish': 'Publică',
  'update': 'Actualizează',
  'confirm': 'Confirmă',
  'close': 'Închide',
  'back': 'Înapoi',
  'next': 'Următorul',
  'done': 'Gata',
  'submit': 'Trimite',
  'retry': 'Reîncearcă',
  'refresh': 'Reîmprospătează',
  'search': 'Caută',
  'filter': 'Filtrează',
  'my_initiatives': 'Inițiativele mele',
  'show_only_my_initiatives': 'Arată doar inițiativele create de mine',
  'my_school': 'Școala mea',
  'show_school_initiatives': 'Arată inițiativele din școala mea',
  'all_schools': 'Toate școlile',
  'show_all_initiatives': 'Arată inițiativele din toate școlile',
  'target_school': 'Școală țintă',
  'send_to_all_schools': 'Trimite notificarea tuturor școlilor',
  'select_school': 'Selectează școala',
  'no_schools_available': 'Nu există școli disponibile',
  'error_loading_schools': 'Eroare la încărcarea școlilor',
  'sort': 'Sortează',
  'view': 'Vezi',
  'view_all': 'Vezi tot',
  'see_more': 'Vezi mai mult',
  'see_less': 'Vezi mai puțin',
  'loading': 'Se încarcă...',
  'yes': 'Da',
  'no': 'Nu',
  'ok': 'OK',
  'apply': 'Aplică',
  'reset': 'Resetează',
  'clear': 'Șterge',
  'select': 'Selectează',
  'select_all': 'Selectează tot',
  'deselect_all': 'Deselectează tot',
  'share': 'Distribuie',
  'download': 'Descarcă',
  'upload': 'Încarcă',
  'copy': 'Copiază',
  'paste': 'Lipește',

  // Authentication
  'login': 'Autentificare',
  'login_subtitle': 'Introdu email-ul și parola pentru\na accesa contul tău',
  'logout': 'Deconectare',
  'register': 'Înregistrare',
  'sign_in': 'Conectare',
  'sign_up': 'Înregistrare',
  'sign_out': 'Deconectare',
  'forgot_password': 'Ai uitat parola?',
  'reset_password': 'Resetează parola',
  'change_password': 'Schimbă parola',
  'email': 'Email',
  'password': 'Parolă',
  'confirm_password': 'Confirmă parola',
  'current_password': 'Parola curentă',
  'new_password': 'Parola nouă',
  'remember_me': 'Ține-mă minte',
  'stay_logged_in': 'Rămâi conectat',
  'sign_in_with_google': 'Conectare cu Google',
  'dont_have_account': 'Nu ai cont?',
  'already_have_account': 'Ai deja cont?',
  'create_account': 'Creează cont',
  'verify_email': 'Verifică email',
  'email_sent': 'Email trimis',
  'check_email': 'Verifică-ți emailul',

  // User Profile
  'profile': 'Profil',
  'view_profile': 'Vezi profilul',
  'edit_profile': 'Editează profil',
  'my_profile': 'Profilul meu',
  'first_name': 'Prenume',
  'last_name': 'Nume',
  'full_name': 'Nume complet',
  'phone': 'Telefon',
  'phone_number': 'Număr de telefon',
  'date_of_birth': 'Data nașterii',
  'gender': 'Gen',
  'male': 'Masculin',
  'female': 'Feminin',
  'other': 'Altul',
  'bio': 'Biografie',
  'about': 'Despre',
  'profile_photo': 'Poză de profil',
  'change_photo': 'Schimbă poza',
  'remove_photo': 'Șterge poza',

  // Navigation & Sections
  'home': 'Acasă',
  'dashboard': 'Panou de control',
  'announcements': 'Anunțuri',
  'meetings': 'Ședințe',
  'meeting_type_county_ag': 'AG Județean',
  'meeting_type_bex': 'BEx',
  'meeting_type_department': 'Departament',
  'meeting_type_school': 'Școală',
  'initiatives': 'Inițiative',
  'documents': 'Documente',
  'files': 'fișiere',
  'add_document': 'Adaugă document',
  'polls': 'Sondaje',
  'calendar': 'Calendar',
  'notifications': 'Notificări',
  'notifications_subtitle': 'Push, email, SMS',
  'notify': 'Notifică',
  'send_notification': 'Trimite notificare',
  'county_notification_info': 'Această notificare va fi trimisă tuturor utilizatorilor selectați din județ.',
  'notification_type': 'Tip notificare',
  'notification_title_hint': 'Introdu titlul notificării',
  'notification_body_hint': 'Scrie mesajul notificării...',
  'target_audience': 'Public țintă',
  'all_users': 'Toți utilizatorii',
  'send_to_all_users': 'Trimite notificarea tuturor utilizatorilor',
  'select_roles': 'Selectează rolurile',
  'select_at_least_one_role': 'Selectează cel puțin un rol',
  'confirm_send': 'Confirmă trimiterea',
  'send_notification_confirm': 'Ești sigur că vrei să trimiți această notificare?',
  'sending': 'Se trimite...',
  'notification_sent': 'Notificare trimisă cu succes',
  'error_sending_notification': 'Eroare la trimiterea notificării',
  'general': 'General',
  'approval': 'Aprobare',
  'settings': 'Setări',
  'admin': 'Administrare',
  'help': 'Ajutor',
  'tech_support': 'Suport',
  'feedback': 'Feedback',
  'members': 'Membri',
  'more': 'Mai mult',
  'management': 'Management',
  'view_schools': 'Vezi școlile din județ',
  'county_documents': 'Documente la nivel de județ',
  'communication': 'Comunicare',
  'notify_county_members': 'Trimite notificări membrilor',
  'view_edit_profile': 'Vezi și editează profilul',
  'change_language': 'Schimbă limba aplicației',
  'change_theme': 'Schimbă tema aplicației',
  'select_theme': 'Selectează tema',
  'light': 'Luminoasă',
  'dark': 'Întunecată',
  'system': 'Sistem',
  'search_members': 'Caută membri...',
  'agenda_items': 'puncte pe ordinea de zi',
  'past': 'Trecute',
  'overview': 'Prezentare generală',

  // Announcements
  'announcement': 'Anunț',
  'new_announcement': 'Anunț nou',
  'create_announcement': 'Creează anunț',
  'edit_announcement': 'Editează anunț',
  'announcement_title': 'Titlu anunț',
  'announcement_content': 'Conținut anunț',
  'announcement_type': 'Tip anunț',
  'publish_announcement': 'Publică anunț',
  'pinned': 'Fixat',
  'unpinned': 'Nefixat',
  'priority': 'Prioritate',
  'urgent': 'Urgent',
  'important': 'Important',
  'normal': 'Normal',
  'info': 'Informativ',

  // Meetings
  'meeting': 'Ședință',
  'new_meeting': 'Ședință nouă',
  'create_meeting': 'Creează ședință',
  'edit_meeting': 'Editează ședință',
  'meeting_title': 'Titlu ședință',
  'meeting_description': 'Descriere ședință',
  'meeting_date': 'Data ședinței',
  'meeting_time': 'Ora ședinței',
  'meeting_location': 'Locație ședință',
  'meeting_type': 'Tip ședință',
  'to_be_determined': 'De stabilit',
  'online': 'Online',
  'in_person': 'Fizic',
  'hybrid': 'Hibrid',
  'agenda': 'Ordine de zi',
  'agenda_item': 'Punct pe ordinea de zi',
  'add_agenda_item': 'Adaugă punct',
  'attendees': 'Participanți',
  'attendance': 'Prezență',
  'present': 'Prezent',
  'absent': 'Absent',
  'excused': 'Motivat',
  'pending': 'În așteptare',
  'confirm_attendance': 'Confirmă prezența',
  'join_meeting': 'Intră în ședință',
  'meeting_link': 'Link ședință',
  'duration': 'Durată',
  'minutes': 'minute',
  'meeting_minutes': 'Proces-verbal',
  'minutes_uploaded': 'Proces-verbal încărcat',
  'upload_minutes': 'Încarcă proces-verbal',
  'tap_to_replace': 'Apasă pentru a înlocui',
  'add_attendees': 'Adaugă participanți',
  'no_attendees': 'Niciun participant adăugat',
  'meeting_updated': 'Ședință actualizată',
  'error_updating_meeting': 'Eroare la actualizarea ședinței',

  // Initiatives
  'initiative': 'Inițiativă',
  'new_initiative': 'Inițiativă nouă',
  'create_initiative': 'Creează inițiativă',
  'edit_initiative': 'Editează inițiativă',
  'initiative_type': 'Tip inițiativă',
  'initiative_title': 'Titlu inițiativă',
  'initiative_description': 'Descriere inițiativă',
  'initiative_status': 'Status inițiativă',
  'proposed': 'Propusă',
  'in_discussion': 'În discuție',
  'approved': 'Aprobată',
  'rejected': 'Respinsă',
  'in_progress': 'În desfășurare',
  'completed': 'Finalizată',
  'on_hold': 'În așteptare',
  'cancelled': 'Anulată',
  'vote': 'Votează',
  'vote_for': 'Vot pentru',
  'vote_against': 'Vot împotrivă',
  'abstain': 'Abținere',
  'voter_details': 'Detalii votanți',
  'votes': 'Voturi',
  'no_votes_yet': 'Niciun vot încă',
  'error_loading_votes': 'Eroare la încărcarea voturilor',
  'comments': 'Comentarii',
  'add_comment': 'Adaugă comentariu',
  'manage_initiative': 'Gestionare inițiativă',
  'approve': 'Aprobă',
  'reject': 'Respinge',
  'adopt': 'Adoptă',
  'move_to_debate': 'Spre dezbatere',
  'move_to_voting': 'Spre vot',
  'reject_initiative': 'Respinge inițiativa',
  'reject_initiative_reason': 'Te rugăm să furnizezi un motiv pentru respingere:',
  'enter_reason': 'Introdu motivul...',
  'reason_required': 'Motivul este obligatoriu',

  // Documents
  'document': 'Document',
  'new_document': 'Document nou',
  'upload_document': 'Încarcă document',
  'upload_document_desc': 'Încarcă documente noi în platformă',
  'document_title': 'Titlu document',
  'document_description': 'Descriere document',
  'document_category': 'Categorie document',
  'file_type': 'Tip fișier',
  'file_size': 'Dimensiune fișier',
  'uploaded_by': 'Încărcat de',
  'uploaded_at': 'Încărcat la',
  'download_document': 'Descarcă document',
  'view_document': 'Vezi document',
  'regulations': 'Regulamente',
  'protocols': 'Procese verbale',
  'reports': 'Rapoarte',
  'templates': 'Șabloane',
  'forms': 'Formulare',
  'regulamente': 'Regulamente',
  'ghiduri': 'Ghiduri',
  'utile': 'Utile',
  'rapoarte': 'Rapoarte',

  // Polls
  'poll': 'Sondaj',
  'new_poll': 'Sondaj nou',
  'create_poll': 'Creează sondaj',
  'edit_poll': 'Editează sondaj',
  'poll_question': 'Întrebare sondaj',
  'poll_options': 'Opțiuni sondaj',
  'add_option': 'Adaugă opțiune',
  'remove_option': 'Șterge opțiune',
  'vote_poll': 'Votează',
  'poll_results': 'Rezultate sondaj',
  'total_votes': 'Total voturi',
  'end_date': 'Data încheierii',
  'poll_ended': 'Sondaj încheiat',
  'poll_active': 'Sondaj activ',
  'poll_school': 'Sondaj Școală',
  'poll_county': 'Sondaj Județ',
  'anonymous': 'Anonim',
  'multiple_choice': 'Alegere multiplă',
  'single_choice': 'Alegere singulară',

  // Schools & Organizations
  'school': 'Școală',
  'schools': 'Școli',
  'school_name': 'Nume școală',
  'class': 'Clasă',
  'school_address': 'Adresă școală',
  'city': 'Oraș',
  'county': 'Județ',
  'region': 'Regiune',
  'organization': 'Organizație',
  'department': 'Departament',
  'gds': 'GDS',
  'bex': 'BEx',

  // User Roles
  'role': 'Rol',
  'student': 'Elev',
  'class_representative': 'Reprezentant de clasă',
  'school_representative': 'Reprezentant de școală',
  'department_member': 'Membru departament',
  'bex_member': 'Membru BEx',
  'super_admin': 'Super Admin',
  'administrator': 'Administrator',
  'member': 'Membru',
  'guest': 'Invitat',

  // Settings
  'general_settings': 'Setări generale',
  'account_settings': 'Setări cont',
  'notification_settings': 'Setări notificări',
  'privacy_settings': 'Setări confidențialitate',
  'appearance': 'Aspect',
  'theme': 'Temă',
  'light_theme': 'Temă deschisă',
  'dark_theme': 'Temă întunecată',
  'system_theme': 'Temă sistem',
  'language': 'Limbă',
  'select_language': 'Selectează limba',
  'push_notifications': 'Notificări push',
  'email_notifications': 'Notificări email',
  'sound_notifications': 'Sunet notificări',
  'vibration': 'Vibrație',
  'privacy_policy': 'Politica de confidențialitate',
  'terms_of_service': 'Termeni și condiții',
  'about_app': 'Despre aplicație',
  'version': 'Versiune',
  'delete_account': 'Șterge contul',

  // Time & Date
  'today': 'Azi',
  'yesterday': 'Ieri',
  'tomorrow': 'Mâine',
  'this_week': 'Săptămâna aceasta',
  'last_week': 'Săptămâna trecută',
  'next_week': 'Săptămâna viitoare',
  'this_month': 'Luna aceasta',
  'last_month': 'Luna trecută',
  'next_month': 'Luna viitoare',
  'date': 'Data',
  'time': 'Ora',
  'start_date': 'Data început',
  'start_time': 'Ora început',
  'now': 'Acum',
  'ago': 'în urmă',
  'in_time': 'în',

  // Status & States
  'active': 'Activ',
  'ended': 'Încheiat',
  'upcoming': 'Viitor',
  'inactive': 'Inactiv',
  'enabled': 'Activat',
  'disabled': 'Dezactivat',
  'verified': 'Verificat',
  'unverified': 'Neverificat',
  'published': 'Publicat',
  'draft': 'Ciornă',
  'archived': 'Arhivat',
  'deleted': 'Șters',
  'open': 'Deschis',
  'closed': 'Închis',
  'new': 'Nou',
  'read': 'Citit',
  'unread': 'Necitit',

  // Messages & Feedback
  'success': 'Succes',
  'error': 'Eroare',
  'warning': 'Atenție',
  'information': 'Informație',
  'saved_successfully': 'Salvat cu succes',
  'deleted_successfully': 'Șters cu succes',
  'updated_successfully': 'Actualizat cu succes',
  'created_successfully': 'Creat cu succes',
  'something_went_wrong': 'Ceva nu a funcționat',
  'try_again': 'Încearcă din nou',
  'no_data_found': 'Nu s-au găsit date',
  'no_results_found': 'Nu s-au găsit rezultate',
  'no_items_yet': 'Niciun element încă',
  'no_notifications': 'Nicio notificare',
  'no_announcements': 'Niciun anunț',
  'no_meetings': 'Nicio ședință programată',
  'no_initiatives': 'Nicio inițiativă',
  'no_documents': 'Niciun document',
  'no_polls': 'Niciun sondaj',
  'participants': 'Participanți',
  'created_by': 'Creat de',
  'no_agenda': 'Fără agendă',
  'no_agenda_description': 'Nu a fost adăugată nicio agendă pentru această ședință',
  'no_documents_description': 'Nu au fost adăugate documente pentru această ședință',
  'no_participants': 'Fără participanți',
  'no_participants_description': 'Nu au fost adăugați participanți pentru această ședință',
  'invited': 'invitați',
  'attendance_not_recorded': 'Prezența nu a fost încă înregistrată',
  'error_loading_participants': 'Eroare la încărcarea participanților',
  'location_tbd': 'Locație de stabilit',
  'add_participant': 'Adaugă participant',
  'attendance_recorded': 'Prezență înregistrată',
  'invited_pending': 'Invitați (în așteptare)',
  'mark_present': 'Marchează prezent',
  'mark_absent': 'Marchează absent',
  'marked_present': 'Marcat ca prezent',
  'marked_absent': 'Marcat ca absent',
  'error_updating_attendance': 'Eroare la actualizarea prezenței',
  'search_to_add_participants': 'Caută pentru a adăuga participanți',
  'error_searching_users': 'Eroare la căutarea utilizatorilor',
  'added_as_participant': 'a fost adăugat ca participant',
  'connection_error': 'Eroare de conexiune',
  'check_connection': 'Verifică conexiunea la internet',
  'session_expired': 'Sesiunea a expirat',
  'please_login_again': 'Te rugăm să te autentifici din nou',
  'are_you_sure': 'Ești sigur?',
  'cannot_be_undone': 'Această acțiune nu poate fi anulată',
  'confirm_delete': 'Confirmă ștergerea',
  'confirm_logout': 'Confirmă deconectarea',

  // Validation Messages
  'required': 'Obligatoriu',
  'field_required': 'Acest câmp este obligatoriu',
  'invalid_email': 'Email invalid',
  'invalid_phone': 'Număr de telefon invalid',
  'invalid_password': 'Parolă invalidă',
  'password_too_short': 'Parola este prea scurtă',
  'passwords_do_not_match': 'Parolele nu coincid',
  'invalid_credentials': 'Credențiale invalide',
  'email_already_exists': 'Emailul există deja',
  'weak_password': 'Parolă slabă',
  'too_short': 'Prea scurt',
  'too_long': 'Prea lung',
  'invalid_format': 'Format invalid',
  'min_characters': 'Minim caractere',
  'max_characters': 'Maxim caractere',

  // Empty States
  'empty_announcements': 'Nu există anunțuri',
  'empty_meetings': 'Nu există ședințe programate',
  'empty_initiatives': 'Nu există inițiative',
  'empty_documents': 'Nu există documente',
  'empty_polls': 'Nu există sondaje active',
  'empty_notifications': 'Nu ai notificări',
  'empty_search': 'Nu s-au găsit rezultate',
  'empty_calendar': 'Nu ai evenimente programate',

  // Permissions
  'permission_denied': 'Permisiune refuzată',
  'camera_permission': 'Permisiune cameră',
  'storage_permission': 'Permisiune stocare',
  'notification_permission': 'Permisiune notificări',
  'location_permission': 'Permisiune locație',
  'grant_permission': 'Acordă permisiune',
  'open_settings': 'Deschide setări',

  // Translation
  'see_translation': 'Vezi traducerea',
  'see_original': 'Vezi originalul',
  'auto_translate': 'Traducere automată',
  'translation_provider': 'Furnizor traducere',
  'api_key': 'Cheie API',
  'translated': 'Tradus',

  // Auth Flow
  'welcome_back': 'Bine ai revenit!',
  'login_to_continue': 'Conectează-te pentru a continua',
  'or': 'sau',
  'create_new_account': 'Creează un cont nou',
  'join_student_council': 'Alătură-te consiliului elevilor',
  'reset_password_title': 'Resetează parola',
  'reset_password_description': 'Introdu adresa de email și îți vom trimite un link pentru resetarea parolei.',
  'send_reset_link': 'Trimite link de resetare',
  'back_to_login': 'Înapoi la autentificare',
  'password_reset_sent': 'Link de resetare trimis!',
  'check_inbox': 'Verifică-ți inbox-ul pentru instrucțiuni.',
  'verification_email_sent': 'Ți-am trimis un email de verificare la adresa:',
  'checking_verification': 'Se verifică...',
  'resend_verification_email': 'Retrimite emailul de verificare',
  'resend_in': 'Retrimite în',
  'i_verified_my_email': 'Am verificat emailul',
  'use_different_account': 'Folosește alt cont',
  'complete_profile': 'Completează profilul',
  'complete_your_profile': 'Completează-ți profilul',
  'complete_profile_description': 'Pentru a finaliza înregistrarea, te rugăm să completezi informațiile de mai jos.',
  'signed_in_with_google': 'Conectat cu Google',
  'registration_approval_info': 'După înregistrare, contul tău va fi în așteptare până când un SuperAdmin sau BEX îl va aproba.',
  'complete_registration': 'Finalizează înregistrarea',
  'account_pending': 'Cont în așteptare',
  'account_pending_description': 'Contul tău a fost creat și așteaptă aprobarea unui SuperAdmin sau BEX.',
  'pending_approval_info': 'Vei primi o notificare când contul tău va fi aprobat. Acest proces poate dura câteva ore.',
  'check_status': 'Verifică statusul',
  'status_pending': 'În așteptare',
  'account_suspended': 'Cont suspendat',
  'account_suspended_description': 'Contul tău a fost suspendat. Contactează un administrator pentru mai multe informații.',
  'status_suspended': 'Suspendat',
  'contact_admin_for_help': 'Dacă crezi că aceasta este o eroare, contactează administratorul școlii tale.',
  'personal_info': 'Informații personale',
  'account': 'Cont',
  'member_since': 'Membru din',
  'last_login': 'Ultima conectare',
  'logout_confirmation': 'Ești sigur că vrei să te deconectezi?',
  'class_name': 'Clasa',
  'coming_soon': 'În curând',
  'city_password': 'Parola orașului',
  'city_password_hint': 'Introdu parola primită de la administrator',
  'invalid_city_password': 'Parola orașului este invalidă',
  'phone_required': 'Numărul de telefon este obligatoriu',
  'city_required': 'Te rugăm să selectezi orașul',
  'school_required': 'Te rugăm să selectezi școala',

  // Announcement screens
  'all': 'Toate',
  'title': 'Titlu',
  'content': 'Conținut',
  'attachments': 'Atașamente',
  'delete_announcement': 'Șterge anunțul',
  'delete_announcement_confirm': 'Ești sigur că vrei să ștergi acest anunț? Această acțiune nu poate fi anulată.',
  'announcement_deleted': 'Anunț șters',
  'announcement_title_hint': 'Introdu titlul anunțului',
  'announcement_content_hint': 'Scrie conținutul anunțului aici...',
  'title_required': 'Titlul este obligatoriu',
  'title_too_short': 'Titlul trebuie să aibă cel puțin 5 caractere',
  'content_required': 'Conținutul este obligatoriu',
  'content_too_short': 'Conținutul trebuie să aibă cel puțin 20 de caractere',
  'pin_announcement': 'Fixează anunțul',
  'pin_announcement_desc': 'Anunțurile fixate apar în partea de sus a listei',
  'add_image': 'Adaugă imagine',
  'add_attachment': 'Adaugă atașament',
  'save_as_draft': 'Salvează ca ciornă',
  'announcement_published': 'Anunț publicat cu succes',
  'error_creating_announcement': 'Eroare la crearea anunțului',
  'draft_saved': 'Ciornă salvată',

  // Meeting screens
  'upcoming_meetings': 'Ședințe viitoare',
  'past_meetings': 'Ședințe trecute',
  'no_upcoming_meetings': 'Nu există ședințe viitoare',
  'meeting_details': 'Detalii ședință',
  'delete_meeting': 'Șterge ședința',
  'delete_meeting_confirm': 'Ești sigur că vrei să ștergi această ședință?',
  'meeting_deleted': 'Ședință ștearsă',
  'meeting_title_hint': 'Introdu titlul ședinței',
  'meeting_description_hint': 'Descrie despre ce este această ședință...',
  'select_date': 'Selectează data',
  'select_time': 'Selectează ora',
  'location_hint': 'Introdu locația sau link-ul ședinței',
  'add_agenda': 'Adaugă puncte pe ordinea de zi',
  'agenda_item_hint': 'Adaugă punct pe ordinea de zi',
  'meeting_created': 'Ședință creată cu succes',
  'error_creating_meeting': 'Eroare la crearea ședinței',
  'schedule_meeting': 'Programează ședință',

  // Initiative screens
  'support': 'Susține',
  'supporters': 'Susținători',
  'problem': 'Problemă',
  'solution': 'Soluție',
  'impact': 'Impact',
  'status': 'Status',
  'delete_initiative': 'Șterge inițiativa',
  'delete_initiative_confirm': 'Ești sigur că vrei să ștergi această inițiativă?',
  'initiative_deleted': 'Inițiativă ștearsă',
  'initiative_title_hint': 'Introdu titlul inițiativei',
  'initiative_description_hint': 'Descrie inițiativa ta...',
  'problem_hint': 'Ce problemă rezolvă aceasta?',
  'solution_hint': 'Cum va fi rezolvată?',
  'impact_hint': 'Ce impact va avea?',
  'submit_initiative': 'Trimite inițiativa',
  'initiative_submitted': 'Inițiativă trimisă cu succes',
  'error_creating_initiative': 'Eroare la crearea inițiativei',
  'write_comment': 'Scrie un comentariu...',
  'comment_added': 'Comentariu adăugat',
  'voting': 'Votare',
  'review': 'În revizuire',
  'debate': 'În dezbatere',
  'adopted': 'Adoptată',
  'submitted': 'Trimisă',

  // Profile screens (new entries only)
  'personal_information': 'Informații personale',
  'account_information': 'Informații cont',
  'profile_updated': 'Profil actualizat cu succes',
  'error_updating_profile': 'Eroare la actualizarea profilului',
  'delete_account_warning': 'Această acțiune este permanentă și nu poate fi anulată. Toate datele tale vor fi șterse.',
  'choose_photo': 'Alege fotografia',
  'camera': 'Cameră',
  'gallery': 'Galerie',
  'photo_updated': 'Fotografie actualizată cu succes',
  'error_picking_image': 'Eroare la selectarea imaginii',
  'error_uploading_photo': 'Eroare la încărcarea fotografiei',

  // Documents screens
  'statut': 'Statut',
  'methodologies': 'Metodologii',
  'no_documents_desc': 'Nu există documente în această categorie.',
  'cannot_open_file': 'Nu s-a putut deschide fișierul',
  'error_opening_file': 'Eroare la deschiderea fișierului',
  'error_loading': 'Eroare la încărcare',
  'error_loading_comments': 'Eroare la încărcarea comentariilor',
  'no_comments_yet': 'Nu există comentarii încă',

  // Polls screens
  'active_only': 'Doar active',
  'no_polls_desc': 'Nu există sondaje momentan.',
  'results': 'Rezultate',
  'options': 'Opțiuni',
  'submit_vote': 'Trimite votul',
  'vote_submitted': 'Vot trimis cu succes',
  'vote_failed': 'Eroare la trimiterea votului',
  'delete_poll': 'Șterge sondajul',
  'delete_poll_confirm': 'Ești sigur că vrei să ștergi acest sondaj?',
  'poll_deleted': 'Sondaj șters',
  'name_required': 'Numele este obligatoriu',

  // Admin screens
  'manage_users': 'Gestionare utilizatori',
  'manage_users_desc': 'Aprobă, modifică roluri',
  'search_users': 'Caută utilizatori...',
  'filter_by_role': 'Filtrează după rol',
  'clear_filter': 'Șterge filtrul',
  'no_users_found': 'Niciun utilizator găsit',
  'user_details': 'Detalii utilizator',
  'change_role': 'Schimbă rolul',
  'select_role': 'Selectează rolul',
  'change_status': 'Schimbă statusul',
  'approve_user': 'Aprobă utilizator',
  'suspend_user': 'Suspendă utilizator',
  'reactivate_user': 'Reactivează utilizator',
  'user_approved': 'Utilizator aprobat',
  'user_suspended': 'Utilizator suspendat',
  'user_reactivated': 'Utilizator reactivat',
  'role_changed': 'Rol schimbat cu succes',
  'error_approving_user': 'Eroare la aprobarea utilizatorului',
  'error_suspending_user': 'Eroare la suspendarea utilizatorului',
  'error_changing_role': 'Eroare la schimbarea rolului',
  'select_department': 'Selectează departamentul',
  'select_department_description': 'Alege departamentul pentru acest utilizator',
  'confirm_role_change': 'Confirmă schimbarea rolului',
  'confirm_role_change_desc': 'Ești sigur că vrei să schimbi rolul acestui utilizator în',
  'confirm_suspend': 'Confirmă suspendarea',
  'confirm_suspend_desc': 'Ești sigur că vrei să suspendezi acest utilizator? Nu va mai putea accesa aplicația.',
  'account_info': 'Informații cont',
  'joined': 'Înregistrat',
  'last_active': 'Ultima activitate',
  'suspended': 'Suspendat',
  'suspend': 'Suspendă',
  'suspend_user_warning': 'Utilizatorul nu va mai putea accesa aplicația.',
  'error_reactivating_user': 'Eroare la reactivarea utilizatorului',
  'change_role_to': 'Schimbă rolul în',
  'superadmin_role_protected': 'Rolul Superadmin este protejat și nu poate fi modificat',
  'bex_role_protected': 'Rolul BEX poate fi modificat doar de Superadmin',

  // Admin Dashboard
  'statistics': 'Statistici',
  'total_users': 'Total utilizatori',
  'quick_actions': 'Acțiuni rapide',
  'add_user': 'Adaugă',
  'user_added_successfully': 'Utilizator adăugat cu succes',
  'error_creating_user': 'Eroare la crearea utilizatorului',
  'error_saving_profile': 'Eroare la salvarea profilului. Încearcă din nou.',
  'user_password_info': 'Utilizatorul va trebui să folosească "Am uitat parola" pentru a-și seta parola la prima autentificare.',
  'bex_county_restriction': 'Poți adăuga utilizatori doar în județul tău',
  'announce': 'Anunț',
  'pending_approvals': 'În așteptare',
  'no_pending_approvals': 'Nicio aprobare în așteptare',
  'recent_activity': 'Activitate recentă',
  'no_recent_activity': 'Nicio activitate recentă',
  'active_polls': 'Sondaje active',

  // Schools Management
  'manage_schools': 'Gestionare Școli',
  'search_schools': 'Caută școli...',
  'no_schools': 'Nu s-au găsit școli',
  'add_school': 'Adaugă Școală',
  'edit_school': 'Editare Școală',
  'short_name': 'Nume scurt',
  'no_representative': 'Niciun reprezentant atribuit',
  'assign': 'Atribuie',
  'select_representative': 'Selectează Reprezentant',
  'school_created': 'Școala a fost creată',
  'school_updated': 'Școala a fost actualizată',
  'school_deleted': 'Școala a fost ștearsă',
  'error_saving_school': 'Eroare la salvarea școlii',
  'error_updating_school': 'Eroare la actualizarea școlii',
  'error_deleting_school': 'Eroare la ștergerea școlii',
  'delete_school_warning': 'Ești sigur că vrei să ștergi această școală? Acest lucru va afecta toți elevii asociați.',

  // Polls Creation
  'poll_type': 'Tip Sondaj',
  'question': 'Întrebare',
  'enter_question': 'Introdu întrebarea',
  'description': 'Descriere',
  'optional': 'opțional',
  'enter_description': 'Introdu o descriere',
  'option': 'Opțiune',
  'anonymous_voting': 'Vot Anonim',
  'anonymous_voting_desc': 'Identitățile votanților vor fi ascunse',
  'allow_multiple_votes': 'Permite Voturi Multiple',
  'allow_multiple_votes_desc': 'Utilizatorii pot vota pentru mai multe opțiuni',
  'voting_period': 'Perioada de Votare',
  'end_date_before_start': 'Data de sfârșit trebuie să fie după data de început',
  'poll_created': 'Sondajul a fost creat',
  'error_creating_poll': 'Eroare la crearea sondajului',
  'continue': 'Continuă',

  // Documents Upload
  'select_file': 'Selectează Fișier',
  'tap_to_select_file': 'Apasă pentru a selecta un fișier',
  'category': 'Categorie',
  'tags': 'Etichete',
  'add_tag': 'Adaugă o etichetă',
  'public_document': 'Document Public',
  'public_document_desc': 'Acest document va fi vizibil pentru toți utilizatorii',
  'minimum_role_required': 'Rol minim necesar',
  'select_minimum_role': 'Selectează rolul minim',
  'minimum_role_hint': 'Utilizatorii cu acest rol sau superior pot vizualiza documentul',
  'school_document': 'Document Școlar',
  'school_document_desc': 'Acest document aparține școlii tale',
  'school_document_required': 'Ca reprezentant de școală, documentele tale sunt asociate școlii',
  'document_title_hint': 'Introdu titlul documentului',
  'document_description_hint': 'Introdu descrierea documentului',
  'document_uploaded': 'Documentul a fost încărcat',
  'error_uploading_document': 'Eroare la încărcarea documentului',

  // Initiatives Creation
  'basic_information': 'Informații de Bază',
  'basic_info_desc': 'Începe prin adăugarea informațiilor de bază despre inițiativa ta',
  'tags_desc': 'Adaugă până la 5 etichete pentru a-ți categorisi inițiativa',
  'detailed_proposal': 'Propunere Detaliată',
  'detailed_proposal_desc': 'Oferă mai multe detalii despre inițiativa ta',
  'problem_statement': 'Problema Identificată',
  'proposed_solution': 'Soluția Propusă',
  'expected_impact': 'Impactul Așteptat',
  'comments_support': 'Comentarii și Susținere',
  'no_impact': 'Niciun impact definit',
  'no_impact_description': 'Această inițiativă nu are încă un impact așteptat definit.',
  'review_submit': 'Revizuire și Trimitere',
  'review_submit_desc': 'Revizuiește inițiativa înainte de trimitere',
  'untitled': 'Fără titlu',
  'no_description': 'Nicio descriere oferită',
  'proposal_details': 'Detalii Propunere',
  'initiative_review_info': 'Inițiativa ta va fi revizuită de consiliul elevilor înainte de a fi publicată.',
  'description_too_short': 'Descrierea trebuie să aibă cel puțin 50 de caractere',
  'error_submitting_initiative': 'Eroare la trimiterea inițiativei',

  // User Detail
  'delete_user': 'Șterge Utilizator',
  'delete_user_confirm': 'Ești sigur că vrei să ștergi acest utilizator? Această acțiune nu poate fi anulată.',
  'user_deleted': 'Utilizatorul a fost șters',
  'error_deleting_user': 'Eroare la ștergerea utilizatorului',
  'users': 'Utilizatori',

  // Warnings & Absences
  'warnings': 'Avertismente',
  'absences': 'Absențe',
  'warnings_absences': 'Avertismente și Absențe',
  'issue_warning': 'Emite Avertisment',
  'warning_type': 'Tip Avertisment',
  'deactivate_warning': 'Dezactivează Avertisment',
  'deactivate_warning_confirm': 'Ești sigur că vrei să dezactivezi acest avertisment?',
  'warning_deactivated': 'Avertisment dezactivat',
  'error_deactivating_warning': 'Eroare la dezactivarea avertismentului',
  'mark_excused': 'Marchează Motivat',
  'absence_updated': 'Absență actualizată',
  'error_updating_absence': 'Eroare la actualizarea absenței',
  'warning_issued': 'Avertisment emis cu succes',
  'error_issuing_warning': 'Eroare la emiterea avertismentului',
  'select_user': 'Selectează Utilizator',
  'reason': 'Motiv',
  'reason_hint': 'Introduceți motivul avertismentului',
  'details_optional': 'Detalii (opțional)',
  'details_hint': 'Introduceți detalii suplimentare',
  'add_warning': 'Adaugă Avertisment',
  'warning_reason': 'Motivul avertismentului',
  'enter_warning_reason': 'Introdu motivul avertismentului',
  'warning_added': 'Avertisment adăugat',
  'error_adding_warning': 'Eroare la adăugarea avertismentului',
  'resolve_warning': 'Rezolvă Avertisment',
  'resolution_note': 'Notă de rezolvare',
  'optional_resolution_note': 'Notă opțională de rezolvare',
  'warning_resolved': 'Avertisment rezolvat',
  'error_resolving_warning': 'Eroare la rezolvarea avertismentului',
  'remove_warning': 'Șterge Avertisment',
  'remove_warning_confirm': 'Ești sigur că vrei să ștergi acest avertisment?',
  'warning_removed': 'Avertisment șters',
  'error_removing_warning': 'Eroare la ștergerea avertismentului',
  'active_warning': 'Activ',
  'resolved_warning': 'Rezolvat',
  'issued_by': 'Emis de',
  'resolved_by': 'Rezolvat de',
  'no_warnings': 'Niciun avertisment',
  'add_absence': 'Adaugă Absență',
  'absence_meeting_id': 'ID Ședință',
  'absence_added': 'Absență adăugată',
  'error_adding_absence': 'Eroare la adăugarea absenței',
  'excuse_absence': 'Motivează Absența',
  'excuse_reason': 'Motiv',
  'enter_excuse_reason': 'Introdu motivul',
  'absence_excused': 'Absență motivată',
  'error_excusing_absence': 'Eroare la motivarea absenței',
  'remove_absence': 'Șterge Absența',
  'remove_absence_confirm': 'Ești sigur că vrei să ștergi această absență?',
  'absence_removed': 'Absență ștearsă',
  'error_removing_absence': 'Eroare la ștergerea absenței',
  'unexcused': 'Nemotivat',
  'recorded_by': 'Înregistrat de',
  'no_absences': 'Nicio absență',

  // GDS (Support Groups)
  'support_groups': 'Grupuri de Suport',
  'manage_gds': 'Gestionare GDS',
  'search_gds': 'Caută grupuri...',
  'no_gds': 'Nu s-au găsit grupuri',
  'no_gds_message': 'Nu există grupuri de suport încă. Creează primul grup!',
  'add_gds': 'Adaugă Grup',
  'edit_gds': 'Editează Grup',
  'create_gds': 'Creează Grup',
  'gds_name': 'Nume Grup',
  'gds_description': 'Descriere',
  'gds_description_hint': 'Descrie scopul și activitățile grupului',
  'gds_focus': 'Focus/Temă',
  'focus_area': 'Aria de Focus',
  'gds_leader': 'Lider',
  'select_leader': 'Selectează Lider',
  'gds_members': 'Membri',
  'gds_created': 'Grup creat cu succes',
  'gds_updated': 'Grup actualizat cu succes',
  'gds_deleted': 'Grup șters cu succes',
  'error_saving_gds': 'Eroare la salvarea grupului',
  'error_updating_gds': 'Eroare la actualizarea grupului',
  'error_deleting_gds': 'Eroare la ștergerea grupului',
  'delete_gds_warning': 'Ești sigur că vrei să ștergi acest grup?',
  'activate': 'Activează',
  'deactivate': 'Dezactivează',
  'gds_status_changed': 'Status grup schimbat',
  'error_changing_gds_status': 'Eroare la schimbarea statusului',
  'member_role': 'Rol Membru',
  'add_member': 'Adaugă Membru',
  'member_added': 'Membru adăugat cu succes',
  'error_adding_member': 'Eroare la adăugarea membrului',
  'remove_member': 'Șterge Membru',
  'confirm_remove_member': 'Confirmă ștergerea',
  'remove_member_message': 'Ești sigur că vrei să ștergi acest membru:',
  'member_removed': 'Membru șters cu succes',
  'error_removing_member': 'Eroare la ștergerea membrului',
  'change_leader': 'Schimbă Lider',
  'no_members': 'Niciun membru',
  'no_users_available': 'Nu există utilizatori disponibili',
  'leader': 'Lider',
  'none': 'Niciunul',
  'change': 'Schimbă',
  'school_members': 'Membri Școală',
  'total': 'Total',

  // CSV Import
  'import_csv': 'Import CSV',
  'import_users': 'Importă Utilizatori',
  'import_users_subtitle': 'Încarcă un fișier CSV cu datele utilizatorilor',
  'csv_format': 'Format CSV',
  'select_csv_file': 'Selectează fișier CSV',
  'tap_to_select': 'Apasă pentru a selecta',
  'import': 'Importă',
  'import_results': 'Rezultate Import',
  'total_rows': 'Total rânduri',
  'successful': 'Reușite',
  'errors': 'Erori',
  'error_details': 'Detalii Erori',

  // Share App
  'share_app_message': 'Descoperă aplicația CJE - Consiliul Județean al Elevilor! Conectează-te cu comunitatea ta școlară și implică-te în activitățile consiliului. 🎓📱',

  // User Detail Screen
  'select_new_role': 'Selectează un nou rol',
  'manage_status': 'Gestionează Status',
  'user_information': 'Informații Utilizator',
  'user_not_found': 'Utilizator negăsit',
  'confirm_remove_warning': 'Confirmă ștergerea avertismentului',
  'remove_warning_message': 'Ești sigur că vrei să ștergi acest avertisment? Această acțiune nu poate fi anulată.',
  'confirm_remove_absence': 'Confirmă ștergerea absenței',
  'remove_absence_message': 'Ești sigur că vrei să ștergi această absență? Această acțiune nu poate fi anulată.',
  'warning_reason_hint': 'Introdu motivul avertismentului...',
  'resolution_note_hint': 'Notă opțională de rezolvare...',
  'excuse_reason_hint': 'Introdu motivul pentru absență...',
  'resolve': 'Rezolvă',
  'remove': 'Șterge',
  'excuse': 'Motivează',

  // Role names for display
  'role_student': 'Elev',
  'role_class_rep': 'Reprezentant de Clasă',
  'role_school_rep': 'Reprezentant de Școală',
  'role_department': 'Departament',
  'role_bex': 'BEx',
  'role_superadmin': 'Super Admin',

  // Home Screen
  'your_impact_this_month': 'Impactul Tău\nLuna Aceasta',

  // Search Screen
  'search_title': 'Caută',
  'search_description': 'Caută comunicări, ședințe, inițiative, sondaje și documente',
  'search_placeholder': 'Caută...',
  'search_min_length': 'Introdu cel puțin 2 caractere',
  'no_results': 'Niciun rezultat',
  'no_results_for': 'Niciun rezultat pentru',
  'results_found': 'rezultate găsite',

  // Notifications Screen
  'mark_all_read': 'Marchează toate ca citite',
  'clear_all': 'Șterge tot',
  'no_notifications_desc': 'Nu ai notificări noi momentan',
  'all_marked_read': 'Toate notificările au fost marcate ca citite',
  'error_marking_read': 'Eroare la marcarea notificărilor',
  'clear_all_notifications': 'Șterge toate notificările',
  'clear_all_notifications_desc': 'Ești sigur că vrei să ștergi toate notificările? Această acțiune nu poate fi anulată.',
  'notifications_cleared': 'Notificările au fost șterse',
  'error_clearing_notifications': 'Eroare la ștergerea notificărilor',

  // Privacy & Security (new keys only)
  'privacy_security': 'Confidențialitate & Securitate',
  'privacy_security_subtitle': 'Parolă, Cont',
  'delete_account_subtitle': 'Permanent și irecuperabil',
  'fill_all_fields': 'Completează toate câmpurile',
  'password_min_length': 'Parola trebuie să aibă cel puțin 6 caractere',
  'passwords_not_match': 'Parolele nu se potrivesc',
  'password_changed_success': 'Parola a fost schimbată cu succes',
  'google_password_message': 'Te-ai autentificat cu Google. Pentru a schimba parola, accesează setările contului tău Google.',

  // Help & Support (new keys only)
  'help_support': 'Ajutor & Suport',
  'help_support_subtitle': 'FAQ, Contactează-ne',
  'contact_us': 'Contactează-ne',
  'email_us': 'Trimite-ne un email',
  'call_us': 'Sună-ne',
  'website': 'Site web',
  'faq': 'Întrebări frecvente',
  'faq_q1': 'Cum pot să-mi schimb parola?',
  'faq_a1': 'Mergi la Profil > Confidențialitate & Securitate > Schimbă parola. Introdu parola curentă și noua parolă pentru a face modificarea.',
  'faq_q2': 'Cum pot participa la sondaje?',
  'faq_a2': 'Deschide secțiunea Sondaje din meniul principal. Selectează un sondaj activ și votează pentru opțiunea preferată.',
  'faq_q3': 'Cum propun o inițiativă?',
  'faq_a3': 'Mergi la secțiunea Inițiative și apasă butonul + pentru a crea o nouă inițiativă. Completează detaliile și trimite pentru aprobare.',
  'faq_q4': 'Cine poate vedea datele mele?',
  'faq_a4': 'Datele tale personale sunt vizibile doar pentru administratorii CJE și reprezentanții școlii tale. Nu partajăm date cu terți.',
  'faq_q5': 'Cum contactez suportul tehnic?',
  'faq_a5': 'Poți să ne trimiți un email la support@cje.ro sau să ne suni la numărul afișat în secțiunea Contactează-ne.',

  // Legal - Terms of Service
  'last_updated': 'Ultima actualizare: Decembrie 2024',
  'terms_section_1_title': '1. Acceptarea Termenilor',
  'terms_section_1_content': 'Prin accesarea și utilizarea aplicației Consiliul Județean al Elevilor (CJE), acceptați să fiți obligat de acești Termeni și Condiții. Dacă nu sunteți de acord cu acești termeni, vă rugăm să nu utilizați aplicația.',
  'terms_section_2_title': '2. Utilizarea Aplicației',
  'terms_section_2_content': 'Aplicația CJE este destinată elevilor, reprezentanților școlari și administratorilor din cadrul consiliilor județene ale elevilor. Utilizatorii trebuie să furnizeze informații corecte la înregistrare și să mențină confidențialitatea contului lor.',
  'terms_section_3_title': '3. Conduita Utilizatorului',
  'terms_section_3_content': 'Utilizatorii se angajează să folosească aplicația în mod responsabil, să respecte drepturile celorlalți utilizatori și să nu distribuie conținut ofensator, ilegal sau dăunător. Încălcarea acestor reguli poate duce la suspendarea contului.',
  'terms_section_4_title': '4. Proprietate Intelectuală',
  'terms_section_4_content': 'Tot conținutul aplicației, inclusiv design-ul, textele și funcționalitățile, este proprietatea CJE. Utilizatorii nu au dreptul să copieze, modifice sau distribuie conținutul fără acordul prealabil.',
  'terms_section_5_title': '5. Limitarea Răspunderii',
  'terms_section_5_content': 'CJE nu își asumă răspunderea pentru eventualele pierderi sau daune rezultate din utilizarea aplicației. Serviciul este oferit "așa cum este" fără garanții de niciun fel.',

  // Legal - Privacy Policy
  'privacy_section_1_title': '1. Colectarea Datelor',
  'privacy_section_1_content': 'Colectăm date personale precum: nume, adresă de email, școală, clasă și rol în consiliu. Aceste informații sunt necesare pentru funcționarea corectă a aplicației și pentru identificarea utilizatorilor.',
  'privacy_section_2_title': '2. Utilizarea Datelor',
  'privacy_section_2_content': 'Datele colectate sunt folosite pentru: autentificare, comunicare între membri, gestionarea activităților consiliului și îmbunătățirea serviciilor. Nu vindem și nu partajăm datele cu terți pentru scopuri comerciale.',
  'privacy_section_3_title': '3. Stocarea și Securitatea',
  'privacy_section_3_content': 'Datele sunt stocate securizat folosind serviciile Firebase (Google). Implementăm măsuri tehnice și organizatorice pentru a proteja informațiile împotriva accesului neautorizat.',
  'privacy_section_4_title': '4. Drepturile Utilizatorilor',
  'privacy_section_4_content': 'Aveți dreptul să: accesați datele dvs., să solicitați corectarea sau ștergerea lor, să vă opuneți procesării și să solicitați portabilitatea datelor. Contactați-ne pentru exercitarea acestor drepturi.',
  'privacy_section_5_title': '5. Contact',
  'privacy_section_5_content': 'Pentru întrebări legate de politica de confidențialitate sau pentru exercitarea drepturilor GDPR, ne puteți contacta la adresa de email: privacy@cje.ro',

  // Greetings
  'good_morning': 'Bună dimineața',
  'good_afternoon': 'Bună ziua',
  'good_evening': 'Bună seara',

  // Time Ago
  'just_now': 'Chiar acum',
  'min_ago': 'min în urmă',
  'hour_ago': 'oră în urmă',
  'hours_ago': 'ore în urmă',
  'day_ago': 'zi în urmă',
  'days_ago': 'zile în urmă',

  // Cancel Registration Dialog
  'cancel_registration': 'Anulezi înregistrarea?',
  'cancel_registration_message': 'Dacă anulezi, vei fi deconectat și va trebui să te înregistrezi din nou.',
  'yes_cancel': 'Da, anulează',

  // Login Screen
  'email_address': 'Adresa de email',
  'email_hint': 'Adresa de email...',
  'password_hint': 'Parola...',
  'continue_with_google': 'Continuă cu Google',
  'admin_setup_taps': 'Mai sunt {count} atingeri pentru configurare admin',

  // Online Meeting
  'this_is_online_meeting': 'Aceasta este o întâlnire online',
  'example_name': 'ex: Ion Popescu',

  // Facebook/Instagram
  'facebook': 'Facebook',
  'instagram': 'Instagram',
  'facebook_url': 'URL Facebook',
  'instagram_url': 'URL Instagram',

  // Home Screen
  'see_all': 'Vezi tot',
  'upcoming_events': 'Evenimente viitoare',
  'check_back_later': 'Reveniți mai târziu pentru actualizări',
  'ends': 'Se termină',
  'ends_on': 'Se termină la',
  'min': 'min',

  // Menu Screen
  'menu': 'Meniu',
  'dark_mode': 'Mod întunecat',
  'documents_subtitle': 'Documente și formulare',
  'polls_subtitle': 'Sondaje și voturi',
  'calendar_subtitle': 'Evenimente și întâlniri',
  'administration': 'Administrare',
  'schools_subtitle': 'Gestionează școlile',
  'gds_subtitle': 'Grupuri de suport',
  'analytics': 'Analiză',
  'analytics_subtitle': 'Statistici și rapoarte',
  'county_settings': 'Setări Județ',
  'county_settings_subtitle': 'Contact și rețele sociale',
  'county_settings_description': 'Editează informațiile de contact pentru Help & Support',
  'settings_info': 'Modificările vor fi vizibile în secțiunea Help & Support',
  'select_county': 'Selectează Județul',
  'contact_info': 'Informații de Contact',
  'social_media': 'Rețele Sociale',
  'save_changes': 'Salvează',
  'settings_saved': 'Setările au fost salvate cu succes',
  'error_saving_settings': 'Eroare la salvarea setărilor',

  // Ideas Screen
  'ideas': 'Idei',
  'show_active_polls_only': 'Afișează doar sondajele active',

  // Edit Initiative
  'edit_initiative_info': 'Actualizează detaliile inițiativei tale. Modificările vor fi salvate imediat.',
  'update_initiative': 'Actualizează Inițiativa',
  'initiative_updated': 'Inițiativa a fost actualizată cu succes',
  'error_updating_initiative': 'Eroare la actualizarea inițiativei',

  // Snackbar & Toast Messages
  'exit_app': 'Ieșire din aplicație?',
  'exit_app_confirm': 'Doriți să ieșiți din aplicație?',
  'exit': 'Ieșire',
  'verification_email_resent': 'Email de verificare trimis!',
  'error_sending_email': 'Eroare la trimitere',
  'account_created_wait_approval': 'Cont creat! Vă rugăm așteptați aprobarea.',
  'error_picking_file': 'Eroare la selectarea fișierului',
  'error_uploading_file': 'Eroare la încărcarea fișierului',
  'error_picking_files': 'Eroare la selectarea fișierelor',
  'user_rejected': 'Utilizator respins',
  'error_rejecting_user': 'Eroare la respingerea utilizatorului',
  'initiative_submitted_for_review': 'Inițiativa a fost trimisă pentru verificare',
  'action_failed': 'Acțiunea a eșuat',
  'failed': 'Eșuat',
  'contact_support_delete_account': 'Vă rugăm contactați suportul pentru a vă șterge contul',
  'error_importing': 'Eroare la import',
  'cannot_open_document': 'Nu se poate deschide documentul',
  'cannot_open_link': 'Nu se poate deschide linkul',
  'select_city_first': 'Selectați mai întâi județul',

  // Auth Errors
  'auth_error_user_not_found': 'Nu există un cont cu această adresă de email.',
  'auth_error_wrong_password': 'Parola este incorectă.',
  'auth_error_invalid_email': 'Adresa de email nu este validă.',
  'auth_error_user_disabled': 'Acest cont a fost dezactivat.',
  'auth_error_email_already_in_use': 'Există deja un cont cu această adresă de email.',
  'auth_error_weak_password': 'Parola este prea slabă. Folosește cel puțin 6 caractere.',
  'auth_error_operation_not_allowed': 'Această operațiune nu este permisă.',
  'auth_error_too_many_requests': 'Prea multe încercări. Încearcă din nou mai târziu.',
  'auth_error_network_request_failed': 'Eroare de conexiune. Verifică internetul.',
  'auth_error_invalid_credential': 'Email sau parolă incorectă.',
  'auth_error_requires_recent_login': 'Te rugăm să te autentifici din nou pentru această operațiune.',
  'auth_error_default': 'A apărut o eroare. Încearcă din nou.',
};

// ============================================
// ENGLISH TRANSLATIONS
// ============================================

const Map<String, String> _enStrings = {
  // App General
  'app_name': 'CJE',
  'app_name_full': 'County Student Council',
  'app_tagline': 'The voice of students',

  // Common Actions
  'save': 'Save',
  'cancel': 'Cancel',
  'delete': 'Delete',
  'edit': 'Edit',
  'add': 'Add',
  'create': 'Create',
  'publish': 'Publish',
  'update': 'Update',
  'confirm': 'Confirm',
  'close': 'Close',
  'back': 'Back',
  'next': 'Next',
  'done': 'Done',
  'submit': 'Submit',
  'retry': 'Retry',
  'refresh': 'Refresh',
  'search': 'Search',
  'filter': 'Filter',
  'my_initiatives': 'My Initiatives',
  'show_only_my_initiatives': 'Show only initiatives I created',
  'my_school': 'My School',
  'show_school_initiatives': 'Show initiatives from my school',
  'all_schools': 'All Schools',
  'show_all_initiatives': 'Show initiatives from all schools',
  'target_school': 'Target School',
  'send_to_all_schools': 'Send notification to all schools',
  'select_school': 'Select school',
  'no_schools_available': 'No schools available',
  'error_loading_schools': 'Error loading schools',
  'sort': 'Sort',
  'view': 'View',
  'view_all': 'View all',
  'see_more': 'See more',
  'see_less': 'See less',
  'loading': 'Loading...',
  'yes': 'Yes',
  'no': 'No',
  'ok': 'OK',
  'apply': 'Apply',
  'reset': 'Reset',
  'clear': 'Clear',
  'select': 'Select',
  'select_all': 'Select all',
  'deselect_all': 'Deselect all',
  'share': 'Share',
  'download': 'Download',
  'upload': 'Upload',
  'copy': 'Copy',
  'paste': 'Paste',

  // Authentication
  'login': 'Login',
  'login_subtitle': 'Enter your email and password to\naccess your account',
  'logout': 'Logout',
  'register': 'Register',
  'sign_in': 'Sign in',
  'sign_up': 'Sign up',
  'sign_out': 'Sign out',
  'forgot_password': 'Forgot password?',
  'reset_password': 'Reset password',
  'change_password': 'Change password',
  'email': 'Email',
  'password': 'Password',
  'confirm_password': 'Confirm password',
  'current_password': 'Current password',
  'new_password': 'New password',
  'remember_me': 'Remember me',
  'stay_logged_in': 'Stay logged in',
  'sign_in_with_google': 'Sign in with Google',
  'dont_have_account': "Don't have an account?",
  'already_have_account': 'Already have an account?',
  'create_account': 'Create account',
  'verify_email': 'Verify email',
  'email_sent': 'Email sent',
  'check_email': 'Check your email',

  // User Profile
  'profile': 'Profile',
  'view_profile': 'View profile',
  'edit_profile': 'Edit profile',
  'my_profile': 'My profile',
  'first_name': 'First name',
  'last_name': 'Last name',
  'full_name': 'Full name',
  'phone': 'Phone',
  'phone_number': 'Phone number',
  'date_of_birth': 'Date of birth',
  'gender': 'Gender',
  'male': 'Male',
  'female': 'Female',
  'other': 'Other',
  'bio': 'Bio',
  'about': 'About',
  'profile_photo': 'Profile photo',
  'change_photo': 'Change photo',
  'remove_photo': 'Remove photo',

  // Navigation & Sections
  'home': 'Home',
  'dashboard': 'Dashboard',
  'announcements': 'Announcements',
  'meetings': 'Meetings',
  'meeting_type_county_ag': 'County AG',
  'meeting_type_bex': 'BEx',
  'meeting_type_department': 'Department',
  'meeting_type_school': 'School',
  'initiatives': 'Initiatives',
  'documents': 'Documents',
  'files': 'files',
  'add_document': 'Add document',
  'polls': 'Polls',
  'calendar': 'Calendar',
  'notifications': 'Notifications',
  'notifications_subtitle': 'Push, email, SMS',
  'notify': 'Notify',
  'send_notification': 'Send notification',
  'county_notification_info': 'This notification will be sent to all selected users in the county.',
  'notification_type': 'Notification type',
  'notification_title_hint': 'Enter notification title',
  'notification_body_hint': 'Write your notification message...',
  'target_audience': 'Target audience',
  'all_users': 'All users',
  'send_to_all_users': 'Send notification to all users',
  'select_roles': 'Select roles',
  'select_at_least_one_role': 'Select at least one role',
  'confirm_send': 'Confirm send',
  'send_notification_confirm': 'Are you sure you want to send this notification?',
  'sending': 'Sending...',
  'notification_sent': 'Notification sent successfully',
  'error_sending_notification': 'Error sending notification',
  'general': 'General',
  'approval': 'Approval',
  'settings': 'Settings',
  'admin': 'Admin',
  'help': 'Help',
  'tech_support': 'Support',
  'feedback': 'Feedback',
  'members': 'Members',
  'more': 'More',
  'management': 'Management',
  'view_schools': 'View county schools',
  'county_documents': 'County-level documents',
  'communication': 'Communication',
  'notify_county_members': 'Send notifications to members',
  'view_edit_profile': 'View and edit profile',
  'change_language': 'Change app language',
  'change_theme': 'Change app theme',
  'select_theme': 'Select theme',
  'light': 'Light',
  'dark': 'Dark',
  'system': 'System',
  'search_members': 'Search members...',
  'agenda_items': 'agenda items',
  'past': 'Past',
  'overview': 'Overview',

  // Announcements
  'announcement': 'Announcement',
  'new_announcement': 'New announcement',
  'create_announcement': 'Create announcement',
  'edit_announcement': 'Edit announcement',
  'announcement_title': 'Announcement title',
  'announcement_content': 'Announcement content',
  'announcement_type': 'Announcement type',
  'publish_announcement': 'Publish announcement',
  'pinned': 'Pinned',
  'unpinned': 'Unpinned',
  'priority': 'Priority',
  'urgent': 'Urgent',
  'important': 'Important',
  'normal': 'Normal',
  'info': 'Info',

  // Meetings
  'meeting': 'Meeting',
  'new_meeting': 'New meeting',
  'create_meeting': 'Create meeting',
  'edit_meeting': 'Edit meeting',
  'meeting_title': 'Meeting title',
  'meeting_description': 'Meeting description',
  'meeting_date': 'Meeting date',
  'meeting_time': 'Meeting time',
  'meeting_location': 'Meeting location',
  'meeting_type': 'Meeting type',
  'to_be_determined': 'TBD',
  'online': 'Online',
  'in_person': 'In person',
  'hybrid': 'Hybrid',
  'agenda': 'Agenda',
  'agenda_item': 'Agenda item',
  'add_agenda_item': 'Add agenda item',
  'attendees': 'Attendees',
  'attendance': 'Attendance',
  'present': 'Present',
  'absent': 'Absent',
  'excused': 'Excused',
  'pending': 'Pending',
  'confirm_attendance': 'Confirm attendance',
  'join_meeting': 'Join meeting',
  'meeting_link': 'Meeting link',
  'duration': 'Duration',
  'minutes': 'minutes',
  'meeting_minutes': 'Meeting minutes',
  'minutes_uploaded': 'Minutes uploaded',
  'upload_minutes': 'Upload minutes',
  'tap_to_replace': 'Tap to replace',
  'add_attendees': 'Add attendees',
  'no_attendees': 'No attendees added',
  'meeting_updated': 'Meeting updated',
  'error_updating_meeting': 'Error updating meeting',

  // Initiatives
  'initiative': 'Initiative',
  'new_initiative': 'New initiative',
  'create_initiative': 'Create initiative',
  'edit_initiative': 'Edit initiative',
  'initiative_type': 'Initiative type',
  'initiative_title': 'Initiative title',
  'initiative_description': 'Initiative description',
  'initiative_status': 'Initiative status',
  'proposed': 'Proposed',
  'in_discussion': 'In discussion',
  'approved': 'Approved',
  'rejected': 'Rejected',
  'in_progress': 'In progress',
  'completed': 'Completed',
  'on_hold': 'On hold',
  'cancelled': 'Cancelled',
  'vote': 'Vote',
  'vote_for': 'Vote for',
  'vote_against': 'Vote against',
  'abstain': 'Abstain',
  'voter_details': 'Voter details',
  'votes': 'Votes',
  'no_votes_yet': 'No votes yet',
  'error_loading_votes': 'Error loading votes',
  'comments': 'Comments',
  'add_comment': 'Add comment',
  'manage_initiative': 'Manage initiative',
  'approve': 'Approve',
  'reject': 'Reject',
  'adopt': 'Adopt',
  'move_to_debate': 'Move to debate',
  'move_to_voting': 'Move to voting',
  'reject_initiative': 'Reject initiative',
  'reject_initiative_reason': 'Please provide a reason for rejection:',
  'enter_reason': 'Enter reason...',
  'reason_required': 'Reason is required',

  // Documents
  'document': 'Document',
  'new_document': 'New document',
  'upload_document': 'Upload document',
  'upload_document_desc': 'Upload new documents to the platform',
  'document_title': 'Document title',
  'document_description': 'Document description',
  'document_category': 'Document category',
  'file_type': 'File type',
  'file_size': 'File size',
  'uploaded_by': 'Uploaded by',
  'uploaded_at': 'Uploaded at',
  'download_document': 'Download document',
  'view_document': 'View document',
  'regulations': 'Regulations',
  'protocols': 'Protocols',
  'reports': 'Reports',
  'templates': 'Templates',
  'forms': 'Forms',
  'regulamente': 'Regulations',
  'ghiduri': 'Guides',
  'utile': 'Useful',
  'rapoarte': 'Reports',

  // Polls
  'poll': 'Poll',
  'new_poll': 'New poll',
  'create_poll': 'Create poll',
  'edit_poll': 'Edit poll',
  'poll_question': 'Poll question',
  'poll_options': 'Poll options',
  'add_option': 'Add option',
  'remove_option': 'Remove option',
  'vote_poll': 'Vote',
  'poll_results': 'Poll results',
  'total_votes': 'Total votes',
  'end_date': 'End date',
  'poll_ended': 'Poll ended',
  'poll_active': 'Poll active',
  'poll_school': 'School Poll',
  'poll_county': 'County Poll',
  'anonymous': 'Anonymous',
  'multiple_choice': 'Multiple choice',
  'single_choice': 'Single choice',

  // Schools & Organizations
  'school': 'School',
  'schools': 'Schools',
  'school_name': 'School name',
  'class': 'Class',
  'school_address': 'School address',
  'city': 'City',
  'county': 'County',
  'region': 'Region',
  'organization': 'Organization',
  'department': 'Department',
  'gds': 'GDS',
  'bex': 'BEx',

  // User Roles
  'role': 'Role',
  'student': 'Student',
  'class_representative': 'Class representative',
  'school_representative': 'School representative',
  'department_member': 'Department member',
  'bex_member': 'BEx member',
  'super_admin': 'Super Admin',
  'administrator': 'Administrator',
  'member': 'Member',
  'guest': 'Guest',

  // Settings
  'general_settings': 'General settings',
  'account_settings': 'Account settings',
  'notification_settings': 'Notification settings',
  'privacy_settings': 'Privacy settings',
  'appearance': 'Appearance',
  'theme': 'Theme',
  'light_theme': 'Light theme',
  'dark_theme': 'Dark theme',
  'system_theme': 'System theme',
  'language': 'Language',
  'select_language': 'Select language',
  'push_notifications': 'Push notifications',
  'email_notifications': 'Email notifications',
  'sound_notifications': 'Sound notifications',
  'vibration': 'Vibration',
  'privacy_policy': 'Privacy policy',
  'terms_of_service': 'Terms of service',
  'about_app': 'About app',
  'version': 'Version',
  'delete_account': 'Delete account',

  // Time & Date
  'today': 'Today',
  'yesterday': 'Yesterday',
  'tomorrow': 'Tomorrow',
  'this_week': 'This week',
  'last_week': 'Last week',
  'next_week': 'Next week',
  'this_month': 'This month',
  'last_month': 'Last month',
  'next_month': 'Next month',
  'date': 'Date',
  'time': 'Time',
  'start_date': 'Start date',
  'start_time': 'Start time',
  'now': 'Now',
  'ago': 'ago',
  'in_time': 'in',

  // Status & States
  'active': 'Active',
  'ended': 'Ended',
  'upcoming': 'Upcoming',
  'inactive': 'Inactive',
  'enabled': 'Enabled',
  'disabled': 'Disabled',
  'verified': 'Verified',
  'unverified': 'Unverified',
  'published': 'Published',
  'draft': 'Draft',
  'archived': 'Archived',
  'deleted': 'Deleted',
  'open': 'Open',
  'closed': 'Closed',
  'new': 'New',
  'read': 'Read',
  'unread': 'Unread',

  // Messages & Feedback
  'success': 'Success',
  'error': 'Error',
  'warning': 'Warning',
  'information': 'Information',
  'saved_successfully': 'Saved successfully',
  'deleted_successfully': 'Deleted successfully',
  'updated_successfully': 'Updated successfully',
  'created_successfully': 'Created successfully',
  'something_went_wrong': 'Something went wrong',
  'try_again': 'Try again',
  'no_data_found': 'No data found',
  'no_results_found': 'No results found',
  'no_items_yet': 'No items yet',
  'no_notifications': 'No notifications',
  'no_announcements': 'No announcements',
  'no_meetings': 'No meetings scheduled',
  'no_initiatives': 'No initiatives',
  'no_documents': 'No documents',
  'no_polls': 'No polls',
  'participants': 'Participants',
  'created_by': 'Created by',
  'no_agenda': 'No agenda',
  'no_agenda_description': 'No agenda has been added for this meeting',
  'no_documents_description': 'No documents have been added for this meeting',
  'no_participants': 'No participants',
  'no_participants_description': 'No participants have been added for this meeting',
  'invited': 'invited',
  'attendance_not_recorded': 'Attendance has not been recorded yet',
  'error_loading_participants': 'Error loading participants',
  'location_tbd': 'Location TBD',
  'add_participant': 'Add participant',
  'attendance_recorded': 'Attendance recorded',
  'invited_pending': 'Invited (pending)',
  'mark_present': 'Mark present',
  'mark_absent': 'Mark absent',
  'marked_present': 'Marked as present',
  'marked_absent': 'Marked as absent',
  'error_updating_attendance': 'Error updating attendance',
  'search_to_add_participants': 'Search to add participants',
  'error_searching_users': 'Error searching users',
  'added_as_participant': 'was added as participant',
  'connection_error': 'Connection error',
  'check_connection': 'Check your internet connection',
  'session_expired': 'Session expired',
  'please_login_again': 'Please login again',
  'are_you_sure': 'Are you sure?',
  'cannot_be_undone': 'This action cannot be undone',
  'confirm_delete': 'Confirm delete',
  'confirm_logout': 'Confirm logout',

  // Validation Messages
  'required': 'Required',
  'field_required': 'This field is required',
  'invalid_email': 'Invalid email',
  'invalid_phone': 'Invalid phone number',
  'invalid_password': 'Invalid password',
  'password_too_short': 'Password is too short',
  'passwords_do_not_match': 'Passwords do not match',
  'invalid_credentials': 'Invalid credentials',
  'email_already_exists': 'Email already exists',
  'weak_password': 'Weak password',
  'too_short': 'Too short',
  'too_long': 'Too long',
  'invalid_format': 'Invalid format',
  'min_characters': 'Minimum characters',
  'max_characters': 'Maximum characters',

  // Empty States
  'empty_announcements': 'No announcements',
  'empty_meetings': 'No scheduled meetings',
  'empty_initiatives': 'No initiatives',
  'empty_documents': 'No documents',
  'empty_polls': 'No active polls',
  'empty_notifications': 'No notifications',
  'empty_search': 'No results found',
  'empty_calendar': 'No scheduled events',

  // Permissions
  'permission_denied': 'Permission denied',
  'camera_permission': 'Camera permission',
  'storage_permission': 'Storage permission',
  'notification_permission': 'Notification permission',
  'location_permission': 'Location permission',
  'grant_permission': 'Grant permission',
  'open_settings': 'Open settings',

  // Translation
  'see_translation': 'See translation',
  'see_original': 'See original',
  'auto_translate': 'Auto translate',
  'translation_provider': 'Translation provider',
  'api_key': 'API key',
  'translated': 'Translated',

  // Auth Flow
  'welcome_back': 'Welcome back!',
  'login_to_continue': 'Sign in to continue',
  'or': 'or',
  'create_new_account': 'Create a new account',
  'join_student_council': 'Join the student council',
  'reset_password_title': 'Reset password',
  'reset_password_description': 'Enter your email address and we will send you a link to reset your password.',
  'send_reset_link': 'Send reset link',
  'back_to_login': 'Back to login',
  'password_reset_sent': 'Reset link sent!',
  'check_inbox': 'Check your inbox for instructions.',
  'verification_email_sent': 'We sent a verification email to:',
  'checking_verification': 'Checking...',
  'resend_verification_email': 'Resend verification email',
  'resend_in': 'Resend in',
  'i_verified_my_email': 'I verified my email',
  'use_different_account': 'Use different account',
  'complete_profile': 'Complete profile',
  'complete_your_profile': 'Complete your profile',
  'complete_profile_description': 'To finish registration, please fill in the information below.',
  'signed_in_with_google': 'Signed in with Google',
  'registration_approval_info': 'After registration, your account will be pending until a SuperAdmin or BEX approves it.',
  'complete_registration': 'Complete registration',
  'account_pending': 'Account pending',
  'account_pending_description': 'Your account has been created and is waiting for SuperAdmin or BEX approval.',
  'pending_approval_info': 'You will receive a notification when your account is approved. This process may take a few hours.',
  'check_status': 'Check status',
  'status_pending': 'Pending',
  'account_suspended': 'Account suspended',
  'account_suspended_description': 'Your account has been suspended. Contact an administrator for more information.',
  'status_suspended': 'Suspended',
  'contact_admin_for_help': 'If you believe this is an error, contact your school administrator.',
  'personal_info': 'Personal information',
  'account': 'Account',
  'member_since': 'Member since',
  'last_login': 'Last login',
  'logout_confirmation': 'Are you sure you want to log out?',
  'class_name': 'Class',
  'coming_soon': 'Coming soon',
  'city_password': 'City Password',
  'city_password_hint': 'Enter the password provided by administrator',
  'invalid_city_password': 'Invalid city password',
  'phone_required': 'Phone number is required',
  'city_required': 'Please select a city',
  'school_required': 'Please select a school',

  // Announcement screens
  'all': 'All',
  'title': 'Title',
  'content': 'Content',
  'attachments': 'Attachments',
  'delete_announcement': 'Delete announcement',
  'delete_announcement_confirm': 'Are you sure you want to delete this announcement? This action cannot be undone.',
  'announcement_deleted': 'Announcement deleted',
  'announcement_title_hint': 'Enter announcement title',
  'announcement_content_hint': 'Write your announcement content here...',
  'title_required': 'Title is required',
  'title_too_short': 'Title must be at least 5 characters',
  'content_required': 'Content is required',
  'content_too_short': 'Content must be at least 20 characters',
  'pin_announcement': 'Pin announcement',
  'pin_announcement_desc': 'Pinned announcements appear at the top of the list',
  'add_image': 'Add image',
  'add_attachment': 'Add attachment',
  'save_as_draft': 'Save as draft',
  'announcement_published': 'Announcement published successfully',
  'error_creating_announcement': 'Error creating announcement',
  'draft_saved': 'Draft saved',

  // Meeting screens
  'upcoming_meetings': 'Upcoming meetings',
  'past_meetings': 'Past meetings',
  'no_upcoming_meetings': 'No upcoming meetings',
  'meeting_details': 'Meeting details',
  'delete_meeting': 'Delete meeting',
  'delete_meeting_confirm': 'Are you sure you want to delete this meeting?',
  'meeting_deleted': 'Meeting deleted',
  'meeting_title_hint': 'Enter meeting title',
  'meeting_description_hint': 'Describe what this meeting is about...',
  'select_date': 'Select date',
  'select_time': 'Select time',
  'location_hint': 'Enter location or meeting link',
  'add_agenda': 'Add agenda items',
  'agenda_item_hint': 'Add agenda item',
  'meeting_created': 'Meeting created successfully',
  'error_creating_meeting': 'Error creating meeting',
  'schedule_meeting': 'Schedule meeting',

  // Initiative screens
  'support': 'Support',
  'supporters': 'Supporters',
  'problem': 'Problem',
  'solution': 'Solution',
  'impact': 'Impact',
  'status': 'Status',
  'delete_initiative': 'Delete initiative',
  'delete_initiative_confirm': 'Are you sure you want to delete this initiative?',
  'initiative_deleted': 'Initiative deleted',
  'initiative_title_hint': 'Enter initiative title',
  'initiative_description_hint': 'Describe your initiative...',
  'problem_hint': 'What problem does this solve?',
  'solution_hint': 'How will this be solved?',
  'impact_hint': 'What impact will this have?',
  'submit_initiative': 'Submit initiative',
  'initiative_submitted': 'Initiative submitted successfully',
  'error_creating_initiative': 'Error creating initiative',
  'write_comment': 'Write a comment...',
  'comment_added': 'Comment added',
  'voting': 'Voting',
  'review': 'Review',
  'debate': 'Debate',
  'adopted': 'Adopted',
  'submitted': 'Submitted',

  // Profile screens (new entries only)
  'personal_information': 'Personal Information',
  'account_information': 'Account Information',
  'profile_updated': 'Profile updated successfully',
  'error_updating_profile': 'Error updating profile',
  'delete_account_warning': 'This action is permanent and cannot be undone. All your data will be deleted.',
  'choose_photo': 'Choose Photo',
  'camera': 'Camera',
  'gallery': 'Gallery',
  'photo_updated': 'Photo updated successfully',
  'error_picking_image': 'Error selecting image',
  'error_uploading_photo': 'Error uploading photo',

  // Documents screens
  'statut': 'Statute',
  'methodologies': 'Methodologies',
  'no_documents_desc': 'No documents in this category.',
  'cannot_open_file': 'Could not open file',
  'error_opening_file': 'Error opening file',
  'error_loading': 'Error loading',
  'error_loading_comments': 'Error loading comments',
  'no_comments_yet': 'No comments yet',

  // Polls screens
  'active_only': 'Active only',
  'no_polls_desc': 'No polls available at the moment.',
  'results': 'Results',
  'options': 'Options',
  'submit_vote': 'Submit vote',
  'vote_submitted': 'Vote submitted successfully',
  'vote_failed': 'Failed to submit vote',
  'delete_poll': 'Delete poll',
  'delete_poll_confirm': 'Are you sure you want to delete this poll?',
  'poll_deleted': 'Poll deleted',
  'name_required': 'Name is required',

  // Admin screens
  'manage_users': 'Manage Users',
  'manage_users_desc': 'Approve, change roles',
  'search_users': 'Search users...',
  'filter_by_role': 'Filter by role',
  'clear_filter': 'Clear filter',
  'no_users_found': 'No users found',
  'user_details': 'User Details',
  'change_role': 'Change Role',
  'select_role': 'Select Role',
  'change_status': 'Change Status',
  'approve_user': 'Approve User',
  'suspend_user': 'Suspend User',
  'reactivate_user': 'Reactivate User',
  'user_approved': 'User approved',
  'user_suspended': 'User suspended',
  'user_reactivated': 'User reactivated',
  'role_changed': 'Role changed successfully',
  'error_approving_user': 'Error approving user',
  'error_suspending_user': 'Error suspending user',
  'error_changing_role': 'Error changing role',
  'select_department': 'Select Department',
  'select_department_description': 'Choose the department for this user',
  'confirm_role_change': 'Confirm Role Change',
  'confirm_role_change_desc': 'Are you sure you want to change this user\'s role to',
  'confirm_suspend': 'Confirm Suspension',
  'confirm_suspend_desc': 'Are you sure you want to suspend this user? They will no longer be able to access the app.',
  'account_info': 'Account Info',
  'joined': 'Joined',
  'last_active': 'Last active',
  'suspended': 'Suspended',
  'suspend': 'Suspend',
  'suspend_user_warning': 'The user will no longer be able to access the app.',
  'error_reactivating_user': 'Error reactivating user',
  'change_role_to': 'Change role to',
  'superadmin_role_protected': 'Superadmin role is protected and cannot be modified',
  'bex_role_protected': 'BEX role can only be modified by Superadmin',

  // Admin Dashboard
  'statistics': 'Statistics',
  'total_users': 'Total Users',
  'quick_actions': 'Quick Actions',
  'add_user': 'Add User',
  'user_added_successfully': 'User added successfully',
  'error_creating_user': 'Error creating user',
  'error_saving_profile': 'Error saving profile. Please try again.',
  'user_password_info': 'The user will need to use "Forgot Password" to set their password on first login.',
  'bex_county_restriction': 'You can only add users to your own county',
  'announce': 'Announce',
  'pending_approvals': 'Pending Approvals',
  'no_pending_approvals': 'No pending approvals',
  'recent_activity': 'Recent Activity',
  'no_recent_activity': 'No recent activity',
  'active_polls': 'Active Polls',

  // Schools Management
  'manage_schools': 'Manage Schools',
  'search_schools': 'Search schools...',
  'no_schools': 'No schools found',
  'add_school': 'Add School',
  'edit_school': 'Edit School',
  'short_name': 'Short Name',
  'no_representative': 'No representative assigned',
  'assign': 'Assign',
  'select_representative': 'Select Representative',
  'school_created': 'School created successfully',
  'school_updated': 'School updated successfully',
  'school_deleted': 'School deleted successfully',
  'error_saving_school': 'Error saving school',
  'error_updating_school': 'Error updating school',
  'error_deleting_school': 'Error deleting school',
  'delete_school_warning': 'Are you sure you want to delete this school? This will also affect all students associated with it.',

  // Polls Creation
  'poll_type': 'Poll Type',
  'question': 'Question',
  'enter_question': 'Enter your question',
  'description': 'Description',
  'optional': 'optional',
  'enter_description': 'Enter a description',
  'option': 'Option',
  'anonymous_voting': 'Anonymous Voting',
  'anonymous_voting_desc': 'Voters\' identities will be hidden',
  'allow_multiple_votes': 'Allow Multiple Votes',
  'allow_multiple_votes_desc': 'Users can vote for multiple options',
  'voting_period': 'Voting Period',
  'end_date_before_start': 'End date must be after start date',
  'poll_created': 'Poll created successfully',
  'error_creating_poll': 'Error creating poll',
  'continue': 'Continue',

  // Documents Upload
  'select_file': 'Select File',
  'tap_to_select_file': 'Tap to select a file',
  'category': 'Category',
  'tags': 'Tags',
  'add_tag': 'Add a tag',
  'public_document': 'Public Document',
  'public_document_desc': 'This document will be visible to all users',
  'minimum_role_required': 'Minimum role required',
  'select_minimum_role': 'Select minimum role',
  'minimum_role_hint': 'Users with this role or higher can view the document',
  'school_document': 'School Document',
  'school_document_desc': 'This document belongs to your school',
  'school_document_required': 'As a school representative, your documents are associated with your school',
  'document_title_hint': 'Enter document title',
  'document_description_hint': 'Enter document description',
  'document_uploaded': 'Document uploaded successfully',
  'error_uploading_document': 'Error uploading document',

  // Initiatives Creation
  'basic_information': 'Basic Information',
  'basic_info_desc': 'Start by adding basic information about your initiative',
  'tags_desc': 'Add up to 5 tags to help categorize your initiative',
  'detailed_proposal': 'Detailed Proposal',
  'detailed_proposal_desc': 'Provide more details about your initiative',
  'problem_statement': 'Problem Statement',
  'proposed_solution': 'Proposed Solution',
  'expected_impact': 'Expected Impact',
  'comments_support': 'Comments & Support',
  'no_impact': 'No impact defined',
  'no_impact_description': 'This initiative does not have an expected impact defined yet.',
  'review_submit': 'Review & Submit',
  'review_submit_desc': 'Review your initiative before submitting',
  'untitled': 'Untitled',
  'no_description': 'No description provided',
  'proposal_details': 'Proposal Details',
  'initiative_review_info': 'Your initiative will be reviewed by the student council before being published.',
  'description_too_short': 'Description must be at least 50 characters',
  'error_submitting_initiative': 'Error submitting initiative',

  // User Detail
  'delete_user': 'Delete User',
  'delete_user_confirm': 'Are you sure you want to delete this user? This action cannot be undone.',
  'user_deleted': 'User deleted successfully',
  'error_deleting_user': 'Error deleting user',
  'users': 'Users',

  // Warnings & Absences
  'warnings': 'Warnings',
  'absences': 'Absences',
  'warnings_absences': 'Warnings & Absences',
  'issue_warning': 'Issue Warning',
  'warning_type': 'Warning Type',
  'deactivate_warning': 'Deactivate Warning',
  'deactivate_warning_confirm': 'Are you sure you want to deactivate this warning?',
  'warning_deactivated': 'Warning deactivated',
  'error_deactivating_warning': 'Error deactivating warning',
  'mark_excused': 'Mark Excused',
  'absence_updated': 'Absence updated',
  'error_updating_absence': 'Error updating absence',
  'warning_issued': 'Warning issued successfully',
  'error_issuing_warning': 'Error issuing warning',
  'select_user': 'Select User',
  'reason': 'Reason',
  'reason_hint': 'Enter the reason for the warning',
  'details_optional': 'Details (optional)',
  'details_hint': 'Enter additional details',
  'add_warning': 'Add Warning',
  'warning_reason': 'Warning reason',
  'enter_warning_reason': 'Enter warning reason',
  'warning_added': 'Warning added',
  'error_adding_warning': 'Error adding warning',
  'resolve_warning': 'Resolve Warning',
  'resolution_note': 'Resolution note',
  'optional_resolution_note': 'Optional resolution note',
  'warning_resolved': 'Warning resolved',
  'error_resolving_warning': 'Error resolving warning',
  'remove_warning': 'Remove Warning',
  'remove_warning_confirm': 'Are you sure you want to remove this warning?',
  'warning_removed': 'Warning removed',
  'error_removing_warning': 'Error removing warning',
  'active_warning': 'Active',
  'resolved_warning': 'Resolved',
  'issued_by': 'Issued by',
  'resolved_by': 'Resolved by',
  'no_warnings': 'No warnings',
  'add_absence': 'Add Absence',
  'absence_meeting_id': 'Meeting ID',
  'absence_added': 'Absence added',
  'error_adding_absence': 'Error adding absence',
  'excuse_absence': 'Excuse Absence',
  'excuse_reason': 'Reason',
  'enter_excuse_reason': 'Enter the reason',
  'absence_excused': 'Absence excused',
  'error_excusing_absence': 'Error excusing absence',
  'remove_absence': 'Remove Absence',
  'remove_absence_confirm': 'Are you sure you want to remove this absence?',
  'absence_removed': 'Absence removed',
  'error_removing_absence': 'Error removing absence',
  'unexcused': 'Unexcused',
  'recorded_by': 'Recorded by',
  'no_absences': 'No absences',

  // GDS (Support Groups)
  'support_groups': 'Support Groups',
  'manage_gds': 'Manage GDS',
  'search_gds': 'Search groups...',
  'no_gds': 'No groups found',
  'no_gds_message': 'No support groups yet. Create the first group!',
  'add_gds': 'Add Group',
  'edit_gds': 'Edit Group',
  'create_gds': 'Create Group',
  'gds_name': 'Group Name',
  'gds_description': 'Description',
  'gds_description_hint': 'Describe the purpose and activities of the group',
  'gds_focus': 'Focus/Theme',
  'focus_area': 'Focus Area',
  'gds_leader': 'Leader',
  'select_leader': 'Select Leader',
  'gds_members': 'Members',
  'gds_created': 'Group created successfully',
  'gds_updated': 'Group updated successfully',
  'gds_deleted': 'Group deleted successfully',
  'error_saving_gds': 'Error saving group',
  'error_updating_gds': 'Error updating group',
  'error_deleting_gds': 'Error deleting group',
  'delete_gds_warning': 'Are you sure you want to delete this group?',
  'activate': 'Activate',
  'deactivate': 'Deactivate',
  'gds_status_changed': 'Group status changed',
  'error_changing_gds_status': 'Error changing status',
  'member_role': 'Member Role',
  'add_member': 'Add Member',
  'member_added': 'Member added successfully',
  'error_adding_member': 'Error adding member',
  'remove_member': 'Remove Member',
  'confirm_remove_member': 'Confirm Removal',
  'remove_member_message': 'Are you sure you want to remove this member:',
  'member_removed': 'Member removed successfully',
  'error_removing_member': 'Error removing member',
  'change_leader': 'Change Leader',
  'no_members': 'No members',
  'no_users_available': 'No users available',
  'leader': 'Leader',
  'none': 'None',
  'change': 'Change',
  'school_members': 'School Members',
  'total': 'Total',

  // CSV Import
  'import_csv': 'Import CSV',
  'import_users': 'Import Users',
  'import_users_subtitle': 'Upload a CSV file with user data',
  'csv_format': 'CSV Format',
  'select_csv_file': 'Select CSV file',
  'tap_to_select': 'Tap to select',
  'import': 'Import',
  'import_results': 'Import Results',
  'total_rows': 'Total rows',
  'successful': 'Successful',
  'errors': 'Errors',
  'error_details': 'Error Details',

  // Share App
  'share_app_message': 'Discover the CJE app - County Student Council! Connect with your school community and get involved in council activities. 🎓📱',

  // User Detail Screen
  'select_new_role': 'Select a new role',
  'manage_status': 'Manage Status',
  'user_information': 'User Information',
  'user_not_found': 'User not found',
  'confirm_remove_warning': 'Confirm Remove Warning',
  'remove_warning_message': 'Are you sure you want to remove this warning? This action cannot be undone.',
  'confirm_remove_absence': 'Confirm Remove Absence',
  'remove_absence_message': 'Are you sure you want to remove this absence? This action cannot be undone.',
  'warning_reason_hint': 'Enter warning reason...',
  'resolution_note_hint': 'Optional resolution note...',
  'excuse_reason_hint': 'Enter reason for absence...',
  'resolve': 'Resolve',
  'remove': 'Remove',
  'excuse': 'Excuse',

  // Role names for display
  'role_student': 'Student',
  'role_class_rep': 'Class Representative',
  'role_school_rep': 'School Representative',
  'role_department': 'Department',
  'role_bex': 'BEx',
  'role_superadmin': 'Super Admin',

  // Home Screen
  'your_impact_this_month': 'Your Impact\nThis Month',

  // Search Screen
  'search_title': 'Search',
  'search_description': 'Search announcements, meetings, initiatives, polls, and documents',
  'search_placeholder': 'Search...',
  'search_min_length': 'Enter at least 2 characters',
  'no_results': 'No results',
  'no_results_for': 'No results for',
  'results_found': 'results found',

  // Notifications Screen
  'mark_all_read': 'Mark all as read',
  'clear_all': 'Clear all',
  'no_notifications_desc': 'You have no new notifications at the moment',
  'all_marked_read': 'All notifications marked as read',
  'error_marking_read': 'Error marking notifications',
  'clear_all_notifications': 'Clear all notifications',
  'clear_all_notifications_desc': 'Are you sure you want to clear all notifications? This action cannot be undone.',
  'notifications_cleared': 'Notifications cleared',
  'error_clearing_notifications': 'Error clearing notifications',

  // Privacy & Security (new keys only)
  'privacy_security': 'Privacy & Security',
  'privacy_security_subtitle': 'Password, Account',
  'delete_account_subtitle': 'Permanent and irreversible',
  'fill_all_fields': 'Please fill in all fields',
  'password_min_length': 'Password must be at least 6 characters',
  'passwords_not_match': 'Passwords do not match',
  'password_changed_success': 'Password changed successfully',
  'google_password_message': 'You signed in with Google. To change your password, access your Google account settings.',

  // Help & Support (new keys only)
  'help_support': 'Help & Support',
  'help_support_subtitle': 'FAQ, Contact us',
  'contact_us': 'Contact Us',
  'email_us': 'Email Us',
  'call_us': 'Call Us',
  'website': 'Website',
  'faq': 'Frequently Asked Questions',
  'faq_q1': 'How can I change my password?',
  'faq_a1': 'Go to Profile > Privacy & Security > Change Password. Enter your current password and new password to make the change.',
  'faq_q2': 'How can I participate in polls?',
  'faq_a2': 'Open the Polls section from the main menu. Select an active poll and vote for your preferred option.',
  'faq_q3': 'How do I propose an initiative?',
  'faq_a3': 'Go to the Initiatives section and press the + button to create a new initiative. Fill in the details and submit for approval.',
  'faq_q4': 'Who can see my data?',
  'faq_a4': 'Your personal data is only visible to CJE administrators and your school representatives. We do not share data with third parties.',
  'faq_q5': 'How do I contact technical support?',
  'faq_a5': 'You can send us an email at support@cje.ro or call us at the number displayed in the Contact Us section.',

  // Legal - Terms of Service
  'last_updated': 'Last updated: December 2024',
  'terms_section_1_title': '1. Acceptance of Terms',
  'terms_section_1_content': 'By accessing and using the County Student Council (CJE) application, you agree to be bound by these Terms and Conditions. If you do not agree with these terms, please do not use the application.',
  'terms_section_2_title': '2. Use of the Application',
  'terms_section_2_content': 'The CJE application is intended for students, school representatives, and administrators within county student councils. Users must provide accurate information during registration and maintain the confidentiality of their account.',
  'terms_section_3_title': '3. User Conduct',
  'terms_section_3_content': 'Users agree to use the application responsibly, respect the rights of other users, and not distribute offensive, illegal, or harmful content. Violation of these rules may result in account suspension.',
  'terms_section_4_title': '4. Intellectual Property',
  'terms_section_4_content': 'All application content, including design, text, and functionality, is the property of CJE. Users do not have the right to copy, modify, or distribute content without prior consent.',
  'terms_section_5_title': '5. Limitation of Liability',
  'terms_section_5_content': 'CJE assumes no liability for any losses or damages resulting from the use of the application. The service is provided "as is" without warranties of any kind.',

  // Legal - Privacy Policy
  'privacy_section_1_title': '1. Data Collection',
  'privacy_section_1_content': 'We collect personal data such as: name, email address, school, class, and role in the council. This information is necessary for the proper functioning of the application and user identification.',
  'privacy_section_2_title': '2. Use of Data',
  'privacy_section_2_content': 'The collected data is used for: authentication, communication between members, managing council activities, and improving services. We do not sell or share data with third parties for commercial purposes.',
  'privacy_section_3_title': '3. Storage and Security',
  'privacy_section_3_content': 'Data is stored securely using Firebase services (Google). We implement technical and organizational measures to protect information against unauthorized access.',
  'privacy_section_4_title': '4. User Rights',
  'privacy_section_4_content': 'You have the right to: access your data, request correction or deletion, object to processing, and request data portability. Contact us to exercise these rights.',
  'privacy_section_5_title': '5. Contact',
  'privacy_section_5_content': 'For questions regarding the privacy policy or to exercise GDPR rights, you can contact us at: privacy@cje.ro',

  // Greetings
  'good_morning': 'Good Morning',
  'good_afternoon': 'Good Afternoon',
  'good_evening': 'Good Evening',

  // Time Ago
  'just_now': 'Just now',
  'min_ago': 'min ago',
  'hour_ago': 'hour ago',
  'hours_ago': 'hours ago',
  'day_ago': 'day ago',
  'days_ago': 'days ago',

  // Cancel Registration Dialog
  'cancel_registration': 'Cancel registration?',
  'cancel_registration_message': 'If you cancel, you will be logged out and will need to register again.',
  'yes_cancel': 'Yes, cancel',

  // Login Screen
  'email_address': 'Email Address',
  'email_hint': 'Email address...',
  'password_hint': 'Password...',
  'continue_with_google': 'Continue with Google',
  'admin_setup_taps': '{count} more taps for admin setup',

  // Online Meeting
  'this_is_online_meeting': 'This is an online meeting',
  'example_name': 'e.g. John Doe',

  // Facebook/Instagram
  'facebook': 'Facebook',
  'instagram': 'Instagram',
  'facebook_url': 'Facebook URL',
  'instagram_url': 'Instagram URL',

  // Home Screen
  'see_all': 'See All',
  'upcoming_events': 'Upcoming Events',
  'check_back_later': 'Check back later for updates',
  'ends': 'Ends',
  'ends_on': 'Ends on',
  'min': 'min',

  // Menu Screen
  'menu': 'Menu',
  'dark_mode': 'Dark Mode',
  'documents_subtitle': 'Documents and forms',
  'polls_subtitle': 'Polls and votes',
  'calendar_subtitle': 'Events and meetings',
  'administration': 'Administration',
  'schools_subtitle': 'Manage schools',
  'gds_subtitle': 'Support groups',
  'analytics': 'Analytics',
  'analytics_subtitle': 'Statistics and reports',
  'county_settings': 'County Settings',
  'county_settings_subtitle': 'Contact and social media',
  'county_settings_description': 'Edit contact info shown in Help & Support',
  'settings_info': 'Changes will be visible in the Help & Support section',
  'select_county': 'Select County',
  'contact_info': 'Contact Info',
  'social_media': 'Social Media',
  'save_changes': 'Save',
  'settings_saved': 'Settings saved successfully',
  'error_saving_settings': 'Error saving settings',

  // Ideas Screen
  'ideas': 'Ideas',
  'show_active_polls_only': 'Show only active polls',

  // Edit Initiative
  'edit_initiative_info': 'Update your initiative details. Changes will be saved immediately.',
  'update_initiative': 'Update Initiative',
  'initiative_updated': 'Initiative updated successfully',
  'error_updating_initiative': 'Error updating initiative',

  // Snackbar & Toast Messages
  'exit_app': 'Exit App?',
  'exit_app_confirm': 'Do you want to exit the app?',
  'exit': 'Exit',
  'verification_email_resent': 'Verification email sent!',
  'error_sending_email': 'Error sending email',
  'account_created_wait_approval': 'Account created! Please wait for approval.',
  'error_picking_file': 'Error picking file',
  'error_uploading_file': 'Error uploading file',
  'error_picking_files': 'Error picking files',
  'user_rejected': 'User rejected',
  'error_rejecting_user': 'Error rejecting user',
  'initiative_submitted_for_review': 'Initiative submitted for review',
  'action_failed': 'Action failed',
  'failed': 'Failed',
  'contact_support_delete_account': 'Please contact support to delete your account',
  'error_importing': 'Error importing',
  'cannot_open_document': 'Cannot open document',
  'cannot_open_link': 'Cannot open link',
  'select_city_first': 'Select county first',

  // Auth Errors
  'auth_error_user_not_found': 'No account exists with this email address.',
  'auth_error_wrong_password': 'The password is incorrect.',
  'auth_error_invalid_email': 'The email address is not valid.',
  'auth_error_user_disabled': 'This account has been disabled.',
  'auth_error_email_already_in_use': 'An account already exists with this email address.',
  'auth_error_weak_password': 'Password is too weak. Use at least 6 characters.',
  'auth_error_operation_not_allowed': 'This operation is not allowed.',
  'auth_error_too_many_requests': 'Too many attempts. Please try again later.',
  'auth_error_network_request_failed': 'Connection error. Check your internet.',
  'auth_error_invalid_credential': 'Invalid email or password.',
  'auth_error_requires_recent_login': 'Please sign in again to perform this operation.',
  'auth_error_default': 'An error occurred. Please try again.',
};
