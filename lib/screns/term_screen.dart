import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: const Text(
              '''
Terms & Conditions

By using this application, you agree to the following terms and conditions. Please read them carefully.

1. Usage
This application is provided to help users search and view text inside their own documents. You are responsible for the files you choose to load and search.

2. Ownership
All documents accessed by the app remain the property of their respective owners. The application does not claim ownership of any user files.

3. Data Responsibility
The app processes files locally on your device. The developer is not responsible for the content, accuracy, or legality of the documents you use.

4. Limitations
The application is provided "as is" without warranties of any kind. While efforts are made to ensure accurate search results, the app does not guarantee error-free operation.

5. Prohibited Use
You agree not to use this application for any illegal, harmful, or unauthorized purposes.

6. Modifications
The developer may update or modify the application at any time without prior notice to improve functionality or security.

7. Liability
The developer is not liable for any data loss, system damage, or other issues resulting from the use of this application.

8. Termination
Access to the application may be suspended or terminated if these terms are violated.

9. Governing Terms
These terms are governed by applicable local laws.

By continuing to use this application, you acknowledge that you have read and agreed to these terms and conditions.
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
