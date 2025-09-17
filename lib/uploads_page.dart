import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'video_upload.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';

class UploadsPage extends StatefulWidget {
  const UploadsPage({super.key});

  @override
  State<UploadsPage> createState() => _UploadsPageState();
}

class _UploadsPageState extends State<UploadsPage> {
  // Store names of 3 videos
  List<String?> videoNames = [null, null, null];

  // Status options
  String status = "draft"; // draft, submitted, flagged
  String verdict = "ongoing"; // accepted, rejected, ongoing

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  /*
  void submitVideos() async {
    if (runningVideo != null && jumpingVideo != null && pushupsVideo != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please login first")));
        return;
      }

      // Video names
      List<String> videoNames = [
        runningVideo!.name,
        jumpingVideo!.name,
        pushupsVideo!.name,
      ];

      // Create a new upload document in Firestore
      String uploadId = FirebaseFirestore.instance
          .collection('uploads')
          .doc()
          .id;

      await FirebaseFirestore.instance.collection('uploads').doc(uploadId).set({
        "user_id": user.uid,
        "video_names": videoNames,
        "upload_date": DateTime.now(),
        "status": "draft", // default
        "verdict": "ongoing", // default
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Upload saved as draft!")));

      // Clear selected videos
      setState(() {
        runningVideo = null;
        jumpingVideo = null;
        pushupsVideo = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select all three videos")),
      );
    }
  }
*/
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Please login to see your uploads"));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Uploads")),
      body:
          /*FutureBuilder(
        future: () async {
          try {
            final snapshot = await FirebaseFirestore.instance
                .collection('uploads')
                .where('user_id', isEqualTo: user.uid)
                .orderBy('upload_date', descending: true)
                .get();
            return snapshot;
          } catch (e) {
            print("Firestore error: $e"); // <-- will show in terminal
            rethrow;
          }
        }(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Text("No uploads found");
          }
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return ListTile(title: Text(doc["video_names"].toString()));
            }).toList(),
          );
        },
      ),
    );
  }
} */
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('uploads')
                .where('user_id', isEqualTo: user.uid)
                .orderBy('upload_date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No uploads yet"));
              }

              final uploads = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: uploads.length,
                itemBuilder: (context, index) {
                  final upload = uploads[index];
                  final videoNames = List<String>.from(upload['video_names']);
                  final uploadDate = (upload['upload_date'] as Timestamp)
                      .toDate();
                  final status = upload['status'];
                  final verdict = upload['verdict'];

                  //extract analysis
                  final Map<String, dynamic> analysis =
                      Map<String, dynamic>.from(upload['analysis']);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Uploaded: ${uploadDate.toLocal()}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          for (var name in videoNames) Text(name),
                          const SizedBox(height: 12),
                          status == "draft"
                              ? ElevatedButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('uploads')
                                        .doc(upload.id)
                                        .update({"status": "submitted"});
                                  },
                                  child: const Text("Submit to Portal"),
                                )
                              : Text(
                                  "Result: $verdict",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                          const SizedBox(height: 12),
                          Table(
                            border: TableBorder.all(color: Colors.grey),
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                ),
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      "Test",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      "Value",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Generate rows dynamically
                              for (var entry in analysis.entries)
                                TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(entry.key),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                        entry.value is Map
                                            ? entry.value
                                                  .toString() // or customize nested map display
                                            : entry.value.toString(),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
    );
  }
}
