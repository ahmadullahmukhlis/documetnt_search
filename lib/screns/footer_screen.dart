import 'package:document_search/design/responsive_design.dart';
import 'package:document_search/screns/about_screen.dart';
import 'package:document_search/screns/contact_screen.dart';
import 'package:document_search/screns/help_screen.dart';
import 'package:document_search/screns/privacy_screen.dart';
import 'package:document_search/screns/term_screen.dart';
import 'package:flutter/material.dart';
class ResponsiveFooter extends StatelessWidget {
  const ResponsiveFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      width: double.infinity,
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const Divider(height: 1, color: Colors.grey),
          const SizedBox(height: 8),

          // Footer Links
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveDesign.contentHorizontalPadding(context),
            ),
            child: isSmallScreen
                ? Column(
              children: [
                _buildFooterLinksRow1(context),
                const SizedBox(height: 8),
                _buildFooterLinksRow2(context),
              ],
            )
                : Row(
              children: [
                Expanded(child: _buildFooterLinksRow1(context)),
                _buildFooterLinksRow2(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLinksRow1(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: [
        _buildFooterLink('About', context ,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AboutScreen()),
            );
          },
        ),
        _buildFooterLink('Privacy', context , onTap: (){
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrivacyScreen()),
          );

        }),
        _buildFooterLink('Terms', context ,onTap: (){
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TermsScreen()),
          );

        }),
      ],
    );
  }

  Widget _buildFooterLinksRow2(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        _buildFooterLink('Help', context , onTap: (){
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HelpScreen()),
          );

        }),
        _buildFooterLink('Contact', context,onTap: (){
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ContactScreen()),
          );

        }),
      ],
    );
  }

  Widget _buildFooterLink(
      String text,
      BuildContext context, {
        VoidCallback? onTap,  // Optional onTap callback
      }) {
    return TextButton(
      onPressed: onTap ?? () {},  // Use provided callback or empty default
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(0, 0),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: ResponsiveDesign.smallFontSize(context),
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}