Below is a detailed, step‐by‐step checklist that combines the high-level features described in both documents with all the prerequisites and implementation details. This plan is intended for a junior developer and has plenty of checkboxes to track progress.

---

# ReelMath Implementation Plan & Checklist

This checklist covers everything from project setup to implementing each core feature. Be sure to check each item off as you complete it.

---

## 0. Preliminary Setup and Project Infrastructure

- [x] **Create the Flutter Project**
  - [x] Use `flutter create reelmath` (or the appropriate command).
  - [x] Set up a Git repository with an initial commit and branch structure.
  - [x] Establish coding conventions and file structure (screens, widgets, services, etc.).

- [ ] **Firebase Project Setup**
  - [x] Create a new Firebase project in the Firebase Console.
  - [ ] Enable Firebase services:
    - [x] Authentication (for email/password, social logins, or anonymous auth).
    - [x] Firestore (set up database structure previews).
    - [ ] USE firebase storage for storing images
    - [ ] Cloud Functions (for offloading compute tasks and API calls).
    - [ ] Cloud Messaging (for real-time updates, if required).
  - [x] Download and integrate configuration files:
    - [x] `google-services.json` for Android.
    - [x] `GoogleService-Info.plist` for iOS.
  - [x] Include the Firebase SDK initialization in your `main.dart`.

- [ ] **Dependencies and Package Management**
  - [ ] Update `pubspec.yaml` with required dependencies:
    - `firebase_core`
    - `firebase_auth`
    - `cloud_firestore`
    - `firebase_storage`
    - `firebase_functions`
    - `video_player`
    - `image_picker`
    - `http`
  - [ ] Run `flutter pub get` to install packages.
  - [ ] Verify that all packages are correctly imported and configured.

- [ ] **Environment & Version Control**
  - [ ] Initialize and configure Git (with appropriate `.gitignore` for Flutter and Firebase).
  - [ ] Set up branch management for development (for example, `develop` and `feature/*` branches).
  - [ ] Document setup steps and environment configurations in your README.

- [ ] **Cloud Functions Local Environment Setup**
  - [ ] Install the Firebase CLI.
  - [ ] Initialize Cloud Functions in your project directory.
  - [ ] Configure environment variables (e.g., Mathpix API credentials) via:
    - `firebase functions:config:set mathpix.app_id="your_app_id" mathpix.app_key="your_app_key"`
  - [ ] Write a basic "ping" function to ensure Cloud Functions deploy correctly.

---

## 1. Core Feature Implementations

### 1.1 Handwritten Answer Evaluation (Mathpix API)

- [ ] **Client Side (Flutter)**
  - [ ] Create a new screen: `UploadAnswerScreen`
    - [ ] Implement UI to capture and display photos.
    - [ ] Integrate the `image_picker` package:
      - [ ] Capture an image from the device camera.
      - [ ] Preview the captured image on-screen.
    - [ ] Write code to upload the image via HTTP:
      - [ ] Use `http.MultipartRequest` to send the image file.
      - [ ] Display progress or loading indicators as needed.
  - [ ] **Testing:**
    - [ ] Verify that the image capture works on both Android and iOS.
    - [ ] Test that the HTTP request is triggered correctly after capturing the image.

- [ ] **Server Side (Firebase Cloud Functions)**
  - [ ] Create a new HTTPS function `evaluateAnswer` in your Cloud Functions project.
    - [ ] Parse the incoming request (handle both multi-part file uploads or a base64-encoded image).
    - [ ] Retrieve Mathpix credentials securely from the environment.
    - [ ] Call the Mathpix API using the `axios` package.
    - [ ] Return the response (or an error) to the client.
  - [ ] **Testing:**
    - [ ] Deploy the Cloud Function.
    - [ ] Use tools like Postman or curl to simulate requests.
    - [ ] Ensure secure handling of API keys (never expose keys to the client).

---

### 1.2 Filtering Learning Topics by Difficulty

- [ ] **UI Implementation**
  - [ ] Create a new screen: `TopicFilterScreen`
    - [ ] Add a Dropdown widget that lists:
      - `All`, `Beginner`, `Intermediate`, `Advanced`
    - [ ] Display a list of topics or videos.
  - [ ] **Firestore Query**
    - [ ] Write a Firestore query using `.where()` to filter by difficulty.
    - [ ] Use a `StreamBuilder` to handle real-time data updates.
  - [ ] **Testing:**
    - [ ] Simulate different difficulty selections.
    - [ ] Verify that the list updates correctly when a filter is applied.

---

### 1.3 Periodic Quizzes

- [ ] **Quiz Screen Implementation**
  - [ ] Create a new screen: `QuizScreen`
    - [ ] Design the UI to display quiz questions.
    - [ ] Add buttons for answering (e.g., True/False or multiple choice).
  - [ ] **Data Integration**
    - [ ] Query Firestore for quiz questions:
      - Filter questions based on a learning path (using a field like `learningPathId`).
    - [ ] Update and maintain the current question index and score.
  - [ ] **Testing:**
    - [ ] Validate correct loading of questions from Firestore.
    - [ ] Ensure that score calculations and question progression work as expected.

---

### 1.4 Displaying Progress Percentage

