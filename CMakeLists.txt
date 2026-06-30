if(CMAKE_GENERATOR STREQUAL "Xcode")
    message(FATAL_ERROR "PureDarwin cannot be compiled with Xcode.")
endif()

cmake_minimum_required(VERSION 3.15.1)
project(PUREDARWIN)

if((NOT CMAKE_C_COMPILER_ID MATCHES "AppleClang") AND (NOT CMAKE_C_COMPILER_ID MATCHES "Clang"))
    message(FATAL_ERROR "PureDarwin must be compiled with clang.")
endif()

cmake_policy(SET CMP0114 NEW)

# Target architecture: x86_64 (default, Intel/VM) or arm64 (Apple Silicon)
set(PUREDARWIN_TARGET_ARCH "x86_64" CACHE STRING "Target architecture for PureDarwin (x86_64 or arm64)")
set_property(CACHE PUREDARWIN_TARGET_ARCH PROPERTY STRINGS "x86_64" "arm64")

if(NOT PUREDARWIN_TARGET_ARCH MATCHES "^(x86_64|arm64)$")
    message(FATAL_ERROR "PUREDARWIN_TARGET_ARCH must be 'x86_64' or 'arm64', got '${PUREDARWIN_TARGET_ARCH}'")
endif()

set(CMAKE_INSTALL_PREFIX "")

# arm64 (Apple Silicon) requires macOS 14 (Sonoma) SDK and Xcode 15+.
# x86_64 requires macOS 13 (Ventura) SDK and Xcode 15+.
if(PUREDARWIN_TARGET_ARCH STREQUAL "arm64")
    set(CMAKE_MACOSX_MIN_VERSION 14.0)
else()
    set(CMAKE_MACOSX_MIN_VERSION 13.0)
endif()

include(ExternalProject)
include(cmake/asm.cmake)
include(cmake/bundle_resources.cmake)
include(cmake/circular.cmake)
include(cmake/crosscompile.cmake)
include(cmake/get_target_dependencies.cmake)
include(cmake/install_helpers.cmake)
include(cmake/kext.cmake)
include(cmake/mig.cmake)
include(cmake/suppress_warnings.cmake)

add_subdirectory(projects)
add_subdirectory(src)
add_subdirectory(tools)
