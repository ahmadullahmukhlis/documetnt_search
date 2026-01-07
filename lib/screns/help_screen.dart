import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.help_outline_rounded,
                  size: 90,
                  color: Colors.blue,
                ),

                const SizedBox(height: 16),

                const Text(
                  'How can we help you?',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Follow the steps below to use the document search app effectively.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),

                const SizedBox(height: 32),

                _helpCard(
                  step: 'Step 1',
                  title: 'Select a Folder',
                  icon: Icons.folder_open,
                  content:
                  'Click on the “Select Folder” button and choose a directory from your device. '
                      'The app will automatically scan all supported documents inside the folder.',
                ),

                _helpCard(
                  step: 'Step 2',
                  title: 'Load Documents',
                  icon: Icons.description,
                  content:
                  'Once a folder is selected, the app loads documents such as PDF and DOCX files. '
                      'Large folders may take a few seconds to process.',
                ),

                _helpCard(
                  step: 'Step 3',
                  title: 'Search Inside Documents',
                  icon: Icons.search,
                  content:
                  'Enter a keyword or phrase in the search box. '
                      'The app searches across all loaded documents and highlights matching results.',
                ),

                _helpCard(
                  step: 'Step 4',
                  title: 'View Results',
                  icon: Icons.find_in_page,
                  content:
                  'Click on a result to view the document content. '
                      'You can quickly jump to the matched text inside the file.',
                ),

                _helpCard(
                  step: 'Tips',
                  title: 'Helpful Tips',
                  icon: Icons.lightbulb_outline,
                  content:
                  '• Use specific keywords for better results\n'
                      '• Make sure documents are text-based (not scanned images)\n'
                      '• Keep folder sizes reasonable for faster loading\n'
                      '• Restart the app if files change inside the folder',
                ),

                const SizedBox(height: 24),

                const Divider(),

                const SizedBox(height: 12),

                const Text(
                  'Need more help?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Visit the Contact page to reach us for further assistance.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),

                const SizedBox(height: 24),

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

  Widget _helpCard({
    required String step,
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
            Column(
              children: [
                Text(
                  step,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 6),
                Icon(icon, size: 28, color: Colors.blue),
              ],
            ),
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
