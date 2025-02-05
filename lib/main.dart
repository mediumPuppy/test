import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/topics_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/learning_paths_screen.dart';
import 'screens/upload_answer_screen.dart';
import 'screens/skill_tree_screen.dart';
import 'services/auth_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('Error during initialization: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReelMath',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            User? user = snapshot.data;
            if (user == null) {
              return const LoginScreen();
            }
            return const FeedScreen();
          }
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
      routes: {
        '/topics': (context) => TopicsScreen(),
        '/learning_paths': (context) => LearningPathsScreen(),
        '/upload_answer': (context) => const UploadAnswerScreen(),
        '/skill_tree': (context) => const SkillTreeScreen(),
      },
    );
  }
}
