/// CJE Platform String Constants
/// All static strings used throughout the app (Romanian language)
class AppStrings {
  AppStrings._();

  // ============================================
  // APP INFO
  // ============================================

  static const String appName = 'CJE Platform';
  static const String appNameFull = 'Consiliul Județean al Elevilor';
  static const String appTagline = 'Platforma digitală pentru consiliile elevilor';

  // ============================================
  // AUTHENTICATION
  // ============================================

  static const String login = 'Autentificare';
  static const String register = 'Înregistrare';
  static const String logout = 'Deconectare';
  static const String email = 'Email';
  static const String password = 'Parolă';
  static const String confirmPassword = 'Confirmă parola';
  static const String forgotPassword = 'Ai uitat parola?';
  static const String resetPassword = 'Resetează parola';
  static const String fullName = 'Nume complet';
  static const String phone = 'Număr de telefon';
  static const String cityPassword = 'Parola orașului';
  static const String selectSchool = 'Selectează școala';
  static const String selectCity = 'Selectează orașul';
  static const String loginWithGoogle = 'Continuă cu Google';
  static const String createAccount = 'Creează cont';
  static const String alreadyHaveAccount = 'Ai deja un cont?';
  static const String dontHaveAccount = 'Nu ai cont?';
  static const String signInHere = 'Autentifică-te aici';
  static const String registerHere = 'Înregistrează-te aici';
  static const String enterEmail = 'Introdu adresa de email';
  static const String enterPassword = 'Introdu parola';
  static const String enterCityPassword = 'Introdu parola orașului';

  // ============================================
  // VALIDATION MESSAGES
  // ============================================

  static const String emailRequired = 'Email-ul este obligatoriu';
  static const String emailInvalid = 'Email-ul nu este valid';
  static const String passwordRequired = 'Parola este obligatorie';
  static const String passwordTooShort = 'Parola trebuie să aibă cel puțin 8 caractere';
  static const String passwordsDoNotMatch = 'Parolele nu coincid';
  static const String nameRequired = 'Numele este obligatoriu';
  static const String phoneRequired = 'Numărul de telefon este obligatoriu';
  static const String phoneInvalid = 'Numărul de telefon nu este valid';
  static const String schoolRequired = 'Școala este obligatorie';
  static const String cityRequired = 'Orașul este obligatoriu';
  static const String cityPasswordRequired = 'Parola orașului este obligatorie';
  static const String cityPasswordInvalid = 'Parola orașului este incorectă';
  static const String fieldRequired = 'Acest câmp este obligatoriu';

  // ============================================
  // NAVIGATION / TABS
  // ============================================

  static const String home = 'Acasă';
  static const String announcements = 'Comunicat';
  static const String meetings = 'Ședințe';
  static const String initiatives = 'Inițiative';
  static const String documents = 'Documente';
  static const String polls = 'Sondaje';
  static const String profile = 'Profil';
  static const String admin = 'Administrare';
  static const String settings = 'Setări';
  static const String calendar = 'Calendar';
  static const String search = 'Căutare';
  static const String notifications = 'Notificări';

  // ============================================
  // USER ROLES
  // ============================================

  static const String roleStudent = 'Elev';
  static const String roleClassRep = 'Reprezentant de clasă';
  static const String roleSchoolRep = 'Reprezentant de școală';
  static const String roleDepartment = 'Departament';
  static const String roleBEX = 'BEX';
  static const String roleSuperadmin = 'Superadmin';

  // ============================================
  // USER STATUS
  // ============================================

  static const String statusActive = 'Activ';
  static const String statusSuspended = 'Suspendat';
  static const String statusPending = 'În așteptare';

  // ============================================
  // DEPARTMENTS
  // ============================================

  static const String deptPRCommunications = 'PR & Comunicare';
  static const String deptVolunteering = 'Voluntariat';
  static const String deptSchoolInclusion = 'Incluziune Școlară';

  // ============================================
  // MEETINGS
  // ============================================

  static const String meetingCountyAG = 'Adunare Generală';
  static const String meetingBEX = 'Ședință BEX';
  static const String meetingDepartment = 'Ședință Departament';
  static const String meetingSchool = 'Ședință Școală';
  static const String agenda = 'Ordinea de zi';
  static const String participants = 'Participanți';
  static const String location = 'Locație';
  static const String dateAndTime = 'Data și ora';
  static const String nextMeeting = 'Următoarea ședință';
  static const String noUpcomingMeetings = 'Nu există ședințe programate';
  static const String createMeeting = 'Creează ședință';
  static const String editMeeting = 'Editează ședință';
  static const String deleteMeeting = 'Șterge ședință';
  static const String meetingDetails = 'Detalii ședință';

  // ============================================
  // INITIATIVES
  // ============================================

  static const String initiativeStatusDraft = 'Ciornă';
  static const String initiativeStatusSubmitted = 'Trimisă';
  static const String initiativeStatusReview = 'În analiză';
  static const String initiativeStatusDebate = 'În dezbatere';
  static const String initiativeStatusVoting = 'La vot';
  static const String initiativeStatusAdopted = 'Adoptată';
  static const String initiativeStatusRejected = 'Respinsă';
  static const String description = 'Descriere';
  static const String expectedImpact = 'Impact așteptat';
  static const String commentsAndSupport = 'Comentarii și susținere';
  static const String createInitiative = 'Creează inițiativă';
  static const String editInitiative = 'Editează inițiativă';
  static const String deleteInitiative = 'Șterge inițiativă';
  static const String approveInitiative = 'Aprobă';
  static const String rejectInitiative = 'Respinge';
  static const String support = 'Susține';
  static const String supporters = 'Susținători';

