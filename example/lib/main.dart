import 'package:ffi_flutter/ffi_flutter.dart';
import 'package:flutter/material.dart';

import 'package:overlay_support/overlay_support.dart';

import 'pages/aws/aws_example_page.dart';
import 'pages/curl/curl_example_page.dart';
import 'pages/opencv/gallery/ui/gallery_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: MaterialApp(
        home: _buildBodyExamples(),
      ),
    );
  }

  Widget _buildBodyExamples() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Builder(
        builder: (context) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNavigateButton(
                  title: 'Curl example page',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) {
                          return const CurlExamplePage();
                        },
                      ),
                    );
                  }),
              // _buildNavigateButton(
              //   title: 'Aws example page',
              //   onPressed: () {
              //     Navigator.of(context).push(
              //       MaterialPageRoute(
              //         builder: (BuildContext context) {
              //           return const AwsExamplePage();
              //         },
              //       ),
              //     );
              //   },
              // ),
              _buildNavigateButton(
                  title: 'Camera filter page',
                  onPressed: () {
                    FfiFlutter.openCameraFilter();
                  }),
              _buildNavigateButton(
                title: 'Gallayer filter page',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return const GalleryPage();
                      },
                    ),
                  );
                },
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildBodyOpencv() {
    return const GalleryPage();
  }

  Widget _buildNavigateButton(
      {void Function()? onPressed, required String title}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Material(
          color: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextButton(
            onPressed: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
