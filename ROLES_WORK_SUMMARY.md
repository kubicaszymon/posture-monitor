# Podsumowanie pracy w projekcie Monitor Postawy

## Przegląd projektu
Projekt "Monitor Postawy" (Posture Monitor) to aplikacja desktopowa do monitorowania postawy ciała użytkownika przed komputerem, wykorzystująca kamerę i sztuczną inteligencję do wykrywania złej postawy i ostrzegania użytkownika.

---

## Rola 1: Machine Learning / AI Developer

### Zakres odpowiedzialności
Implementacja systemu wykrywania postawy ciała za pomocą algorytmów Computer Vision i MediaPipe.

### Zrealizowane zadania

#### 1. **Prototyp detekcji postawy** (`python-model/obsluga.py`)
- Utworzenie proof-of-concept dla detekcji postawy
- Integracja z biblioteką MediaPipe do wykrywania punktów kluczowych ciała (landmarks)
- Implementacja algorytmu obliczania wskaźnika garbienia:
  - Wykrywanie punktów: ramię (shoulder), biodro (hip), ucho (ear)
  - Obliczanie odległości głowy od linii tułowia
  - Normalizacja względem długości tułowia
- Ustawienie progu klasyfikacji (POSTURE_THRESHOLD = 0.12)
- Wizualizacja wyników z użyciem OpenCV:
  - Rysowanie punktów kluczowych
  - Linia tułowia
  - Tekst z oceną postawy i wskaźnikiem

#### 2. **Produkcyjny moduł detekcji** (`ui-app/posture_detector.py`)
- Przepisanie prototypu do klasy `PostureDetector` z rozbudowaną funkcjonalnością:
  - **Multi-API support**: Obsługa różnych wersji MediaPipe (solutions API, tasks API, direct import)
  - **Automatyczna inicjalizacja**: Inteligentne wykrywanie dostępnego API MediaPipe
  - **Pobieranie modeli**: Automatyczne pobieranie modelu pose landmarker dla nowszych wersji
  - **Dwustronna detekcja**: Analiza obu stron ciała (lewa/prawa) i wybór lepiej widocznej
  - **Walidacja visibility**: Sprawdzanie widoczności punktów kluczowych przed analizą
  - **Minimalne progi**: Zabezpieczenia przed błędnymi detekcjami (torso_len < 20)
- Zmiana progu garbienia z 0.12 na 0.20 (bardziej realistyczna wartość)
- Implementacja metody `draw_landmarks()`:
  - Rysowanie pełnej sylwetki MediaPipe z połączeniami
  - Podświetlanie używanych punktów
  - Wyświetlanie informacji diagnostycznych (strona ciała, wskaźnik, próg)
- Obsługa błędów i fallback mechanisms
- Funkcja `point_line_distance()` do geometrycznego obliczania odległości punktu od linii
- Tryb wideo z timestamp dla tasks API
- Testowy main block do weryfikacji działania detektora

#### 3. **Konfiguracja zależności ML**
- Określenie wymaganych bibliotek w `requirements.txt`:
  - `mediapipe>=0.10.9` - Model pose detection
  - `opencv-python>=4.8.0` - Przetwarzanie obrazu i wideo
  - `numpy>=1.24.0` - Operacje matematyczne na macierzach

---

## Rola 2: Backend / Desktop Application Developer

### Zakres odpowiedzialności
Implementacja logiki biznesowej, zarządzania kamerą, systemu statystyk i integracji z systemem operacyjnym.

### Zrealizowane zadania

#### 1. **Zarządzanie kamerą** (`ui-app/main_advanced.py` - klasa `CameraManager`)
- Wykrywanie dostępnych kamer za pomocą Qt QMediaDevices:
  - Enumeracja dostępnych urządzeń wideo
  - Pobieranie informacji o rozdzielczościach
  - Mapowanie na indeksy OpenCV
- Integracja z OpenCV dla różnych platform:
  - Windows: `CAP_DSHOW`
  - Linux: `CAP_V4L2`
  - macOS: `CAP_AVFOUNDATION`
- Fallback mechanisms przy problemach z otwarciem kamery
- Optymalizacja bufora kamery (`CAP_PROP_BUFFERSIZE = 1`)
- Metody Qt Slots dla komunikacji z frontendem:
  - `get_available_cameras()` - lista kamer dla QML
  - `refresh_cameras()` - odświeżanie listy
  - `get_camera_info()` - informacje o aktywnej kamerze

#### 2. **System monitorowania** (`ui-app/main_advanced.py` - klasa `PostureMonitor`)
- **Dual-timer architecture**:
  - Preview timer: Ciągły podgląd kamery (10 FPS domyślnie)
  - Analysis timer: Rzadsza analiza postawy (co 5 sekund)
- **Oddzielenie podglądu od monitoringu**:
  - `startPreview()` / `stopPreview()` - podgląd kamery
  - `startMonitoring()` / `stopMonitoring()` - analiza postawy
