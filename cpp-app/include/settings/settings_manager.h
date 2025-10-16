#pragma once

#include <QObject>
#include <QSettings>
#include <QString>
#include <memory>

class SettingsManager : public QObject
{
   Q_OBJECT

public:
   explicit SettingsManager(QObject* parent = nullptr);
   ~SettingsManager();

   // Load/Save
   void loadSettings();
   void saveSettings();
   void resetToDefaults();

signals:
   void settingsChanged();

private:
   std::unique_ptr<QSettings> m_settings;
};