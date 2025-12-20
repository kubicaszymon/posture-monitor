import cv2 
import mediapipe as mp # biblioteka mediapipe z gotowym modelem do detekcji sylwetki
import numpy as np

IMAGE_PATH = "mediapipe/format.png"   # To ścieżka do zdjęcia do analizy
POSTURE_THRESHOLD = 0.12              # próg garbienia wykorzystywany do klasyfikacji postawy


img = cv2.imread(IMAGE_PATH) # tablica numpy z wartościami dla każedgo piksela

if img is None:
    raise FileNotFoundError(f"Nie udało się wczytać obrazu: {IMAGE_PATH}")

h, w, _ = img.shape
rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB) # konwersja BGR (OpenCV) do RGB (MediaPipe)

# deklaracja pracy modelu
mp_pose = mp.solutions.pose # model do detekcji sylwetki
pose = mp_pose.Pose(
    static_image_mode=True, # analiza pojedynczego obrazu
    model_complexity=1, # złożoność modelu (0, 1, 2) czy ma być szybki czy dokładny - w tym wypadku środek
    min_detection_confidence=0.6 # minimalne zaufanie detekcji - jeżeli model jest mniej pewny niż ten próg, to nie zwraca wyniku
)

results = pose.process(rgb) # zwraca wyniki detekcji sylwetki punkty x, y, z i na ile widoczny jest element

if not results.pose_landmarks:
    raise RuntimeError("Nie wykryto sylwetki")

def get_point(results, landmark, w, h):
    """
    Funkcja zwraca współrzędne punktu sylwetki w pikselach
    """
    lm = results.pose_landmarks.landmark[landmark]
    return np.array([lm.x * w, lm.y * h])

# uproszczona logika do liczenia zgarbienia - odległość w pikselach
# mierzone jest jak bardzo głowa odstaje od lini tułowia
def point_line_distance(point, line_p1, line_p2):
    return np.cross(line_p2 - line_p1, point - line_p1) / np.linalg.norm(line_p2 - line_p1)

shoulder = get_point(results, mp_pose.PoseLandmark.LEFT_SHOULDER, w, h)
hip      = get_point(results, mp_pose.PoseLandmark.LEFT_HIP, w, h)
ear      = get_point(results, mp_pose.PoseLandmark.LEFT_EAR, w, h)

torso_len = np.linalg.norm(shoulder - hip)
raw_dist = point_line_distance(ear, hip, shoulder)
norm_dist = abs(raw_dist) / torso_len

if norm_dist > POSTURE_THRESHOLD:
    posture = "Z GARBIONY"
    color = (0, 0, 255)
else:
    posture = "WYPROSTOWANY"
    color = (0, 255, 0)

# Punkty
cv2.circle(img, tuple(shoulder.astype(int)), 6, (255, 0, 0), -1)
cv2.circle(img, tuple(hip.astype(int)), 6, (255, 0, 0), -1)
cv2.circle(img, tuple(ear.astype(int)), 6, (0, 255, 255), -1)

# Linia tułowia
cv2.line(
    img,
    tuple(hip.astype(int)),
    tuple(shoulder.astype(int)),
    (255, 255, 255),
    2
)

# Tekst
cv2.putText(
    img,
    f"Postawa: {posture}",
    (30, 40),
    cv2.FONT_HERSHEY_SIMPLEX,
    1,
    color,
    2
)

cv2.putText(
    img,
    f"Wskaznik: {norm_dist:.3f}",
    (30, 80),
    cv2.FONT_HERSHEY_SIMPLEX,
    0.8,
    (255, 255, 255),
    2
)

cv2.imshow("Posture Monitor", img)
cv2.waitKey(0)
cv2.destroyAllWindows()
