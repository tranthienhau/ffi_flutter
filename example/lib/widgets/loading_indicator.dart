import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({Key? key, this.backgroundColor, this.size = 50}) : super(key: key);
  final Color? backgroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.transparent,
      child: Center(
        child: SpinKitCircle(
          color: Theme.of(context).primaryColor,
          size: size,
        ),
      ),
    );
  }
}
