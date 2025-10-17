cmake_minimum_required(VERSION 3.16)

project(PostureMonitor VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Qt
if(WIN32)
	list(APPEND CMAKE_PREFIX_PATH
		"C:/Qt/6.9.1/msvc2022_64"  # DO ZMIANYYY BO JEST TRAGICZNE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		"$ENV{QTDIR}"
	)
endif()
find_package(Qt6 REQUIRED COMPONENTS
	Core
	Quick
	Widgets
	Multimedia
)

# OpenCV
find_package(OpenCV REQUIRED)

# ONNX Runtime
#find_package(onnxruntime REQUIRED)

# Include directories
include_directories(
	${CMAKE_SOURCE_DIR}/include
	${Open_CV_INCLUDE_DIRS}
)

# Source files
set(SOURCES
    src/main.cpp
    src/application.cpp
    src/camera/camera_manager.cpp
    src/camera/frame_processor.cpp
    src/ml/model_loader.cpp
    src/ml/posture_analyzer.cpp
    src/notification/notification_manager.cpp
    src/settings/settings_manager.cpp
)

# Headers
set(HEADERS
    include/application.h
    include/camera/camera_manager.h
    include/camera/frame_processor.h
    include/ml/model_loader.h
    include/ml/posture_analyzer.h
    include/notification/notification_manager.h
    include/settings/settings_manager.h
)

# QML
set(QML_RESOURCES
    qml/resources.qrc
)

add_executable(${PROJECT_NAME}
    ${SOURCES}
    ${HEADERS}
    ${QML_RESOURCES}
)

# Link libraries
target_link_libraries(${PROJECT_NAME}
    Qt6::Core
    Qt6::Quick
    Qt6::Widgets
    Qt6::Multimedia
    ${OpenCV_LIBS}
    #onnxruntime::onnxruntime
)

# Platform specific
if(WIN32)
    set_target_properties(${PROJECT_NAME} PROPERTIES
        WIN32_EXECUTABLE TRUE
    )
endif()

# Install
install(TARGETS ${PROJECT_NAME}
    BUNDLE DESTINATION .
    RUNTIME DESTINATION bin
)

# Copy models directory to build
#file(COPY ${CMAKE_SOURCE_DIR}/models DESTINATION ${CMAKE_BINARY_DIR})