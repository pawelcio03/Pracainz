# Checklista testow aplikacji

Stan na `2026-06-03`.

## Android

1. Uruchomic `flutter run` na emulatorze lub telefonie Android.
2. Zalogowac sie istniejacym kontem albo utworzyc nowe konto.
3. Dodac i edytowac:
   - transakcje
   - budzety
   - cele
   - inwestycje
   - operacje inwestycyjne
   - subskrypcje
4. Wygenerowac:
   - eksport CSV
   - eksport PDF
   - raport miesieczny
   - archiwum CSV/PDF do Firebase Storage
5. Sprawdzic wylogowanie i ponowne logowanie.

## Web

1. Uruchomic `flutter run -d chrome`.
2. Zweryfikowac logowanie i rejestracje przez Firebase Authentication.
3. Dodac po jednej pozycji do kazdego glownego modulu:
   - transakcje
   - budzety
   - cele
   - inwestycje
   - subskrypcje
4. Zweryfikowac:
   - filtry transakcji
   - alerty dashboardu
   - analityke portfela
   - zapis raportu miesiecznego
   - zapis archiwum w Storage
5. Sprawdzic responsywnosc dashboardu dla szerokosci mobilnej i desktopowej.

## Bezpieczenstwo

1. Zalogowany uzytkownik widzi tylko dane ze swojej przestrzeni `users/{userId}`.
2. Niezalogowany uzytkownik nie powinien miec dostepu do Firestore ani Storage.
3. Archiwum raportow powinno zapisywac pliki tylko pod `users/{userId}/reports/...`.
4. Usuniecie dokumentu archiwum powinno usuwac tez plik z Firebase Storage.

## Automaty

- `flutter test`
- `dart analyze`
- `firebase deploy --only firestore:rules,storage --project projektinz-274ba`
