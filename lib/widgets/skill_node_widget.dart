import 'package:flutter/material.dart';
import '../models/skill.dart';

class SkillNodeWidget extends StatelessWidget {
  final Skill skill;
  final bool isUnlocked;
  final bool isCompleted;
  final double progress;
  final VoidCallback onTap;
  final double size;

  const SkillNodeWidget({
    Key? key,
    required this.skill,
    required this.isUnlocked,
    required this.isCompleted,
    required this.progress,
    required this.onTap,
    this.size = 120.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getBackgroundColor(theme),
          border: Border.all(
            color: _getBorderColor(theme),
            width: 3.0,
          ),
          boxShadow: [
            if (isUnlocked)
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Stack(
          children: [
            // Progress indicator
            if (!isCompleted && isUnlocked)
              CircularProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.primaryColor,
                ),
              ),
            
            // Main content
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (skill.isMiniChallenge)
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 24.0,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    skill.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _getTextColor(theme),
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Level ${skill.difficultyLevel}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getTextColor(theme).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // Lock icon for locked skills
            if (!isUnlocked)
              Center(
                child: Icon(
                  Icons.lock,
                  color: _getTextColor(theme).withOpacity(0.5),
                  size: 32.0,
                ),
              ),
              
            // Completion checkmark
            if (isCompleted)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(ThemeData theme) {
    if (!isUnlocked) return Colors.grey[300]!;
    if (isCompleted) return Colors.green[100]!;
    return theme.cardColor;
  }

  Color _getBorderColor(ThemeData theme) {
    if (!isUnlocked) return Colors.grey;
    if (isCompleted) return Colors.green;
    return theme.primaryColor;
  }

  Color _getTextColor(ThemeData theme) {
    if (!isUnlocked) return Colors.grey[600]!;
    return theme.textTheme.bodyLarge?.color ?? Colors.black;
  }
} 