- **Logika zliczania złej postawy**:
  - Licznik czasu trwania złej postawy
  - Próg ostrzeżenia (domyślnie 30 sekund)
  - Emitowanie sygnału `badPostureWarning` po przekroczeniu progu
- **Zarządzanie klatkami**:
  - Zapisywanie snapshotów do pliku tymczasowego
  - Cache busting dla QML (URL z timestampem)
  - Rysowanie landmarks na podglądzie
- Integracja z `StatisticsManager` do zapisywania danych
- **Konfigurowalne parametry**:
  - FPS podglądu (30, 20, 10, 5, 1)
  - Interwał analizy (w sekundach)
  - Próg ostrzeżenia o złej postawie
- Wybór kamery i restart podglądu
- Auto-start podglądu przy uruchomieniu aplikacji

#### 3. **System statystyk i historii** (`ui-app/statistics_manager.py`)
- **Baza danych SQLite**:
  - Tabela `sessions` - sesje monitorowania
  - Tabela `checks` - pojedyncze sprawdzenia postawy
  - Indeksy dla optymalizacji zapytań
  - Lokalizacja: `~/.posture_monitor/statistics.db`
- **Zarządzanie sesjami**:
  - `start_session()` - rozpoczęcie nowej sesji
  - `end_session()` - zakończenie z obliczeniem statystyk
  - `add_check()` - dodawanie pojedynczych sprawdzeń
- **Statystyki sesji**:
  - Liczba sprawdzeń (total, good, bad)
  - Procentowy wskaźnik dobrej postawy
  - Średni współczynnik garbienia
  - Czas trwania w minutach
- **Eksport danych** do CSV:
  - `export_current_session_csv()` - eksport aktywnej/ostatniej sesji
  - `export_all_sessions_csv()` - eksport całej historii
  - `export_session_to_path()` - eksport z opcjami (szczegóły, podsumowanie)
  - Katalog eksportu: `~/.posture_monitor/exports/`
- **Qt Slots dla integracji z QML**:
  - `get_current_session_stats()` - statystyki bieżącej sesji
  - `get_current_session_checks()` - lista sprawdzeń
  - `get_all_sessions()` - historia sesji (ostatnie 50)
  - `get_overall_stats()` - statystyki globalne
  - `get_comparison_data()` - dane do wykresów trendów
- Zarządzanie historią (usuwanie sesji, czyszczenie historii)

#### 4. **System Tray i integracja z systemem** (`ui-app/main_advanced.py` - funkcja `main()`)
- Ikona w zasobniku systemowym (System Tray):
  - Programowe generowanie ikony (zielone kółko z literą "P")
  - Menu kontekstowe z opcjami
  - Podwójne kliknięcie do pokazania okna
- Konfiguracja Qt Application:
  - `setQuitOnLastWindowClosed(False)` - działanie w tle
  - Obsługa sygnału `requestMinimizeToTray`
- **Auto-minimalizacja** po starcie monitorowania (opcjonalna)
- Cleanup resources przy zamykaniu aplikacji
- Integracja z `plyer` dla natywnych powiadomień systemowych (opcjonalna)

#### 5. **Konfiguracja projektu**
- Struktura projektu w `pyproject.toml`:
  - Lista plików PySide6
  - Konfiguracja Qt Quick
- Zależności Python w `requirements.txt`:
  - `PySide6>=6.4.0` - Framework Qt dla Python
  - `plyer>=2.1.0` - Powiadomienia systemowe

---

## Rola 3: Frontend / UI/UX Developer

### Zakres odpowiedzialności
Projektowanie i implementacja interfejsu użytkownika z wykorzystaniem QML (Qt Quick).

### Zrealizowane zadania

#### 1. **Główny interfejs aplikacji** (`ui-app/main_advanced_stats.qml`)
- **Architektura aplikacji**:
  - ApplicationWindow jako główne okno (1200x800)
  - System nawigacji oparty na `currentView`
  - Integracja z backendem przez Qt Connections
- **Obsługa zamykania**:
  - Właściwość `closeOnExit` - ukrywanie vs zamykanie
  - Minimalizacja do tray zamiast zamknięcia
- **System powiadomień**:
  - ListModel dla powiadomień
  - Ograniczenie do 20 ostatnich powiadomień
  - Typy powiadomień: success, warning, error
- **Dialogi ostrzeżeń**:
  - Dialog ostrzeżenia o złej postawie (`badPostureWarningDialog`)
  - Opcja wyciszenia ostrzeżeń (`mutePostureWarnings`)
- **Timer odświeżania statystyk**:
  - Automatyczne odświeżanie co 5 sekund podczas monitoringu
  - Reaktywność interfejsu

#### 2. **Wielozakładkowy interfejs**
Implementacja 4 głównych widoków:

**a) Widok Monitorowania** (`currentView: "monitoring"`)
- Podgląd kamery w czasie rzeczywistym
- Wizualizacja landmarks z MediaPipe
- Status kamery i informacje
- Przyciski sterowania:
  - Start/Stop podglądu kamery
  - Start/Stop monitorowania postawy
