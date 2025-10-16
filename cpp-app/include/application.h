#pragma once

#include <QObject>
#include <QTimer>
#include <memory>

// Forward declarations
class CameraManager;
class PostureAnalyzer;
class NotificationManager;
class SettingsManager;

class Application : public QObject
{
   Q_OBJECT
      Q_PROPERTY(bool isRunning READ isRunning NOTIFY isRunningChanged)
      Q_PROPERTY(QString status READ status NOTIFY statusChanged)

public:
   explicit Application(QObject* parent = nullptr);
   ~Application();

   // Getters for managers
   CameraManager* cameraManager() const
   {
      return m_cameraManager.get();
   }
   PostureAnalyzer* postureAnalyzer() const
   {
      return m_postureAnalyzer.get();
   }
   NotificationManager* notificationManager() const
   {
      return m_notificationManager.get();
   }
   SettingsManager* settingsManager() const
   {
      return m_settingsManager.get();
   }

   // Properties
   bool isRunning() const
   {
      return m_isRunning;
   }
   QString status() const
   {
      return m_status;
   }

public slots:
   void initialize();

   void startMonitoring();
   void stopMonitoring();
   void toggleMonitoring();

   // Shutdown
   void shutdown();

signals:
   void isRunningChanged(bool running);
   void statusChanged(const QString& status);
   void errorOccurred(const QString& error);

private slots:
   void onProcessingCycle();
   void onCameraError(const QString& error);
   void onPostureDetected(const QString& postureType, float confidence);

private:
   void setStatus(const QString& status);
   void setIsRunning(bool running);
   void connectSignals();

   // Manager instances
   std::unique_ptr<CameraManager> m_cameraManager;
   std::unique_ptr<PostureAnalyzer> m_postureAnalyzer;
   std::unique_ptr<NotificationManager> m_notificationManager;
   std::unique_ptr<SettingsManager> m_settingsManager;

   // State
   bool m_isRunning;
   QString m_status;

   // Processing timer
   QTimer* m_processingTimer;
};