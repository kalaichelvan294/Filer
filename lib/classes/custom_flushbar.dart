import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';

class FlushbarCustom {
  /// Get an information notification flushbar
  static Flushbar internetDisabled(){
    return Flushbar(
      titleText :  Text(
        "Internet disabled",
        style: TextStyle(
          color:Colors.white,
        ),
      ),
      message:  "Filer requires internet to get files",
      backgroundColor: Colors.black,
      flushbarPosition: FlushbarPosition.BOTTOM,
      flushbarStyle: FlushbarStyle.GROUNDED,
      reverseAnimationCurve: Curves.decelerate,
      forwardAnimationCurve: Curves.elasticOut,
      isDismissible: true,
      duration:  Duration(seconds: 5),
      leftBarIndicatorColor: Colors.red,            
      icon: Icon(
        Icons.signal_cellular_connected_no_internet_4_bar,
        color: Colors.red,
        ),
    );
  }

  static Flushbar internetEnabled(){
    return Flushbar(
      titleText:  Text(
        "Internet Enabled",
        style: TextStyle(
          color:Colors.white,
        ),
      ),
      backgroundColor: Colors.black,
      message:  " ",
      flushbarPosition: FlushbarPosition.BOTTOM,
      flushbarStyle: FlushbarStyle.GROUNDED,
      reverseAnimationCurve: Curves.decelerate,
      forwardAnimationCurve: Curves.elasticOut,
      isDismissible: true,
      duration:  Duration(seconds: 2),
      leftBarIndicatorColor: Colors.lightGreen,            
      icon: Icon(
        Icons.check,
        color: Colors.lightGreen,
        ),
    );
  }


static Flushbar buildFlusbar(String ttitle, String tmessage, String level)
{
  return Flushbar(
        titleText:  Text(
          ttitle,
          style: TextStyle(
            color:Colors.white,
          ),
        ),
        message:  tmessage,
        backgroundColor: Colors.black,
        flushbarPosition: FlushbarPosition.BOTTOM,
        flushbarStyle: FlushbarStyle.GROUNDED,
        reverseAnimationCurve: Curves.decelerate,
        forwardAnimationCurve: Curves.elasticOut,
        isDismissible: true,
        duration:  Duration(seconds: 5),
        leftBarIndicatorColor: Colors.orangeAccent,
        icon: Icon(
          Icons.warning,
          color: Colors.orangeAccent,
          ),
      );
}


}
