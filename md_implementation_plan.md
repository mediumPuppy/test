Below is a detailed plan for implementing the ReelMath features. In this plan we assume that you already have a basic Flutter app set up with Firebase initialized. We'll cover each user story in its own section, explain the approach, and provide code snippets along the way. You can build and test each feature independently; later you can combine them into a unified experience.

---

## 1. [x] Handwritten Answer Image Upload and Processing

### **Overview**

When a user takes a photo of their handwritten math answer, the app should:
- [x] Open the device camera to capture an image.
- [x] Upload the image to Firebase Cloud Storage.
- [x] Call a Firebase Cloud Function that will process the image.
- [ ] Return a placeholder evaluation result to the user.

## 2. [x] Combined Topic and Difficulty Filtering

### **Topics (from seed data):**
- [x] Arithmetic
  - [x] Counting Numbers
  - [x] Addition
- [x] Visual Learning
  - [x] Colors
- [x] Geometry
  - [x] Shapes
- [x] Practical Math
  - [x] Telling Time
  - [x] Money Math

### **Difficulty Levels:**
- [x] Beginner
- [x] Intermediate
- [x] Advanced

### **Implementation Approach:**
- [x] Create a dual-filter system with:
  1. [x] Subject/Topic dropdown (Arithmetic, Visual Learning, Geometry, Practical Math)
  2. [x] Difficulty dropdown (Beginner, Intermediate, Advanced)
- [x] Use Firestore queries with multiple `.where()` clauses
- [x] Allow "All" option for both filters

### **Additional Features Implemented:**
- [x] Topic completion tracking
- [x] Prerequisites checking and display
- [x] Progress tracking with progress bars
- [x] User-friendly card layout
- [x] Visual completion indicators
- [x] Topic detail screen (TODO)
- [ ] Video/content integration
- [ ] Automatic progress updates
- [ ] Offline support
- [ ] Loading state optimizations
- [ ] Error recovery improvements

## 3. [ ] Periodic Quizzes

### **Overview**

After learning certain topics, users take quizzes to test their understanding.  
Initially, you can load hard-coded (or Firestore-stored) questions for a learning path. Later, logic can be added to auto-generate quizzes based on recently covered topics.

### **Approach:**

- Create a dedicated **Quiz Screen** where questions are loaded from a Firestore collection (e.g., `"quizzes"`).
- Each quiz document can include fields like `question`, `answer`, and a reference field (such as `learningPathId`) to filter for the learning sequence.
- Once a question is answered, update the user's progress (flag "reviewed" in user data) if needed.

### **Flutter Code Example**

```dart:lib/screens/quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizScreen extends StatefulWidget {
  final String learningPathId; // To filter quizzes for a specific learning path
  
  QuizScreen({required this.learningPathId});
  
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  int _score = 0;
  
  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }
  
  Future<void> _loadQuestions() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('quizzes')
        .where('learningPathId', isEqualTo: widget.learningPathId)
        .get();
    setState(() {
      _questions = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      _isLoading = false;
    });
  }
  
  void _submitAnswer(bool answer) {
    bool correctAnswer = _questions[_currentQuestionIndex]['answer'];
    if (answer == correctAnswer) {
      _score += 1;
    }
    setState(() {
      _currentQuestionIndex += 1;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_currentQuestionIndex >= _questions.length) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Quiz Completed'),
        ),
        body: Center(child: Text('Your score: $_score/${_questions.length}')),
      );
    }
    var currentQuestion = _questions[_currentQuestionIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(currentQuestion['question']),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _submitAnswer(true),
              child: Text("True"),
            ),
            ElevatedButton(
              onPressed: () => _submitAnswer(false),
              child: Text("False"),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 4. [x] Displaying Progress Percentage

### **Overview**

Show users' progress through a learning path via a percentage or progress circle.  
Track completed videos and total videos in Firestore and calculate the percentage.

### **Implementation Status:**
- [x] Progress tracking in Firestore
- [x] Progress bar UI component
- [x] Real-time progress updates
- [x] Visual completion indicators
- [x] Integration with topic completion

### **Flutter Code Example**

```dart:lib/widgets/progress_bar.dart
import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final double progress; // expected value between 0.0 and 1.0

  ProgressBar({required this.progress});
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircularProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          strokeWidth: 8,
        ),
        Text("${(progress * 100).toInt()}%", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
```

---

## 5. [ ] Video Pause/Unpause at Key Moments

### **Overview**

Implement a video player that pauses when the user taps the video (or at key markers).  
Use the Flutter `video_player` package to control playback.

### **Approach:**

- Create a custom widget wrapping the `VideoPlayerController`.
- Use a `GestureDetector` to toggle play and pause.

### **Flutter Code Example**

```dart:lib/widgets/video_player_widget.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  
  VideoPlayerWidget({required this.videoUrl});
  
  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {}); // Video is ready to be played
      });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _togglePlayPause() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: _controller.value.isInitialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
          : Container(
              color: Colors.black,
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
    );
  }
}
```

---

## 6. [ ] Rating Understanding of a Math Concept Video

### **Overview**

Allow users to rate their understanding of a video (via a like/dislike or swipe mechanic).  
Based on their rating, the app can either suggest more foundational videos or let the user advance.

### **Approach:**

- Create a widget with two buttons (thumb up and thumb down).
- Save the rating to Firestore along with the video ID (and optionally, user ID).
- If the user dislikes, trigger logic to display fundamental concepts. (You can later implement a navigation or modal dialog with additional explanations.)

### **Flutter Code Example**

```dart:lib/widgets/understanding_rating_widget.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UnderstandingRatingWidget extends StatefulWidget {
  final String videoId;
  
  UnderstandingRatingWidget({required this.videoId});
  
  @override
  _UnderstandingRatingWidgetState createState() => _UnderstandingRatingWidgetState();
}

