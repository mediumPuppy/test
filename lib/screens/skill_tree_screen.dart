import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../models/skill.dart';

class SkillTreeScreen extends StatefulWidget {
  const SkillTreeScreen({Key? key}) : super(key: key);

  @override
  State<SkillTreeScreen> createState() => _SkillTreeScreenState();
}

class _SkillTreeScreenState extends State<SkillTreeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TransformationController _transformationController = TransformationController();
  
  // Zoom control
  static const double minScale = 0.5;
  static const double maxScale = 2.5;
  double currentScale = 1.0;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Tree'),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              setState(() {
                currentScale = (currentScale + 0.1).clamp(minScale, maxScale);
                _transformationController.value = Matrix4.identity()..scale(currentScale);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              setState(() {
                currentScale = (currentScale - 0.1).clamp(minScale, maxScale);
                _transformationController.value = Matrix4.identity()..scale(currentScale);
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getSkills(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final skills = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Skill.fromFirestore(data, doc.id);
          }).toList();

          return InteractiveViewer(
            transformationController: _transformationController,
            minScale: minScale,
            maxScale: maxScale,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            child: Stack(
              children: [
                // TODO: Add SkillConnectionPainter here
                
                // Skill nodes
                ...skills.map((skill) {
                  // TODO: Replace with actual SkillNodeWidget
                  return Positioned(
                    left: skill.orderIndex * 150.0, // Temporary positioning
                    top: 100.0,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(skill.title),
                            Text('Level ${skill.difficultyLevel}'),
                            if (skill.isMiniChallenge)
                              const Icon(Icons.star, color: Colors.amber),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Reset view transformation
          _transformationController.value = Matrix4.identity();
          setState(() => currentScale = 1.0);
        },
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }
} 