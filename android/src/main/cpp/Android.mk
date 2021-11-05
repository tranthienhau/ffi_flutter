LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := ssl
LOCAL_SRC_FILES := libs/openssl/$(TARGET_ARCH_ABI)/lib/libssl.a
LOCAL_EXPORT_CFLAGS := -I$(LOCAL_PATH)/libs/openssl/$(TARGET_ARCH_ABI)/include
include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := crypto
LOCAL_SRC_FILES := libs/openssl/$(TARGET_ARCH_ABI)/lib/libcrypto.a
LOCAL_EXPORT_CFLAGS := -I$(LOCAL_PATH)/libs/openssl/$(TARGET_ARCH_ABI)/include
include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := curl
LOCAL_SRC_FILES := libs/curl/$(TARGET_ARCH_ABI)/lib/libcurl.a
LOCAL_EXPORT_CFLAGS := -I$(LOCAL_PATH)/libs/curl/$(TARGET_ARCH_ABI)/include
include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_SRC_FILES := native_curl
LOCAL_MODULE := native_curl
LOCAL_SRC_FILES := native_curl.cpp
LOCAL_STATIC_LIBRARIES := curl ssl crypto
LOCAL_LDLIBS    := -lz
include $(BUILD_SHARED_LIBRARY)
