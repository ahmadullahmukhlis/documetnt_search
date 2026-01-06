import 'package:flutter/material.dart';
// Responsive Design Helper Class
class ResponsiveDesign {
  static double logoWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return width * 0.9;
    if (width < 400) return width * 0.8;
    if (width < 600) return width * 0.7;
    if (width < 900) return 272;
    return 300;
  }

  static double logoFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return 20;
    if (width < 400) return 24;
    if (width < 600) return 32;
    return 40;
  }

  static double searchFieldWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return width * 0.95;
    if (width < 400) return width * 0.9;
    if (width < 600) return width * 0.85;
    if (width < 900) return 584;
    return 692;
  }

  static double searchFieldHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return 40;
    if (width < 400) return 44;
    if (width < 600) return 48;
    return 52;
  }

  static double searchFieldHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return 8;
    if (width < 400) return 12;
    if (width < 600) return 16;
    return 24;
  }

  static double iconSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return 16;
    if (width < 400) return 18;
    if (width < 600) return 20;
    return 22;
  }

  static double textFieldFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return 13;
    if (width < 400) return 14;
    if (width < 600) return 15;
    return 16;
  }

  static double buttonFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return 12;
    if (width < 400) return 13;
    if (width < 600) return 14;
    return 15;
  }

  static double buttonHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return 8;
    if (width < 400) return 12;
    if (width < 600) return 16;
    return 20;
  }

  static double contentHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return 12;
    if (width < 400) return 16;
    if (width < 600) return 20;
    if (width < 900) return 24;
    return 32;
  }

  static double smallFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 350) return 10;
    if (width < 400) return 11;
    if (width < 600) return 12;
    return 13;
  }
}