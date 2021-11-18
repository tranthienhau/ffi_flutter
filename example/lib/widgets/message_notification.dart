import 'package:flutter/material.dart';

class MessageNotification extends StatelessWidget {
  final String? title;
  final String? subTitle;
  final Widget? leading;
  final Widget? trailing;

  const MessageNotification(
      {Key? key, this.title, this.subTitle, this.leading, this.trailing})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget? titleWidget;
    Widget? subtitleWidget;
    if(title == null){
      titleWidget = Text(
        subTitle ?? '',
        style: const TextStyle(
          color: Colors.grey,
        ),
      );
    }else{
      titleWidget = Text(
        title ?? '',
        style: const TextStyle(
          color: Colors.grey,
        ),
      );

      subtitleWidget = Text(
        subTitle ?? '',
        style: const TextStyle(
          color: Colors.grey,
        ),
      );

    }



    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      elevation: 5,
      child: SafeArea(
        child: ListTile(
          leading: leading,
          title: titleWidget,
          subtitle: subtitleWidget,
          trailing: trailing,
          horizontalTitleGap: 0.0,
        ),
      ),
    );
  }
}
