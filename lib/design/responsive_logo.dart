/// Google Logo Widget
import 'package:document_search/design/responsive_design.dart';
import 'package:flutter/material.dart';
class ResponsiveLogo extends StatelessWidget {
  const ResponsiveLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 350) {
      return SizedBox(
        width: width * 0.8,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTextPart('A', Colors.blue, context),
                _buildTextPart('P', Colors.blue, context),
                _buildTextPart('S', Colors.green, context),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'Ps',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      );
    } else if (width < 450) {
      return SizedBox(
        width: width * 0.9,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [_buildTextPart('A', Colors.blue, context)],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTextPart('P', Colors.blue, context),
                    SizedBox(width: 4),
                    _buildTextPart('S', Colors.green, context),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: ResponsiveDesign.logoWidth(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTextPart('A', Colors.blue, context),
          SizedBox(width: width < 600 ? 2 : 4),
          _buildTextPart('P', Colors.blue, context),
          SizedBox(width: width < 600 ? 2 : 4),
          _buildTextPart('S', Colors.green, context),
        ],
      ),
    );
  }

  Widget _buildTextPart(String text, Color color, BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double fontSize;

    if (width < 350) {
      fontSize = 20;
    } else if (width < 400) {
      fontSize = 24;
    } else if (width < 450) {
      fontSize = 28;
    } else if (width < 600) {
      fontSize = 32;
    } else {
      fontSize = ResponsiveDesign.logoFontSize(context);
    }

    return Flexible(
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}