#pragma once

#include <QObject>
#include <QString>
#include <opencv2/opencv.hpp>

class PostureAnalyzer : public QObject
{
   Q_OBJECT
      Q_PROPERTY(bool modelLoaded READ modelLoaded NOTIFY modelLoadedChanged)
      Q_PROPERTY(QString modelPath READ modelPath WRITE setModelPath NOTIFY modelPathChanged)

public:
   explicit PostureAnalyzer(QObject* parent = nullptr);
   ~PostureAnalyzer();

   bool initialize();

   bool loadModel(const QString& modelPath);
   bool modelLoaded() const
   {
      return m_modelLoaded;
   }
   QString modelPath() const
   {
      return m_modelPath;
   }
   void setModelPath(const QString& path);

   bool analyzeFrame(const cv::Mat& frame, QString& postureType, float& confidence);

signals:
   void modelLoadedChanged(bool loaded);
   void modelPathChanged(const QString& path);
   void postureDetected(const QString& postureType, float confidence);
   void errorOccurred(const QString& error);

private:
   cv::Mat preprocessFrame(const cv::Mat& frame);

   // Dummy analysis
   bool dummyAnalysis(const cv::Mat& frame, QString& postureType, float& confidence);

   bool m_modelLoaded;
   QString m_modelPath;

   // TODO: Add ONNX Runtime session here
   // std::unique_ptr<Ort::Session> m_session;
   // std::unique_ptr<Ort::Env> m_env;
};