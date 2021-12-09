#include <opencv2/opencv.hpp>
#include <chrono>
#include<opencv2/imgproc.hpp>
#include<opencv2/photo.hpp>
#include<opencv2/highgui.hpp>
#include "general_funtion.h"
#include <opencv2/imgproc/imgproc.hpp>
#include <iostream>
#include <string>
#include <cstdint>
#include <cstring>

#if defined(WIN32) || defined(_WIN32) || defined(__WIN32)
#define IS_WIN32
#endif

#ifdef __ANDROID__

#include <android/log.h>
#include <opencv2/imgproc/types_c.h>

#endif

#ifdef IS_WIN32
#include <windows.h>
#endif

#if defined(__GNUC__)
// Attributes to prevent 'unused' function from being removed and to make it visible
#define FUNCTION_ATTRIBUTE __attribute__((visibility("default"))) __attribute__((used))
#elif defined(_MSC_VER)
// Marking a function for export
#define FUNCTION_ATTRIBUTE __declspec(dllexport)
#endif

using namespace cv;
using namespace std;

struct DuoToneParam {
    float exponent;
    int s1; // value from 0-2 (0 : BLUE n1 : GREEN n2 : RED)
    int s2; // value from 0-3 (0 : BLUE n1 : GREEN n2 : RED n3 : NONE)
    int s3; // (0 : DARK n1 : LIGHT)
};


long long int get_now() {
    return chrono::duration_cast<std::chrono::milliseconds>(
            chrono::system_clock::now().time_since_epoch()
    ).count();
}

