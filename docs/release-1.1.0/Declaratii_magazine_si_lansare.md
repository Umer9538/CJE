# CJE — declarații magazine și traseu minim de lansare

Actualizat: 1 octombrie 2026

Acest document este o fișă de completare pentru sursa integrată `1.1.0+16`, nu un formular deja trimis magazinelor. Include modificările de confidențialitate și funcțiile report/block păstrate din versiunea aprobată a lui Abdul. Nu înlocuiește verificarea unui avocat/DPO; declarațiile trebuie confirmate cu comportamentul și SDK-urile buildului efectiv publicat.

## Situația verificată

- Aplicația folosește Firebase Authentication, Cloud Firestore, Cloud Storage, Cloud Functions și Cloud Messaging.
- Nu include Firebase Analytics, Crashlytics, Firebase Performance Monitoring, SDK-uri de reclame sau SDK-uri de plăți. Include însă ML Kit Translation, care transmite automat metrici tehnice pentru diagnostic și analizarea utilizării funcției; textul tradus rămâne pe dispozitiv.
- Nu cere permisiuni de locație, contacte, microfon, SMS sau apeluri.
- Cere notificări; camera și galeria sunt folosite numai la alegerea utilizatorului pentru imagini opționale.
- Aplicația colectează date de cont/afiliere, activitate CJE, conținut și fișiere încărcate, precum și identificatorii tehnici necesari Firebase.
- Firebase este furnizor tehnic/persoană împuternicită. În formularul Google Play, transferul către un furnizor care prelucrează datele în numele operatorului nu este, în sine, „sharing”.
- Nu există tracking publicitar și nu se folosesc date pentru reclame sau marketing.

## Google Play — Data safety

În Play Console: **Policy and programs / App content → Data safety**.

### Răspunsuri generale

| Întrebare | Răspuns recomandat |
|---|---|
| Aplicația colectează sau partajează tipuri de date? | **Da** |
| Toate datele sunt criptate în tranzit? | **Da** |
| Utilizatorii pot solicita ștergerea datelor? | **Da** |
| Creare cont în aplicație? | **Da** |
| Ștergere cont în aplicație? | **Da** — Profil → Confidențialitate și securitate → Șterge contul |
| URL web pentru ștergere | `https://gavrilaandrei.github.io/cje-privacy-policy/#deletion` |
| Evaluare independentă de securitate | **Nu**, dacă nu a fost contractată și finalizată una |
| Families Policy badge | **Nu se bifează automat**; întâi trebuie verificată separat încadrarea publicului-țintă și respectarea Families Policy |

### Date de selectat

Pentru datele persistente din tabel: **Collected = Da**, **Ephemeral = Nu**. Nu completa automat **Shared = Nu** pentru întreaga aplicație. Google Play exceptă transferurile către furnizori care prelucrează în numele dezvoltatorului și anumite transferuri inițiate de utilizator; verifică excepția pentru fiecare flux și SDK. Documentația ML Kit arată colectarea de metrici și precizează că SDK-ul nu le transmite altor terți, dar dezvoltatorul trebuie să țină cont și de utilizarea și transferurile propriei aplicații. Exporturile ori accesul unei instituții care folosește datele pentru propriile scopuri necesită reevaluare. Rolul GDPR și clasificarea „sharing” din formular nu sunt concepte identice.

