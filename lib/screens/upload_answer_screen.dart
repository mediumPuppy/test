import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

class UploadAnswerScreen extends StatefulWidget {
  const UploadAnswerScreen({super.key});

  @override
  _UploadAnswerScreenState createState() => _UploadAnswerScreenState();
}

class _UploadAnswerScreenState extends State<UploadAnswerScreen> {
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _feedback;

  // Captures photo from camera
  Future<void> _takePhoto() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      setState(() {
        _imageFile = pickedFile;
        _feedback = null;
      });
      
      if (_imageFile != null) {
        await _uploadAndProcess(_imageFile!);
      }
    } catch (e) {
      setState(() {
        _feedback = 'Error taking photo: $e';
      });
    }
  }

  // Uploads image and calls processing function
  Future<void> _uploadAndProcess(XFile file) async {
    setState(() {
      _isLoading = true;
      _feedback = 'Uploading image...';
    });

    try {
      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child('answers/${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await imageRef.putFile(File(file.path));
      final imageUrl = await imageRef.getDownloadURL();
      
      // Call Cloud Function to process the image
      final uri = Uri.parse('https://us-central1-reelmath-jl.cloudfunctions.net/processAnswer');
      final response = await http.post(
        uri,
        body: {'imageUrl': imageUrl},
      );

      if (response.statusCode == 200) {
        setState(() {
          _feedback = 'Answer processed successfully!';
        });
        // TODO: Parse and display the response
      } else {
        setState(() {
          _feedback = 'Error processing answer: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _feedback = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Your Answer'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_imageFile != null)
                Expanded(
                  child: Image.file(
                    File(_imageFile!.path),
                    fit: BoxFit.contain,
                  ),
                ),
              const SizedBox(height: 16),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                ),
              if (_feedback != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _feedback!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _feedback!.contains('Error') 
                          ? Colors.red 
                          : Colors.green,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 