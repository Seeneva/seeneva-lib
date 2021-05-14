#!/bin/sh

#For reusable purpose

# Path to CMake
CMAKE_BIN=${ANDROID_HOME}/cmake/${CMAKE_VERSION}/bin/cmake

# Path to CMake output directory
NINJA_OUTPUT=${GITHUB_WORKSPACE}/build/android/${ABI}

# We should create the directory before run CMake
mkdir -p ${NINJA_OUTPUT}

# Generate Ninja
# see https://developer.android.com/studio/projects/configure-cmake#call-cmake-cli
# Or open any 'build_command.txt' inside Android Gradle module .cxx/cmake/${ANDROID_BUILD_VARIANT}/${ABI}/ 
${CMAKE_BIN} \
    -H${GITHUB_WORKSPACE} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${ANDROID_HOME}/ndk/${NDK_VERSION}/build/cmake/android.toolchain.cmake \
    -DANDROID_ABI=${ABI} \
    -DANDROID_NDK=${ANDROID_HOME}/ndk/${NDK_VERSION} \
    -DANDROID_PLATFORM=android-16 \
    -DCMAKE_LIBRARY_OUTPUT_DIRECTORY=${NINJA_OUTPUT}/obj \
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=${NINJA_OUTPUT}/obj \
    -DCMAKE_MAKE_PROGRAM=${ANDROID_HOME}/cmake/${CMAKE_VERSION}/bin/ninja \
    -DRUST_RELEASE=ON \
    -DRUST_DEBUG_LOGS=OFF \
    -DLIB_DEB_SYMBOLS=OFF \
    -B${NINJA_OUTPUT} \
    -GNinja

# Run Ninja build
${CMAKE_BIN} --build ${NINJA_OUTPUT} --target cargo-build
