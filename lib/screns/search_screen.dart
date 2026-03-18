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
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const ResponsiveLogo(),
                  const SizedBox(height: 20),
                  // Make the search field widget take remaining space properly
                  Expanded(
                    child: SingleChildScrollView(
                      child: ResponsiveSearchField(),
                    ),
                  ),
                ],
              ),
            ),
            const ResponsiveFooter(),
          ],
        ),
      ),
    );
  }
}