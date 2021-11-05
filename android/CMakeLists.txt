cmake_minimum_required(VERSION 3.4.1)

add_library(libcurl STATIC IMPORTED)
set_target_properties(libcurl PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp/libs/curl/${ANDROID_ABI}/lib/libcurl.a)

add_library(libssl STATIC IMPORTED)
set_target_properties(libssl PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp/libs/openssl/${ANDROID_ABI}/lib/libssl.a)

add_library(libcrypto STATIC IMPORTED)
set_target_properties(libcrypto PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp/libs/openssl/${ANDROID_ABI}/lib/libcrypto.a)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp/libs/curl/${ANDROID_ABI}/include/curl)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp/libs/openssl/${ANDROID_ABI}/include)

find_library(log-lib log)
find_library(android-lib android)

add_library(native_curl SHARED ../cpp/native_curl.cpp)

target_include_directories(native_curl PRIVATE
                           ${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp/curl/${ANDROID_ABI}/include
                           ${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp/openssl/${ANDROID_ABI}/include)

target_link_libraries(native_curl ${log-lib} ${android-lib})
target_link_libraries(native_curl
                      android
                      z
                      android
                      libcurl
                      libssl
                      libcrypto
                      log)