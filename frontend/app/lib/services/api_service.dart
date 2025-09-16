import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class ApiService {
  static Future<Map<String, dynamic>> uploadMultipleVideos(List<PlatformFile> videos) async {
    var uri = Uri.parse('http://10.26.223.16:5000/upload_multiple');
    var request = http.MultipartRequest('POST', uri);

    for (var video in videos) {
      if (video.path != null) {
        request.files.add(await http.MultipartFile.fromPath('videos', video.path!));
      }
    }

    var response = await request.send();
    if (response.statusCode == 200) {
      var respStr = await response.stream.bytesToString();
      return json.decode(respStr);
    } else {
      throw Exception('Upload failed with status code: ${response.statusCode}');
    }
  }
}
