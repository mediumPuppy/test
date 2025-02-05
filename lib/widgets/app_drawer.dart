import '../services/auth_service.dart';
import '../screens/upload_answer_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService _auth = AuthService();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          StreamBuilder<User?>(
            stream: _auth.authStateChanges,
            builder: (context, snapshot) {
              final user = snapshot.data;
              return UserAccountsDrawerHeader(
                accountName: Text(user?.displayName ?? 'Student'),  // Use display name from Firebase
                accountEmail: Text(user?.email ?? 'student@example.com'),  // Use email from Firebase
                currentAccountPicture: CircleAvatar(
                  child: Icon(Icons.person),
                ),
              );
            }
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Feed'),
            onTap: () {
              Navigator.pop(context);  // Close drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Topics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/topics');
            },
          ),
          ListTile(
            leading: const Icon(Icons.route),
            title: const Text('Learning Paths'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/learning_paths');
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Upload Answer'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UploadAnswerScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () async {
              await _auth.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
} 