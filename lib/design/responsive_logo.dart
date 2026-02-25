/// Document Search Logo Widget
import 'package:document_search/design/responsive_design.dart';
import 'package:flutter/material.dart';
class ResponsiveLogo extends StatelessWidget {
  const ResponsiveLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final logoWidth = width < 450 ? width * 0.8 : ResponsiveDesign.logoWidth(context);

    return SizedBox(
      width: logoWidth,
      child: Image.asset(
        'assets/document_search_logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