- [ ] **Progress Bar Widget**
  - [ ] Create a `ProgressBar` widget that accepts a progress value (0.0–1.0).
    - [ ] Implement a CircularProgressIndicator with an overlaid percentage text.
  - [ ] **Integration:**
    - [ ] Use this widget on a dashboard or profile screen.
    - [ ] Connect the widget to user progress data from Firestore.
  - [ ] **Testing:**
    - [ ] Simulate different progress values.
    - [ ] Verify the accuracy and responsiveness of the indicator.

---

### 1.5 Video Playback Control

- [ ] **Video Player Widget**
  - [ ] Create a new widget: `VideoPlayerWidget`
    - [ ] Integrate the `video_player` package.
    - [ ] Load a video from a network URL.
    - [ ] Implement tap gesture detection to toggle play/pause.
  - [ ] **Testing:**
    - [ ] Verify proper initialization of the video.
    - [ ] Ensure that tapping the video correctly toggles its state.

---

### 1.6 Concept Understanding Rating

- [ ] **Rating Widget**
  - [ ] Build the `UnderstandingRatingWidget` with two buttons (thumb up and thumb down).
    - [ ] Add logic to capture the user's rating.
    - [ ] Integrate with Firestore to store the rating along with the video ID and timestamp.
    - [ ] Implement additional logic (or placeholder) for when a user dislikes a video.
  - [ ] **Testing:**
    - [ ] Verify that the rating is stored correctly.
    - [ ] Test the UI response and ensure feedback can be expanded later.

---

### 1.7 Missing Required Topics Indicator

- [ ] **Topic Indicator Widget**
  - [ ] Develop the `TopicStatusIndicator` widget.
    - [ ] Show green bubbles for topics the user completed.
    - [ ] Show red bubbles for topics that are missing.
    - [ ] Use the first letter of each topic for the bubble content.
  - [ ] **Testing:**
    - [ ] Mock data for both completed and missing topics.
    - [ ] Ensure that the UI displays the bubble indicators correctly.

---

### 1.8 Creator Feedback (Like/Dislike a Creator)

- [ ] **Creator Rating Widget**
  - [ ] Create the `CreatorRatingButton` widget.
    - [ ] Add a button to toggle between liked and not liked.
    - [ ] Update Firestore with the user's preference for the creator.
  - [ ] **Testing:**
    - [ ] Verify that pressing the button toggles the state visually.
    - [ ] Check that the data is recorded in Firestore.

---

### 1.9 Commenting System

- [ ] **Comment Screen**
  - [ ] Create a new screen: `CommentScreen`
    - [ ] Use a `StreamBuilder` to load comments from Firestore in real time.
    - [ ] Design a text input field and a send button for new comments.
  - [ ] **Data Integration**
    - [ ] Ensure comments are stored with the video ID and timestamp.
    - [ ] Optionally include user identification for comments.
  - [ ] **Testing:**
    - [ ] Test adding new comments.
    - [ ] Verify that comments appear in real time.
    - [ ] Check the ordering (newest first, etc.).

---

## 2. Additional Integration & Future-Proofing Tasks

- [ ] **UI & Navigation**
  - [ ] Establish a clear navigation structure:
    - [ ] Use named routes or a navigation package (e.g., `go_router`).
    - [ ] Create placeholders for each major feature's screen.
  - [ ] Maintain a consistent Material Design style across the app.

- [ ] **Error Handling and Security**
  - [ ] Ensure proper error messages are displayed throughout the app.
  - [ ] Set up Firestore, Cloud Storage, and Cloud Functions security rules.
  - [ ] Validate and sanitize all inputs (both from the client and backend).

- [ ] **Dependency Management and Documentation**
  - [ ] Keep documentations of architectural decisions, API endpoints, and security practices.
  - [ ] Update comments in code (do not remove any existing comments as per guidelines).

- [ ] **Future-Proofing for AI Integration**
  - [ ] Design module interfaces that allow adding additional functions easily.
  - [ ] Place hooks in the code where AI-generated recommendations can be integrated later (e.g., after a video is rated).

- [ ] **Testing & Quality Assurance**
  - [ ] Write unit tests for key widget functionalities.
  - [ ] Create integration tests for Firestore operations and Cloud Function endpoints.
  - [ ] Set up a CI/CD pipeline if possible to run tests automatically on commits.

---

## 3. Final Review and Deployment

- [ ] **Code Review & Cleanup**
  - [ ] Double-check that all feature widgets/screens are modular and decoupled.
  - [ ] Ensure code follows the team's style guidelines.
  - [ ] Verify that comments are intact and helpful.

- [ ] **Deployment Preparation**
  - [ ] Finalize Firebase security rules based on testing.
  - [ ] Prepare staging and production versions of your app.
  - [ ] Write deployment scripts for Cloud Functions and Flutter builds if needed.

- [ ] **Post-Deployment Testing**
  - [ ] Perform a final round of testing on actual devices.
  - [ ] Monitor logs for Cloud Functions and app crashes.
  - [ ] Gather feedback from initial users for further improvements.

---

By following this detailed checklist, you'll be well prepared to implement each feature of ReelMath step by step. Each checkbox is designed to ensure you cover all aspects—from setting up the environment to thorough testing—so that the final product is robust and scalable. Happy coding!
