#include "ml/posture_analyzer.h"

PostureAnalyzer::PostureAnalyzer(QObject* parent)
{
}

PostureAnalyzer::~PostureAnalyzer()
{
}

bool PostureAnalyzer::initialize()
{
   return false;
}

bool PostureAnalyzer::loadModel(const QString& modelPath)
{
   return false;
}

void PostureAnalyzer::setModelPath(const QString& path)
{
}

bool PostureAnalyzer::analyzeFrame(const cv::Mat& frame, QString& postureType, float& confidence)
{
   return false;
}

cv::Mat PostureAnalyzer::preprocessFrame(const cv::Mat& frame)
{
   return cv::Mat();
}

bool PostureAnalyzer::dummyAnalysis(const cv::Mat& frame, QString& postureType, float& confidence)
{
   return false;
}
