#include "notification/notification_manager.h"

NotificationManager::NotificationManager(QObject* parent)
{
}

NotificationManager::~NotificationManager()
{
}

void NotificationManager::setNotificationsEnabled(bool enabled)
{
}

void NotificationManager::setNotificationCooldown(int seconds)
{
}

void NotificationManager::showPostureWarning(const QString& postureType, float confidence)
{
}

void NotificationManager::showInfo(const QString& title, const QString& message)
{
}

void NotificationManager::showError(const QString& title, const QString& message)
{
}

void NotificationManager::clearHistory()
{
}

bool NotificationManager::canShowNotification()
{
   return false;
}

void NotificationManager::showSystemNotification(const QString& title, const QString& message)
{
}

QString NotificationManager::getPostureMessage(const QString& postureType)
{
   return QString();
}
