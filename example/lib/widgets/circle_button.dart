import 'package:flutter/material.dart';

class CircleButton extends StatelessWidget {
  const CircleButton({
    Key? key,
    this.size = 40,
    this.backgroundColor = Colors.transparent,
    required this.child,
    this.onPressed,
  }) : super(key: key);

  final double size;
  final Color backgroundColor;
  final Widget child;
  final Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: backgroundColor,
          child: IconButton(
            icon: child,
            padding: EdgeInsets.zero,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
