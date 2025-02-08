import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/learning_paths_screen.dart';
import 'screens/upload_answer_screen.dart';
import 'screens/quizzes_screen.dart';
import 'screens/triangle_svg_screen.dart';
import 'services/auth_service.dart';
import 'services/quiz_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize test data
  final quizService = QuizService();
  await quizService.initializeSampleQuizzes();

  runApp(const MyApp());
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
            return const HomeScreen();
          }
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
      routes: {
        '/learning_paths': (context) => LearningPathsScreen(),
        '/upload_answer': (context) => const UploadAnswerScreen(),
        '/quizzes': (context) => QuizzesScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              title: const Text('Triangle SVG Screen'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TriangleSvgScreen()),
                );
              },
            ),
            // Additional drawer items could be added here.
          ],
        ),
      ),
      body: const Center(
        child: Text('Welcome to the SVG Math App!'),
      ),
    );
  }
}
