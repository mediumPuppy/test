import 'package:flutter/material.dart';
import '../models/skill.dart';

class SkillDetailsModal extends StatelessWidget {
  final Skill skill;
  final bool isUnlocked;
  final bool isCompleted;
  final double progress;
  final VoidCallback onStartLearning;
  final VoidCallback? onWatchVideo;
  final VoidCallback? onTakeChallenge;

  const SkillDetailsModal({
    Key? key,
    required this.skill,
    required this.isUnlocked,
    required this.isCompleted,
    required this.progress,
    required this.onStartLearning,
    this.onWatchVideo,
    this.onTakeChallenge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              if (skill.isMiniChallenge)
                const Icon(Icons.star, color: Colors.amber, size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  skill.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Level ${skill.difficultyLevel}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress indicator
          if (!isCompleted && isUnlocked)
            Column(
              children: [
                LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${progress.toStringAsFixed(0)}% Complete',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
              ],
            ),

          // Description
          Text(
            skill.description,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),

          // Prerequisites
          if (skill.prerequisites.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prerequisites:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: skill.prerequisites.map((prereq) {
                    return Chip(
                      label: Text(prereq),
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),

          // Rewards
          if (skill.rewards.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rewards:',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...skill.rewards.entries.map((entry) {
                  return ListTile(
                    leading: const Icon(Icons.emoji_events, color: Colors.amber),
                    title: Text(entry.key),
                    subtitle: Text(entry.value.toString()),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),

          // Action buttons
          if (!isCompleted)
            Column(
              children: [
                if (isUnlocked) ...[
                  ElevatedButton.icon(
                    onPressed: onStartLearning,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Learning'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  if (skill.videoUrl != null && onWatchVideo != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: onWatchVideo,
                      icon: const Icon(Icons.video_library),
                      label: const Text('Watch Tutorial'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                  if (skill.isMiniChallenge && onTakeChallenge != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: onTakeChallenge,
                      icon: const Icon(Icons.extension),
                      label: const Text('Take Challenge'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ] else
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.lock,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Complete the prerequisites to unlock this skill',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 48,
                    color: Colors.green,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You have mastered this skill!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 