class _UnderstandingRatingWidgetState extends State<UnderstandingRatingWidget> {
  
  void _rateVideo(bool isUnderstood) {
    // Update Firestore with the user's rating for this video.
    FirebaseFirestore.instance.collection('videoRatings').add({
      'videoId': widget.videoId,
      'understood': isUnderstood,
      'timestamp': FieldValue.serverTimestamp(),
      // Optionally include the user ID.
    });
    
    if (!isUnderstood) {
      // TODO: Add logic to present or navigate to foundational content.
      print("User did not understand. Consider showing foundational material.");
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.thumb_up_alt_outlined),
          onPressed: () => _rateVideo(true),
        ),
        IconButton(
          icon: Icon(Icons.thumb_down_alt_outlined),
          onPressed: () => _rateVideo(false),
        ),
      ],
    );
  }
}
```

---

## 7. [x] Missing Required Topics Indicator

### **Overview**

While the user is watching a video, show indicators of what prerequisite topics are missing versus what has been completed.  
Display a red bubble (for missing topics) and a green bubble (for topics already completed).

### **Implementation Status:**
- [x] Prerequisites data structure in topics
- [x] Prerequisites completion checking
- [x] Visual indicators for completed/incomplete prerequisites
- [x] User-friendly error messages
- [x] Integration with topic access control
- [x] Real-time updates of completion status

### **Flutter Code Example**

```dart:lib/widgets/topic_status_indicator.dart
import 'package:flutter/material.dart';

class TopicStatusIndicator extends StatelessWidget {
  final List<String> requiredTopics;
  final List<String> completedTopics;
  
  TopicStatusIndicator({required this.requiredTopics, required this.completedTopics});
  
  @override
  Widget build(BuildContext context) {
    // Identify topics that are missing
    List<String> missingTopics = requiredTopics.where((topic) => !completedTopics.contains(topic)).toList();
    return Row(
      children: [
        // Display green bubble for each completed topic
        ...completedTopics.map((t) => Padding(
              padding: const EdgeInsets.all(4.0),
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.green,
                child: Text(t[0].toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.white)),
              ),
            )),
        // Display red bubble for missing topics
        ...missingTopics.map((t) => Padding(
              padding: const EdgeInsets.all(4.0),
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.red,
                child: Text(t[0].toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.white)),
              ),
            )),
      ],
    );
  }
}
```

---

## 8. [ ] Liking/Disliking a Creator

### **Overview**

Allow users to "like" or "dislike" a creator so the app can later adjust which creators' content to show. This is separate from rating an individual video.

### **Approach:**

- On the video details or creator profile screen, include a button to like or dislike a creator.
- Save this preference to Firestore (e.g., in a `creatorRatings` collection), and later use it for filtering recommendations.

### **Flutter Code Example**

```dart:lib/widgets/creator_rating_button.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreatorRatingButton extends StatefulWidget {
  final String creatorId;
  
  CreatorRatingButton({required this.creatorId});
  
  @override
  _CreatorRatingButtonState createState() => _CreatorRatingButtonState();
}

class _CreatorRatingButtonState extends State<CreatorRatingButton> {
  bool isLiked = false;
  
  void _toggleLike() {
    setState(() {
      isLiked = !isLiked;
    });
    FirebaseFirestore.instance.collection('creatorRatings').add({
      'creatorId': widget.creatorId,
      'liked': isLiked,
      'timestamp': FieldValue.serverTimestamp(),
      // Optionally include a user reference here.
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
      color: Colors.pink,
      onPressed: _toggleLike,
    );
  }
}
```

---

## 9. [ ] Commenting on Videos

### **Overview**

Allow users to leave comments on videos. Use Firestore to store and retrieve comments in real time (coupled with Cloud Messaging to push live updates if needed).

### **Approach:**

- Build a dedicated **Comment Screen** where users can view and add comments.
- Use a `StreamBuilder` to listen to Firestore changes in the `comments` collection.
- Include a text field and send button for new comments.

### **Flutter Code Example**

```dart:lib/screens/comment_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentScreen extends StatefulWidget {
  final String videoId;
  
  CommentScreen({required this.videoId});
  
  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  
  void _postComment() {
    if (_commentController.text.trim().isEmpty) return;
    FirebaseFirestore.instance.collection('comments').add({
      'videoId': widget.videoId,
      'comment': _commentController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      // Optionally attach user ID
    });
    _commentController.clear();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Comments"),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('comments')
                  .where('videoId', isEqualTo: widget.videoId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                var comments = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    var data = comments[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['comment']),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _postComment,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
```

---

## Additional Integration Notes

1. **Dependencies:**  
   Make sure you add the required dependencies in your `pubspec.yaml`:
   - `firebase_core`
   - `firebase_auth`
   - `cloud_firestore`
   - `firebase_storage`
   - `firebase_functions`
   - `video_player`
   - `image_picker`
   - `http`

2. **Firebase Setup:**  
   Configure Firebase Auth, Firestore, Cloud Storage, and Cloud Functions correctly in your app. Make sure to secure API keys especially for services by moving them to Cloud Functions environment variables (using `firebase functions:config:set`).

3. **UI & Navigation:**  
   Keep your UI simple but beautiful. Use Flutter's material design principles. For page navigation, consider using named routes or a package like `go_router`