#include "camera/frame_processor.h"

FrameProcessor::FrameProcessor(QObject* parent)
{
}

FrameProcessor::~FrameProcessor()
{
}

cv::Mat FrameProcessor::preprocessForModel(const cv::Mat& input, int targetWidth, int targetHeight)
{
   return cv::Mat();
}

cv::Mat FrameProcessor::resize(const cv::Mat& input, int width, int height)
{
   return cv::Mat();
}

cv::Mat FrameProcessor::convertToRGB(const cv::Mat& input)
{
   return cv::Mat();
}

cv::Mat FrameProcessor::normalize(const cv::Mat& input)
{
   return cv::Mat();
}

cv::Mat FrameProcessor::adjustBrightness(const cv::Mat& input, float alpha, int beta)
{
   return cv::Mat();
}

cv::Mat FrameProcessor::adjustContrast(const cv::Mat& input, float alpha)
{
   return cv::Mat();
}

bool FrameProcessor::isFrameValid(const cv::Mat& frame)
{
   return false;
}

float FrameProcessor::calculateBrightness(const cv::Mat& frame)
{
   return 0.0f;
}

float FrameProcessor::calculateSharpness(const cv::Mat& frame)
{
   return 0.0f;
}

cv::Mat FrameProcessor::applyGaussianBlur(const cv::Mat& input, int kernelSize)
{
   return cv::Mat();
}