| Categorie Google Play | Tip | Obligatoriu/opțional | Scopuri recomandate |
|---|---|---|---|
| Personal info | Name | Obligatoriu pentru cont | App functionality; Account management |
| Personal info | Email address | Obligatoriu pentru cont | App functionality; Account management; Fraud prevention, security and compliance |
| Personal info | User IDs | Obligatoriu | App functionality; Account management; Fraud prevention, security and compliance |
| Personal info | Phone number | Opțional | App functionality; Account management |
| Personal info | Other info | Obligatoriu în funcție de rol: județ, școală, clasă, rol, statut, categorie sub 16/16+ și confirmările aferente | App functionality; Account management; Fraud prevention, security and compliance |
| Location | Approximate location | De verificat: afilierea administrativă la un județ nu dovedește singură colectarea locației fizice. Declară dacă buildul ori SDK-urile colectează/inferă efectiv o locație aproximativă, inclusiv prin IP; nu este cerut GPS | Scopurile reale ale fluxului identificat |
| Photos and videos | Photos | Opțional | App functionality; Account management |
| Files and docs | Files and docs | Opțional | App functionality |
| App activity | App interactions | Obligatoriu: vizualizări și interacțiuni necesare funcțiilor | App functionality |
| App activity | Other user-generated content | Opțional: anunțuri, inițiative, comentarii, texte, motivele raportării și alte contribuții | App functionality; Fraud prevention, security and compliance pentru moderare |
| App activity | Other actions | Obligatoriu pentru funcțiile folosite: voturi, susțineri, prezențe/absențe, avertismente, raportări, blocări și stări de citire | App functionality; Fraud prevention, security and compliance |
| App info and performance | Diagnostics | Obligatoriu cât timp ML Kit Translation este inclus | Analytics; App functionality |
| App info and performance | Other app performance data | Obligatoriu cât timp ML Kit Translation este inclus | Analytics; App functionality |
| Device or other IDs | Device or other IDs | Obligatoriu cât timp Firebase Cloud Messaging și ML Kit Translation sunt active | App functionality; Developer communications; Fraud prevention, security and compliance; Analytics |

### Date care NU se selectează în configurația verificată

- Precise location; Address; Race and ethnicity; Political or religious beliefs; Sexual orientation.
- Financial info și Purchase history.
- Emails, SMS/MMS și contacte din agenda telefonului.
- Videos, Audio files și Calendar events din calendarul dispozitivului.
- Installed apps, Web browsing history, In-app search history.
- Advertising data.
- Crash logs. Nu sunt incluse Firebase Crashlytics, Firebase Performance Monitoring sau Firebase Analytics; `Diagnostics` și `Other app performance data` se declară totuși din cauza metricilor ML Kit.

### Notă despre absențe și avertismente

În câmpurile libere nu trebuie introduse diagnostice, documente medicale, CNP, copii de acte sau alte date sensibile. Introducerea accidentală se gestionează prin moderare, ștergere/redactare și, după caz, procedura de incidente. Colectarea intenționată a unor date medicale ar necesita înainte de colectare o analiză separată art. 6 și 9 RGPD, informare, măsuri adecvate și declarații precum **Health info**; simpla bifare a categoriei în magazin nu o autorizează.

## Apple App Store Connect — App Privacy

În App Store Connect: aplicația → **App Privacy**. Răspunsurile pot fi actualizate fără încărcarea unui build nou, dar trebuie să fie exacte la momentul publicării.

### Urmărire

- **Data Used to Track You: Nu** pentru toate categoriile.

### Date colectate

Pentru categoriile de mai jos, scopul principal este **App Functionality**. Datele de profil și activitate trebuie marcate **Linked to the User = Da**. **Tracking = Nu**.

| Categorie Apple | Tip | Observație |
|---|---|---|
| Contact Info | Name | Numele contului |
| Contact Info | Email Address | Autentificare și administrarea contului |
| Contact Info | Phone Number | Opțional |
| Location | Coarse Location | Județ ales manual, fără GPS; abordare conservatoare |
| User Content | Photos or Videos | Fotografii opționale; aplicația nu încarcă video în fluxurile verificate |
| User Content | Other User Content | Anunțuri, inițiative, comentarii, documente și texte încărcate |
| User Content | Customer Support | Cereri trimise prin fluxul de suport/ștergere, dacă sunt inițiate de utilizator |
| Identifiers | User ID | UID Firebase și identificatori de cont |
| Identifiers | Device ID | Firebase Installation ID/token de notificare; tokenul este salvat în profil |
| Usage Data | Product Interaction | Vizualizări, voturi, susțineri, prezență și acțiuni similare |
| Usage Data | Other Usage Data | Stări de citire/notificare și activitate administrativă legată de cont |
| Diagnostics | Performance Data | Latența și metricile tehnice ML Kit; Analytics și App Functionality; de regulă **Linked to the User = Nu** |
| Diagnostics | Other Diagnostic Data | Model/OS/versiune aplicație, configurare, evenimente și erori ML Kit; Analytics și App Functionality; de regulă **Linked to the User = Nu** |
| Other Data | Other Data Types | Școală, clasă, rol, stare cont, categorie sub 16/16+, avertismente și absențe |

