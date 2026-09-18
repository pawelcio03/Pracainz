# Wersje i historia zmian

Stan na `2026-06-10`.

Ten plik porzadkuje informacje, ktore warto miec przy pytaniach o proces
tworzenia projektu: aktualna wersja, zakres release, wymagane wdrozenia i slady
historii zmian.

## Aktualna wersja

| Pole | Wartosc |
| --- | --- |
| Nazwa aplikacji | Finovo |
| Nazwa pakietu Dart | `finovo` |
| Android package name | `pl.elcpawel.finovo` |
| Wersja z `pubspec.yaml` | `1.0.0+1` |
| Backend Functions | `functions/index.js` |
| Region funkcji inwestycyjnych | `europe-west1` |
| Projekt Firebase w konfiguracji | `projektinz-274ba` |

## Release candidate `1.0.0+1`

Zakres release:
- aplikacja Flutter z konfiguracja Android, iOS, web, Linux, macOS i Windows,
- Firebase Authentication dla kont uzytkownikow,
- Firestore jako baza danych finansowych per uzytkownik,
- Firebase Storage dla archiwow raportow,
- Firebase Functions dla kursow inwestycji i migawek portfela,
- CRUD dla transakcji, kategorii, budzetow, celow, inwestycji, subskrypcji i
  raportow,
- import danych z plikow oraz eksport `CSV`/`PDF`,
- testy automatyczne w katalogu `test`,
- checklisty odbioru w `docs/test-checklist.md`.

Warunki uznania release za gotowy:
- `dart analyze` bez bledow,
- `flutter test` bez bledow,
- build Android `APK` i/lub `AAB` zakonczony sukcesem,
- Firebase rules wdrozone dla Firestore i Storage,
- Functions wdrozone; dla administracyjnego backfillu migawek ustawiony sekret
  `PORTFOLIO_BACKFILL_TOKEN`. Automatyczny feed kursow krypto korzysta z
  publicznego API Binance i nie wymaga sekretu API,
- wykonana checklista manualna dla Androida albo weba.

## Etapy rozwoju z historii Git

Lokalna historia Git zawiera `16` commitow. Ostatnie widoczne etapy:

| Commit | Opis z historii | Znaczenie dla projektu |
| --- | --- | --- |
| `c8d18d2` | `dead code/blad` | porzadkowanie kodu i usuwanie bledow |
| `8ebd731` | `PDF/Excel` | eksporty plikowe i raportowanie |
| `965f793` | `dopracowanie Konto/System plikow` | profil, konto i obsluga plikow |
| `f8f814e` | `UI/Inwestycje/main page` | rozbudowa UI i modulu inwestycji |
| `353a353` | `poprawki ustawnienia/konto, inwestycje, przeglad` | stabilizacja ustawien, konta, inwestycji i dashboardu |
| `8c78b35` | `poprawa Sub i Inwestycji` | subskrypcje oraz inwestycje |
| `add402f` | `name` | nazewnictwo aplikacji/pakietu |
| `3de5d65` | `modol inwestycje poprawki` | poprawki modulu inwestycji |
| `61dabbc` | `poprawa ekranu logowania/rejestracji/rozbicie modulow` | auth oraz modularyzacja |
| `cb2d36a` | `poprawki` | poprawki stabilizacyjne |
| `a68ecfd` | `walidacje` | walidacja danych wejsciowych |
| `5bc2447` | `mobile app` | bazowa aplikacja mobilna |

Nie warto sztucznie przepisywac historii tylko po to, zeby wygladala na dluzsza.
Przy obronie lepiej pokazac te etapy razem z dokumentacja zakresu, testami i
release candidate.

## Punkty kontrolne spojnosci

| Obszar | Wynik lokalnej kontroli |
| --- | --- |
| `pubspec.yaml` | `name: finovo` |
| Importy testow | `package:finovo/...` |
| Katalog Functions | `functions` istnieje i jest wskazany w `firebase.json` |
| Pliki Functions w Git | `functions/index.js`, `functions/package.json`, `functions/package-lock.json` |
| Ignorowane zaleznosci Functions | `functions/node_modules/` jest w `functions/.gitignore` |

## Komendy release

```bash
dart analyze
flutter test
flutter build apk --release
flutter build appbundle --release
firebase deploy --only firestore:rules,storage
firebase deploy --only functions
```

## Uwagi do prezentacji

- Jezeli komisja zapyta o modul inwestycyjny, pokazac zarowno kod Fluttera
  `FirebaseFunctionsInvestmentQuoteService`, jak i backend w `functions/index.js`.
- Jezeli funkcje nie sa wdrozone w dniu prezentacji, jasno powiedziec, ze kod
  backendu jest w repo, ale demo end-to-end wymaga deployu Functions.
- Jezeli padnie pytanie o proces pracy, oprzec odpowiedz na etapach z historii
  Git, a nie na samej liczbie commitow.
