//
// Created by zale on 2020/5/29.
//



#ifndef CAMERA_FILTER_OPENCVUTIL_H
#define CAMERA_FILTER_OPENCVUTIL_H

#include <opencv2/opencv.hpp>
#include <opencv2/core.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include <android/bitmap.h>
#include <android/log.h>
#include <jni.h>

void BitmapToMat(JNIEnv *env, jobject& bitmap, cv::Mat& mat);
void MatToBitmap(JNIEnv *env, cv::Mat& mat, jobject& bitmap);


#endif //CAMERA_FILTER_OPENCVUTIL_H
