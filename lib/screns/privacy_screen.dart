import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: const Text(
              '''
Privacy Policy

Your privacy is important to us. This application is designed to respect your privacy and protect your personal data.

1. Data Collection
This app does not collect, store, or transmit any personal information. All documents remain on your device and are never uploaded to any server.

2. File Access
The app only accesses files and folders that you explicitly select. It reads document content solely for the purpose of searching text inside your files.

3. Internet Usage
This application works completely offline. No internet connection is required to search or read your documents.

4. Third-Party Services
The app does not use third-party analytics, tracking tools, or advertising services.

5. Security
All processing is done locally on your device. We do not save or share your documents, search queries, or results.

6. Changes to This Policy
This privacy policy may be updated in the future to reflect improvements or changes in the app. Any updates will be shown within the application.

7. Contact
If you have any questions or concerns about this privacy policy, please contact us through the Contact page.

By using this application, you agree to this privacy policy.
              ''',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
