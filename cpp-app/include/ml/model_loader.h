#pragma once

#include <QObject>
#include <QString>

// Placeholder for future ONNX model loading functionality
class ModelLoader : public QObject
{
   Q_OBJECT

public:
   explicit ModelLoader(QObject* parent = nullptr);
   ~ModelLoader();

   // TODO: Add ONNX model loading methods
   // bool loadModel(const QString& modelPath);
   // void* getSession();
};