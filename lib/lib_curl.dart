import 'dart:ffi';

import 'dart:io';

class LibCurl {
  late DynamicLibrary _dylib;

  void init({String? libPath}){
    if (libPath != null) {
      _dylib = DynamicLibrary.open(libPath);
    } else if (Platform.isIOS) {
      _dylib = DynamicLibrary.process();
    }  else if (Platform.isAndroid) {
      _dylib = DynamicLibrary.open("libcurl.so");
    } else {
      // TODO: add windows, macos and linux
      throw Exception("Unsupported platform");
    }
  }
}
