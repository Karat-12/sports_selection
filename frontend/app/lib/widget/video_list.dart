import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class VideoList extends StatelessWidget {
  final List videos; // PlatformFile or XFile
  final Function(int) onDelete;
  final bool isPlatformFiles;

  const VideoList({
    required this.videos,
    required this.onDelete,
    this.isPlatformFiles = false,
  });

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return Center(child: Text('No videos selected.'));
    }

    return ListView.builder(
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final name = isPlatformFiles ? videos[index].name : videos[index].name;
        return ListTile(
          leading: Icon(Icons.video_library),
          title: Text(name),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => onDelete(index),
          ),
        );
      },
    );
  }
}
