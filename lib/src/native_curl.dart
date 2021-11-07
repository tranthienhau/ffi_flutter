import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:native_add/native_curl.dart';

class NativeCurl {
  static final NativeCurl _instance = NativeCurl._internal();

  factory NativeCurl() {
    return _instance;
  }

  NativeCurl._internal();

  ///Add certificates to path
  Future<void> init(String certPath) async {
    certPath = certPath;
  }

  ///In Android to use curl we must provide a certificates file
  late String certPath;

  ///[url]: url to get data
  ///[certPath]: in Android, you must save certificates.pem and provide [certPath] to access to https
  String curlGet(String url, String certPath) {
    ///convert url and certPath to Pointer to pass to native
    final Pointer<Utf8> urlPointer = url.toNativeUtf8();

    final Pointer<Utf8> certPathPointer = certPath.toNativeUtf8();

    ///call native curl get
    final response = nativeCurlGet(urlPointer, certPathPointer);

    ///free pointer
    calloc.free(urlPointer);
    calloc.free(certPathPointer);

    ///convert Pointer to string in dart
    final result = response.toDartString();

    return result;
  }

  ///Convert [formDataList] to native Pointer to pass to [nativeCurlPost]
  static Pointer _createFormDataToArray(List<FormData> formDataList) {
    final formDataPtr = createPointerArrayFormData(formDataList.length);
    int pointerIndex = 0;
    for (final formData in formDataList) {
      final name = formData.name;
      final value = formData.value;

      ///convert url and certPath to Pointer to pass to native
      final Pointer<Utf8> namePointer = name.toNativeUtf8();

      final Pointer<Utf8> valuePointer = value.toNativeUtf8();

      setValueFormDataArrayPointer(
        formDataPtr,
        pointerIndex,
        namePointer,
        valuePointer,
        formData.type.index,
      );

      ///free pointer
      calloc.free(namePointer);
      calloc.free(valuePointer);
      pointerIndex++;
    }

    return formDataPtr;
  }

  ///[url]: url to get data
  ///[certPath]: in Android, you must save certificates.pem and provide [certPath] to access to https
  String postFormData({
    required String url,
    required String certPath,
    required List<FormData> formDataList,
  }) {
    ///convert url and certPath to Pointer to pass to native
    final Pointer<Utf8> urlPointer = url.toNativeUtf8();

    final Pointer<Utf8> certPathPointer = certPath.toNativeUtf8();

    final Pointer formDataPointer = _createFormDataToArray(formDataList);

    final response = nativeCurlPost(
        urlPointer, certPathPointer, formDataPointer, formDataList.length);

    ///free pointer
    calloc.free(urlPointer);
    calloc.free(certPathPointer);

    ///convert Pointer to string in dart
    final result = response.toDartString();

    return result;
  }

  ///[url]: url to get data
  ///[certPath]: in Android, you must save certificates.pem and provide [certPath] to access to https
  Future<String> postFormDataInBackground({
    required String url,
    required String certPath,
    required List<FormData> formDataList,
  }) async {
    ///await isolate complete
    Completer<String> _resultCompleter = Completer<String>();

    ///create receiport to get response
    final port = ReceivePort();

    // IsolateNameServer.registerPortWithName(
    //     port.sendPort, 'isolateCurlPostFormData');

    /// Spawning an isolate
    Isolate.spawn<Map<String, dynamic>>(
      _isolateCurlPostFormData,
      {
        'url': url,
        'certPath': certPath,
        'formDataList': formDataList,
        'sendPort': port.sendPort,
      },
      onError: port.sendPort,
      onExit: port.sendPort,
    );

    port.listen((message) {
      ///ensure not call more than one times
      if (_resultCompleter.isCompleted) {
        return;
      }

      ///Complete wait data
      _resultCompleter.complete(message);
    });

    ///wait for send port return data
    final result = await _resultCompleter.future;

    return result;
  }

  static void _isolateCurlPostFormData(Map<String, dynamic> data) {
    /// get data
    final String url = data['url'];
    final String certPath = data['certPath'];
    final SendPort sendPort = data['sendPort'];
    final List<FormData> formDataList = data['formDataList'];

    // SendPort.lookupPortByName();
    ///convert url and certPath to Pointer to pass to native
    final Pointer<Utf8> urlPointer = url.toNativeUtf8();

    final Pointer<Utf8> certPathPointer = certPath.toNativeUtf8();

    final Pointer formDataPointer = _createFormDataToArray(formDataList);

    ///call native curl post form data
    final response = nativeCurlPost(
      urlPointer,
      certPathPointer,
      formDataPointer,
      formDataList.length,
    );

    ///free pointer
    calloc.free(urlPointer);
    calloc.free(certPathPointer);

    ///convert Pointer to string in dart
    final result = response.toDartString();

    sendPort.send(result);
  }
}
