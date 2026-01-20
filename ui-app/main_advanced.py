import sys
import os
from pathlib import Path
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QObject, Signal, Slot, QTimer, Property, QUrl
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
    
    def __init__(self):
        super().__init__()
        self.camera = None
        self.current_frame = None
        self.is_camera_open = False
        
    def open_camera(self, camera_id: int = 0) -> bool:
        try:
            self.camera = cv2.VideoCapture(camera_id)
            if self.camera.isOpened():
                self.is_camera_open = True
                return True
        except Exception as e:
            print(f"Błąd otwarcia kamery: {e}")
        return False
    
    def read_frame(self) -> np.ndarray:
        if not self.is_camera_open or self.camera is None:
            return None
        ret, frame = self.camera.read()
        if ret:
            self.current_frame = frame
            self.frameReady.emit()
            return frame
        return None
    
    def release(self):
        if self.camera is not None:
            self.camera.release()
            self.is_camera_open = False


class PostureMonitor(QObject):
    statusChanged = Signal(str)
    notificationAdded = Signal(str, str, str)
    monitoringStateChanged = Signal(bool)
    cameraImageChanged = Signal(str)
    badPostureWarning = Signal(int)  # Wysyła czas złej postawy w sekundach
    
    def __init__(self, statistics_manager):
        super().__init__()
        self._is_monitoring = False
        self._check_interval = 30000
        self._timer = QTimer()
        self._timer.timeout.connect(self._check_posture)
        
        self.detector = PostureDetector(posture_threshold=0.12)
        self.camera_manager = CameraManager()
        
        # Statystyki - teraz zarządzane przez StatisticsManager
        self.stats_manager = statistics_manager
        self._good_posture_count = 0
        self._bad_posture_count = 0
        
        # Licznik złej postawy
        self._bad_posture_duration = 0  # w sekundach
        self._bad_posture_threshold = 30  # 30 sekund (można zmieniać)
        self._last_was_bad_posture = False
        
        # Snapshot kamery
        self._temp_dir = tempfile.gettempdir()
        self._camera_snapshot_path = os.path.join(self._temp_dir, "posture_monitor_snapshot.jpg")
        self._current_camera_image = ""
        
        print(f"Snapshot: {self._camera_snapshot_path}")
    
    @Property(bool, notify=monitoringStateChanged)
    def isMonitoring(self):
        return self._is_monitoring
    
    @Property(str, notify=cameraImageChanged)
    def cameraImage(self):
        return self._current_camera_image
    
    @Slot()
    def startMonitoring(self):
        print("Rozpoczynam monitoring...")
        if not self._is_monitoring:
            if not self.camera_manager.open_camera(0):
                self.statusChanged.emit("Błąd: Nie można otworzyć kamery!")
                return
            
            # Rozpocznij nową sesję w statystykach
            self.stats_manager.start_session()
            
            self._is_monitoring = True
            self._timer.start(self._check_interval)
            self.monitoringStateChanged.emit(True)
            self.statusChanged.emit("Monitoring rozpoczęty")
            
            print(f"Monitoring uruchomiony (interwał: {self._check_interval/1000}s)")
            
            # Pierwsze sprawdzenie od razu
            QTimer.singleShot(1000, self._check_posture)
    
    @Slot()
    def stopMonitoring(self):
        print("Zatrzymuję monitoring...")
        if self._is_monitoring:
            self._is_monitoring = False
            self._timer.stop()
            self.camera_manager.release()
            self.monitoringStateChanged.emit(False)
            self.statusChanged.emit("Monitoring zatrzymany")
            
            # Zakończ sesję
            self.stats_manager.end_session()
            
            print("Monitoring zatrzymany")
    
    def _check_posture(self):
        if not self._is_monitoring:
            return
        
        print(f"\nSprawdzam postawę...")
        
        frame = self.camera_manager.read_frame()
        if frame is None:
            print("Nie można odczytać klatki z kamery")
            return
        
        # Zapisz RAW snapshot
        raw_snapshot_path = os.path.join(self._temp_dir, "posture_raw_snapshot.jpg")
        cv2.imwrite(raw_snapshot_path, frame)
        
        # Analizuj postawę
        is_good_posture, norm_dist, landmarks = self.detector.analyze_posture(frame)
        
        # Zapisz do bazy danych
        detection_successful = landmarks is not None
        self.stats_manager.add_check(is_good_posture, norm_dist, detection_successful)
        
        # ===== LOGIKA LICZNIKA ZŁEJ POSTAWY =====
        if not detection_successful:
            # Nie wykryto osoby - resetuj licznik
            self._bad_posture_duration = 0
            self._last_was_bad_posture = False
        elif is_good_posture:
            # Dobra postawa - resetuj licznik
            self._bad_posture_duration = 0
            self._last_was_bad_posture = False
        else:
            # Zła postawa - zwiększaj licznik
            self._bad_posture_duration += self._check_interval // 1000  # Konwersja ms na sekundy
            self._last_was_bad_posture = True
            
            # Wyślij sygnał ostrzeżenia jeśli przekroczono próg
            if self._bad_posture_duration >= self._bad_posture_threshold:
                print(f"⚠️ OSTRZEŻENIE: Zła postawa przez {self._bad_posture_duration}s!")
                self.badPostureWarning.emit(self._bad_posture_duration)
        
        # ==========================================
        
        # Narysuj landmarks
        if landmarks is not None:
            frame_with_landmarks = self.detector.draw_landmarks(
                frame.copy(), is_good_posture, norm_dist, landmarks
            )
        else:
            frame_with_landmarks = frame.copy()
            cv2.putText(
                frame_with_landmarks,
                "NIE WYKRYTO OSOBY W KADRZE",
                (20, 40),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.8,
                (0, 0, 255),
                2
            )
        
        # Zapisz snapshot
        try:
            cv2.imwrite(self._camera_snapshot_path, frame_with_landmarks)
            import time
            self._current_camera_image = f"file:///{self._camera_snapshot_path}?t={int(time.time())}"
            self.cameraImageChanged.emit(self._current_camera_image)
        except Exception as e:
            print(f"Błąd zapisu snapshota: {e}")
        
        # Aktualizuj lokalne liczniki (dla kompatybilności)
        if landmarks is None:
            self.notificationAdded.emit(
                "Nie wykryto osoby w kadrze",
                "just now",
                "warning"
            )
            return
        
        if is_good_posture:
            self._good_posture_count += 1
            print(f"Dobra postawa (wskaźnik: {norm_dist:.3f})")
            self.notificationAdded.emit(
                f"Dobra postawa ({norm_dist:.3f})",
                "just now",
                "success"
            )
        else:
            self._bad_posture_count += 1
            print(f"Zła postawa! (wskaźnik: {norm_dist:.3f})")
            self.notificationAdded.emit(
                f"Zła postawa ({norm_dist:.3f})",
                "just now",
                "warning"
            )
    
    @Slot(int)
    def setCheckInterval(self, seconds: int):
        self._check_interval = seconds * 1000
        print(f"Interwał zmieniony na {seconds}s")
        if self._is_monitoring:
            self._timer.setInterval(self._check_interval)
    
    @Slot(int)
    def setBadPostureThreshold(self, seconds: int):
        """Ustaw próg ostrzeżenia o złej postawie (w sekundach)"""
        self._bad_posture_threshold = seconds
        print(f"Próg ostrzeżenia o złej postawie: {seconds}s")
    
    @Slot(result=int)
    def getGoodCount(self) -> int:
        return self._good_posture_count
    
    @Slot(result=int)
    def getBadCount(self) -> int:
        return self._bad_posture_count
    
    def cleanup(self):
        print("Sprzątanie PostureMonitor...")
        self.stopMonitoring()
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
    
    print(f"Ładowanie QML z: {qml_file}")
    engine.load(QUrl.fromLocalFile(str(qml_file)))
    
    if not engine.rootObjects():
        print("Nie można załadować QML")
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
