# Path definitions
set(pathToProject ${CMAKE_CURRENT_SOURCE_DIR})
#set(pathToOpenCv /Users/jonathanreynolds/Documents/Projects/OpenCV-android-sdk)

cmake_minimum_required(VERSION 3.4.1)

# Make sure we use flags for OpenGL in cpp
#set(CMAKE_VERBOSE_MAKEFILE on)
#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=gnu++11")

# OpenCV includes
#include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)
include_directories(../cpp/general)
#Added by IDE on project create
set(CPP_ROOT src/main/cpp)

set(SRC_FILES ${CPP_ROOT}/common.hpp ${CPP_ROOT}/native-lib.cpp
        ${CPP_ROOT}/opencvutil.h ${CPP_ROOT}/opencvutil.cpp
        ${CPP_ROOT}/image_filter.h ${CPP_ROOT}/image_filter.cpp
        ../cpp/general/general_funtion.h
        ../cpp/general/general_funtion.cpp
        ../cpp/native_curl.cpp
        ../cpp/native_opencv.cpp
        )
#set(SRC_FILES ${CPP_ROOT}/common.hpp ${CPP_ROOT}/native-lib.cpp
#        ${CPP_ROOT}/opencvutil.h ${CPP_ROOT}/opencvutil.cpp
#        ${CPP_ROOT}/image_filter.h ${CPP_ROOT}/image_filter.cpp ${CPP_ROOT}/native_curl.cpp)
add_library(native-lib SHARED ${SRC_FILES})

target_include_directories(native-lib PRIVATE
                           ${CMAKE_CURRENT_SOURCE_DIR}/src/main/curl/${ANDROID_ABI}/include
                           ${CMAKE_CURRENT_SOURCE_DIR}/src/main/openssl/${ANDROID_ABI}/include)

add_library(libcurl STATIC IMPORTED)
set_target_properties(libcurl PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/curl/${ANDROID_ABI}/lib/libcurl.a)

add_library(zlib STATIC IMPORTED)
set_target_properties(zlib PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/zlib/${ANDROID_ABI}/lib/libz.a)

add_library(libssl STATIC IMPORTED)
set_target_properties(libssl PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/openssl/${ANDROID_ABI}/lib/libssl.a)

add_library(libcrypto STATIC IMPORTED)
set_target_properties(libcrypto PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/openssl/${ANDROID_ABI}/lib/libcrypto.a)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/main/curl/${ANDROID_ABI}/include/curl)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/main/zlib/${ANDROID_ABI}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/main/openssl/${ANDROID_ABI}/include)

# OpenCV library
#add_library( lib_opencv SHARED IMPORTED )
#set_target_properties(lib_opencv PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/libs/${ANDROID_ABI}/libopencv_java3.so)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/main/opencv2/include)
add_library(lib_opencv SHARED IMPORTED)
set_target_properties(lib_opencv PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/opencv2/libs/${ANDROID_ABI}/libopencv_java4.so)

target_link_libraries(native-lib ${log-lib} ${android-lib})
# Link libraries
target_link_libraries(native-lib
                      z
                      lib_opencv
                      android
                      jnigraphics
                      zlib
                      libcurl
                      libssl
                      libcrypto
                      log)
