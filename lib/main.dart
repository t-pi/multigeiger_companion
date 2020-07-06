// Project: MultiGeiger Companion
// (c) 2020 by the authors, see AUTHORS file in toplevel directory.
// Licensed under the MIT license, see LICENSE file in toplevel directory.

import 'package:flutter/material.dart';
import 'screen_companion.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MultiGeiger Companion',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: CompanionScreen(),
    );
  }
}
