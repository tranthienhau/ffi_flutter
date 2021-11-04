cmake_minimum_required(VERSION 3.4.1)

add_library(lib_curl STATIC IMPORTED)
set_target_properties(lib_curl PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libcurl.a)

include_directories(../include/curl)
find_library(log-lib log)
find_library(android-lib android)
# find_library(log-lib log)
add_library(native_curl SHARED ../cpp/native_curl.cpp)
target_link_libraries(native_curl ${log-lib} ${android-lib})
target_link_libraries(native_curl
                      android
                      z
                      lib_curl
                      log)