  // ============================================
  // ANNOUNCEMENTS
  // ============================================

  static const String announcementCJE = 'Comunicat CJE';
  static const String announcementSchool = 'Comunicat Școală';
  static const String createAnnouncement = 'Creează comunicat';
  static const String editAnnouncement = 'Editează comunicat';
  static const String deleteAnnouncement = 'Șterge comunicat';
  static const String publishNow = 'Publică acum';
  static const String attachments = 'Atașamente';
  static const String noAnnouncements = 'Nu există comunicat';
  static const String recentAnnouncements = 'Comunicat recente';

  // ============================================
  // DOCUMENTS
  // ============================================

  static const String docCategoryStatut = 'Statut Elevului';
  static const String docCategoryRegulamente = 'Regulamente';
  static const String docCategoryMetodologii = 'Metodologii';
  static const String docCategoryFormulare = 'Formulare';
  static const String uploadDocument = 'Încarcă document';
  static const String downloadDocument = 'Descarcă';
  static const String deleteDocument = 'Șterge document';
  static const String openDocument = 'Deschide';
  static const String noDocuments = 'Nu există documente';
  static const String newDocuments = 'Documente noi';

  // ============================================
  // POLLS
  // ============================================

  static const String pollSchool = 'Sondaj Școală';
  static const String pollCounty = 'Sondaj Județ';
  static const String createPoll = 'Creează sondaj';
  static const String vote = 'Votează';
  static const String viewResults = 'Vezi rezultate';
  static const String pollEnded = 'Sondaj încheiat';
  static const String pollActive = 'Sondaj activ';
  static const String noActivePolls = 'Nu există sondaje active';
  static const String activePolls = 'Sondaje active';

  // ============================================
  // ADMINISTRATION
  // ============================================

  static const String users = 'Utilizatori';
  static const String schools = 'Școli';
  static const String gds = 'GDS';
  static const String gdsFullName = 'Grupuri de Suport';
  static const String warnings = 'Avertismente';
  static const String absences = 'Absențe';
  static const String addWarning = 'Adaugă avertisment';
  static const String removeWarning = 'Elimină avertisment';
  static const String addAbsence = 'Adaugă absență';
  static const String removeAbsence = 'Elimină absență';
  static const String suspendAccount = 'Suspendă cont';
  static const String activateAccount = 'Activează cont';
  static const String changeRole = 'Schimbă rol';
  static const String importCSV = 'Importă CSV';

  // ============================================
  // FILTERS
  // ============================================

  static const String all = 'Toate';
  static const String filterCJE = 'CJE';
  static const String filterSchool = 'Școală';

  // ============================================
  // COMMON ACTIONS
  // ============================================

  static const String save = 'Salvează';
  static const String cancel = 'Anulează';
  static const String delete = 'Șterge';
  static const String edit = 'Editează';
  static const String create = 'Creează';
  static const String confirm = 'Confirmă';
  static const String close = 'Închide';
  static const String back = 'Înapoi';
  static const String next = 'Următorul';
  static const String done = 'Gata';
  static const String submit = 'Trimite';
  static const String refresh = 'Reîmprospătează';
  static const String retry = 'Reîncearcă';
  static const String seeAll = 'Vezi tot';
  static const String seeMore = 'Vezi mai mult';
  static const String seeLess = 'Vezi mai puțin';
  static const String loading = 'Se încarcă...';
  static const String noData = 'Nu există date';
  static const String error = 'Eroare';
  static const String success = 'Succes';
  static const String warning = 'Atenție';
  static const String info = 'Informație';

  // ============================================
  // ERROR MESSAGES
  // ============================================

  static const String errorGeneric = 'A apărut o eroare. Te rugăm să încerci din nou.';
  static const String errorNetwork = 'Eroare de conexiune. Verifică conexiunea la internet.';
  static const String errorUnauthorized = 'Nu ai permisiunea să efectuezi această acțiune.';
  static const String errorNotFound = 'Resursa nu a fost găsită.';
  static const String errorServer = 'Eroare de server. Te rugăm să încerci mai târziu.';
  static const String errorTimeout = 'Timpul de așteptare a expirat. Te rugăm să încerci din nou.';

  // ============================================
  // SUCCESS MESSAGES
  // ============================================

  static const String successSaved = 'Salvat cu succes!';
  static const String successDeleted = 'Șters cu succes!';
  static const String successCreated = 'Creat cu succes!';
  static const String successUpdated = 'Actualizat cu succes!';
  static const String successSent = 'Trimis cu succes!';

  // ============================================
  // CONFIRMATION DIALOGS
  // ============================================

  static const String confirmDelete = 'Ești sigur că vrei să ștergi?';
  static const String confirmLogout = 'Ești sigur că vrei să te deconectezi?';
  static const String confirmCancel = 'Ești sigur că vrei să anulezi? Modificările nu vor fi salvate.';

  // ============================================
  // EMPTY STATES
  // ============================================

  static const String emptyAnnouncements = 'Nu există comunicat momentan.';
  static const String emptyMeetings = 'Nu există ședințe programate.';
  static const String emptyInitiatives = 'Nu există inițiative momentan.';
  static const String emptyDocuments = 'Nu există documente în această categorie.';
  static const String emptyPolls = 'Nu există sondaje active.';
  static const String emptyNotifications = 'Nu ai notificări noi.';
  static const String emptySearch = 'Nu s-au găsit rezultate.';

  // ============================================
  // DATE/TIME
  // ============================================

  static const String today = 'Azi';
  static const String tomorrow = 'Mâine';
  static const String yesterday = 'Ieri';
}
