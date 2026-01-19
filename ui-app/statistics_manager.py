"""
Moduł do zarządzania statystykami i historią sesji
Zapisuje dane do bazy SQLite
"""

import sqlite3
import os
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Optional, Tuple
from PySide6.QtCore import QObject, Signal, Slot, Property


class StatisticsManager(QObject):
    """Zarządza statystykami i historią sesji"""
    
    sessionDataChanged = Signal()
    historicalDataChanged = Signal()
    
    def __init__(self):
        super().__init__()
        
        # Ścieżka do bazy danych
        self.db_path = Path.home() / ".posture_monitor" / "statistics.db"
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        
        print(f"Baza danych: {self.db_path}")
        
        # Inicjalizuj bazę
        self._init_database()
        
        # Aktualna sesja
        self.current_session_id = None
        self.session_start_time = None
        
    def _init_database(self):
        """Stwórz tabele w bazie danych"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Tabela sesji
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                start_time TIMESTAMP NOT NULL,
                end_time TIMESTAMP,
                total_checks INTEGER DEFAULT 0,
                good_posture_count INTEGER DEFAULT 0,
                bad_posture_count INTEGER DEFAULT 0,
                average_coefficient REAL,
                duration_minutes INTEGER,
                notes TEXT
            )
        ''')
        
        # Tabela pojedynczych sprawdzeń
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS checks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id INTEGER NOT NULL,
                timestamp TIMESTAMP NOT NULL,
                is_good_posture BOOLEAN NOT NULL,
                coefficient REAL NOT NULL,
                detection_successful BOOLEAN NOT NULL,
                FOREIGN KEY (session_id) REFERENCES sessions (id)
            )
        ''')
        
        # Indeksy dla szybszych zapytań
        cursor.execute('''
            CREATE INDEX IF NOT EXISTS idx_session_id 
            ON checks (session_id)
        ''')
        
        cursor.execute('''
            CREATE INDEX IF NOT EXISTS idx_timestamp 
            ON checks (timestamp)
        ''')
        
        conn.commit()
        conn.close()
        
        print("Baza danych zainicjalizowana")
    
    @Slot()
    def start_session(self):
        """Rozpocznij nową sesję"""
        if self.current_session_id is not None:
            print("Sesja już trwa, zamykam poprzednią...")
            self.end_session()
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        self.session_start_time = datetime.now()
        
        cursor.execute('''
            INSERT INTO sessions (start_time, total_checks, good_posture_count, bad_posture_count)
            VALUES (?, 0, 0, 0)
        ''', (self.session_start_time,))
        
        self.current_session_id = cursor.lastrowid
        conn.commit()
        conn.close()
        
        print(f"Sesja rozpoczęta: ID={self.current_session_id}")
        self.sessionDataChanged.emit()
        
        return self.current_session_id
    
    @Slot()
    def end_session(self):
        """Zakończ aktualną sesję"""
        if self.current_session_id is None:
            print("Brak aktywnej sesji do zakończenia")
            return
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        end_time = datetime.now()
        duration = (end_time - self.session_start_time).total_seconds() / 60  # minuty
        
        # Oblicz średni współczynnik
        cursor.execute('''
            SELECT AVG(coefficient) FROM checks 
            WHERE session_id = ? AND detection_successful = 1
        ''', (self.current_session_id,))
        
        avg_coeff = cursor.fetchone()[0] or 0.0
        
        # Zaktualizuj sesję
        cursor.execute('''
            UPDATE sessions 
            SET end_time = ?, 
                duration_minutes = ?,
                average_coefficient = ?
            WHERE id = ?
        ''', (end_time, int(duration), avg_coeff, self.current_session_id))
        
        conn.commit()
        conn.close()
        
        print(f"Sesja zakończona: ID={self.current_session_id}, czas={int(duration)}min")
        
        self.current_session_id = None
        self.session_start_time = None
        
        self.historicalDataChanged.emit()
    
    @Slot(bool, float, bool)
    def add_check(self, is_good_posture: bool, coefficient: float, detection_successful: bool):
        """Dodaj sprawdzenie do bazy"""
        if self.current_session_id is None:
            print("Brak aktywnej sesji, tworzę nową...")
            self.start_session()
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        timestamp = datetime.now()
        
        # Dodaj sprawdzenie
        cursor.execute('''
            INSERT INTO checks (session_id, timestamp, is_good_posture, coefficient, detection_successful)
            VALUES (?, ?, ?, ?, ?)
        ''', (self.current_session_id, timestamp, is_good_posture, coefficient, detection_successful))
        
        # Zaktualizuj liczniki sesji
        if detection_successful:
            if is_good_posture:
                cursor.execute('''
                    UPDATE sessions 
                    SET total_checks = total_checks + 1,
                        good_posture_count = good_posture_count + 1
                    WHERE id = ?
                ''', (self.current_session_id,))
            else:
                cursor.execute('''
                    UPDATE sessions 
                    SET total_checks = total_checks + 1,
                        bad_posture_count = bad_posture_count + 1
                    WHERE id = ?
                ''', (self.current_session_id,))
        
        conn.commit()
        conn.close()
        
        self.sessionDataChanged.emit()
    
    @Slot(result='QVariantList')
    def get_current_session_checks(self) -> List[Dict]:
        """Pobierz wszystkie sprawdzenia z aktualnej sesji"""
        if self.current_session_id is None:
            return []
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT timestamp, is_good_posture, coefficient, detection_successful
            FROM checks
            WHERE session_id = ?
            ORDER BY timestamp ASC
        ''', (self.current_session_id,))
        
        checks = []
        for row in cursor.fetchall():
            timestamp_str = datetime.fromisoformat(row[0]).strftime("%H:%M:%S")
            checks.append({
                'time': timestamp_str,
                'is_good': bool(row[1]),
                'coefficient': float(row[2]),
                'detected': bool(row[3])
            })
        
        conn.close()
        return checks
    
    @Slot(result='QVariantList')
    def get_all_sessions(self) -> List[Dict]:
        """Pobierz wszystkie sesje z historii"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT id, start_time, end_time, total_checks, 
                   good_posture_count, bad_posture_count, 
                   average_coefficient, duration_minutes
            FROM sessions
            WHERE end_time IS NOT NULL
            ORDER BY start_time DESC
            LIMIT 50
        ''')
        
        sessions = []
        for row in cursor.fetchall():
            start_dt = datetime.fromisoformat(row[1])
            end_dt = datetime.fromisoformat(row[2]) if row[2] else None
            
            total = row[3]
            good = row[4]
            percentage = (good / total * 100) if total > 0 else 0
            
            sessions.append({
                'id': row[0],
                'date': start_dt.strftime("%Y-%m-%d"),
                'time': start_dt.strftime("%H:%M"),
                'duration': row[7] or 0,
                'total_checks': total,
                'good_count': good,
                'bad_count': row[5],
                'percentage': round(percentage, 1),
                'avg_coefficient': round(row[6] or 0, 3)
            })
        
        conn.close()
        return sessions
    
    @Slot(int, result='QVariantList')
    def get_session_checks(self, session_id: int) -> List[Dict]:
        """Pobierz sprawdzenia dla konkretnej sesji"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT timestamp, is_good_posture, coefficient, detection_successful
            FROM checks
            WHERE session_id = ?
            ORDER BY timestamp ASC
        ''', (session_id,))
        
        checks = []
        for row in cursor.fetchall():
            timestamp_str = datetime.fromisoformat(row[0]).strftime("%H:%M:%S")
            checks.append({
                'time': timestamp_str,
                'is_good': bool(row[1]),
                'coefficient': float(row[2]),
                'detected': bool(row[3])
            })
        
        conn.close()
        return checks
    
    @Slot(result='QVariantMap')
    def get_current_session_stats(self) -> Dict:
        """Pobierz statystyki aktualnej sesji"""
        if self.current_session_id is None:
            return {
                'total': 0,
                'good': 0,
                'bad': 0,
                'percentage': 0,
                'avg_coefficient': 0,
                'duration': 0
            }
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT total_checks, good_posture_count, bad_posture_count, start_time
            FROM sessions
            WHERE id = ?
        ''', (self.current_session_id,))
        
        row = cursor.fetchone()
        
        if row:
            total = row[0]
            good = row[1]
            bad = row[2]
            start_time = datetime.fromisoformat(row[3])
            duration = (datetime.now() - start_time).total_seconds() / 60
            
            # Średni współczynnik
            cursor.execute('''
                SELECT AVG(coefficient) FROM checks
                WHERE session_id = ? AND detection_successful = 1
            ''', (self.current_session_id,))
            
            avg_coeff = cursor.fetchone()[0] or 0.0
            
            percentage = (good / total * 100) if total > 0 else 0
            
            stats = {
                'total': total,
                'good': good,
                'bad': bad,
                'percentage': round(percentage, 1),
                'avg_coefficient': round(avg_coeff, 3),
                'duration': int(duration)
            }
        else:
            stats = {
                'total': 0,
                'good': 0,
                'bad': 0,
                'percentage': 0,
                'avg_coefficient': 0,
                'duration': 0
            }
        
        conn.close()
        return stats
    
    @Slot(result='QVariantMap')
    def get_overall_stats(self) -> Dict:
        """Pobierz ogólne statystyki ze wszystkich sesji"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Suma wszystkich sesji
        cursor.execute('''
            SELECT 
                COUNT(*) as session_count,
                SUM(total_checks) as total_checks,
                SUM(good_posture_count) as total_good,
                SUM(bad_posture_count) as total_bad,
                AVG(average_coefficient) as overall_avg_coeff,
                SUM(duration_minutes) as total_minutes
            FROM sessions
            WHERE end_time IS NOT NULL
        ''')
        
        row = cursor.fetchone()
        
        session_count = row[0] or 0
        total_checks = row[1] or 0
        total_good = row[2] or 0
        total_bad = row[3] or 0
        overall_avg = row[4] or 0.0
        total_minutes = row[5] or 0
        
        overall_percentage = (total_good / total_checks * 100) if total_checks > 0 else 0
        
        # Najlepsza sesja
        cursor.execute('''
            SELECT 
                start_time,
                (good_posture_count * 100.0 / total_checks) as percentage
            FROM sessions
            WHERE end_time IS NOT NULL AND total_checks > 0
            ORDER BY percentage DESC
            LIMIT 1
        ''')
        
        best_row = cursor.fetchone()
        best_date = ""
        best_percentage = 0
        
        if best_row:
            best_date = datetime.fromisoformat(best_row[0]).strftime("%Y-%m-%d %H:%M")
            best_percentage = round(best_row[1], 1)
        
        conn.close()
        
        return {
            'session_count': session_count,
            'total_checks': total_checks,
            'total_good': total_good,
            'total_bad': total_bad,
            'overall_percentage': round(overall_percentage, 1),
            'overall_avg_coefficient': round(overall_avg, 3),
            'total_hours': round(total_minutes / 60, 1),
            'best_session_date': best_date,
            'best_session_percentage': best_percentage
        }
    
    @Slot(int)
    def delete_session(self, session_id: int):
        """Usuń sesję z historii"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Usuń sprawdzenia
        cursor.execute('DELETE FROM checks WHERE session_id = ?', (session_id,))
        
        # Usuń sesję
        cursor.execute('DELETE FROM sessions WHERE id = ?', (session_id,))
        
        conn.commit()
        conn.close()
        
        print(f"Usunięto sesję ID={session_id}")
        self.historicalDataChanged.emit()
    
    @Slot()
    def clear_all_history(self):
        """Usuń całą historię (ostrożnie!)"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('DELETE FROM checks')
        cursor.execute('DELETE FROM sessions')
        
        conn.commit()
        conn.close()
        
        print("Historia wyczyszczona")
        self.historicalDataChanged.emit()
    
    def cleanup(self):
        """Sprzątanie przy zamykaniu"""
        if self.current_session_id is not None:
            print("Zamykanie sesji przed wyjściem...")
            self.end_session()


# Test
if __name__ == "__main__":
    import sys
    from PySide6.QtCore import QCoreApplication
    
    app = QCoreApplication(sys.argv)
    
    stats = StatisticsManager()
    
    # Test
    print("\n=== TEST ===")
    stats.start_session()
    stats.add_check(True, 0.089, True)
    stats.add_check(False, 0.156, True)
    stats.add_check(True, 0.092, True)
    
    print("\nAktualna sesja:")
    print(stats.get_current_session_stats())
    
    print("\nSprawdzenia:")
    for check in stats.get_current_session_checks():
        print(check)
    
    stats.end_session()
    
    print("\nWszystkie sesje:")
    for session in stats.get_all_sessions():
        print(session)
    
    print("\nOgólne statystyki:")
    print(stats.get_overall_stats())
    
    print("\nTest zakończony")
