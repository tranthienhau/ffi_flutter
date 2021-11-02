#include <stdint.h>
#include "curl.h"
#include <string>
#include <iostream>
size_t writeFunction(void *ptr, size_t size, size_t nmemb, std::string* data) {
    data->append((char*) ptr, size * nmemb);
    return size * nmemb;
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
const char* curl_get(const char* url) {
    
    const char *response = "";
    CURL *curl = curl_easy_init();

       if (curl) {
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


