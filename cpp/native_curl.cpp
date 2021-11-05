#include <stdint.h>
#include <iostream>
#include "curl.h"
#include "native_curl.h"
#include <string>
#include <iostream>



size_t writeFunction(void *ptr, size_t size, size_t nmemb, std::string* data) {
    data->append((char*) ptr, size * nmemb);
    return size * nmemb;
}


struct CurlFormData{
    const char* name;
    const char* value;
    int type;
};


extern "C" __attribute__((visibility("default"))) __attribute__((used))
struct CurlFormData create_form_data(const char* name,const char* value, int type)
{
    struct CurlFormData formData;
    formData.name = name;
    formData.value = value;
    formData.type = type;
    return formData;
}



extern "C" __attribute__((visibility("default"))) __attribute__((used))
const char* curl_post(const char* url, const char* cert_path, CurlFormData* forms, int formDataLength) {
    struct curl_httppost* post = NULL;
    struct curl_httppost* last = NULL;
    CURLFORMcode formrc;
    curl_global_init(CURL_GLOBAL_ALL);
    CURL *curl = curl_easy_init();
    if (curl) {
       #ifdef __ANDROID__
           // For https requests, you need to specify the ca-bundle path
           curl_easy_setopt(curl, CURLOPT_CAINFO, cert_path);
       #endif
       for (CurlFormData* formData = &forms[0]; formData < &forms[formDataLength]; formData++){
            int type = formData->type;
            const char* name = formData->name;
            const char* value = formData->value;

            //check type of CurlFormData: 0: text, 1:path of image
            switch (type) {
                case 0:
    //            long namelength = strlen(name);
                   formrc = curl_formadd(&post, &last, CURLFORM_COPYNAME, name,
                              CURLFORM_COPYCONTENTS, value, CURLFORM_END);

    //           curl_formadd(&post, &last, CURLFORM_PTRNAME, name,
    //                                    CURLFORM_PTRCONTENTS, value, CURLFORM_NAMELENGTH,
    //                                    namelength, CURLFORM_END);
                   break;
                case 1:
                   formrc = curl_formadd(&post, &last, CURLFORM_COPYNAME, name,
                              CURLFORM_FILE,value, CURLFORM_END);
                   break;
            }

        }

        curl_easy_setopt(curl, CURLOPT_HTTPPOST, post);

        curl_easy_setopt(curl, CURLOPT_URL, url);
        curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 1L);
        curl_easy_setopt(curl, CURLOPT_MAXREDIRS, 50L);
        curl_easy_setopt(curl, CURLOPT_TCP_KEEPALIVE, 1L);

        std::string response_string;
        std::string header_string;
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writeFunction);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response_string);
        curl_easy_setopt(curl, CURLOPT_HEADERDATA, &header_string);

        char* url;
        long response_code;
        double elapsed;
        curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &response_code);
        curl_easy_getinfo(curl, CURLINFO_TOTAL_TIME, &elapsed);
        curl_easy_getinfo(curl, CURLINFO_EFFECTIVE_URL, &url);

        curl_easy_perform(curl);
        curl_easy_cleanup(curl);
//        curl_formfree(formrc);
        curl_global_cleanup();
        curl = NULL;

         char * cstr = new char [response_string.length()];
         std::strcpy(cstr, response_string.c_str());

        return cstr;

    }

    return "Failed to init curl";
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
const char* curl_get(const char* url, const char* cert_path) {

    const char *response = "";


        curl_global_init(CURL_GLOBAL_ALL);
        CURL *curl = curl_easy_init();

           if (curl) {
               #ifdef __ANDROID__
                 // For https requests, you need to specify the ca-bundle path
                 curl_easy_setopt(curl, CURLOPT_CAINFO, cert_path);
               #endif

               curl_easy_setopt(curl, CURLOPT_URL, url);
               curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 1L);
               curl_easy_setopt(curl, CURLOPT_MAXREDIRS, 50L);
               curl_easy_setopt(curl, CURLOPT_TCP_KEEPALIVE, 1L);

               std::string response_string;
               std::string header_string;
               curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writeFunction);
               curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response_string);
               curl_easy_setopt(curl, CURLOPT_HEADERDATA, &header_string);

               char* url;
               long response_code;
               double elapsed;
               curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &response_code);
               curl_easy_getinfo(curl, CURLINFO_TOTAL_TIME, &elapsed);
               curl_easy_getinfo(curl, CURLINFO_EFFECTIVE_URL, &url);

               curl_easy_perform(curl);
               curl_easy_cleanup(curl);
               curl = NULL;

                char * cstr = new char [response_string.length()];
                std::strcpy(cstr, response_string.c_str());

               return cstr;
           }




    return response;
}


