#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include "application.h"
#include "camera/camera_manager.h"
#include "ml/posture_analyzer.h"
#include "notification/notification_manager.h"
#include "settings/settings_manager.h"

int main(int argc, char* argv[])
{
   QGuiApplication app(argc, argv);

   // Application settings
   app.setOrganizationName("PostureMonitor");
   app.setOrganizationDomain("posturemonitor.app");
   app.setApplicationName("Posture Monitor");
   app.setApplicationVersion("0.1.0");

   // Register types for QML
   qmlRegisterUncreatableType<Application>("PostureMonitor", 1, 0, "Application", "Cannot create Application from QML");
   qmlRegisterUncreatableType<CameraManager>("PostureMonitor", 1, 0, "CameraManager", "Cannot create CameraManager from QML");
   qmlRegisterUncreatableType<PostureAnalyzer>("PostureMonitor", 1, 0, "PostureAnalyzer", "Cannot create PostureAnalyzer from QML");
   qmlRegisterUncreatableType<NotificationManager>("PostureMonitor", 1, 0, "NotificationManager", "Cannot create NotificationManager from QML");
   qmlRegisterUncreatableType<SettingsManager>("PostureMonitor", 1, 0, "SettingsManager", "Cannot create SettingsManager from QML");

   // Main application instance
   Application* application = new Application(&app);

   // QML Engine
   QQmlApplicationEngine engine;

   // Expose C++ objects to QML
   engine.rootContext()->setContextProperty("application", application);
   engine.rootContext()->setContextProperty("cameraManager", application->cameraManager());
   engine.rootContext()->setContextProperty("postureAnalyzer", application->postureAnalyzer());
   engine.rootContext()->setContextProperty("notificationManager", application->notificationManager());
   engine.rootContext()->setContextProperty("settingsManager", application->settingsManager());

   // Load main QML file
   const QUrl url(QStringLiteral("qrc:/main.qml"));

   QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
      &app, [] ()
      {
         QCoreApplication::exit(-1);
      }, Qt::QueuedConnection);

   engine.load(url);

   if (engine.rootObjects().isEmpty())
      return -1;

   // Initialize application
   application->initialize();

   return app.exec();
}