import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:overlay_support/overlay_support.dart';

import 'message_notification.dart';

class ToastUtils {
  static done({String? title, required String subTitle}) {
    showSimpleNotification(
      MessageNotification(
        subTitle: subTitle,
        title: title,
        leading: const Icon(
          FontAwesomeIcons.solidCheckCircle,
          color: Colors.green,
        ),
      ),
      background: Colors.transparent,
      elevation: 0,
    );
  }

  static error({String? title, required String error}) {
    showSimpleNotification(
      MessageNotification(
        title: title,
        subTitle: error,
        leading: const Icon(
          FontAwesomeIcons.exclamationCircle,
          color: Colors.redAccent,
        ),
      ),
      background: Colors.transparent,
      elevation: 0,
    );
  }
}
