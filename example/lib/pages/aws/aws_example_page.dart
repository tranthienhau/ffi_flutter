import 'dart:io';
import 'dart:typed_data';

import 'package:ffi_flutter/native_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class AwsExamplePage extends StatefulWidget {
  const AwsExamplePage({Key? key}) : super(key: key);

  @override
  _AwsExamplePageState createState() => _AwsExamplePageState();
}

class _AwsExamplePageState extends State<AwsExamplePage> {
  final NativeCurl _nativeCurl = NativeCurl();

  List<String> _buckets = [];
  final NativeAws _nativeAws = NativeAws();

  String? _bucketSelection;
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

  File? _certFile;

  Future<void> _uploadFile() async {
    final ImagePicker _picker = ImagePicker();
    // Pick an image
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    reponse = 'Waiting for reponse';

    _loading = true;
    setState(() {});
    if (image != null && _bucketSelection != null) {
      final fileName = image.path.split('/').last;

      await _nativeAws.uploadFile(
          filePath: image.path,
          fileName: fileName,
          bucketName: _bucketSelection!);
    }

    _loading = false;
    setState(() {});
  }

  Future<void> _getBuckets() async {
    reponse = 'Waiting for reponse';

    _loading = true;
    setState(() {});

    _certFile ??= await writeCacert();
    _bucketSelection = null;

    String? certPath = _certFile?.path;
    if (certPath != null) {
      _nativeAws.init(
        certPath: certPath,
        accessKeyId: 'AKIA6O4PXIXCF5TCKN6H',
        secretKeyId: '1SIFGF+fxo2hY9PmE+efRlNyxMdKmgGMwO67u4cS',
      );
    }

    final result = await _nativeAws.getAllBuckets();

    _loading = false;
    if (result != null) {
      _buckets = result;
    }
    setState(() {});
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
                    _buildBucketSelection(),
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
                        onPressed: _getBuckets,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'Get list buckets',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_bucketSelection != null) _buildUploadImageView()
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

  Widget _buildBucketSelection() {
    return SizedBox(
      height: 50,
      child: DropdownButton<String>(
        value: _bucketSelection,
        icon: const Icon(Icons.arrow_downward),
        iconSize: 24,
        elevation: 16,
        isExpanded: false,
        style: const TextStyle(color: Colors.deepPurple),
        underline: Container(
          height: 2,
          color: Colors.deepPurpleAccent,
        ),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _bucketSelection = newValue;
            });
          }
        },
        items: _buckets.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              // textAlign: TextAlign.center,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUploadImageView() {
    return Material(
      color: Colors.blue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: _uploadFile,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'Upload image to bucket',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
