import 'package:flutter/material.dart';

import 'page_main.dart';

//void main() => runApp(MyApp()); //sucks
void main() {
  // add this, and it should be the first line in main method
  WidgetsFlutterBinding.ensureInitialized();

  // rest of your app code

  // MaterialApp not ready
//  runApp(
//    MyApp(),
//  );

  // MaterialApp ready
  runApp(MaterialApp(home: MyApp()));
}

