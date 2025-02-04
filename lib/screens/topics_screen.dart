import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/topic.dart';

class TopicsScreen extends StatelessWidget {
  TopicsScreen({super.key});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _addSampleTopic() async {
    try {
      await _firestore.collection('topics').add({
        'title': 'Introduction to Algebra',
        'description': 'Learn the basics of algebraic expressions',
        'difficulty': 'beginner',
        'orderIndex': 1,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding topic: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Math Topics'),
        actions: [
          // This is just for testing - remove in production
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addSampleTopic,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('topics')
            .orderBy('orderIndex')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final topics = snapshot.data?.docs.map((doc) {
            return Topic.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList() ?? [];

          return ListView.builder(
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  title: Text(topic.title),
                  subtitle: Text(topic.description),
                  trailing: _DifficultyBadge(difficulty: topic.difficulty),
                  onTap: () {
                    // TODO: Navigate to topic detail screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Selected: ${topic.title}')),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final String difficulty;

  const _DifficultyBadge({required this.difficulty});

  Color _getColor() {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        difficulty,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }
} 