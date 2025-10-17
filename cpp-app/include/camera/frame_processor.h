#pragma once

#include <QObject>
#include <opencv2/opencv.hpp>

class FrameProcessor : public QObject
{
   Q_OBJECT

public:
   explicit FrameProcessor(QObject* parent = nullptr);
   ~FrameProcessor();

   // Preprocessing methods
   cv::Mat preprocessForModel(const cv::Mat& input, int targetWidth = 224, int targetHeight = 224);
   cv::Mat resize(const cv::Mat& input, int width, int height);
   cv::Mat convertToRGB(const cv::Mat& input);
   cv::Mat normalize(const cv::Mat& input);

   // Image enhancement
   cv::Mat adjustBrightness(const cv::Mat& input, float alpha = 1.0f, int beta = 0);
   cv::Mat adjustContrast(const cv::Mat& input, float alpha = 1.0f);

   // Quality checks
   bool isFrameValid(const cv::Mat& frame);
   float calculateBrightness(const cv::Mat& frame);
   float calculateSharpness(const cv::Mat& frame);

signals:
   void processingError(const QString& error);

private:
   // Helper methods
   cv::Mat applyGaussianBlur(const cv::Mat& input, int kernelSize = 5);
};