import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class StorageService {
  // 🔥 YOUR REAL CLOUDINARY DETAILS
  final String cloudName = "dkozyl0c2";       // ✅ your cloud name
  final String uploadPreset = "profile_upload"; // ✅ unsigned preset

  Future<String> uploadProfileImage(String uid, File file) async {
    try {
      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      var request = http.MultipartRequest("POST", url);

      // ✅ required field
      request.fields['upload_preset'] = uploadPreset;

      // ✅ attach image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
        ),
      );

      // ✅ send request
      final response = await request.send();

      // ✅ read response
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseData);

        print("✅ Upload Success: ${data['secure_url']}");

        return data['secure_url']; // 🔥 final image URL
      } else {
        print("❌ Cloudinary Error: $responseData");
        throw Exception("Upload failed: $responseData");
      }
    } catch (e) {
      print("❌ Cloudinary Upload Error: $e");
      throw Exception("Upload failed");
    }
  }

  // 🔥 OPTIONAL (for backward compatibility)
  Future<String> uploadProfilePicture(String uid, File file) async {
    return await uploadProfileImage(uid, file);
  }
}