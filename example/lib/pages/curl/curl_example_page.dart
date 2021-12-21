import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi_flutter/native_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class CurlExamplePage extends StatefulWidget {
  const CurlExamplePage({Key? key}) : super(key: key);

  @override
  _CurlExamplePageState createState() => _CurlExamplePageState();
}

class _CurlExamplePageState extends State<CurlExamplePage> {
  final NativeCurl _nativeCurl = NativeCurl();

  NativeAws? _nativeAws;
  String? _imageUrl;
  Uint8List? _imageBytes;
  String? _imagePath;
  bool _loading = false;

  bool _init = false;

  @override
  void initState() {
    super.initState();
  }

  String reponse = '';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> _writeCacert() async {
    final path = await _localPath;
    ByteData data = await rootBundle.load('assets/cacert.pem');
    final cacertFile = File('$path/cacert.pem');
    final buffer = data.buffer;

    await cacertFile.writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));

    return cacertFile;
  }

  File? _certFile;



  Future<void> _uploadImage() async {
    final ImagePicker _picker = ImagePicker();
    // Pick an image
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    reponse = 'Waiting for reponse';
    _imagePath = null;
    _imageBytes = null;
    _imageUrl = null;
    _loading = true;
    setState(() {});

    if (!_init) {
      _certFile ??= await _writeCacert();
      _nativeCurl.init(_certFile!.path);
      _init = true;
    }

    if (_certFile != null && image != null) {
      final reponseData = await _nativeCurl.postFormData(
        url: 'https://api.kraken.io/v1/upload',
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
        ],
      );

      final data = reponseData?.data;
      if (data != null) {
        reponse = data;
      }

      try {
        final map = json.decode(reponse);
        if (map is Map) {
          _imageUrl = map['kraked_url'];
        }
      } catch (_) {}
    }

    _loading = false;
    setState(() {});
  }

  Future<void> _downloadImage() async {
    _loading = true;
    setState(() {});

    _certFile ??= await _writeCacert();
    final imageUrl = _imageUrl;
    if (_certFile != null && imageUrl != null) {
      final path = await _localPath;
      String fileName = imageUrl.split('/').last;
      // final fileExtension = fileName.split('.').last;
      fileName = fileName.replaceAll('-', '_');
      final reponseData = await _nativeCurl.downloadFile(
        url: imageUrl,
        savePath: '$path/$fileName',
      );
      final filePath = reponseData.data;
      if (filePath != '') {
        _imagePath = filePath;
      }

      print(reponseData.data);
      setState(() {});
      _loading = false;
    }
  }

  Future<void> _readFile() async {
    _loading = true;
    setState(() {});

    final imagePath = _imagePath;

    if (imagePath != null) {
      final bytes = await NativeIO.readFile(imagePath);
      if (bytes != null) {
        _imageBytes = bytes;
      }
      _loading = false;
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
            SizedBox(
              height: double.infinity,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const SizedBox(height: 10),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed: () {
                          _uploadImage();
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'Upload file from network with curl',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_imageUrl != null) ..._buildDownLoadImage(),
                    if (_imagePath != null) ..._buildReadImage(),
                    const SizedBox(height: 10),
                    if (_imageBytes != null) _buildImage(_imageBytes!),
                  ],
                ),
              ),
            ),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.red,
                ),
              )
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDownLoadImage() {
    return [
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Text(
            'Image url: $_imageUrl',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      const SizedBox(height: 10),
      Material(
        color: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextButton(
          onPressed: () {
            _downloadImage();
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Download',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildReadImage() {
    return [
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Text(
            'Image path: $_imagePath',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      const SizedBox(height: 10),
      Material(
        color: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextButton(
          onPressed: () {
            _readFile();
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Read image path',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildImage(Uint8List bytes) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Image.memory(
        bytes,
        fit: BoxFit.cover,
      ),
    );
  }
}
