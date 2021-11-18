#include <opencv2/opencv.hpp>
#include <chrono>
#include<opencv2/imgproc.hpp>
#include<opencv2/photo.hpp>
#include<opencv2/highgui.hpp>
#include "general_funtion.h"
#if defined(WIN32) || defined(_WIN32) || defined(__WIN32)
#define IS_WIN32
#endif

#ifdef __ANDROID__
#include <android/log.h>
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

long long int get_now() {
    return chrono::duration_cast<std::chrono::milliseconds>(
            chrono::system_clock::now().time_since_epoch()
    ).count();
}
//
//void platform_log(const char *fmt, ...) {
//    va_list args;
//    va_start(args, fmt);
//#ifdef __ANDROID__
//    __android_log_vprint(ANDROID_LOG_VERBOSE, "ndk", fmt, args);
//#elif defined(IS_WIN32)
//    char *buf = new char[4096];
//    std::fill_n(buf, 4096, '\0');
//    _vsprintf_p(buf, 4096, fmt, args);
//    OutputDebugStringA(buf);
//    delete[] buf;
//#else
//    vprintf(fmt, args);
//#endif
//    va_end(args);
//}

// Avoiding name mangling
extern "C" {
    FUNCTION_ATTRIBUTE
    const char* version() {
        return CV_VERSION;
    }

//    FUNCTION_ATTRIBUTE
//    void process_image(char* inputImagePath, char* outputImagePath) {
//        long long start = get_now();
//
//        Mat input = imread(inputImagePath, IMREAD_GRAYSCALE);
//        Mat threshed, withContours;
//
//        vector<vector<Point>> contours;
//        vector<Vec4i> hierarchy;
//
//        adaptiveThreshold(input, threshed, 255, ADAPTIVE_THRESH_GAUSSIAN_C, THRESH_BINARY_INV, 77, 6);
//        findContours(threshed, contours, hierarchy, RETR_TREE, CHAIN_APPROX_TC89_L1);
//
//        cvtColor(threshed, withContours, COLOR_GRAY2BGR);
//        drawContours(withContours, contours, -1, Scalar(0, 255, 0), 4);
//
//        imwrite(outputImagePath, withContours);
//
//        int evalInMillis = static_cast<int>(get_now() - start);
//        platform_log("Processing done in %dms\n", evalInMillis);
//    }
    FUNCTION_ATTRIBUTE
    void apply_gray_filter(char* inputImagePath, char* outputImagePath){
        Mat image = imread(inputImagePath, IMREAD_GRAYSCALE);
        if(image.empty()) {
            return;
        }
        imwrite(outputImagePath, image);
    }

    FUNCTION_ATTRIBUTE
    void apply_cartoon_filter(char* inputImagePath, char* outputImagePath){
        //Read input image
        Mat image = imread(inputImagePath, IMREAD_COLOR);
        if(image.empty()) {
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
    void apply_sepia_filter(char* inputImagePath, char* outputImagePath){
        //Read input image
        Mat image = imread(inputImagePath, IMREAD_COLOR);
        if(image.empty()) {
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
    void apply_edge_preserving_filter(char* inputImagePath, char* outputImagePath){
        //Read input image
        Mat image = imread(inputImagePath, IMREAD_COLOR);
        if(image.empty()) {
            return;
        }
        // Create a output Matrix
        Mat output;

        cv::edgePreservingFilter(image, output,1, 60, 0.4);
        imwrite(outputImagePath, output);
    }

    FUNCTION_ATTRIBUTE
    void apply_stylization_filter(char* inputImagePath, char* outputImagePath){
        //Read input image
        Mat image = imread(inputImagePath, IMREAD_COLOR);
        if(image.empty()) {
            return;
        }
        // Create a output Matrix
        Mat output;

        cv::stylization(image, output, 60, 0.07);

        imwrite(outputImagePath, output);
    }
}