Nu se declară, pentru versiunea verificată: Physical Address, Precise Location, Contacts, Browsing/Search History, Purchases, Advertising Data, Crash Data, Audio, Health sau Sensitive Info. Această concluzie presupune respectarea interdicției operaționale de a introduce informații medicale/sensibile în câmpurile libere.

## Politica publică

Versiunea publică actuală este:

`https://gavrilaandrei.github.io/cje-privacy-policy/`

Sursa locală este:

`D:\Aplicatie_CJE\06_LEGAL_AND_PRIVACY\Privacy_policy\cje-privacy-policy-publish\index.html`

Versiunea publicată:

- îl indică pe Gavrilă Andrei-Zian ca operator pentru propriile scopuri ale platformei în configurația actuală; o instituție parteneră nu preia automat toate obligațiile;
- folosește public numai `app.consiliulelevilor@gmail.com`;
- nu publică numărul de telefon ori adresa personală;
- descrie Firebase, transferurile, datele reale, termenele și drepturile;
- are secțiunea `#deletion`, cu ștergere în aplicație și solicitare prin e-mail;
- identificatorul de confirmare este 2026-09-30, cu clarificări juridice din 2026-10-01, fără schimbarea scopurilor, categoriilor de date ori operatorului actual.

## Traseul minim rămas până la lansare

### Deja finalizat

1. Politica nouă este publicată, fără număr de telefon sau adresă personală.
2. Indexurile, regulile Firestore/Storage și funcțiile Node.js 22 sunt active în Firebase.
3. Migrarea celor 9 fișiere Storage referite este făcută și verificată, iar sursele vechi au fost păstrate pentru revenire.
4. A fost adăugat fluxul obligatoriu de confirmare a politicii și vârstei la prima autentificare pentru conturile importate.
5. Acordul poate fi trimis președinților CJE ca **proiect de acord**, pentru analiză și completarea datelor județului.

### Activare juridică înainte de elevi reali

1. Confirmarea, pentru fiecare județ, a persoanei cu putere de semnare și dacă este necesară contrasemnarea/avizarea ISJ sau a altei instituții competente.
2. Verificare juridică/DPO a acordului, în special pentru rolurile operatorilor, minori, date disciplinare, transferurile internaționale și procedura de incidente.
3. Semnarea acordului și Anexei 1 după documentarea temeiurilor, condițiilor minorilor și procedurilor. Crearea unui cont neaprobat prelucrează deja date personale; nu se consideră „fără date reale”.

### Publicarea cu Abdul

1. Trimite numai `CJE_FLUTTER_ONLY_1.1.0_build16.zip` și `HANDOFF_ENG.md` din `01_CURRENT_RELEASE\2026-10-01_release_v1.1.0_build16\TO_ABDUL_FLUTTER`, nu V1 ori ZIP-urile anterioare.
2. Abdul deține cheia originală de upload, SHA-1 49:CA:23:D5:1D:D9:6B:CA:D6:D5:2D:B6:14:32:95:CD:49:13:BC:01. Nu este necesară resetarea ei.
3. Verifică dacă build 16 este nefolosit în ambele console; crește numărul dacă este necesar. Creează artefacte noi din sursa curentă; APK/AAB build 15 existente nu includ noile texte.
4. Actualizează Data Safety și App Privacy, publicul-țintă, ratingurile și contul demo; testează Android Internal testing și iOS TestFlight înainte de promovare.
5. Aprobarea magazinelor și funcționarea tehnică nu certifică RGPD și nu transferă răspunderea. Activarea juridică pentru elevi rămâne o etapă distinctă.

## Surse oficiale verificate

- Google Play — Data safety: <https://support.google.com/googleplay/android-developer/answer/10787469?hl=en>
- Google Play — ștergerea conturilor: <https://support.google.com/googleplay/android-developer/answer/13327111?hl=en>
- Firebase — ghid Data safety Android: <https://firebase.google.com/docs/android/play-data-disclosure>
- Firebase — privacy și datele prelucrate: <https://firebase.google.com/support/privacy>
- Apple — App Privacy Details: <https://developer.apple.com/app-store/app-privacy-details/>
- ML Kit — Data safety Android: <https://developers.google.com/ml-kit/android-data-disclosure>
- ML Kit — App Privacy iOS: <https://developers.google.com/ml-kit/ios-data-disclosure>
