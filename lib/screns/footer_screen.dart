import 'package:document_search/design/responsive_design.dart';
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
        _buildFooterLink('About', context),
        _buildFooterLink('Privacy', context),
        _buildFooterLink('Terms', context),
      ],
    );
  }

  Widget _buildFooterLinksRow2(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        _buildFooterLink('Settings', context),
        _buildFooterLink('Help', context),
        _buildFooterLink('Contact', context),
      ],
    );
  }

  Widget _buildFooterLink(String text, BuildContext context) {
    return TextButton(
      onPressed: () {},
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