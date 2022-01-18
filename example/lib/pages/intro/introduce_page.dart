import 'package:ffi_flutter_example/pages/opencv/gallery/ui/gallery_page.dart';
import 'package:ffi_flutter_example/pages/opencv/memory_filter/ui/memory_filter_page.dart';
import 'package:ffi_flutter_example/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

class IntroducePage extends StatefulWidget {
  const IntroducePage({Key? key}) : super(key: key);

  @override
  _IntroducePageState createState() => _IntroducePageState();
}

class _IntroducePageState extends State<IntroducePage> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        _buildImageBackground(),
        _buildGradientBackground1(),
        _buildGradientBackground1(),
        _buildContent(),
      ],
    );
  }

  Widget _buildImageBackground() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Image.asset(
        'assets/images/introduce_background.png',
        fit: BoxFit.fitWidth,
      ),
    );
  }

  Widget _buildGradientBackground1() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.389,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.5, 0.7, 1],
          colors: <Color>[
            const Color(0xff252223),
            const Color(0xff252223).withOpacity(0.9),
            const Color(0xff252223).withOpacity(0.6),
            const Color(0xff252223).withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientBackground2() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.195,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xff252223),
            const Color(0xff252223).withOpacity(0.5),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildContentHeader(),
            _buildContentButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildContentHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/icons/camera.svg',
              semanticsLabel: 'Acme Logo'),
          const SizedBox(width: 10),
          const Text(
            'IMAGES',
            style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildContentButtons() {
    return Column(
      children: [
        AppButton(
          backgroundColor: const Color(0xff005FF9),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return const GalleryPage();
                },
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/icons/photo_video.svg',
                  semanticsLabel: 'Acme Logo'),
              const SizedBox(width: 10),
              const Text(
                'Import from photo library',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AppButton(
          backgroundColor: const Color(0xff252223),
          onPressed: () async {
            final XFile? photo =
                await _picker.pickImage(source: ImageSource.camera);
            if (photo != null) {
              final bytes = await photo.readAsBytes();

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return MemoryFilterPage(
                      imagePath: photo.path,
                      thumnail: bytes,
                    );
                  },
                ),
              );
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/icons/camera_retro.svg',
                  semanticsLabel: 'Acme Logo'),
              const SizedBox(width: 10),
              const Text(
                'Take image from camera',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.12),
      ],
    );
  }
}
