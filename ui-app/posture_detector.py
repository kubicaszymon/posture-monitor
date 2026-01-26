"""
Moduł do detekcji postawy ciała używając MediaPipe
Wersja poprawiona - używa tasks API jeśli solutions nie działa
"""

import cv2
import numpy as np
from typing import Tuple, Optional
import sys


class PostureDetector:
    """Klasa do detekcji i analizy postawy ciała"""

    def __init__(self, posture_threshold: float = 0.20):
        """
        Args:
            posture_threshold: Próg garbienia (0.20 = realistyczny próg dla normalnej postawy)
                              Poprzednia wartość 0.12 była zbyt restrykcyjna
        """
        self.POSTURE_THRESHOLD = posture_threshold
        
        # Spróbuj zaimportować MediaPipe z obsługą różnych wersji
        self._init_mediapipe()
        
    def _init_mediapipe(self):
        """Inicjalizacja MediaPipe z obsługą różnych API"""
        try:
            import mediapipe as mp
            
            # Sprawdź jakie API jest dostępne
            print("MediaPipe version:", mp.__version__)
            print("Dostępne atrybuty:", [attr for attr in dir(mp) if not attr.startswith('_')])
            
            # Próba 1: Użyj solutions API (starsze wersje lub Linux)
            if hasattr(mp, 'solutions') and hasattr(mp.solutions, 'pose'):
                print("Używam MediaPipe solutions API")
                self.mp_pose = mp.solutions.pose
                self.pose = self.mp_pose.Pose(
                    static_image_mode=False,
                    model_complexity=1,
                    min_detection_confidence=0.6,
                    min_tracking_confidence=0.5,
                    smooth_landmarks=True
                )
                self.mp_drawing = mp.solutions.drawing_utils
                self.mp_drawing_styles = mp.solutions.drawing_styles
                self.api_type = 'solutions'
                return
            
            # Próba 2: Użyj tasks API (nowsze wersje)
            elif hasattr(mp, 'tasks'):
                print("Używam MediaPipe tasks API")
                from mediapipe.tasks import python
                from mediapipe.tasks.python import vision
                
                # Pobierz model pose landmarker
                model_path = self._download_pose_model()
                
                base_options = python.BaseOptions(model_asset_path=model_path)
                options = vision.PoseLandmarkerOptions(
                    base_options=base_options,
                    running_mode=vision.RunningMode.VIDEO,
                    min_pose_detection_confidence=0.6,
                    min_pose_presence_confidence=0.5,
                    min_tracking_confidence=0.5
                )
                self.pose = vision.PoseLandmarker.create_from_options(options)
                self.api_type = 'tasks'
                
                # Mapowanie landmark indices (kompatybilność z solutions API)
                self.POSE_LANDMARKS = {
                    'LEFT_SHOULDER': 11,
                    'LEFT_HIP': 23,
                    'LEFT_EAR': 7,
                    'RIGHT_SHOULDER': 12,
                    'RIGHT_HIP': 24,
                    'RIGHT_EAR': 8
                }
                return
            
            else:
                raise ImportError("MediaPipe nie ma ani 'solutions' ani 'tasks' API")
                
        except Exception as e:
            print(f"BŁĄD inicjalizacji MediaPipe: {e}")
            print(f"Typ błędu: {type(e).__name__}")
            import traceback
            traceback.print_exc()
            
            # Fallback - spróbuj prostszej metody
            print("\nPróbuję alternatywną metodę inicjalizacji...")
            self._init_mediapipe_fallback()
    
    def _init_mediapipe_fallback(self):
        """Alternatywna metoda inicjalizacji dla problematycznych instalacji"""
        try:
            # Bezpośredni import modułów
            import mediapipe.python.solutions.pose as mp_pose
            import mediapipe.python.solutions.drawing_utils as mp_drawing
            
            print("Użyto bezpośredniego importu modułów MediaPipe")
            
            self.mp_pose = mp_pose
            self.pose = mp_pose.Pose(
                static_image_mode=False,
                model_complexity=1,
                min_detection_confidence=0.6,
                min_tracking_confidence=0.5,
                smooth_landmarks=True
            )
            self.mp_drawing = mp_drawing
            self.api_type = 'direct'
            
        except Exception as e:
            print(f"Fallback również nie zadziałał: {e}")
            raise RuntimeError(
                "Nie można zainicjalizować MediaPipe. "
                "Spróbuj przeinstalować: pip uninstall mediapipe && pip install mediapipe==0.10.9"
            )
    
    def _download_pose_model(self) -> str:
        """Pobierz model pose landmarker dla tasks API"""
        import os
        import urllib.request
        
        model_dir = os.path.expanduser("~/.mediapipe/models")
        os.makedirs(model_dir, exist_ok=True)
        
        model_path = os.path.join(model_dir, "pose_landmarker_lite.task")
        
        if not os.path.exists(model_path):
            print("Pobieram model pose landmarker...")
            url = "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/latest/pose_landmarker_lite.task"
            
            try:
                urllib.request.urlretrieve(url, model_path)
                print("Model pobrany")
            except Exception as e:
                print(f"Nie można pobrać modelu: {e}")
                raise
        
        return model_path
    
    def get_point(self, results, landmark_name: str, w: int, h: int) -> Optional[np.ndarray]:
        """
        Zwraca współrzędne punktu sylwetki w pikselach
        Sprawdza visibility i zwraca None jeśli punkt jest słabo widoczny
        """
        try:
            if self.api_type == 'solutions' or self.api_type == 'direct':
                # Solutions API
                landmark_idx = getattr(self.mp_pose.PoseLandmark, landmark_name)
                lm = results.pose_landmarks.landmark[landmark_idx]

                # Sprawdź visibility - jeśli za niska, punkt jest niepewny
                if lm.visibility < 0.5:
                    return None

                return np.array([lm.x * w, lm.y * h])

            elif self.api_type == 'tasks':
                # Tasks API
                if not results.pose_landmarks or len(results.pose_landmarks) == 0:
                    return None

                landmark_idx = self.POSE_LANDMARKS[landmark_name]
                lm = results.pose_landmarks[0][landmark_idx]

                # Sprawdź visibility
                if hasattr(lm, 'visibility') and lm.visibility < 0.5:
                    return None

                return np.array([lm.x * w, lm.y * h])
        except Exception as e:
            return None

        return None
    
    def point_line_distance(self, point: np.ndarray, 
                           line_p1: np.ndarray, 
                           line_p2: np.ndarray) -> float:
        """
        Oblicza odległość punktu od linii
        Mierzy jak bardzo głowa odstaje od linii tułowia
        """
        return np.cross(line_p2 - line_p1, point - line_p1) / np.linalg.norm(line_p2 - line_p1)
    
    def _get_side_landmarks(self, results, side: str, w: int, h: int) -> Tuple[Optional[np.ndarray], Optional[np.ndarray], Optional[np.ndarray], float]:
        """
        Pobiera punkty dla jednej strony ciała i oblicza ich widoczność

        Returns:
            (shoulder, hip, ear, visibility_score)
        """
        try:
            shoulder = self.get_point(results, f'{side}_SHOULDER', w, h)
            hip = self.get_point(results, f'{side}_HIP', w, h)
            ear = self.get_point(results, f'{side}_EAR', w, h)

            if shoulder is None or hip is None or ear is None:
                return None, None, None, 0.0

            # Oblicz "widoczność" na podstawie odległości między punktami
            # Większa odległość ramię-biodro oznacza lepszą widoczność tej strony
            torso_len = np.linalg.norm(shoulder - hip)

            return shoulder, hip, ear, torso_len
        except:
            return None, None, None, 0.0

    def analyze_posture(self, frame: np.ndarray) -> Tuple[bool, float, Optional[dict]]:
        """
        Analizuje postawę na podstawie klatki wideo
        Używa obu stron ciała i wybiera lepiej widoczną stronę

        Args:
            frame: Klatka wideo (BGR format z OpenCV)

        Returns:
            Tuple[is_good_posture, norm_dist, landmarks_dict]
        """
        if frame is None:
            return False, 0.0, None

        h, w, _ = frame.shape

        try:
            # Konwersja BGR -> RGB dla MediaPipe
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

            # Detekcja sylwetki - różne dla różnych API
            if self.api_type == 'solutions' or self.api_type == 'direct':
                results = self.pose.process(rgb)

                if not results.pose_landmarks:
                    return False, 0.0, None

            elif self.api_type == 'tasks':
                # Tasks API wymaga timestamp
                import mediapipe as mp
                timestamp_ms = int(cv2.getTickCount() / cv2.getTickFrequency() * 1000)

                mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
                results = self.pose.detect_for_video(mp_image, timestamp_ms)

                if not results.pose_landmarks:
                    return False, 0.0, None

            # Zapisz wyniki do rysowania pełnej sylwetki
            self._last_results = results

            # Pobierz punkty z obu stron ciała
            left_shoulder, left_hip, left_ear, left_visibility = self._get_side_landmarks(results, 'LEFT', w, h)
            right_shoulder, right_hip, right_ear, right_visibility = self._get_side_landmarks(results, 'RIGHT', w, h)

            # Wybierz stronę z lepszą widocznością (większa długość tułowia = lepsza widoczność)
            if left_visibility >= right_visibility and left_visibility > 0:
                shoulder, hip, ear = left_shoulder, left_hip, left_ear
                torso_len = left_visibility
                used_side = 'LEFT'
            elif right_visibility > 0:
                shoulder, hip, ear = right_shoulder, right_hip, right_ear
                torso_len = right_visibility
                used_side = 'RIGHT'
            else:
                return False, 0.0, None

            if shoulder is None or hip is None or ear is None:
                return False, 0.0, None

            # Minimalny próg długości tułowia (żeby uniknąć dzielenia przez małe wartości)
            if torso_len < 20:
                return False, 0.0, None

            # Oblicz odległość głowy od linii tułowia
            raw_dist = self.point_line_distance(ear, hip, shoulder)
            norm_dist = abs(raw_dist) / torso_len

            # Oceń postawę
            is_good_posture = norm_dist <= self.POSTURE_THRESHOLD

            # Przygotuj dane punktów
            landmarks_dict = {
                'shoulder': shoulder,
                'hip': hip,
                'ear': ear,
                'torso_len': torso_len,
                'raw_dist': raw_dist,
                'used_side': used_side
            }

            return is_good_posture, norm_dist, landmarks_dict

        except Exception as e:
            print(f"Błąd podczas analizy postawy: {e}")
            import traceback
            traceback.print_exc()
            return False, 0.0, None
    
    def draw_landmarks(self, frame: np.ndarray,
                       is_good_posture: bool,
                       norm_dist: float,
                       landmarks_dict: Optional[dict]) -> np.ndarray:
        """
        Rysuje punkty kluczowe i informacje na obrazie
        Używa wbudowanej funkcji MediaPipe dla pełnej sylwetki
        """
        if landmarks_dict is None:
            return frame

        # Rysuj pełną sylwetkę MediaPipe (jeśli dostępne)
        if hasattr(self, '_last_results') and self._last_results is not None:
            try:
                if self.api_type in ['solutions', 'direct'] and hasattr(self, 'mp_drawing'):
                    # Użyj wbudowanej funkcji MediaPipe do rysowania
                    self.mp_drawing.draw_landmarks(
                        frame,
                        self._last_results.pose_landmarks,
                        self.mp_pose.POSE_CONNECTIONS,
                        landmark_drawing_spec=self.mp_drawing.DrawingSpec(
                            color=(0, 255, 0) if is_good_posture else (0, 0, 255),
                            thickness=2,
                            circle_radius=3
                        ),
                        connection_drawing_spec=self.mp_drawing.DrawingSpec(
                            color=(200, 200, 200),
                            thickness=2
                        )
                    )
            except Exception as e:
                # Fallback do ręcznego rysowania
                pass

        shoulder = landmarks_dict['shoulder']
        hip = landmarks_dict['hip']
        ear = landmarks_dict['ear']
        used_side = landmarks_dict.get('used_side', 'LEFT')

        # Kolor zależny od postawy
        if is_good_posture:
            color = (0, 255, 0)  # Zielony
            posture_text = "WYPROSTOWANY"
        else:
            color = (0, 0, 255)  # Czerwony
            posture_text = "ZGARBIONY"

        # Podświetl używane punkty grubszą obwódką
        cv2.circle(frame, tuple(shoulder.astype(int)), 12, color, 3)
        cv2.circle(frame, tuple(hip.astype(int)), 12, color, 3)
        cv2.circle(frame, tuple(ear.astype(int)), 12, (0, 255, 255), 3)

        # Linia tułowia - grubsza, w kolorze postawy
        cv2.line(
            frame,
            tuple(hip.astype(int)),
            tuple(shoulder.astype(int)),
            color,
            4
        )

        # Linia od ramienia do ucha (pokazuje pozycję głowy)
        cv2.line(
            frame,
            tuple(shoulder.astype(int)),
            tuple(ear.astype(int)),
            (0, 255, 255),
            2
        )

        # Tło dla tekstu
        cv2.rectangle(frame, (10, 10), (350, 100), (0, 0, 0), -1)
        cv2.rectangle(frame, (10, 10), (350, 100), color, 2)

        # Tekst z oceną postawy
        cv2.putText(
            frame,
            f"Postawa: {posture_text}",
            (20, 40),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.9,
            color,
            2
        )

        # Wskaźnik garbienia
        cv2.putText(
            frame,
            f"Wskaznik: {norm_dist:.3f} (prog: {self.POSTURE_THRESHOLD})",
            (20, 70),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            (255, 255, 255),
            2
        )

        # Używana strona
        cv2.putText(
            frame,
            f"Strona: {used_side}",
            (20, 95),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.5,
            (180, 180, 180),
            1
        )

        return frame
    
    def release(self):
        """Zwolnij zasoby"""
        try:
            if self.api_type in ['solutions', 'direct']:
                self.pose.close()
            # Tasks API automatycznie zwalnia zasoby
        except:
            pass


# Test funkcji
if __name__ == "__main__":
    print("=" * 60)
    print("TEST POSTURE DETECTOR")
    print("=" * 60)
    
    try:
        detector = PostureDetector()
        print("\nDetektor zainicjalizowany poprawnie")
        print(f"Używane API: {detector.api_type}")
        
        # Test z kamerą
        print("\nTestowanie z kamerą...")
        cap = cv2.VideoCapture(0)
        
        if not cap.isOpened():
            print("Nie można otworzyć kamery")
        else:
            print("Kamera otwarta")
            
            for i in range(5):
                ret, frame = cap.read()
                if ret:
                    is_good, norm_dist, landmarks = detector.analyze_posture(frame)
                    
                    if landmarks:
                        print(f"  Frame {i+1}: {'✅ Dobra' if is_good else '❌ Zła'} postawa (wskaźnik: {norm_dist:.3f})")
                    else:
                        print(f"  Frame {i+1}: Nie wykryto osoby")
                else:
                    print(f"  Frame {i+1}: Błąd odczytu")
            
            cap.release()
        
        detector.release()
        print("\nTest zakończony pomyślnie")
        
    except Exception as e:
        print(f"\nTest nie powiódł się: {e}")
        import traceback
        traceback.print_exc()
