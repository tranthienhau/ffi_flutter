#include <stdint.h>
#include <iostream>
#include "curl.h"
#include "native_curl.h"
#include <string>
#include <cstring>
#include <iostream>
#include <vector>
#ifdef __ANDROID__
#include <android/log.h>
#endif

#ifdef __ANDROID__
#define LOGI(...) \
  ((void)__android_log_print(ANDROID_LOG_VERBOSE, "native_curl:", __VA_ARGS__))
#endif


struct CurlFormData{
    std::string name;
    std::string value;
    int type;
};

///write out data from curl perform
size_t writeFunction(void *ptr, size_t size, size_t nmemb, std::string* data) {
    data->append((char*) ptr, size * nmemb);
    return size * nmemb;
}

//allocate form data pointer array
extern "C" __attribute__((visibility("default"))) __attribute__((used))
CurlFormData** allocate_form_data_pointer(int length){
    CurlFormData **form_data_pointer = new CurlFormData *[length];

    for(int i = 0; i < length; ++i) {
        form_data_pointer[i] = new CurlFormData();
    }

    return  form_data_pointer;
}

///set value for formdata pointer array, call [allocate_form_data_pointer] first
extern "C" __attribute__((visibility("default"))) __attribute__((used))
void set_value_formdata_pointer_array(CurlFormData** form_data_pointer, int index, const char* name, const char* value, int type ){
    form_data_pointer[index]->name = name;
    form_data_pointer[index]->value = value;
    form_data_pointer[index]->type = type;
}


extern "C" __attribute__((visibility("default"))) __attribute__((used))
const char* curl_post_form_data(const char* url, const char* cert_path, CurlFormData** forms, int length) {
    curl_global_init(CURL_GLOBAL_ALL);
    CURL *curl = curl_easy_init();
    if (curl) {
       #ifdef __ANDROID__
           // For https requests, you need to specify the ca-bundle path
           curl_easy_setopt(curl, CURLOPT_CAINFO, cert_path);
       #endif
        curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_easy_setopt(curl, CURLOPT_URL, url);
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
        curl_easy_setopt(curl, CURLOPT_DEFAULT_PROTOCOL, "https");

        curl_mime *mime;
        curl_mimepart *part;
        mime = curl_mime_init(curl);

       for (int index = 0; index < length; ++index){
            int type = forms[index]->type;
            const char* name = forms[index]->name.c_str();
            const char* value = forms[index]->value.c_str();
            part = curl_mime_addpart(mime);
            curl_mime_name(part, name);

            #ifdef __ANDROID__
            LOGI("curl_formadd: name:%s, value:%s, type:%d", name, value, type);
            #endif

            //check type of CurlFormData: 0: text, 1:path of file
            switch (type) {
                case 0:
                    curl_mime_data(part, value, CURL_ZERO_TERMINATED);
                   break;
                case 1:
                    curl_mime_filedata(part, value);
                   break;
            }

        }
        ///add multiple part formdata to curl
        curl_easy_setopt(curl, CURLOPT_MIMEPOST, mime);

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
        curl_mime_free(mime);
        curl_global_cleanup();
        curl = NULL;

         char * cstr = new char [response_string.length()];
         std::strcpy(cstr, response_string.c_str());

        for (int index = 0; index < length; ++index){
           delete forms[index];
        }

        delete[] forms;
        return cstr;
    }

    for (int index = 0; index < length; ++index){
       delete forms[index];
    }

    delete[] forms;
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