#include <stdint.h>
#include <iostream>
#include "curl.h"
#include "native_curl.h"
#include <string>
#include <cstring>
#include <iostream>
#include <vector>
#include <chrono>
#include <fstream>
#include <sstream>
#include <iostream>
#include <filesystem>
#ifdef __ANDROID__
#include <android/log.h>
#endif
using namespace std;

//Log to view in console
void platform_log(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
#ifdef __ANDROID__
    __android_log_vprint(ANDROID_LOG_VERBOSE, "native_curl:", fmt, args);
#else
    vprintf(fmt, args);
#endif
    va_end(args);
}

//curl reponse to dart side
struct CurlResponse{
    const char* data;
    int status;
};

//read file data to dart side convert to Uint8List
struct FileData{
    uint8_t* bytes;
    int length;
};

//curl form data use with [curl_post_form_data]
struct CurlFormData{
    string name;
    string value;
    int type;
};

//Write out data from curl perform
size_t writeFunction(void *ptr, size_t size, size_t nmemb, string* data) {
    data->append((char*) ptr, size * nmemb);
    return size * nmemb;
}

//Allocate form data pointer array
extern "C" __attribute__((visibility("default"))) __attribute__((used))
CurlFormData** allocate_form_data_pointer(int length){
    CurlFormData **form_data_pointer = new CurlFormData *[length];

    for(int i = 0; i < length; ++i) {
        form_data_pointer[i] = new CurlFormData();
    }

    return  form_data_pointer;
}

//Set value for formdata pointer array, call [allocate_form_data_pointer] first
extern "C" __attribute__((visibility("default"))) __attribute__((used))
void set_value_formdata_pointer_array(CurlFormData** form_data_pointer, int index, const char* name, const char* value, int type ){
    form_data_pointer[index]->name = name;
    form_data_pointer[index]->value = value;
    form_data_pointer[index]->type = type;
}

//Curl post form data
extern "C" __attribute__((visibility("default"))) __attribute__((used))
struct CurlResponse curl_post_form_data(const char* url, const char* cert_path, CurlFormData** forms, int length) {
    struct CurlResponse curl_response;
    curl_response.status = -1;
    curl_global_init(CURL_GLOBAL_ALL);
    CURL *curl = curl_easy_init();
    if (curl) {
        //In Android must be provided certificate file to access curl
        #ifdef __ANDROID__
           // For https requests, you need to specify the ca-bundle path
           curl_easy_setopt(curl, CURLOPT_CAINFO, cert_path);
        #endif
        curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "POST");
        curl_easy_setopt(curl, CURLOPT_URL, url);
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
        curl_easy_setopt(curl, CURLOPT_DEFAULT_PROTOCOL, "https");

        //Create multiple part formdata
        curl_mime *mime;
        curl_mimepart *part;
        mime = curl_mime_init(curl);

       for (int index = 0; index < length; ++index){
            int type = forms[index]->type;
            const char* name = forms[index]->name.c_str();
            const char* value = forms[index]->value.c_str();
            part = curl_mime_addpart(mime);
            curl_mime_name(part, name);

            platform_log("curl_formadd: name:%s, value:%s, type:%d", name, value, type);

            //Check type of CurlFormData: 0: text, 1:path of file
            switch (type) {
                case 0:
                    curl_mime_data(part, value, CURL_ZERO_TERMINATED);
                   break;
                case 1:
                    curl_mime_filedata(part, value);
                   break;
            }

        }
        //Add multiple part formdata to curl
        curl_easy_setopt(curl, CURLOPT_MIMEPOST, mime);

        string response_string;
        string header_string;
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


        //Release pointer array form data
        for (int index = 0; index < length; ++index){
           delete forms[index];
        }
        delete[] forms;
        
        //Get reponse data
        char* cstr = new char [response_string.length()];
        std::strcpy(cstr, response_string.c_str());
        curl_response.data = cstr;
        curl_response.status = (int) response_code;
        
        platform_log("curl_response:response:%s, code:%d", cstr, response_code);
        return curl_response;
    }

    //Release pointer array form data
    for (int index = 0; index < length; ++index){
       delete forms[index];
    }
    delete[] forms;
    
    //Return default value
    return curl_response;
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
struct CurlResponse curl_get(const char* url, const char* cert_path) {
    struct CurlResponse curl_response;
    curl_response.status = -1;
  
        curl_global_init(CURL_GLOBAL_ALL);
        CURL *curl = curl_easy_init();

           if (curl) {
               #ifdef __ANDROID__
                 // For https requests, you need to specify the ca-bundle path
                 curl_easy_setopt(curl, CURLOPT_CAINFO, cert_path);
               #endif
               curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, "GET");
               curl_easy_setopt(curl, CURLOPT_URL, url);
               curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
               curl_easy_setopt(curl, CURLOPT_DEFAULT_PROTOCOL, "https");

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

               curl_response.data = cstr;
               curl_response.status = (int) response_code;
               
               platform_log("curl_response:response:%s, code:%d", cstr, response_code);
               return curl_response;
           }

    return curl_response;
}


size_t write_file_call_back(void* buf, size_t size, size_t nmemb, void* userp)
{
    if (userp)
    {
        std::ostream& os = *static_cast<std::ostream*>(userp);
        std::streamsize len = size * nmemb;
        if (os.write(static_cast<char*>(buf), len))
            return len;
    }

    return 0;
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
struct CurlResponse download_file(const char* url, const char* cert_path,  const char* save_path) {
    
    struct CurlResponse curl_response;
    curl_response.status = -1;
    std::ofstream os(save_path, std::ostream::binary);

    platform_log("start download file:save_path:%s, url:%s", save_path, url);
    curl_global_init(CURL_GLOBAL_ALL);
    CURL *curl = curl_easy_init();

    if (curl) {
        #ifdef __ANDROID__
        // For https requests, you need to specify the ca-bundle path
        curl_easy_setopt(curl, CURLOPT_CAINFO, cert_path);
        #endif
        
        curl_easy_setopt(curl, CURLOPT_URL, url);
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
        curl_easy_setopt(curl, CURLOPT_DEFAULT_PROTOCOL, "https");
        curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 1L);
//        string response_string;
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_file_call_back);
        curl_easy_setopt(curl, CURLOPT_FILE, &os);

//        char* url;
//        long response_code;
//        double elapsed;
//        curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &response_code);
//        curl_easy_getinfo(curl, CURLINFO_TOTAL_TIME, &elapsed);
//        curl_easy_getinfo(curl, CURLINFO_EFFECTIVE_URL, &url);

        CURLcode code = curl_easy_perform(curl);
        curl_easy_cleanup(curl);
        curl = NULL;
            
        if(code == CURLE_OK){
            char * cstr = new char [strlen(save_path)];
            std::strcpy(cstr, save_path);

            curl_response.data = cstr;
            curl_response.status = 200;
            platform_log("download successful");
            
            return curl_response;
        }
        curl_response.data = "Failed to download file";

        return curl_response;
    }
    
    return curl_response;
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
FileData read_file(const char* file_path) {
    
    std::ifstream instream(file_path, std::ios::in | std::ios::binary);
    std::vector<uint8_t> vec((std::istreambuf_iterator<char>(instream)), std::istreambuf_iterator<char>());
    
    uint8_t *result = vec.data();
    
    FileData fileData;
    fileData.bytes = result;
    fileData.length = (int) vec.size();
    
    return fileData;
}
