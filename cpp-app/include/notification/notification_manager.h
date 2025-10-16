#pragma once

#include <QObject>
#include <QString>
#include <QDateTime>
#include <QTimer>

class NotificationManager : public QObject
{
   Q_OBJECT
      Q_PROPERTY(bool notificationsEnabled READ notificationsEnabled WRITE setNotificationsEnabled NOTIFY notificationsEnabledChanged)
      Q_PROPERTY(int notificationCooldown READ notificationCooldown WRITE setNotificationCooldown NOTIFY notificationCooldownChanged)

public:
   explicit NotificationManager(QObject* parent = nullptr);
   ~NotificationManager();

   bool notificationsEnabled() const
   {
      return m_notificationsEnabled;
   }
   void setNotificationsEnabled(bool enabled);

   int notificationCooldown() const
   {
      return m_notificationCooldown;
   }
   void setNotificationCooldown(int seconds);

public slots:
   void showPostureWarning(const QString& postureType, float confidence);
   void showInfo(const QString& title, const QString& message);
   void showError(const QString& title, const QString& message);

   void clearHistory();

signals:
   void notificationsEnabledChanged(bool enabled);
   void notificationCooldownChanged(int seconds);
   void notificationShown(const QString& type, const QString& message);

private:
   bool canShowNotification();
   void showSystemNotification(const QString& title, const QString& message);
   QString getPostureMessage(const QString& postureType);

   bool m_notificationsEnabled;
   int m_notificationCooldown; // in seconds
   QDateTime m_lastNotificationTime;
};