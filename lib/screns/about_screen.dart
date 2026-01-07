import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.folder_open_rounded,
                  size: 90,
                  color: Colors.blue,
                ),

                const SizedBox(height: 16),

                const Text(
                  'Document Search App',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Search smarter. Find faster.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 32),

                _infoCard(
                  title: 'What this app does',
                  icon: Icons.description_outlined,
                  content:
                  'This application allows users to select a folder from their device, automatically load all supported documents, and perform fast text search across files such as PDF and DOCX.',
                ),

                _infoCard(
                  title: 'How it works',
                  icon: Icons.search,
                  content:
                  '1. Select a folder\n'
                      '2. The app scans and loads all documents\n'
                      '3. Enter a keyword to search\n'
                      '4. Instantly find matching content inside your documents',
                ),

                _infoCard(
                  title: 'Why use this app',
                  icon: Icons.lightbulb_outline,
                  content:
                  '• Saves time searching documents\n'
                      '• Works offline\n'
                      '• Simple and clean interface\n'
                      '• Designed for students, researchers, and professionals',
                ),

                _infoCard(
                  title: 'Developer',
                  icon: Icons.person_outline,
                  content:
                  'Developed by Ahmadullah Mukhlis.\n'
                      'Built with Flutter for cross-platform support.',
                ),

                const SizedBox(height: 24),

                const Divider(),

                const SizedBox(height: 12),

                const Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 8),

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

  Widget _infoCard({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
