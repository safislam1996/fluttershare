import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

header(context,{isAppTittle=false,String titleText,removeBackButton=false}) {
  return AppBar(
    automaticallyImplyLeading: removeBackButton?false:true,
    title: Text(

      isAppTittle?"FlutterShare":titleText,
      style: TextStyle(
          color: Colors.white,
          fontSize: isAppTittle?50.0:22.0,
          fontFamily: isAppTittle?'Signatra':''),overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).accentColor,
  );
}