- Lista powiadomień w czasie rzeczywistym
- Panel wyboru kamery (lista dostępnych kamer)
- Panel ustawień:
  - FPS podglądu (slider)
  - Interwał analizy (slider)
  - Próg ostrzeżenia (slider)
  - Auto-minimalizacja do tray

**b) Widok Statystyk Bieżącej Sesji** (`currentView: "stats-current"`)
- Wyświetlanie statystyk w czasie rzeczywistym
- Canvas do rysowania wykresów
- Podsumowanie liczbowe:
  - Liczba sprawdzeń
  - Dobra/zła postawa
  - Procent dobrej postawy
  - Średni współczynnik
  - Czas trwania
- Przycisk eksportu danych do CSV

**c) Widok Historii Sesji** (`currentView: "stats-history"`)
- TableView z listą zakończonych sesji
- Kolumny: Data, Czas, Czas trwania, Sprawdzenia, Dobra%, Zła%, Średni wskaźnik
- Szczegóły wybranej sesji
- Opcje:
  - Usuwanie pojedynczej sesji
  - Eksport wszystkich sesji do CSV
  - Czyszczenie całej historii

**d) Widok Porównania Sesji** (`currentView: "stats-compare"`)
- Wykres trendu ostatnich 10 sesji
- Wizualizacja poprawy/pogorszenia postawy w czasie
- Statystyki globalne:
  - Liczba sesji
  - Łączna liczba sprawdzeń
  - Ogólny procent dobrej postawy
  - Całkowity czas monitorowania
  - Najlepsza sesja

#### 3. **Hamburger menu i nawigacja**
- Wysuwane menu boczne:
  - Przycisk hamburger (3 linie)
  - Animacja wysuwania (Behavior on x)
  - Nakładka przyciemniająca tło
- Menu items z ikonami:
  - Monitoring
  - Statystyki bieżące
  - Historia
  - Porównanie
- Ikony z katalogu `resources/`:
  - `home.png`, `statistics.png`, `settings.png`, etc.

#### 4. **Komponenty wielokrotnego użytku** (`ui-app/CustomButton.qml`)
- Niestandardowy przycisk z efektami:
  - Hover effect (zmiana koloru)
  - Pressed effect
  - Konfigurowalny tekst i kolor
  - Border radius
- Używany w całej aplikacji dla spójności UI

#### 5. **Dialogi użytkownika**
- **FileDialog** dla eksportu CSV:
  - Wybór lokalizacji zapisu
  - Domyślna nazwa pliku z timestampem
  - Filtr na pliki CSV
- **Dialog ostrzeżenia** o złej postawie:
  - Wyświetlanie czasu trwania
  - Opcja wyciszenia na przyszłość
  - Ikonografia i kolorystyka
- **Dialog eksportu**:
  - Potwierdzenie sukcesu
  - Ścieżka do zapisanego pliku
  - Opcja otwarcia folderu

#### 6. **Styling i responsywność**
- Kolorystyka:
  - Tło: `#f0f0f0` (jasny szary)
  - Sukces: Zielony
  - Błąd/Ostrzeżenie: Czerwony/Pomarańczowy
  - Ramki i cienie dla oddzielenia elementów
- Layouty:
  - ColumnLayout, RowLayout dla responsywności
  - ScrollView dla długich list
  - Anchors dla pozycjonowania
- Czcionki:
  - Różne rozmiary dla hierarchii (12, 14, 16, 20, 24)
  - Bold dla nagłówków
  - Konsystencja w całej aplikacji

#### 7. **Obsługa stanów i reaktywność**
- Property bindings dla automatycznej aktualizacji UI:
  - `isMonitoring` - włączanie/wyłączanie przycisków
  - `hasCameraAvailable` - wyświetlanie ostrzeżeń
  - `currentSessionStats` - aktualizacja liczników
- Connections z backendem:
  - `onNotificationAdded` - dodawanie powiadomień
  - `onCameraImageChanged` - aktualizacja obrazu
  - `onBadPostureWarning` - pokazywanie dialogu
  - `onCameraAvailableChanged` - obsługa braku kamery
- Timery do automatycznych akcji
- Disabled states dla przycisków gdy brak kamery

---

## Podsumowanie współpracy ról

Projekt wymagał ścisłej współpracy między trzema rolami:

1. **ML Developer** dostarczył algorytmy detekcji i prototyp, który został zintegrowany w aplikację produkcyjną.

2. **Backend Developer** stworzył solidną architekturę aplikacji, obsługę kamery, system statystyk z bazą danych, i integrację z systemem operacyjnym.

3. **Frontend Developer** zaprojektował i zaimplementował intuicyjny, wielofunkcyjny interfejs użytkownika z zaawansowanymi statystykami i wizualizacjami.

Wszystkie trzy role pracowały zgodnie z wzorcem Model-View-Controller, gdzie:
- **Model**: Detektor postawy + Menedżer statystyk
- **Controller**: PostureMonitor + CameraManager
- **View**: QML UI

Efektem jest w pełni funkcjonalna aplikacja desktopowa do monitorowania postawy z zaawansowanymi możliwościami analizy i raportowania.
