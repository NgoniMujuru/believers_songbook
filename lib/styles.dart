// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

abstract class Styles {
  static const TextStyle productRowItemName = TextStyle(
    color: Color.fromRGBO(0, 0, 0, 0.8),
    fontSize: 20,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle appInfo = TextStyle(
    color: Color.fromRGBO(0, 0, 0, 0.8),
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle searchText = TextStyle(
    color: Color.fromRGBO(0, 0, 0, 1),
    fontSize: 14,
  );

  static const TextStyle searchTextDark = TextStyle(
    color: Colors.white,
    fontSize: 14,
  );

  static const TextStyle link =
      TextStyle(color: Color.fromARGB(255, 46, 125, 0), fontSize: 16.0);

  static const Color scaffoldBackground = Colors.white;

  static const Color searchBackground = Color.fromARGB(255, 240, 248, 224);
  static Color searchBackgroundDark = Colors.grey.shade700;

  static const Color searchCursorColor = Color.fromARGB(255, 46, 125, 0);
  static const Color searchCursorColorDark = Colors.white;

  static const Color searchIconColor = Color.fromRGBO(128, 128, 128, 1);
  static const Color searchIconColorDark = Colors.white;

  static const Color themeColor = Color.fromRGBO(46, 125, 0, 1);
}
