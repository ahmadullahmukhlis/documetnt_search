import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.contact_support_outlined,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Get in Touch',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'If you have questions, feedback, or need help using the document search feature, feel free to contact us.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),

                const SizedBox(height: 32),

                // Email
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.blue),
                  title: const Text('Email'),
                  subtitle: const Text('AHmadullahmukhlis2019@gmail.com'),
                  onTap: () {
                    _launchUrl(
                      'mailto:AHmadullahmukhlis2019@gmail.com',
                    );
                  },
                ),

                // Phone / WhatsApp
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.green),
                  title: const Text('Phone / WhatsApp'),
                  subtitle: const Text('+93 779 404 681'),
                  onTap: () {
                    _launchUrl('tel:+93779404681');
                  },
                ),

                const SizedBox(height: 24),

                const Divider(),

                const SizedBox(height: 16),

                const Text(
                  'Follow on Social Media',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Facebook',
                      icon: const Icon(Icons.facebook, size: 30),
                      onPressed: () {
                        _launchUrl('https://facebook.com/');
                      },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      tooltip: 'LinkedIn',
                      icon: const Icon(Icons.work, size: 30),
                      onPressed: () {
                        _launchUrl('https://linkedin.com/');
                      },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      tooltip: 'GitHub',
                      icon: const Icon(Icons.code, size: 30),
                      onPressed: () {
                        _launchUrl('https://github.com/');
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                const Text(
                  '© 2026 Ahmadullah Mukhlis',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
