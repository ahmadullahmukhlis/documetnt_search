import 'dart:io';
import 'package:document_search/design/responsive_logo.dart';
import 'package:document_search/design/responsive_search.dart';
import 'package:flutter/material.dart';
import 'package:document_search/screns/footer_screen.dart';



class GoogleSearchPage extends StatelessWidget {
  const GoogleSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            const ResponsiveLogo(),
            const SizedBox(height: 32),
            ResponsiveSearchField(),
            const SizedBox(height: 32),
            const Spacer(flex: 3),
            const ResponsiveFooter(),
          ],
        ),
      ),
    );
  }
}




