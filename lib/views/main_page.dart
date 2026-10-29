import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smart_glove_app/views/LanguageSelectionPage.dart';
import 'package:smart_glove_app/views/saved_message.dart';
import 'package:smart_glove_app/widgets/action_card.dart';
import 'login_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF660643),
        centerTitle: true,
        title: const Text(
          'Main Page',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _handleSignOut(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Welcome!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ActionCard(
              title: 'Start Translation',
              imagePath: 'lib/assets/translation_image.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TranslationPage(),
                  ),
                );
              },
            ),
            ActionCard(
              title: 'Saved Messages',
              imagePath: 'lib/assets/saved_masseage.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedMessages(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}