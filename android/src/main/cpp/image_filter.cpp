//
// Created by Sang Chau Van on 26/11/2021.
//

#include "image_filter.h"
#include <vector>

using namespace std;

Mat exponential_function(Mat channel, float exp) {
    Mat table(1, 256, CV_8U);

    for (int i = 0; i < 256; i++)
        table.at<uchar>(i) = min((int) pow(i, exp), 255);

    LUT(channel, table, channel);
    return channel;
}

void apply_mat_duo_tone_filter(Mat &mat, DuoToneParam param) {

    float exp = 1.0f + (float) param.exponent / 100.0f;

    int s1 = param.s1;
    int s2 = param.s2;
    int s3 = param.s3;


    Mat channels[4];
    split(mat, channels);

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

    vector<Mat> newChannels{channels[0], channels[1], channels[2], channels[3]};

    merge(newChannels, mat);
}