// Avoiding name mangling
extern "C" {

Mat exponential_function(Mat channel, float exp) {
    Mat table(1, 256, CV_8U);

    for (int i = 0; i < 256; i++)
        table.at<uchar>(i) = min((int) pow(i, exp), 255);

    LUT(channel, table, channel);
    return channel;
}

FUNCTION_ATTRIBUTE
const char *version() {
    return CV_VERSION;
}


FUNCTION_ATTRIBUTE
void *create_mat_pointer_from_bytes(unsigned char *bytes,
                                   int32_t *imgLengthBytes) {
    cv::Mat *src = new Mat();
    int32_t a = *imgLengthBytes;
    std::vector<unsigned char> m;

    while (a >= 0) {
        m.push_back(*(bytes++));
        a--;
    }
    *src = cv::imdecode(m, cv::IMREAD_UNCHANGED);
    if (src->data == nullptr)
        return nullptr;
    platform_log("create_mat_pointer_from_bytes: len before:%d  len after:%d  width:%d  height:%d",
                 *imgLengthBytes, src->step[0] * src->rows,
                 src->cols, src->rows);

    *imgLengthBytes = src->step[0] * src->rows;

    return src;
}

FUNCTION_ATTRIBUTE
unsigned char * process_mat_to_bytes_greyscale(void *imgMat, int32_t *imgLengthBytes) {
    cv::Mat *src = (Mat *) imgMat;
    if (src == nullptr || src->data == nullptr)
        return nullptr;
    Mat dst =  cv::Mat();

    std::vector<uchar> buf(1);
    cv::imencode(".bmp", dst, buf);
    *imgLengthBytes = buf.size();

    unsigned char *ret = (unsigned char *)malloc(buf.size());
    memcpy(ret, buf.data(), buf.size());
    return ret;
}


FUNCTION_ATTRIBUTE
unsigned char * process_mat_to_duo_tone_bytes(void *imgMat,  DuoToneParam param) {
    Mat duo_tone = ((Mat *) imgMat)->clone();
    float exp = 1.0f + param.exponent / 100.0f;
    int s1 = param.s1;
    int s2 = param.s2;
    int s3 = param.s3;

    platform_log("apply_mat_duo_tone_filter:  param: %d,s1: %d,s2: %d,s3: %d", param.exponent, s1,
                 s2, s3);

    Mat channels[3];
    split(duo_tone, channels);

    for (int i = 0; i < 3; i++) {
        if ((i == s1) || (i == s2)) {
            channels[i] = exponential_function(channels[i], exp);
        } else {
            if (s3) {
                channels[i] = exponential_function(channels[i], 2 - exp);
            } else {
                channels[i] = Mat::zeros(channels[i].size(), CV_8UC1);
            }
        }
    }

    vector<Mat> newChannels{channels[0], channels[1], channels[2]};

    merge(newChannels, duo_tone);


    std::vector<uchar> buf(1);
    cv::imencode(".bmp", duo_tone, buf);
//    *imgLengthBytes = buf.size();

    unsigned char *ret = (unsigned char *)malloc(buf.size());
    memcpy(ret, buf.data(), buf.size());
    return ret;
}


FUNCTION_ATTRIBUTE
Mat *create_mat_pointer(char *inputImagePath) {

    Mat image = imread(inputImagePath, IMREAD_COLOR);
    Mat *matPointer = new Mat(image);

    return matPointer;
}

FUNCTION_ATTRIBUTE
void apply_mat_gray_filter(Mat *mat, char *outputImagePath) {
    Mat greyMat;
    platform_log("apply_mat_gray_filter:  outputImagePath: %s", outputImagePath);
    std::vector<uchar> array;

    cv::cvtColor(*mat, greyMat, CV_BGR2GRAY);

    imwrite(outputImagePath, greyMat);

}


FUNCTION_ATTRIBUTE
void apply_mat_duo_tone_filter(Mat *mat, char *outputImagePath, DuoToneParam param) {


    Mat duo_tone = mat->clone();
    float exp = 1.0f + param.exponent / 100.0f;
    int s1 = param.s1;
    int s2 = param.s2;
    int s3 = param.s3;

    platform_log("apply_mat_duo_tone_filter:  param: %d,s1: %d,s2: %d,s3: %d", param.exponent, s1,
                 s2, s3);

    Mat channels[3];
    split(duo_tone, channels);

    for (int i = 0; i < 3; i++) {
        if ((i == s1) || (i == s2)) {
            channels[i] = exponential_function(channels[i], exp);
        } else {
            if (s3) {
                channels[i] = exponential_function(channels[i], 2 - exp);
            } else {
                channels[i] = Mat::zeros(channels[i].size(), CV_8UC1);
            }
        }
    }

    vector<Mat> newChannels{channels[0], channels[1], channels[2]};

    merge(newChannels, duo_tone);


    imwrite(outputImagePath, duo_tone);

}

FUNCTION_ATTRIBUTE
void apply_mat_invert_filter(Mat *mat, char *outputImagePath) {
    Mat output;
    bitwise_not(*mat, output);
    imwrite(outputImagePath, output);
}

FUNCTION_ATTRIBUTE
void apply_mat_pencil_sketch_filter(Mat *mat, char *outputImagePath) {
    Mat kernel = (cv::Mat_<float>(3, 3)
            <<
            -1, -1, -1,
            -1, 9.5, -1,
            -1, -1, -1);
    Mat colorOutput;
    Mat grayOutput;
    pencilSketch(*mat, grayOutput, colorOutput, 60, 0.07, 0.1);
    imwrite(outputImagePath, colorOutput);
}

FUNCTION_ATTRIBUTE
void apply_mat_sharpen_filter(Mat *mat, char *outputImagePath) {
    Mat kernel = (cv::Mat_<float>(3, 3)
            <<
            -1, -1, -1,
            -1, 9.5, -1,
            -1, -1, -1);
    Mat output;
    filter2D(*mat, output, -1, kernel);
    imwrite(outputImagePath, output);
}

FUNCTION_ATTRIBUTE
void apply_mat_hdr_filter(Mat *mat, char *outputImagePath) {
    Mat output;
    detailEnhance(*mat, output, 12, 0.15);
    imwrite(outputImagePath, output);
}

FUNCTION_ATTRIBUTE
void apply_mat_summer_filter(Mat *mat, char *outputImagePath) {
//    Mat greyMat;
    platform_log("apply_mat_summer_filter:  outputImagePath: %s", outputImagePath);
//    std::vector<uchar> array;
//
//    cv::cvtColor(*mat, greyMat, CV_BGR2GRAY);

    float data[8] = {0, 64, 128, 256, 0, 80, 160, 256};
    cv::Mat your_matrix = cv::Mat(3, 2, CV_8U, data);

    Mat increase_lookup = (cv::Mat_<float>(3, 2)
            <<
            0, 64, 128, 256,
            0, 80, 160, 256);

    Mat decrease_lookup = (cv::Mat_<float>(3, 2)
            <<
            0, 64, 128, 256,
            0, 50, 100, 256);
    Mat channel_mat[3];
    split(*mat, channel_mat);

    Mat blue_channel = channel_mat[0];
    Mat green_channel = channel_mat[1];
    Mat red_channel = channel_mat[2];


    Mat red_lut;
    Mat blue_lut;
    cv::LUT(red_channel, increase_lookup, red_lut);
    cv::LUT(blue_channel, decrease_lookup, blue_lut);
    vector<Mat> channels;
    channels.push_back(blue_channel);
    channels.push_back(green_channel);
    channels.push_back(red_lut);

    Mat output;
    cv::merge(channels, output);
    imwrite(outputImagePath, output);

}


FUNCTION_ATTRIBUTE
void apply_mat_cartoon_filter(Mat *mat, char *outputImagePath) {
    //Convert to gray scale
    Mat grayImage;
    cvtColor(*mat, grayImage, COLOR_BGR2GRAY);

    //apply gaussian blur
    GaussianBlur(grayImage, grayImage, Size(3, 3), 0);

    //find edges
    Mat edgeImage;
    Laplacian(grayImage, edgeImage, -1, 5);
    convertScaleAbs(edgeImage, edgeImage);

    //invert the image
    edgeImage = 255 - edgeImage;

    //apply thresholding
    threshold(edgeImage, edgeImage, 150, 255, THRESH_BINARY);

    //blur images heavily using edgePreservingFilter
    Mat edgePreservingImage;
    edgePreservingFilter(*mat, edgePreservingImage, 2, 50, 0.4);

    // Create a output Matrix
    Mat output;
    output = Scalar::all(0);

    // Combine the cartoon and edges
    cv::bitwise_and(edgePreservingImage, edgePreservingImage, output, edgeImage);

    imwrite(outputImagePath, output);
}

FUNCTION_ATTRIBUTE
void apply_mat_sepia_filter(Mat *mat, char *outputImagePath) {

    Mat kernel = (cv::Mat_<float>(3, 3)
            <<
            0.272, 0.534, 0.131,
            0.349, 0.686, 0.168,
            0.393, 0.769, 0.189);

    // Create a output Matrix
    Mat output;
    cv::transform(*mat, output, kernel);

    imwrite(outputImagePath, output);
}

FUNCTION_ATTRIBUTE
void apply_mat_edge_preserving_filter(Mat *mat, char *outputImagePath) {
    // Create a output Matrix
    Mat output;

    cv::edgePreservingFilter(*mat, output, 1, 60, 0.4);
    imwrite(outputImagePath, output);
}

FUNCTION_ATTRIBUTE
void apply_mat_stylization_filter(Mat *mat, char *outputImagePath) {

    // Create a output Matrix
    Mat output;

    cv::stylization(*mat, output, 60, 0.07);

    imwrite(outputImagePath, output);
}

FUNCTION_ATTRIBUTE
void apply_gray_filter(char *inputImagePath, char *outputImagePath) {
    Mat image = imread(inputImagePath, IMREAD_GRAYSCALE);
    if (image.empty()) {
        return;
    }
    imwrite(outputImagePath, image);
}


FUNCTION_ATTRIBUTE
void apply_cartoon_filter(char *inputImagePath, char *outputImagePath) {
    //Read input image
    Mat image = imread(inputImagePath, IMREAD_COLOR);
    if (image.empty()) {
        return;
    }
    //Convert to gray scale
    Mat grayImage;
    cvtColor(image, grayImage, COLOR_BGR2GRAY);

    //apply gaussian blur
    GaussianBlur(grayImage, grayImage, Size(3, 3), 0);

    //find edges
    Mat edgeImage;
    Laplacian(grayImage, edgeImage, -1, 5);
    convertScaleAbs(edgeImage, edgeImage);

    //invert the image
    edgeImage = 255 - edgeImage;

    //apply thresholding
    threshold(edgeImage, edgeImage, 150, 255, THRESH_BINARY);

    //blur images heavily using edgePreservingFilter
    Mat edgePreservingImage;
    edgePreservingFilter(image, edgePreservingImage, 2, 50, 0.4);

    // Create a output Matrix
    Mat output;
    output = Scalar::all(0);

    // Combine the cartoon and edges
    cv::bitwise_and(edgePreservingImage, edgePreservingImage, output, edgeImage);

    imwrite(outputImagePath, output);
}

FUNCTION_ATTRIBUTE
void apply_sepia_filter(char *inputImagePath, char *outputImagePath) {
    //Read input image
    Mat image = imread(inputImagePath, IMREAD_COLOR);
    if (image.empty()) {
        return;
    }
    Mat kernel = (cv::Mat_<float>(3, 3)
            <<
            0.272, 0.534, 0.131,
            0.349, 0.686, 0.168,
            0.393, 0.769, 0.189);

    // Create a output Matrix
    Mat output;
    cv::transform(image, output, kernel);

    imwrite(outputImagePath, output);
}

FUNCTION_ATTRIBUTE
void apply_edge_preserving_filter(char *inputImagePath, char *outputImagePath) {
    //Read input image
    Mat image = imread(inputImagePath, IMREAD_COLOR);
    if (image.empty()) {
        return;
    }
    // Create a output Matrix
    Mat output;

    cv::edgePreservingFilter(image, output, 1, 60, 0.4);
    imwrite(outputImagePath, output);
}

FUNCTION_ATTRIBUTE
void apply_stylization_filter(char *inputImagePath, char *outputImagePath) {
    //Read input image
    Mat image = imread(inputImagePath, IMREAD_COLOR);
    if (image.empty()) {
        return;
    }
    // Create a output Matrix
    Mat output;

    cv::stylization(image, output, 60, 0.07);

    imwrite(outputImagePath, output);
}
}
