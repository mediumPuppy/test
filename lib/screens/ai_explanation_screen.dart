import 'package:flutter/material.dart';

class AIExplanationScreen extends StatefulWidget {
  final String videoContext;

  const AIExplanationScreen({
    super.key,
    required this.videoContext,
  });

  @override
  State<AIExplanationScreen> createState() => _AIExplanationScreenState();
}

class _AIExplanationScreenState extends State<AIExplanationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Explanation'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.lightbulb,
              color: Colors.white,
            ),
            onPressed: () {
              // Handle light bulb tap
            },
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Welcome to AI Explanation',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}