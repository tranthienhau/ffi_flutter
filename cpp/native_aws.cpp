//#include <aws/core/auth/AWSCredentials.h>
//#include <aws/core/Aws.h>
//#include <aws/core/utils/logging/LogLevel.h>
#include <iostream>
#include <chrono>
#include <cstring>
#include <iostream>
#include <aws/core/Aws.h>
#include <aws/core/utils/Outcome.h>
#include <aws/core/utils/logging/AWSLogging.h>
#include <aws/core/client/ClientConfiguration.h>
#include <aws/core/auth/AWSCredentialsProvider.h>
#include <algorithm>    // std::copy
#include <aws/identity-management/auth/CognitoCachingCredentialsProvider.h>
#include <aws/s3/S3Client.h>
#include <aws/s3/model/Bucket.h>
#include <aws/s3/model/PutObjectRequest.h>
#include <aws/core/utils/memory/AWSMemory.h>
#include <aws/core/utils/memory/MemorySystemInterface.h>
#include <aws/s3/model/GetObjectRequest.h>
#include <memory>
#include <fstream>
#include "general_funtion.h"

#if __ANDROID__
#include <android/log.h>
#include <jni.h>
#include <aws/core/platform/Android.h>
#include <aws/core/utils/logging/android/LogcatLogSystem.h>
#endif

using namespace Aws::Auth;
using namespace Aws::CognitoIdentity;
using namespace Aws::CognitoIdentity::Model;
using namespace Aws;
using namespace Aws::S3;
using namespace Aws::S3::Model;
using namespace std;
struct BucketListData {
    char **buckets;
    int length;
};

extern "C" __attribute__((visibility("default"))) __attribute__((used))
void upload_file_to_s3(
        const char *access_key_id,
        const char *secret_key_id,
        const char *cert_path,
        const char *bucket_name,
        const char *file_path,
        const char *bucket_key
) {
    Aws::Auth::AWSCredentials credentials;
    Aws::SDKOptions options;
//    String bucket_name_str(bucket_name);
    options.loggingOptions.logLevel = Aws::Utils::Logging::LogLevel::Debug;
    platform_log(
            "upload_file_to_s3: access_key_id:%s, secret_key_id:%s, cert_path:%s, bucket_name:%s, bucket_key:%s, file_path:%s",
            access_key_id, secret_key_id, cert_path, bucket_name, bucket_key, file_path
    );
    //The AWS SDK for C++ must be initialized by calling Aws::InitAPI.
    InitAPI(options);
    {
        Aws::Client::ClientConfiguration clientConfig;
        clientConfig.region = "ap-southeast-1";
#ifdef __ANDROID__
        clientConfig.caFile = Aws::String(cert_path);
#endif
        Aws::Auth::AWSCredentials credentials = Aws::Auth::AWSCredentials();
        credentials.SetAWSAccessKeyId(Aws::String(access_key_id));
        credentials.SetAWSSecretKey(Aws::String(secret_key_id));
        Aws::S3::S3Client s3Client(credentials, clientConfig);
        platform_log("auth_aws: access_key_id:%s, secret_key_id:%s", access_key_id, secret_key_id);
//        auto outcome = s3Client.ListBuckets();

        Aws::S3::Model::PutObjectRequest putObjectRequest;
        putObjectRequest.WithBucket(Aws::String(bucket_name)).WithKey(Aws::String(bucket_key));

        auto requestStream = MakeShared<FStream>("PutObjectInputStream", file_path,
                                                 ios_base::in | ios_base::binary);

        putObjectRequest.SetBody(requestStream);

        auto putObjectOutcome = s3Client.PutObject(putObjectRequest);

        if (putObjectOutcome.IsSuccess()) {
            platform_log("Put object succeeded");
        } else {
            platform_log("Failed with error: outcome error: %s",
                         putObjectOutcome.GetError().GetMessage().c_str());
        }
//        URL s3Url = s3Client.getUrl(bucketName, bucket_key);

    }

    //Before the application terminates, the SDK must be shut down.
    ShutdownAPI(options);

    platform_log("ShutdownAPI");
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
BucketListData get_buckets(const char *access_key_id, const char *secret_key_id, const char *cert_path) {
    std::vector<const char *> buckets;
    Aws::Auth::AWSCredentials credentials;
    BucketListData bucket_data;
    Aws::SDKOptions options;

    options.loggingOptions.logLevel = Aws::Utils::Logging::LogLevel::Debug;

    //The AWS SDK for C++ must be initialized by calling Aws::InitAPI.
    InitAPI(options);
    {

        Aws::Client::ClientConfiguration clientConfig;
        clientConfig.region = "ap-southeast-1";
#ifdef __ANDROID__
        clientConfig.caFile = Aws::String(cert_path);
#endif
        Aws::Auth::AWSCredentials credentials = Aws::Auth::AWSCredentials();
        credentials.SetAWSAccessKeyId(Aws::String(access_key_id));
        credentials.SetAWSSecretKey(Aws::String(secret_key_id));
        Aws::S3::S3Client s3Client(credentials, clientConfig);
        platform_log("auth_aws: access_key_id:%s, secret_key_id:%s", access_key_id, secret_key_id);
        auto outcome = s3Client.ListBuckets();

        if (outcome.IsSuccess()) {
//               platform_log("Found: buckets size:%d", outcome.GetResult().GetBuckets().size());
            for (auto &&b : outcome.GetResult().GetBuckets()) {
                platform_log("Buckets name:%s", b.GetName().c_str());
                buckets.push_back(b.GetName().c_str());
            }
        } else {
            platform_log("Failed with error: outcome error: %s",
                         outcome.GetError().GetMessage().c_str());
        }
    }

    //Before the application terminates, the SDK must be shut down.
    ShutdownAPI(options);

    platform_log("ShutdownAPI");
//    bucket_data.buckets = buckets.data();
    bucket_data.length = buckets.size();
    char **bucket_array;


    bucket_array = new char *[buckets.size()];
    for (int i = 0; i < buckets.size(); i++) {
        const size_t n = strlen(buckets[i]);
        char *bucket_item = new char[n + 1]{};
        std::copy_n(buckets[i], n, bucket_item);
        bucket_array[i] = bucket_item;
    }

    bucket_data.buckets = bucket_array;
    return bucket_data;
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
char *get_item_char_array(char **buckets, int index) {
    return buckets[index];
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
void free_char_array(char **buckets, int length) {
    for (int i = 0; i < length; i++) {
        delete[] buckets[i];
    }
    delete[] buckets;
}