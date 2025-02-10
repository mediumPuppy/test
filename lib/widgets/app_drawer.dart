import '../services/auth_service.dart';
import '../screens/upload_answer_screen.dart';
import '../screens/whiteboard_screen.dart';
import '../screens/triangle_svg_screen.dart';
import '../screens/drawing_spec_test_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService auth = AuthService();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          StreamBuilder<User?>(
              stream: auth.authStateChanges,
              builder: (context, snapshot) {
                final user = snapshot.data;
                return UserAccountsDrawerHeader(
                  accountName: Text(user?.displayName ??
                      'Student'), // Use display name from Firebase
                  accountEmail: Text(user?.email ??
                      'student@example.com'), // Use email from Firebase
                  currentAccountPicture: CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                );
              }),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Feed'),
            onTap: () {
              Navigator.pop(context); // Close drawer
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
                MaterialPageRoute(
                    builder: (context) => const UploadAnswerScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.quiz),
            title: const Text('Quizzes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/quizzes');
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Whiteboard'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const WhiteboardScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.draw),
            title: const Text('Triangle SVG Demo'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TriangleSvgScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.mic),
            title: const Text('Drawing & Speech Demo'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DrawingSpecTestScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () async {
              await auth.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
