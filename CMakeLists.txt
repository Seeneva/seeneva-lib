#
# This file is part of Seeneva Android Reader
# Copyright (C) 2021 Sergei Solodovnikov
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

cmake_minimum_required(VERSION 3.10.2)

# Dummy CMake which will generate 'cargo_build.sh' as result
# Run 'cargo_build.sh' to call cargo build
# See '${NDK}/build/cmake/android.toolchain.cmake' for CMake arguments

option(RUST_RELEASE "Specify cargo release build type" OFF)
option(RUST_DEBUG_LOGS "Library should show debug logs" ON)
option(LIB_DEB_SYMBOLS "The output library should contains debug symbols" ON)

# Check '${NDK}/build/cmake/android.toolchain.cmake' for variables
# Also https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html#id21

macro(list_to_spaced_string varName)
    string(REPLACE ";" " " ${varName} "${${varName}}")
endmacro()

find_program(CARGO cargo PATHS $ENV{HOME}/.cargo/bin)

if(NOT CARGO)
    message(FATAL_ERROR "Can't find Rust Cargo path")
endif()

if(ANDROID_ABI STREQUAL armeabi-v7a)
    set(CLANG_TRIPPLE armv7a-linux-androideabi)
    set(RUST_TARGET_TRIPPLE armv7-linux-androideabi)
else()
    set(CLANG_TRIPPLE ${CMAKE_LIBRARY_ARCHITECTURE})
    set(RUST_TARGET_TRIPPLE ${CMAKE_LIBRARY_ARCHITECTURE})
endif()

if(ANDROID_NATIVE_API_LEVEL LESS 21)
    # android_support should be linked to prevent *locale undefinde symbols
    # needed by Tesseract
    # You do not need it if your Android API level is >= 21
    set(RUST_FLAGS "-C link-arg=-landroid_support")
endif()

if(NOT DEFINED RUST_TARGET_TRIPPLE)
    message(FATAL_ERROR "Rust target is not defined!")
endif()

# Set Cargo build features
set(RUST_BUILD_FEATURES "tflite_with_mmap")

if(ANDROID_ABI STREQUAL arm64-v8a)
    list(APPEND RUST_BUILD_FEATURES "tflite_with_ruy")
endif()

if(RUST_DEBUG_LOGS)
    list(APPEND RUST_BUILD_FEATURES "debug_logs")
endif()

list_to_spaced_string(RUST_BUILD_FEATURES)

# Tripple used by Cargo
string(REPLACE "-" "_" CARGO_TARGET_TRIPPLE ${RUST_TARGET_TRIPPLE})
string(TOUPPER ${CARGO_TARGET_TRIPPLE} CARGO_TARGET_TRIPPLE)

# Cargo command
list(APPEND CARGO_COMMAND ${CARGO} build --target=${RUST_TARGET_TRIPPLE} --features "${RUST_BUILD_FEATURES}")

# C/CXX flags
set(C_FLAGS ${CMAKE_C_FLAGS} ${CMAKE_SHARED_LIBRARY_C_FLAGS})
set(CXX_FLAGS ${CMAKE_CXX_FLAGS} ${CMAKE_SHARED_LIBRARY_CXX_FLAGS})

if(LIB_DEB_SYMBOLS)
    # rustflags = [
    # # Add build-id to help LLDB find debug symbols for result stripped .so file using `$lldb settings append target.exec-search-paths`
    # "-C", "link-arg=-Wl,--build-id=sha1",
    # # This will pass `-g` to Rust compiler. This will prevent debug symbols from strip.
    # # So you can use output .so as debug symbols source during debug even release builds
    # # By default Android Studio strip debug symbols from all libraries before pack them into .apk, so you do not need to think about app size.
    # "-C", "debuginfo=2"
    # ]
    list(APPEND RUST_FLAGS "-C link-arg=-Wl,--build-id=sha1" "-C debuginfo=2")
else()
    list(APPEND RUST_FLAGS "-C debuginfo=0")

    # Remove -g C/CXX flag
    set(_pattern "-g ?")

    string(REGEX REPLACE ${_pattern} "" C_FLAGS ${C_FLAGS})
    string(REGEX REPLACE ${_pattern} "" CXX_FLAGS ${CXX_FLAGS})
endif()


if(RUST_RELEASE)
    set(RustBuildType release)
    list(APPEND CARGO_COMMAND --release)
    list(APPEND C_FLAGS -DNDEBUG)
    list(APPEND CXX_FLAGS -DNDEBUG)
else()
    set(RustBuildType debug)
endif()

list_to_spaced_string(RUST_FLAGS)
list_to_spaced_string(C_FLAGS)
list_to_spaced_string(CXX_FLAGS)

# Set clang compiler with proper target equal to android min level. 64-bit support starts from Android SDK 21
set(CC "${ANDROID_TOOLCHAIN_ROOT}/bin/${CLANG_TRIPPLE}${ANDROID_NATIVE_API_LEVEL}-clang")
set(CXX "${CC}++")

# Set required env variables
list(APPEND CARGO_ENVS
    # Set libc linker and ar
    # You can also set specific flags by CXX_${abi.rustTriple} (CXX_i686-linux-android)
    # https://github.com/alexcrichton/cc-rs#external-configuration-via-environment-variables
    "CC=${CC}"
    "CXX=${CXX}"
    "AR=${CMAKE_AR}"
    "LD=${CMAKE_LINKER}"
    "STRIP=${CMAKE_STRIP}"
    "LLVM_CONFIG_PATH=${ANDROID_TOOLCHAIN_ROOT}/bin/llvm-config"
    # Setup cargo. It can be overrided via .cargo/config TOML file
    # https://doc.rust-lang.org/cargo/reference/config.html
    "CARGO_TARGET_${CARGO_TARGET_TRIPPLE}_LINKER=${CXX}"
    "CARGO_TARGET_${CARGO_TARGET_TRIPPLE}_AR=${CMAKE_AR}"
    # This will override your rustflags value in a .cargo/config file
    "RUSTFLAGS=${RUST_FLAGS}"
    # C/CXX flags
    "CFLAGS=${C_FLAGS}"
    "CXXFLAGS=${CXX_FLAGS}"
    "LDFLAGS=${CMAKE_SHARED_LINKER_FLAGS}"
    # Passed to cc crate. Needed for Android. Without it cc crate will use c++_shared by default
    # https://github.com/alexcrichton/cc-rs#c-support
    "CXXSTDLIB=${ANDROID_STL}"
    # CMAKE arguments
    # https://developer.android.com/ndk/guides/cmake#usage
    "CMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}"
    "ANDROID_ABI=${ANDROID_ABI}"
    "ANDROID_NATIVE_API_LEVEL=${ANDROID_NATIVE_API_LEVEL}"
)

add_custom_target(
    cargo-build
    COMMENT "Run Rust Cargo build for Seeneva native library"
    WORKING_DIRECTORY ${CMAKE_HOME_DIRECTORY}
    VERBATIM
    USES_TERMINAL
    COMMAND ${CMAKE_COMMAND} -E env ${CARGO_ENVS} ${CARGO_COMMAND}
)

add_custom_command(
    TARGET cargo-build POST_BUILD
    WORKING_DIRECTORY "${CMAKE_HOME_DIRECTORY}"
    COMMENT "Copy shared libraries into output directory"
    # Make output directory if it doesn't exist
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}"
    # Copy builded shared libraries
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "./target/${RUST_TARGET_TRIPPLE}/${RustBuildType}/*.so" "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}"
)
