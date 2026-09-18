# Dokumentacja zakresu pracy inzynierskiej

Stan na `2026-06-09`.

Ten dokument jest mapa techniczna do rozdzialow pracy inzynierskiej. README
opisuje repozytorium, natomiast tutaj zebrano problem, cel, wymagania,
architekture, integracje, testy i ograniczenia systemu Finovo.

## 1. Cel pracy

Celem pracy bylo zaprojektowanie i wykonanie aplikacji do zarzadzania finansami
osobistymi, ktora laczy codzienna ewidencje budzetu z analiza inwestycji,
subskrypcji i raportow miesiecznych.

System ma odpowiadac na trzy problemy:
- rozproszenie informacji finansowych pomiedzy arkuszami, aplikacjami bankowymi
  i recznym notatnikiem,
- brak jednego widoku laczacego saldo, koszty cykliczne, cele i inwestycje,
- trudnosc w odtworzeniu historii finansowej uzytkownika oraz wygenerowaniu
  raportu za wybrany miesiac.

## 2. Zakres funkcjonalny

| Obszar | Zrealizowany zakres | Glowne pliki |
| --- | --- | --- |
| Autoryzacja | rejestracja, logowanie, reset hasla, Google Sign-In, wylogowanie | `lib/features/auth` |
| Profil | dane profilu, avatar, preferencje motywu | `lib/features/profile`, `lib/core/app` |
| Transakcje | CRUD transakcji, kategorie, filtrowanie, sortowanie, walidacja kwot | `lib/features/transactions`, `lib/features/categories` |
| Budzety | limity miesieczne, alerty przekroczen, powiazanie z kategoriami | `lib/features/budgets` |
| Cele | cele oszczednosciowe, prognoza, plany cyklicznych wplat | `lib/features/goals`, `lib/features/goal_contribution_plans` |
| Przychody cykliczne | plany regularnych przychodow i powiazanie z transakcjami | `lib/features/recurring_incomes` |
| Inwestycje | ewidencja aktywow, operacje kupna/sprzedazy, historia cen, analityka portfela | `lib/features/investments`, `lib/features/investment_operations` |
| Subskrypcje | koszty cykliczne, terminy odnowien, import z pliku | `lib/features/subscriptions`, `lib/features/subscription_import` |
| Raporty | raport miesieczny, porownanie miesiecy, eksport CSV/PDF, archiwum w Storage | `lib/features/monthly_reports`, `lib/features/export`, `lib/features/report_archives` |
| Bezpieczenstwo | izolacja danych per uzytkownik, reguly Firestore i Storage, walidacja wejscia | `firestore.rules`, `storage.rules`, `lib/core/validation` |

## 3. Wymagania funkcjonalne

| ID | Wymaganie | Status |
| --- | --- | --- |
| F01 | Uzytkownik moze zalozyc konto, zalogowac sie i odzyskac dostep do konta. | zrealizowane |
| F02 | Uzytkownik widzi tylko swoje dane zapisane w przestrzeni `users/{userId}`. | zrealizowane |
| F03 | Uzytkownik moze dodawac, edytowac i usuwac transakcje. | zrealizowane |
| F04 | Uzytkownik moze zarzadzac kategoriami i przenosic dane miedzy kategoriami. | zrealizowane |
| F05 | System oblicza saldo, przychody, wydatki i podstawowe wskazniki dashboardu. | zrealizowane |
| F06 | Uzytkownik moze definiowac budzety miesieczne i otrzymywac alerty. | zrealizowane |
| F07 | Uzytkownik moze prowadzic cele oszczednosciowe oraz planowac wplaty. | zrealizowane |
| F08 | Uzytkownik moze rejestrowac inwestycje, operacje i historie cen. | zrealizowane |
| F09 | System moze pobierac dane rynkowe przez Firebase Functions. | zrealizowane w repo, wymaga wdrozenia funkcji |
| F10 | Uzytkownik moze prowadzic liste subskrypcji i kosztow cyklicznych. | zrealizowane |
| F11 | Uzytkownik moze importowac dane z plikow `CSV`, `TXT` i `XLSX`. | zrealizowane |
| F12 | Uzytkownik moze wygenerowac raport miesieczny i eksport `CSV`/`PDF`. | zrealizowane |
| F13 | Uzytkownik moze zapisac metadane raportu w Firestore i plik w Storage. | zrealizowane |

## 4. Wymagania niefunkcjonalne

| ID | Wymaganie | Realizacja |
| --- | --- | --- |
| N01 | Aplikacja ma dzialac wieloplatformowo. | Flutter, konfiguracje Android/iOS/web/desktop |
| N02 | Dane uzytkownikow maja byc odseparowane. | kolekcje pod `users/{userId}` oraz reguly Firebase |
| N03 | Kod ma byc podzielony na warstwy. | `presentation`, `application`, `domain`, `data` w modulach |
| N04 | System ma miec testy automatyczne dla logiki i kluczowych widgetow. | katalog `test` oraz komenda `flutter test` |
| N05 | System ma byc mozliwy do lokalnego uruchomienia i wdrozenia. | README, `firebase.json`, `functions/package.json` |
| N06 | Dane wejsciowe maja byc walidowane przed zapisem. | `FinanceInputSanitizer`, kontrolery i testy walidacji |

## 5. Architektura systemu

Aplikacja jest klientem Flutter opartym o Firebase. Glowny podzial kodu:
- `lib/core` - bootstrap aplikacji, konfiguracja Firebase, walidacja, elementy
  wspolne UI i preferencje,
