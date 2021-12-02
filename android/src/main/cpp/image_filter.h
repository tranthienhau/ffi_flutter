//
// Created by Sang Chau Van on 26/11/2021.
//
#include <opencv2/core.hpp>
#include <opencv2/imgproc.hpp>

#ifndef CAMERA_FILTER_IMAGE_FILTER_H
#define CAMERA_FILTER_IMAGE_FILTER_H
struct DuoToneParam{
    double exponent;
    int s1;
    int s2;
    int s3;
};

using namespace cv;
void apply_mat_duo_tone_filter(Mat& mat, DuoToneParam param);

#endif //CAMERA_FILTER_IMAGE_FILTER_H
