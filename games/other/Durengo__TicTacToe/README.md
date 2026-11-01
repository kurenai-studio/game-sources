# Tic Tac Toe

## Description

A [Tic-Tac-Toe game](https://en.wikipedia.org/wiki/Tic-tac-toe) for two players.
The core game loop will use a GUI.
You can choose the grid size, as well as how will Player 1 start.

## Building From Source

### Prerequisites

#### Platform

|     Windows     |     UNIX      |     macOS     |
| :-------------: | :-----------: | :-----------: |
|      __X__      | NOT SUPPORTED | NOT SUPPORTED |
| __64-bit only__ |      N/A      |      N/A      |

#### Compiler

| MSVC  |      GNU      |     CLANG     |
| :---: | :-----------: | :-----------: |
| __X__ | NOT SUPPORTED | NOT SUPPORTED |

#### Additional requirements

* [Git](https://git-scm.com/)
* [Cmake](https://cmake.org/)
* MSVC17 - Available through [Microsoft Visual Studio 2022](https://visualstudio.microsoft.com/vs/)
* [Python](https://www.python.org/)

#### Libraries

If using the MSVC compiler a library manager such as [VCPKG](https://vcpkg.io/en/) is REQUIRED. Libraries could also be built from source, but that will not be as simple as using VCPKG.

1. [fmt](https://github.com/fmtlib/fmt)
2. [spdlog](https://github.com/gabime/spdlog)
3. [jsoncpp](https://github.com/open-source-parsers/jsoncpp)
4. [stb](https://github.com/nothings/stb)
5. [OpenGL](https://www.opengl.org/) - also OpenGL compatible GPU
6. [raylib](https://www.raylib.com/)
7. [PkgConfig](https://www.freedesktop.org/wiki/Software/pkg-config/)

Additionally [durlib](https://github.com/Durengo/durlib) library is required but it is added as a submodule of this project and is built together with it.

Note: All libraries must be built for x64 architecture. If using VCPKG use "triplet=x64-windows".

#### Setup The Project

1. Clone this repository
2. CD into the repository
3. Run ``$ git submodule update --init --recursive``
4. Run ``$ .\Tools\build.bat``
5. Enter the root directory of your VCPKG, e.g. "c:/dev/vcpkg"
6. Exit out of the script by entering '0'
7. Generate the CMake Project by running ``$ .\Tools\build.bat -pg "nt/msvc" "Debug"`` for Debug Builds or "Release" for Release Builds
8. Run the script again with the following flags ``$ .\Tools\build.bat -pb Debug`` for Debug builds or "Release" for Release builds 
9. First time running the build might take a while as durlib library also needs to be built from source
10. Done! This will create a build folder and all the executables and libraries are built to that folder.

Note: build.bat calls build.py which requires python.

Additionally, if prepping the project for release another command can be run to gather all the dependencies and executables into an Install folder.
``$ .\Tools\build.bat -pi Debug`` for Debug Installs or "Release" for Release Installs

#### Running Tests

1. Tests are integrated with ctest, therefore it is easy to run all the tests with this simple command ``$ ctest --test-dir "build" -C Debug -VV`` this will run tests for Debug builds, change "Debug" to "Release" for release builds. This additionally runs durlib tests.
2. There is also a PS script which will run the above command as many times as it is required, to properly run the tests and make sure they are not failing in dynamic scenarios. ``$ .\Tools\TestRunner.ps1``. By default it will run the above command for Debug and for a 100 iteration. Edit these values within the script itself if needed.
3. Running individual tests is also possible by running the executables found within "Build/Tests"

#### Increasing Iteration Times

Within the "Library/durlib/CMakeLists.txt" setting "set(MAIN_TEST ON)" and "set(EXAMPLES ON)" to OFF, will disable building tests and any examples exes within this library and improve the build times for GridWorks drastically.