cmake_minimum_required(VERSION 3.4.1)

add_library(libcurl STATIC IMPORTED)
set_target_properties(libcurl PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp/libs/curl/${ANDROID_ABI}/lib/libcurl.a)

add_library(libssl STATIC IMPORTED)
set_target_properties(libssl PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp/libs/openssl/${ANDROID_ABI}/lib/libssl.a)

add_library(libcrypto STATIC IMPORTED)
set_target_properties(libcrypto PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp/libs/openssl/${ANDROID_ABI}/lib/libcrypto.a)



include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp/libs/curl/${ANDROID_ABI}/include/curl)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp/libs/openssl/${ANDROID_ABI}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../dart_api)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../dart_api/internal)


add_library(native_curl SHARED
            ../cpp/native_curl.cpp
            ../cpp/native_curl.h
            ../dart_api/dart_api.h
            ../dart_api/dart_api_dl.h
            ../dart_api/dart_native_api.h
            ../dart_api/dart_version.h
            ../dart_api/internal/dart_api_dl_impl.h
            ../dart_api/dart_api_dl.c)

target_include_directories(native_curl PRIVATE
                          ${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp/curl/${ANDROID_ABI}/include
                          ${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp/openssl/${ANDROID_ABI}/include)

target_link_libraries(native_curl ${log-lib} ${android-lib})
target_link_libraries(native_curl
                      z
                      android
                      libcurl
                      libssl
                      libcrypto
                      log)


#AWS libraries
set(AWS_LIB "${CMAKE_CURRENT_SOURCE_DIR}/src/main/aws/${ANDROID_ABI}/lib")
set(AWS_INCLUDE "${CMAKE_CURRENT_SOURCE_DIR}/src/main/aws/${ANDROID_ABI}/include")

add_library(libaws_auth STATIC IMPORTED)
set_target_properties(libaws_auth PROPERTIES IMPORTED_LOCATION ${AWS_LIB}/libaws-c-auth.a)

add_library(libaws_cal STATIC IMPORTED)
set_target_properties(libaws_cal PROPERTIES IMPORTED_LOCATION ${AWS_LIB}/libaws-c-cal.a)

add_library(libaws_common STATIC IMPORTED)
set_target_properties(libaws_common PROPERTIES IMPORTED_LOCATION ${AWS_LIB}/libaws-c-common.a)

add_library(libaws_compression STATIC IMPORTED)
set_target_properties(libaws_compression PROPERTIES IMPORTED_LOCATION ${AWS_LIB}/libaws-c-compression.a)

add_library(libaws_event_stream STATIC IMPORTED)
set_target_properties(libaws_event_stream PROPERTIES IMPORTED_LOCATION ${AWS_LIB}/libaws-c-event-stream.a)

add_library(libaws_http STATIC IMPORTED)
set_target_properties(libaws_http PROPERTIES IMPORTED_LOCATION ${AWS_LIB}/libaws-c-http.a)

add_library(libaws_io STATIC IMPORTED)
set_target_properties(libaws_io PROPERTIES IMPORTED_LOCATION ${AWS_LIB}/libaws-c-io.a)

add_library(libaws_mqtt STATIC IMPORTED)
set_target_properties(libaws_mqtt PROPERTIES IMPORTED_LOCATION ${AWS_LIB}/libaws-c-mqtt.a)

add_library(libaws_s3 STATIC IMPORTED)
set_target_properties(libaws_s3 PROPERTIES IMPORTED_LOCATION ${AWS_LIB}/libaws-c-s3.a)

add_library(libaws_checksumss3 STATIC IMPORTED)
set_target_properties(libaws_checksumss3 PROPERTIES IMPORTED_LOCATION ${AWS_LIB}/libaws-checksums.a)

add_library(libaws_cpp_sdk_cognito_identity STATIC IMPORTED)
set_target_properties(libaws_cpp_sdk_cognito_identity PROPERTIES IMPORTED_LOCATION ${AWS_LIB}/libaws-cpp-sdk-cognito-identity.a)

add_library(libaws_cpp_sdk_core STATIC IMPORTED)
set_target_properties(libaws_cpp_sdk_core PROPERTIES IMPORTED_LOCATION ${AWS_LIB}/libaws-cpp-sdk-core.a)

add_library(libaws_cpp_sdk_identity_management STATIC IMPORTED)
set_target_properties(libaws_cpp_sdk_identity_management PROPERTIES IMPORTED_LOCATION ${AWS_LIB}/libaws-cpp-sdk-identity-management.a)

add_library(libaws_cpp_sdk_s3 STATIC IMPORTED)
set_target_properties(libaws_cpp_sdk_s3 PROPERTIES IMPORTED_LOCATION ${AWS_LIB}/libaws-cpp-sdk-s3.a)

add_library(libaws_cpp_sdk_sts STATIC IMPORTED)
set_target_properties(libaws_cpp_sdk_sts PROPERTIES IMPORTED_LOCATION ${AWS_LIB}/libaws-cpp-sdk-sts.a)

add_library(libaws_crt_cpp STATIC IMPORTED)
set_target_properties(libaws_crt_cpp PROPERTIES IMPORTED_LOCATION ${AWS_LIB}/libaws-crt-cpp.a)

add_library(libs2n STATIC IMPORTED)
set_target_properties(libs2n PROPERTIES IMPORTED_LOCATION ${AWS_LIB}/libs2n.a)

add_library(libtesting_resources STATIC IMPORTED)
set_target_properties(libtesting_resources PROPERTIES IMPORTED_LOCATION ${AWS_LIB}/libtesting-resources.a)

include_directories(${AWS_INCLUDE})

target_link_libraries(native_curl
                      libtesting_resources
                      libs2n
                      libaws_crt_cpp
                      libaws_cpp_sdk_sts
                      libaws_cpp_sdk_s3
                      libaws_cpp_sdk_identity_management
                      libaws_cpp_sdk_core
                      libaws_cpp_sdk_cognito_identity
                      libaws_checksumss3
                      libaws_s3
                      libaws_mqtt
                      libaws_io
                      libaws_http
                      libaws_event_stream
                      libaws_compression
                      libaws_common
                      libaws_cal
                      libaws_auth
                      )