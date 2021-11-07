import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:native_add/native_curl.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final NativeCurl _nativeCurl = NativeCurl();

  bool _loading = false;
  @override
  void initState() {
    super.initState();
  }

  String reponse = '';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> writeCacert() async {
    final path = await _localPath;
    ByteData data = await rootBundle.load('assets/cacert.pem');
    final cacertFile = File('$path/cacert.pem');
    final buffer = data.buffer;

    await cacertFile.writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));

    return cacertFile;
  }

  File? certFile;

  Future<void> curlGet() async {
    reponse = 'Waiting for reponse';
    setState(() {});
    certFile ??= await writeCacert();

    if (certFile != null) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        reponse = _nativeCurl.curlGet(
            "https://api.genderize.io/?name=luc", certFile!.path);
        setState(() {});
      });
    }
  }

  Future<void> testCreateFormData() async {
    final ImagePicker _picker = ImagePicker();
    // Pick an image
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    reponse = 'Waiting for reponse';
    setState(() {});
    certFile ??= await writeCacert();
    if (certFile != null && image != null) {
      _loading = true;
      final imageUrl = await _nativeCurl.postFormDataInBackground(
          url: 'https://api.kraken.io/v1/upload',
          certPath: certFile!.path,
          formDataList: [
            FormData(
              type: FormDataType.file,
              name: 'upload',
              value: image.path,
            ),
            FormData(
              type: FormDataType.text,
              value:
                  "{\"auth\":{\"api_key\": \"42e4ab284ddbc382444d292743c2c861\", "
                  "\"api_secret\": \"c2ccdf0f9803f25e26f0f98b3de208220d862237\"}, "
                  "\"wait\":true"
                  "}",
              name: 'data',
            ),
          ]);
      _loading = false;
      reponse = imageUrl;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Text(
                      'Reponse: $reponse',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextButton(
                    onPressed: () {
                      testCreateFormData();
                      // curlGet();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Get data from network with curl',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
            if(_loading)
              const  Center(child:  CircularProgressIndicator())
          ],
        ),
      ),
    );
  }
}
