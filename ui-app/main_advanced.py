import sys
import os
from pathlib import Path
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QObject, Signal, Slot, QTimer, Property, QUrl
from PySide6.QtMultimedia import QMediaDevices, QCameraDevice
import cv2
import numpy as np
import tempfile

from posture_detector import PostureDetector
from statistics_manager import StatisticsManager

try:
    from plyer import notification
    NOTIFICATIONS_AVAILABLE = True
except ImportError:
    NOTIFICATIONS_AVAILABLE = False


class CameraManager(QObject):
    frameReady = Signal()
    availableCamerasChanged = Signal()
    cameraErrorOccurred = Signal(str)

    def __init__(self):
        super().__init__()
        self.camera = None
        self.current_frame = None
        self.is_camera_open = False
        self._available_cameras = []
        self._current_camera_id = 0
        self._current_backend = None

        # Wykryj dostępne kamery przy starcie
        self._detect_available_cameras()

    def _detect_available_cameras(self):
        """Wykrywa dostępne kamery używając Qt QMediaDevices"""
        self._available_cameras = []

        print("\n=== Wykrywanie kamer (Qt QMediaDevices) ===")

        # Użyj Qt do wykrycia PRAWDZIWYCH kamer
        video_inputs = QMediaDevices.videoInputs()

        if video_inputs:
            print(f"Znaleziono {len(video_inputs)} kamer(y):")
            for idx, camera_device in enumerate(video_inputs):
                name = camera_device.description()
                device_id = camera_device.id().data().decode() if camera_device.id() else f"camera_{idx}"

                # Pobierz obsługiwane rozdzielczości
                formats = camera_device.videoFormats()
                resolution = "Nieznana"
                if formats:
                    # Weź największą rozdzielczość
                    max_res = max(formats, key=lambda f: f.resolution().width() * f.resolution().height())
                    resolution = f"{max_res.resolution().width()}x{max_res.resolution().height()}"

                camera_info = {
                    'id': idx,  # Indeks dla OpenCV
                    'device_id': device_id,
                    'name': name,
                    'resolution': resolution,
                    'qt_device': camera_device
                }
                self._available_cameras.append(camera_info)
                print(f"  [{idx}] {name} - {resolution}")
        else:
            print("  Nie znaleziono zadnych kamer!")
            print("  Sprawdz czy:")
            print("    - Kamera jest podlaczona")
            print("    - Sterowniki sa zainstalowane")
            print("    - Kamera nie jest uzywana przez inna aplikacje")

        print("=" * 45)

        self.availableCamerasChanged.emit()

    @Slot(result='QVariantList')
    def get_available_cameras(self) -> list:
        """Zwraca listę dostępnych kamer dla QML"""
        return [{'id': cam['id'], 'name': cam['name'], 'resolution': cam['resolution']}
                for cam in self._available_cameras]

    @Slot()
    def refresh_cameras(self):
        """Odśwież listę dostępnych kamer"""
        self._detect_available_cameras()

    def open_camera(self, camera_id: int = 0) -> bool:
        """Otwiera kamerę używając OpenCV"""
        self.release()

        # Pobierz nazwę kamery
        camera_name = f"Kamera {camera_id}"
        for cam in self._available_cameras:
            if cam['id'] == camera_id:
                camera_name = cam['name']
                break

        print(f"\nOtwieram: {camera_name} (index: {camera_id})...")

        # Wybierz backend w zależności od systemu
        if sys.platform == 'win32':
            backend = cv2.CAP_DSHOW
        elif sys.platform.startswith('linux'):
            backend = cv2.CAP_V4L2
        elif sys.platform == 'darwin':
            backend = cv2.CAP_AVFOUNDATION
        else:
            backend = cv2.CAP_ANY

        try:
            self.camera = cv2.VideoCapture(camera_id, backend)

            if not self.camera.isOpened():
                # Sprobuj bez specyficznego backendu
                print("  Probuje z domyslnym backendem...")
                self.camera = cv2.VideoCapture(camera_id)

            if self.camera.isOpened():
                self.camera.set(cv2.CAP_PROP_BUFFERSIZE, 1)

                # Kilka prób odczytu
                for attempt in range(5):
                    ret, frame = self.camera.read()
                    if ret and frame is not None:
                        self.is_camera_open = True
                        self._current_camera_id = camera_id

                        width = int(self.camera.get(cv2.CAP_PROP_FRAME_WIDTH))
                        height = int(self.camera.get(cv2.CAP_PROP_FRAME_HEIGHT))
                        fps = int(self.camera.get(cv2.CAP_PROP_FPS)) or 30

                        print(f"  [OK] Otwarto! {width}x{height} @ {fps}fps")
                        return True

                print("  [BLAD] Nie mozna odczytac obrazu")
                self.camera.release()

        except Exception as e:
            print(f"  [BLAD] {e}")

        error_msg = f"Nie mozna otworzyc kamery: {camera_name}"
        self.cameraErrorOccurred.emit(error_msg)
        return False

    def read_frame(self) -> np.ndarray:
        if not self.is_camera_open or self.camera is None:
            return None

        ret, frame = self.camera.read()
        if ret and frame is not None:
            self.current_frame = frame
            self.frameReady.emit()
            return frame
        return None

    def release(self):
        if self.camera is not None:
            self.camera.release()
            self.camera = None
        self.is_camera_open = False
        self._current_backend = None

    @Slot(result=str)
    def get_camera_info(self) -> str:
        """Zwraca informacje o aktualnie używanej kamerze"""
        if not self.is_camera_open or self.camera is None:
            return "Kamera nieaktywna"

        # Znajdź nazwę kamery
        camera_name = f"Kamera {self._current_camera_id}"
        for cam in self._available_cameras:
            if cam['id'] == self._current_camera_id:
                camera_name = cam['name']
                break

        width = int(self.camera.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(self.camera.get(cv2.CAP_PROP_FRAME_HEIGHT))
        fps = int(self.camera.get(cv2.CAP_PROP_FPS)) or 30

        return f"{camera_name} - {width}x{height}"


class PostureMonitor(QObject):
    statusChanged = Signal(str)
    notificationAdded = Signal(str, str, str)
    monitoringStateChanged = Signal(bool)
    cameraImageChanged = Signal(str)
    badPostureWarning = Signal(int)
    cameraInfoChanged = Signal(str)
    cameraActiveChanged = Signal(bool)
    fpsChanged = Signal(int)

    def __init__(self, statistics_manager):
        super().__init__()
        self._is_monitoring = False  # Czy analiza postawy jest wlaczona
        self._is_camera_active = False  # Czy podglad kamery jest wlaczony

        # Timer do podgladu kamery (ciagly)
        self._preview_fps = 10  # Domyslnie 10 FPS
        self._preview_timer = QTimer()
        self._preview_timer.timeout.connect(self._update_preview)

        # Timer do analizy postawy (rzadziej)
        self._analysis_interval = 5000  # Co 5 sekund analiza
        self._analysis_timer = QTimer()
        self._analysis_timer.timeout.connect(self._analyze_posture)

        self.detector = PostureDetector(posture_threshold=0.12)
        self.camera_manager = CameraManager()

        self.camera_manager.cameraErrorOccurred.connect(self._on_camera_error)

        self.stats_manager = statistics_manager
        self._good_posture_count = 0
        self._bad_posture_count = 0

        self._bad_posture_duration = 0
        self._bad_posture_threshold = 30
        self._last_was_bad_posture = False

        self._temp_dir = tempfile.gettempdir()
        self._camera_snapshot_path = os.path.join(self._temp_dir, "posture_monitor_snapshot.jpg")
        self._current_camera_image = ""

        self._selected_camera_id = 0

        # Ostatni wynik analizy (do rysowania na podgladzie)
        self._last_landmarks = None
        self._last_is_good_posture = True
        self._last_norm_dist = 0.0

        print(f"Snapshot path: {self._camera_snapshot_path}")

        # Automatycznie uruchom podglad kamery
        QTimer.singleShot(500, self._auto_start_preview)

    def _on_camera_error(self, error_msg: str):
        """Obsluga bledow kamery"""
        self.statusChanged.emit(f"Blad kamery: {error_msg}")
        self.notificationAdded.emit(error_msg, "teraz", "error")

    def _auto_start_preview(self):
        """Automatycznie uruchom podglad pierwszej kamery"""
        if self._available_cameras_count() > 0:
            self.startPreview()

    def _available_cameras_count(self):
        return len(self.camera_manager.get_available_cameras())

    @Property(bool, notify=monitoringStateChanged)
    def isMonitoring(self):
        return self._is_monitoring

    @Property(bool, notify=cameraActiveChanged)
    def isCameraActive(self):
        return self._is_camera_active

    @Property(str, notify=cameraImageChanged)
    def cameraImage(self):
        return self._current_camera_image

    @Property(int, notify=fpsChanged)
    def previewFps(self):
        return self._preview_fps

    # ========== PODGLAD KAMERY (ciagly) ==========

    @Slot()
    def startPreview(self):
        """Uruchom podglad kamery (bez analizy)"""
        if self._is_camera_active:
            return

        print(f"Uruchamiam podglad kamery {self._selected_camera_id}...")

        if not self.camera_manager.open_camera(self._selected_camera_id):
            self.statusChanged.emit("Nie mozna otworzyc kamery")
            return

        self._is_camera_active = True
        self.cameraActiveChanged.emit(True)

        camera_info = self.camera_manager.get_camera_info()
        self.cameraInfoChanged.emit(camera_info)

        # Uruchom timer podgladu
        interval = int(1000 / self._preview_fps) if self._preview_fps > 0 else 2000
        self._preview_timer.start(interval)

        print(f"Podglad uruchomiony ({self._preview_fps} FPS)")

    @Slot()
    def stopPreview(self):
        """Zatrzymaj podglad kamery"""
        if not self._is_camera_active:
            return

        print("Zatrzymuje podglad...")
        self._preview_timer.stop()

        # Jesli monitoring tez jest wlaczony, zatrzymaj go
        if self._is_monitoring:
            self.stopMonitoring()

        self.camera_manager.release()
        self._is_camera_active = False
        self.cameraActiveChanged.emit(False)

    def _update_preview(self):
        """Aktualizuj podglad kamery"""
        if not self._is_camera_active:
            return

        frame = self.camera_manager.read_frame()
        if frame is None:
            return

        display_frame = frame.copy()

        # Jesli analiza wlaczona i mamy landmarks - rysuj je
        if self._is_monitoring and self._last_landmarks is not None:
            display_frame = self.detector.draw_landmarks(
                display_frame, self._last_is_good_posture,
                self._last_norm_dist, self._last_landmarks
            )
        elif self._is_monitoring and self._last_landmarks is None:
            # Analiza wlaczona ale nie wykryto osoby
            cv2.putText(display_frame, "NIE WYKRYTO OSOBY",
                        (20, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 0, 255), 2)

        try:
            cv2.imwrite(self._camera_snapshot_path, display_frame)
            import time
            path_for_url = self._camera_snapshot_path.replace("\\", "/")
            self._current_camera_image = f"file:///{path_for_url}?t={int(time.time() * 1000)}"
            self.cameraImageChanged.emit(self._current_camera_image)
        except:
            pass

    # ========== ANALIZA POSTAWY (monitoring) ==========

    @Slot()
    def startMonitoring(self):
        """Uruchom analize postawy (wymaga aktywnego podgladu)"""
        print("Rozpoczynam monitoring postawy...")

        # Jesli podglad nie jest aktywny, uruchom go
        if not self._is_camera_active:
            self.startPreview()
            if not self._is_camera_active:
                return

        if self._is_monitoring:
            return

        self.stats_manager.start_session()

        self._is_monitoring = True
        self._analysis_timer.start(self._analysis_interval)
        self.monitoringStateChanged.emit(True)
        self.statusChanged.emit("Analiza postawy wlaczona")

        print(f"Analiza uruchomiona (co {self._analysis_interval/1000}s)")

        # Pierwsza analiza od razu
        QTimer.singleShot(500, self._analyze_posture)

    @Slot()
    def stopMonitoring(self):
        """Zatrzymaj analize postawy (podglad zostaje)"""
        if not self._is_monitoring:
            return

        print("Zatrzymuje analize postawy...")
        self._is_monitoring = False
        self._analysis_timer.stop()
        self.monitoringStateChanged.emit(False)
        self.statusChanged.emit("Analiza zatrzymana")

        # Wyczysc ostatnie wyniki analizy
        self._last_landmarks = None
        self._last_is_good_posture = True
        self._last_norm_dist = 0.0

        self.stats_manager.end_session()

    def _analyze_posture(self):
        """Analizuj postawe (wywolywane przez timer)"""
        if not self._is_monitoring or not self._is_camera_active:
            return

        frame = self.camera_manager.read_frame()
        if frame is None:
            return

        # Analizuj postawe
        is_good_posture, norm_dist, landmarks = self.detector.analyze_posture(frame)

        # Zapisz wyniki do wyswietlania na podgladzie
        self._last_landmarks = landmarks
        self._last_is_good_posture = is_good_posture
        self._last_norm_dist = norm_dist

        detection_successful = landmarks is not None
        self.stats_manager.add_check(is_good_posture, norm_dist, detection_successful)

        # Logika licznika zlej postawy
        if not detection_successful:
            self._bad_posture_duration = 0
            self._last_was_bad_posture = False
        elif is_good_posture:
            self._bad_posture_duration = 0
            self._last_was_bad_posture = False
        else:
            self._bad_posture_duration += self._analysis_interval // 1000
            self._last_was_bad_posture = True

            if self._bad_posture_duration >= self._bad_posture_threshold:
                print(f"OSTRZEZENIE: Zla postawa przez {self._bad_posture_duration}s!")
                self.badPostureWarning.emit(self._bad_posture_duration)

        # Powiadomienia
        if landmarks is None:
            self.notificationAdded.emit("Nie wykryto osoby", "teraz", "warning")
            return

        if is_good_posture:
            self._good_posture_count += 1
            self.notificationAdded.emit(f"Dobra postawa ({norm_dist:.3f})", "teraz", "success")
        else:
            self._bad_posture_count += 1
            self.notificationAdded.emit(f"Zla postawa ({norm_dist:.3f})", "teraz", "warning")
    
    @Slot(int)
    def setPreviewFps(self, fps: int):
        """Ustaw FPS podgladu (30, 20, 10, 5, 1)"""
        self._preview_fps = fps
        self.fpsChanged.emit(fps)
        print(f"FPS podgladu: {fps}")

        if self._is_camera_active and fps > 0:
            interval = int(1000 / fps)
            self._preview_timer.setInterval(interval)

    @Slot(int)
    def setAnalysisInterval(self, seconds: int):
        """Ustaw interwal analizy postawy"""
        self._analysis_interval = seconds * 1000
        print(f"Interwal analizy: {seconds}s")
        if self._is_monitoring:
            self._analysis_timer.setInterval(self._analysis_interval)

    @Slot(int)
    def setBadPostureThreshold(self, seconds: int):
        """Ustaw prog ostrzezenia o zlej postawie"""
        self._bad_posture_threshold = seconds
        print(f"Prog ostrzezenia: {seconds}s")

    @Slot(result=int)
    def getGoodCount(self) -> int:
        return self._good_posture_count

    @Slot(result=int)
    def getBadCount(self) -> int:
        return self._bad_posture_count

    @Slot(int)
    def setSelectedCamera(self, camera_id: int):
        """Ustaw wybrana kamere i restartuj podglad"""
        if camera_id == self._selected_camera_id:
            return

        self._selected_camera_id = camera_id
        print(f"Wybrano kamere: {camera_id}")

        # Restartuj podglad z nowa kamera
        if self._is_camera_active:
            self.stopPreview()
            QTimer.singleShot(100, self.startPreview)

    @Slot(result=int)
    def getSelectedCamera(self) -> int:
        """Zwróć ID wybranej kamery"""
        return self._selected_camera_id

    @Slot(result='QVariantList')
    def getAvailableCameras(self):
        """Zwróć listę dostępnych kamer"""
        return self.camera_manager.get_available_cameras()

    @Slot()
    def refreshCameras(self):
        """Odśwież listę kamer"""
        self.camera_manager.refresh_cameras()

    @Slot(result=str)
    def getCameraInfo(self) -> str:
        """Zwróć informacje o aktualnej kamerze"""
        return self.camera_manager.get_camera_info()

    def cleanup(self):
        print("Sprzatanie PostureMonitor...")
        self.stopMonitoring()
        self.stopPreview()
        self.detector.release()

        if os.path.exists(self._camera_snapshot_path):
            try:
                os.remove(self._camera_snapshot_path)
            except:
                pass


def main():
    print("=" * 60)
    print("Monitor Postawy - Z ROZBUDOWANYMI STATYSTYKAMI")
    print("=" * 60)
    
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Posture Monitor")
    app.setQuitOnLastWindowClosed(True)
    
    # Menedżer statystyk
    statistics_manager = StatisticsManager()
    
    # Monitor postawy
    posture_monitor = PostureMonitor(statistics_manager)
    
    # QML Engine
    engine = QQmlApplicationEngine()
    root_context = engine.rootContext()
    root_context.setContextProperty("postureMonitor", posture_monitor)
    root_context.setContextProperty("statisticsManager", statistics_manager)
    
    # Dummy trayManager
    class DummyTray(QObject):
        pass
    root_context.setContextProperty("trayManager", DummyTray())
    
    # Załaduj QML
    qml_file = Path(__file__).resolve().parent / "main_advanced_stats.qml"
    
    if not qml_file.exists():
        print("main_advanced_stats.qml nie znaleziony")
        qml_file = Path(__file__).resolve().parent / "main.qml"
    
    if not qml_file.exists():
        print(f"Nie znaleziono: {qml_file}")
        return 1
    
    print(f"Ladowanie QML z: {qml_file}")
    engine.load(QUrl.fromLocalFile(str(qml_file)))
    
    if not engine.rootObjects():
        print("Nie mozna zaladowac QML")
        return 1
    
    root = engine.rootObjects()[0]
    root.setProperty("closeOnExit", True)
    
    print("QML załadowany")
    print("Aplikacja uruchomiona")
    print("=" * 60)
    
    exit_code = app.exec()
    
    posture_monitor.cleanup()
    statistics_manager.cleanup()
    
    return exit_code

if __name__ == "__main__":
    sys.exit(main())
