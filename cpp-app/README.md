# Posture Monitor

https://www.youtube.com/watch?v=CnXUTG9XYGI

A real-time desktop application for monitoring and correcting sitting posture using computer vision and machine learning.

## Table of Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Features](#features)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Building from Source](#building-from-source)
  - [Prerequisites](#prerequisites)
  - [Linux/macOS Build](#linuxmacos-build)
  - [Windows Build](#windows-build)
- [Usage](#usage)
- [Development Roadmap](#development-roadmap)
- [Privacy](#privacy)
- [Contributing](#contributing)
- [License](#license)

## Overview

Posture Monitor is a cross-platform desktop application that runs in the background and analyzes user posture in real-time using webcam input. The application detects poor sitting habits such as slouching, leaning, and forward head posture, providing timely notifications to help maintain healthy ergonomics during computer use.

## Motivation

Prolonged computer use with poor posture contributes to numerous health issues including:

- Chronic back and neck pain
- Muscle tension and fatigue
- Reduced productivity and focus
- Long-term musculoskeletal disorders

This project aims to provide a non-intrusive, privacy-focused solution that helps users maintain proper posture through real-time feedback and gentle reminders.

## Features

### Current Implementation

- Real-time webcam capture and processing
- Modular architecture supporting ML model integration
- Cross-platform Qt/QML user interface
- Configurable notification system with cooldown periods
- Persistent settings management
- Frame preprocessing and quality validation
- Low system resource footprint

### Planned Features

- ONNX model integration for posture classification
- Native system notifications (Windows/macOS/Linux)
- Usage statistics and posture analytics
- System tray integration with quick actions
- "Do Not Disturb" mode
- Multi-monitor support
- Automatic posture correction suggestions

## Architecture

The application follows a modular architecture with clear separation of concerns:

```
┌─────────────────────────────────────────────┐
│           Application Core                   │
│  (Lifecycle Management & Coordination)       │
└─────────────────────────────────────────────┘
         │         │         │         │
    ┌────┴────┐ ┌─┴──┐ ┌────┴────┐ ┌──┴───┐
    │ Camera  │ │ ML │ │  Notif. │ │ UI   │
    │ Manager │ │    │ │ Manager │ │(QML) │
    └────┬────┘ └─┬──┘ └────┬────┘ └──────┘
         │        │         │
    ┌────┴────────┴─────────┴────┐
    │     Settings Manager         │
    └──────────────────────────────┘
```

### Key Components

- **Application**: Main controller managing lifecycle and component coordination
- **CameraManager**: Webcam access and frame capture using OpenCV
- **FrameProcessor**: Image preprocessing and quality validation
- **PostureAnalyzer**: ML model interface for posture classification
- **NotificationManager**: User notification system with configurable cooldowns
- **SettingsManager**: Persistent configuration storage using Qt Settings

## Technology Stack

### Production Application (C++)

- **C++17**: Core application language
- **Qt 6**: Cross-platform framework for UI and system integration
- **QML**: Modern declarative UI language
- **OpenCV 4.x**: Computer vision and camera handling
- **ONNX Runtime**: Machine learning model inference (planned)
- **CMake**: Build system and dependency management

### Research Prototype (Python)

- **Python 3.8+**: Rapid prototyping and experimentation
- **MediaPipe**: Pose detection and landmark extraction
- **PyTorch/TensorFlow**: Model training and experimentation
- **OpenCV**: Image processing and visualization
- **Jupyter**: Interactive development and analysis

## Project Structure

```
posture-monitor/
├── python-prototype/          # Research and model training
│   ├── data/                  # Training datasets
│   ├── models/                # Trained models
│   ├── notebooks/             # Jupyter experiments
│   └── train.py               # Training scripts
│
├── cpp-app/                   # Production application
│   ├── CMakeLists.txt        # Build configuration
│   ├── src/                  # C++ source files
│   │   ├── main.cpp
│   │   ├── application.cpp
│   │   ├── camera/
│   │   ├── ml/
│   │   ├── notification/
│   │   └── settings/
│   ├── include/              # Header files
│   │   ├── application.h
│   │   ├── camera/
│   │   ├── ml/
│   │   ├── notification/
│   │   └── settings/
│   ├── qml/                  # QML UI files
│   │   ├── main.qml
│   │   └── resources.qrc
│   ├── models/               # Deployed ML models
│   └── resources/            # Icons and assets
│
└── shared/                   # Shared resources
    └── exported_models/      # ONNX model exports
```

## Building from Source

### Prerequisites

#### All Platforms

- CMake 3.16 or higher
- C++17 compatible compiler
- Qt 6.2 or higher
- OpenCV 4.x

#### Linux (Ubuntu/Debian)

```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    cmake \
    qt6-base-dev \
    qt6-declarative-dev \
    qt6-multimedia-dev \
    libopencv-dev \
    libgl1-mesa-dev
```

#### macOS

```bash
brew install cmake qt@6 opencv
```

#### Windows

1. Install Visual Studio 2019/2022 with C++ Desktop Development workload
2. Install CMake from https://cmake.org/download/
3. Install Qt 6 from https://www.qt.io/download
4. Install OpenCV:
   - Via vcpkg: `vcpkg install opencv4:x64-windows`
   - Or download from https://opencv.org/releases/

For detailed Windows setup instructions, see [WINDOWS_SETUP.md](WINDOWS_SETUP.md)

### Linux/macOS Build

```bash
cd cpp-app
mkdir build && cd build
cmake ..
make -j$(nproc)
./PostureMonitor
```

Or use the provided build script:

```bash
cd cpp-app
chmod +x build.sh
./build.sh
```

### Windows Build

#### PowerShell (Recommended)

```powershell
cd cpp-app
.\build.ps1
```

With custom Qt path:

```powershell
.\build.ps1 -QtPath "C:\Qt\6.5.3\msvc2019_64"
```

#### Command Prompt

```cmd
cd cpp-app
build.bat
```

#### Manual Build

```cmd
cd cpp-app
mkdir build
cd build
cmake .. -G "Visual Studio 17 2022" -A x64
cmake --build . --config Release
.\Release\PostureMonitor.exe
```

### Qt Creator

1. Open Qt Creator
2. File → Open File or Project
3. Select `cpp-app/CMakeLists.txt`
4. Configure project with appropriate kit
5. Build → Build Project
6. Run

## Usage

1. Launch the application
2. Grant camera access when prompted
3. Click "Start" to begin posture monitoring
4. The application will run in the background and notify you of poor posture
5. Configure settings through the Settings dialog:
   - Camera selection and resolution
   - Notification preferences
   - Analysis intervals
   - Model selection (when available)

### System Requirements

- Windows 10/11, macOS 10.15+, or Linux with X11/Wayland
- Webcam (built-in or external)
- Minimum 4GB RAM
- 100MB disk space
- OpenGL support for UI rendering

## Development Roadmap

### Phase 1: Prototype (Python)

- [ ] Data collection pipeline
- [ ] Pose landmark extraction using MediaPipe
- [ ] Dataset annotation and augmentation
- [ ] Model architecture experimentation
- [ ] Model training and validation
- [ ] ONNX export

### Phase 2: Core Application (Current)

- [x] Project architecture and module structure
- [ ] Camera management and frame capture
- [ ] Frame preprocessing pipeline
- [ ] Settings persistence
- [ ] Basic QML user interface
- [ ] Notification system framework
- [ ] ONNX Runtime integration
- [ ] Model inference implementation
- [ ] Performance optimization

### Phase 3: Production

- [ ] Comprehensive unit tests
- [ ] Integration tests
- [ ] Performance benchmarking
- [ ] Native system notifications
- [ ] System tray integration
- [ ] Startup automation
- [ ] Multi-language support
- [ ] Packaging and installers
- [ ] User documentation
- [ ] Website and distribution

## Privacy

Privacy is a core design principle of Posture Monitor:

- All processing is performed locally on the user's device
- No data is transmitted to external servers
- Webcam frames are processed in memory and immediately discarded
- No images or video are stored to disk
- The application operates entirely offline
- Users maintain complete control over camera access

## Contributing

Contributions are welcome. Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure:
- Code follows the existing style conventions
- Changes are well-documented
- Commits have clear, descriptive messages
- New features include appropriate tests

## License

[To be determined]

## Acknowledgments

This project uses the following open-source libraries:

- Qt Framework (LGPL v3)
- OpenCV (Apache 2.0)
- ONNX Runtime (MIT)
- MediaPipe (Apache 2.0)

## Contact

[To be determined]

---

For build troubleshooting and platform-specific instructions, see:
- [BUILD.md](BUILD.md) - Detailed build instructions
