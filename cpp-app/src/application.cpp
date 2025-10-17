#include "application.h"
#include "camera/camera_manager.h"
#include "camera/frame_processor.h"
#include "ml/posture_analyzer.h"
#include "notification/notification_manager.h"
#include "settings/settings_manager.h"
#include <QDebug>

Application::Application(QObject* parent)
   : QObject(parent)
   , m_isRunning(false)
   , m_status("Initialization...")
   , m_processingTimer(new QTimer(this))
{

   // Create manager instances
   m_settingsManager = std::make_unique<SettingsManager>(this);
   m_cameraManager = std::make_unique<CameraManager>(this);
   m_postureAnalyzer = std::make_unique<PostureAnalyzer>(this);
   m_notificationManager = std::make_unique<NotificationManager>(this);

   // Timer for processing cycle
   m_processingTimer->setInterval(1000);
   connect(m_processingTimer, &QTimer::timeout, this, &Application::onProcessingCycle);
}

Application::~Application()
{
   shutdown();
}

void Application::initialize()
{
   qDebug() << "Application initialization...";

   connectSignals();

   m_settingsManager->loadSettings();

   if (!m_cameraManager->initialize())
   {
      setStatus("Error: Unable to initialize camera");
      emit errorOccurred("Unable to initialize camera");
      return;
   }
   if (!m_postureAnalyzer->initialize())
   {
      setStatus("Warning: Model not loaded");
      qWarning() << "Model not loaded - demo mode";
   }

   setStatus("Ready for action");
   qDebug() << "Application initialized";
}

void Application::startMonitoring()
{
   if (m_isRunning)
   {
      qDebug() << "Monitoring is already operational";
      return;
   }

   qDebug() << "I am starting monitoring...";

   if (!m_cameraManager->start())
   {
      setStatus("Error: Unable to start camera");
      emit errorOccurred("The camera cannot be started");
      return;
   }

   m_processingTimer->start();

   setIsRunning(true);
   setStatus("Active monitoring");

   qDebug() << "Monitoring started";
}

void Application::stopMonitoring()
{
   if (!m_isRunning)
   {
      qDebug() << "Monitoring already stopped";
      return;
   }

   qDebug() << "I am stopping the monitoring...";

   m_processingTimer->stop();

   m_cameraManager->stop();

   setIsRunning(false);
   setStatus("Monitoring stopped");

   qDebug() << "Monitoring stopped";
}

void Application::toggleMonitoring()
{
   if (m_isRunning)
   {
      stopMonitoring();
   }
   else
   {
      startMonitoring();
   }
}

void Application::shutdown()
{
   qDebug() << "Shutting down the application...";

   stopMonitoring();

   // Cleanup
   m_cameraManager.reset();
   m_postureAnalyzer.reset();
   m_notificationManager.reset();
   m_settingsManager.reset();

   qDebug() << "Application disabled";
}

void Application::onProcessingCycle()
{
   // Main processing cycle - called periodically by the timer

   // Get current frame from camera
   cv::Mat frame = m_cameraManager->getCurrentFrame();

   if (frame.empty())
   {
      qDebug() << "No frame from the camera";
      return;
   }

   QString postureType;
   float confidence;

   if (m_postureAnalyzer->analyzeFrame(frame, postureType, confidence))
   {
      if (postureType != "correct" && confidence > 0.7f)
      {
         m_notificationManager->showPostureWarning(postureType, confidence);
      }
   }
}

void Application::onCameraError(const QString& error)
{
   qWarning() << "Camera error:" << error;
   setStatus("Camera error: " + error);
   emit errorOccurred(error);
   stopMonitoring();
}

void Application::onPostureDetected(const QString& postureType, float confidence)
{
   qDebug() << "A posture has been detected:" << postureType << " : " << confidence;

   if (postureType != "correct")
   {
      setStatus(QString("Uwaga: %1 (%.0f%%)").arg(postureType).arg(confidence * 100));
   }
   else
   {
      setStatus("Correct posture");
   }
}

void Application::connectSignals()
{
   connect(m_cameraManager.get(), &CameraManager::errorOccured,
      this, &Application::onCameraError);

   connect(m_postureAnalyzer.get(), &PostureAnalyzer::postureDetected,
      this, &Application::onPostureDetected);
}

void Application::setStatus(const QString& status)
{
   if (m_status != status)
   {
      m_status = status;
      emit statusChanged(m_status);
   }
}

void Application::setIsRunning(bool running)
{
   if (m_isRunning != running)
   {
      m_isRunning = running;
      emit isRunningChanged(m_isRunning);
   }
}