- `lib/features` - moduly domenowe, zwykle podzielone na `presentation`,
  `application`, `domain` i `data`,
- `lib/models` - wspolne modele finansowe,
- `functions` - Firebase Cloud Functions dla danych rynkowych i migawek
  portfela,
- `firestore.rules` i `storage.rules` - reguly dostepu do danych.

Warstwa prezentacji nie zapisuje danych bezposrednio w Firebase. Ekrany i
formularze korzystaja z kontrolerow aplikacyjnych, a kontrolery komunikuja sie z
repozytoriami domenowymi. Implementacje repozytoriow w katalogach `data`
obsluguja Firestore, Storage albo Firebase Functions.

## 6. Model danych

Dane sa organizowane wokol dokumentu uzytkownika:

```text
users/{userId}
users/{userId}/transactions/{transactionId}
users/{userId}/categories/{categoryId}
users/{userId}/budgets/{budgetId}
users/{userId}/goals/{goalId}
users/{userId}/goalContributionPlans/{planId}
users/{userId}/recurringIncomes/{recurringIncomeId}
users/{userId}/investments/{investmentId}
users/{userId}/investments/{investmentId}/priceHistory/{pricePointId}
users/{userId}/investmentOperations/{operationId}
users/{userId}/subscriptions/{subscriptionId}
users/{userId}/monthlyReports/{reportId}
users/{userId}/dailyPortfolioSnapshots/{snapshotId}
users/{userId}/reportArchives/{archiveId}
```

Ten model upraszcza reguly bezpieczenstwa: uzytkownik powinien miec dostep tylko
do dokumentow znajdujacych sie pod jego `userId`. Archiwum raportow laczy dane
metadanych w Firestore z plikami w Firebase Storage.

## 7. Backend i integracje

Projekt zawiera Firebase Functions w `functions/index.js`. Konfiguracja
`firebase.json` wskazuje `"functions": { "source": "functions" }`, a katalog
jest sledzony w repo przez Git.

Najwazniejsze funkcje:
- `fetchInvestmentHistory` - callable function uzywana przez aplikacje Flutter,
- `fetchInvestmentHistoryHttp` - fallback HTTP dla platform, dla ktorych
  bezposrednie callable functions sa mniej wygodne,
- `refreshInvestmentQuotesDaily` - harmonogram dziennego odswiezania kursow,
- `saveDailyPortfolioSnapshots` - harmonogram zapisu dziennych migawek portfela,
- `backfillDailyPortfolioSnapshotsHttp` - narzedzie HTTP do uzupelniania historii.

Backend inwestycyjny pobiera automatyczne kursy krypto z publicznego API
Binance. Sekret `PORTFOLIO_BACKFILL_TOKEN` zabezpiecza administracyjny endpoint
HTTP do backfillu migawek portfela.

Klient Flutter korzysta z regionu `europe-west1` w
`lib/features/investments/data/firebase_functions_investment_quote_service.dart`.

## 8. Testowanie

Repo zawiera testy automatyczne dla kontrolerow, walidacji, importow,
eksportow, raportow, inwestycji, subskrypcji i podstawowych przeplywow UI.

Glowne komendy:

```bash
dart analyze
flutter test
```

Testy manualne i scenariusze uruchomieniowe sa opisane w
`docs/test-checklist.md`. Ten plik powinien byc traktowany jako protokol odbioru
dla Androida, weba i zasad bezpieczenstwa.

## 9. Zakres gotowy do obrony

Do obrony projektu szczegolnie istotne sa nastepujace elementy:
- warstwowa architektura aplikacji i rozdzielenie UI od repozytoriow danych,
- izolacja danych uzytkownika w modelu `users/{userId}`,
- walidacja wejscia przed zapisem,
- integracja aplikacji mobilnej/webowej z Firebase Auth, Firestore, Storage i
  Functions,
- modul raportowania z eksportem oraz archiwum plikow,
- modul inwestycyjny z historia operacji, historia cen i migawkami portfela,
- automatyczne testy logiki biznesowej i checklisty testow manualnych.

## 10. Ograniczenia i ryzyka

- Funkcje inwestycyjne end-to-end wymagaja wdrozenia Firebase Functions.
  Backfill migawek portfela wymaga ustawionego sekretu
  `PORTFOLIO_BACKFILL_TOKEN`.
- Reguly Firebase trzeba wdrazac razem ze zmianami modelu danych.
- Logowanie Google wymaga poprawnych odciskow SHA dla docelowego keystore.
- Repo zawiera konfiguracje wieloplatformowa Fluttera, ale finalny odbior
  mobilny powinien byc wykonany na realnym telefonie Android.
- Historia Git pokazuje etapy prac, ale do formalnej prezentacji lepiej
  uzupelnic ja opisem wersji w `docs/release-notes.md`.

## 11. Najblizsze kroki dokumentacyjne

1. W pracy Word rozwinac rozdzial "Analiza wymagan" na podstawie sekcji 2-4.
2. W rozdziale "Projekt systemu" opisac architekture z sekcji 5-7.
3. W rozdziale "Implementacja" opisac po jednym przykladzie modulu: transakcje,
   inwestycje, raporty i bezpieczenstwo.
4. W rozdziale "Testowanie" przeniesc wyniki z `docs/test-checklist.md`.
5. W aneksie lub repo pozostawic `docs/release-notes.md` jako opis wersji i
   etapow rozwoju.
