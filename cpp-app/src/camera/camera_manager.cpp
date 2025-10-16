#include "camera/camera_manager.h"

CameraManager::CameraManager(QObject* parent)
   : QObject(parent)
   , m_camera(nullptr)
   , m_isActive(false)
   , m_isInitialized(false)
   , m_cameraIndex(0)
   , m_width(640)
   , m_height(480)
   , m_fps(30)
{
}

CameraManager::~CameraManager()
{
}

bool CameraManager::initialize(int cameraIndex)
{
   return false;
}

bool CameraManager::start()
{
   return false;
}

bool CameraManager::stop()
{
   return false;
}

cv::Mat CameraManager::getCurrentFrame()
{
   return cv::Mat();
}

QImage CameraManager::currentFrameAsQImage()
{
   return QImage();
}

void CameraManager::setCameraIndex(int index)
{
}

void CameraManager::setResolution(int width, int height)
{
}

void CameraManager::setFPS(int fps)
{
}

bool CameraManager::openCamera()
{
   return false;
}

bool CameraManager::closeCamera()
{
   return false;
}

cv::Mat CameraManager::captureFrame()
{
   return cv::Mat();
}

QImage CameraManager::matToQImage(const cv::Mat& mat)
{
   return QImage();
}
