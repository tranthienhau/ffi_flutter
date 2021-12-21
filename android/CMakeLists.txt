cmake_minimum_required(VERSION 3.4.1)

include_directories(../cpp/general)

set(CPP_ROOT src/main/cpp)

set(SRC_FILES
        ../cpp/general/general_funtion.h
        ../cpp/general/general_funtion.cpp
        ../cpp/native_opencv.cpp
        )

add_library(native-lib SHARED ${SRC_FILES})

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
                      log)
