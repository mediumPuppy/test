import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/topic.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedSubject = 'All';
  String _selectedDifficulty = 'All';
  List<String> _completedTopics = [];

  final Map<String, String> _subjectLabels = {
    'arithmetic': 'Arithmetic',
    'visual_learning': 'Visual Learning',
    'geometry': 'Geometry',
    'practical_math': 'Practical Math',
  };

  final List<String> _difficulties = ['All', 'beginner', 'intermediate', 'advanced'];

  @override
  void initState() {
    super.initState();
    _loadCompletedTopics();
  }

  void _loadCompletedTopics() {
    _firestoreService.getUserCompletedTopics().listen((completed) {
      setState(() {
        _completedTopics = completed;
      });
    });
  }

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = _firestore.collection('topics');
    print('Building query for collection: topics');
    print('Selected subject: $_selectedSubject');
    print('Selected difficulty: $_selectedDifficulty');

    if (_selectedSubject != 'All') {
      query = query.where('subject', isEqualTo: _selectedSubject);
    }
    if (_selectedDifficulty != 'All') {
      query = query.where('difficulty', isEqualTo: _selectedDifficulty);
    }

    // Temporarily removed orderBy to test
    print('Query path: ${query.parameters}');
    return query;
  }

  Widget _buildPrerequisiteBadges(List<String> prerequisites) {
    return prerequisites.isEmpty
        ? const SizedBox.shrink()
        : Wrap(
            spacing: 4,
            children: prerequisites.map((prereq) {
              final isCompleted = _completedTopics.contains(prereq);
              return Chip(
                label: Text(
                  prereq,
                  style: TextStyle(
                    fontSize: 10,
                    color: isCompleted ? Colors.white : Colors.black87,
                  ),
                ),
                backgroundColor: isCompleted ? Colors.green.shade300 : Colors.grey.shade300,
              );
            }).toList(),
          );
  }

  void _handleTopicSelection(Topic topic) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestoreService.setUserSelectedTopic(user.uid, topic.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected topic: ${topic.title}')),
        );
        Navigator.pop(context);
      }
    }
  }

  Widget _buildTopicCard(Topic topic) {
    final isCompleted = _completedTopics.contains(topic.id);
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: InkWell(
        onTap: () => _handleTopicSelection(topic),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      topic.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isCompleted)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(topic.description),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: topic.difficulty == 'beginner'
                              ? Colors.green
                              : topic.difficulty == 'intermediate'
                                  ? Colors.orange
                                  : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          topic.difficulty[0].toUpperCase() +
                              topic.difficulty.substring(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _subjectLabels[topic.subject] ?? topic.subject,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (topic.prerequisites.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prerequisites:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildPrerequisiteBadges(topic.prerequisites),
                  ],
                ),
              ),
            FutureBuilder<double>(
              future: _firestoreService.getTopicProgress(topic.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                
                final progress = snapshot.data ?? 0.0;
                if (progress == 0.0) return const SizedBox.shrink();
                
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Progress:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 100 ? Colors.green : Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${progress.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Math Topics'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Topics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedSubject,
                        items: [
                          const DropdownMenuItem(
                            value: 'All',
                            child: Text('All Subjects'),
                          ),
                          ..._subjectLabels.entries.map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSubject = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Difficulty',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedDifficulty,
                        items: _difficulties
                            .map((difficulty) => DropdownMenuItem(
                                  value: difficulty,
                                  child: Text(
                                    difficulty == 'All'
                                        ? 'All Difficulties'
                                        : difficulty[0].toUpperCase() +
                                            difficulty.substring(1),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDifficulty = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                print('StreamBuilder state: ${snapshot.connectionState}');
                if (snapshot.hasError) {
                  print('StreamBuilder error: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                print('StreamBuilder has data: ${snapshot.hasData}');
                print('Number of docs: ${snapshot.data?.docs.length ?? 0}');
                
                final topics = snapshot.data?.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  print('Topic data: $data');
                  return Topic.fromFirestore(data, doc.id);
                }).toList() ?? [];

                print('Parsed topics length: ${topics.length}');

                if (topics.isEmpty) {
                  return const Center(
                    child: Text('No topics found matching your filters'),
                  );
                }

                return ListView.builder(
                  itemCount: topics.length,
                  itemBuilder: (context, index) => _buildTopicCard(topics[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 