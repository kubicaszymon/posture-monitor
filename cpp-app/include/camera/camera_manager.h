#pragma once

#include <QObject>
#include <QImage>
#include <opencv2/opencv.hpp>
#include <memory>
#include <mutex>

class CameraManager : public QObject
{
   Q_OBJECT
      Q_PROPERTY(bool isActive READ isActive NOTIFY isActiveChanged)
      Q_PROPERTY(QImage currentFrame READ currentFrameAsQImage NOTIFY frameUpdated)

public:
   explicit CameraManager(QObject* parent = nullptr);
   ~CameraManager();

   bool initialize(int cameraIndex = 0);

   bool start();
   bool stop();
   bool isActive() const
   {
      return m_isActive;
   }

   cv::Mat getCurrentFrame();
   QImage currentFrameAsQImage();

   void setCameraIndex(int index);
   void setResolution(int width, int height);
   void setFPS(int fps);

signals:
   void isActiveChanged(bool active);
   void frameUpdated(const QImage& frame);
   void errorOccured(const QString& error);

private:
   bool openCamera();
   bool closeCamera();
   cv::Mat captureFrame();
   QImage matToQImage(const cv::Mat& mat);

   std::unique_ptr<cv::VideoCapture> m_camera;
   cv::Mat m_currentFrame;
   std::mutex m_frameMutex;

   bool m_isActive;
   bool m_isInitialized;
   int m_cameraIndex;
   int m_width;
   int m_height;
   int m_fps;
};
