import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  Map<String, PlatformFile?> selectedVideos = {
    'Push-ups': null,
    'Squats': null,
    'Jumping Jacks': null,
  };

  bool uploading = false;
  Map<String, dynamic> perExerciseResults = {};
  String finalReport = '';

  Future<void> pickVideo(String exercise) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.video,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedVideos[exercise] = result.files.first;
        // Clear previous results for this exercise
        perExerciseResults.remove(exercise);
        finalReport = '';
      });
    }
  }

  Future<void> uploadVideos() async {
    if (selectedVideos.values.any((video) => video == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload videos for all exercises.')),
      );
      return;
    }

    setState(() {
      uploading = true;
      perExerciseResults.clear();
      finalReport = '';
    });

    try {
      // Prepare videos list in order
      final videos = selectedVideos.values.whereType<PlatformFile>().toList();
      final response = await ApiService.uploadMultipleVideos(videos);

      // Map backend results by exercise name for quick access
      Map<String, dynamic> mappedResults = {};
      for (var result in response['per_video_results']) {
        mappedResults[result['exercise']] = result;
      }

      setState(() {
        perExerciseResults = mappedResults;
        finalReport = response['final_report'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() {
        uploading = false;
      });
    }
  }

  Widget _buildExerciseUpload(String exercise) {
    final video = selectedVideos[exercise];
    final result = perExerciseResults[exercise];

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(exercise, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 8),
            ElevatedButton.icon(
              icon: Icon(video == null ? Icons.upload_file : Icons.check_circle),
              label: Text(video == null ? 'Upload Video' : 'Change Video'),
              onPressed: () => pickVideo(exercise),
            ),
            if (video != null) ...[
              SizedBox(height: 8),
              Text('Selected: ${video.name}', style: TextStyle(fontStyle: FontStyle.italic)),
            ],
            if (result != null) ...[
              SizedBox(height: 8),
              Text('Result: Exercise detected: ${result['exercise']}'),
              Text('Confidence: ${(result['confidence'] * 100).toStringAsFixed(2)}%'),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Exercise Videos')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildExerciseUpload('Push-ups'),
            _buildExerciseUpload('Squats'),
            _buildExerciseUpload('Jumping Jacks'),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: uploading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Icon(Icons.cloud_upload),
              label: Text(uploading ? 'Uploading...' : 'Upload All Videos'),
              onPressed: uploading ? null : uploadVideos,
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
            ),
            SizedBox(height: 24),
            if (finalReport.isNotEmpty)
              Card(
                color: Colors.blue.shade50,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(finalReport,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                ),
              )
          ],
        ),
      ),
    );
  }
}
