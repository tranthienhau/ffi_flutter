import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    Key? key,
    this.onPressed,
    this.borderColor,
    required this.child,
    this.padding = const EdgeInsets.only(top: 13, bottom: 13),
    this.borderRadius = 8,
    this.backgroundColor,
    this.height,
    this.width,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final Color? borderColor;
  final Color? backgroundColor;
  final Widget child;
  final EdgeInsets padding;
  final double? borderRadius;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius!),
        child: FlatButton(
          color: backgroundColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius!),
              side: BorderSide(
                  color: borderColor ?? Colors.transparent, width: 1)),
          padding: padding,
          onPressed: (){
            onPressed?.call();
          },
          child: child,
        ),
      ),
    );
  }
}
