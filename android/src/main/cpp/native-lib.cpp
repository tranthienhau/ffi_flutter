#include <jni.h>

#include <opencv2/core.hpp>
#include <opencv2/imgproc.hpp>

#include <GLES2/gl2.h>

#include "common.hpp"
#include "opencvutil.h"
#include "image_filter.h"

using namespace cv;


//#define JAVA(X) JNIEXPORT Java_com_sangcv_ffi_1flutter_ImageFilterUtils_##X

extern "C"
JNIEXPORT void JNICALL
Java_com_sangcv_ffi_1flutter_ImageFilterUtils_00024Companion_applyDuoToneFilter(JNIEnv *env,
                                                                                jobject thiz,
                                                                                jobject src_bit_map,
                                                                                jobject target_bitmap,
                                                                                jobject param) {
    jclass cls = env->GetObjectClass(param);
    jfieldID fidExponent = env->GetFieldID(cls, "exponent", "D");
    jdouble exponent = env->GetDoubleField(param, fidExponent);
    printf("exponent: %f\n", exponent);

    jfieldID fidS1 = env->GetFieldID(cls, "s1", "I");
    jint s1 = env->GetIntField(param, fidS1);
    printf("s1: %d\n", s1);


    jfieldID fidS2 = env->GetFieldID(cls, "s2", "I");
    jdouble s2 = env->GetIntField(param, fidS2);
    printf("s2: %f\n", s2);


    jfieldID fidS3 = env->GetFieldID(cls, "s3", "I");
    jdouble s3 = env->GetIntField(param, fidS3);
    printf("s3: %f\n", s3);

    Mat mat_result;
    BitmapToMat(env, src_bit_map, mat_result);

    DuoToneParam duo_tone_param{};

    duo_tone_param.exponent = exponent;

    duo_tone_param.s1 = s1;

    duo_tone_param.s2 = s2;

    duo_tone_param.s3 = s3;

    apply_mat_duo_tone_filter(mat_result, duo_tone_param);

    MatToBitmap(env, mat_result, target_bitmap);
}

extern "C"
JNIEXPORT void JNICALL
Java_com_sangcv_ffi_1flutter_ImageFilterUtils_00024Companion_applyDuoToneFilterJNI(JNIEnv *env,
                                                                                   jobject thiz,
                                                                                   jlong mat_addr,
                                                                                   jobject param) {
    Mat &mat = *(Mat *) mat_addr;
    jclass cls = env->GetObjectClass(param);
    jfieldID fidExponent = env->GetFieldID(cls, "exponent", "D");
    jdouble exponent = env->GetDoubleField(param, fidExponent);
    printf("exponent: %f\n", exponent);

    jfieldID fidS1 = env->GetFieldID(cls, "s1", "I");
    jint s1 = env->GetIntField(param, fidS1);
    printf("s1: %d\n", s1);


    jfieldID fidS2 = env->GetFieldID(cls, "s2", "I");
    jdouble s2 = env->GetIntField(param, fidS2);
    printf("s2: %f\n", s2);


    jfieldID fidS3 = env->GetFieldID(cls, "s3", "I");
    jdouble s3 = env->GetIntField(param, fidS3);
    printf("s3: %f\n", s3);


    DuoToneParam duo_tone_param{};

    duo_tone_param.exponent = exponent;

    duo_tone_param.s1 = s1;

    duo_tone_param.s2 = s2;

    duo_tone_param.s3 = s3;

    apply_mat_duo_tone_filter(mat, duo_tone_param);
}