import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryHelper {
  static const String cloudName = 'daqutjt69';
  static const String apiKey = '168673571585838';
  static const String apiSecret = 'GSHSnUhx4dli-vXBeudlfG91eyQ';
  static const String uploadPreset = 'profile_setup';
  static const String folder = 'Setup Profile'; // Default folder for profile setup

  // Modify uploadImageToCloudinary to include username-based dynamic folder
  static Future<String?> uploadImageToCloudinary(String imagePath, String username) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add the file to the request
      request.files.add(await http.MultipartFile.fromPath('file', imagePath));

      // Add necessary fields
      request.fields['upload_preset'] = uploadPreset;
      // Dynamically set the folder path based on username
      request.fields['folder'] = '$folder/$username'; // Dynamic folder based on username

      // Add authentication
      request.headers['Authorization'] = 'Basic ${base64Encode(utf8.encode('$apiKey:$apiSecret'))}';

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final responseData = jsonDecode(responseBody);
        return responseData['secure_url']; // Return the secure image URL
      } else {
        print('Failed to upload image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      return null;
    }
  }
}






// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class CloudinaryHelper {
//   static const String cloudName = 'daqutjt69';
//   static const String apiKey = '168673571585838';
//   static const String apiSecret = 'GSHSnUhx4dli-vXBeudlfG91eyQ';
//   static const String uploadPreset = 'profile_setup';
//   static const String folder = 'Setup Profile'; // Default folder for profile setup

//   // Modify uploadImageToCloudinary to include username-based dynamic folder
//   static Future<String?> uploadImageToCloudinary(String imagePath, String username) async {
//     try {
//       final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
//       final request = http.MultipartRequest('POST', uri);

//       // Add the file to the request
//       request.files.add(await http.MultipartFile.fromPath('file', imagePath));

//       // Add necessary fields
//       request.fields['upload_preset'] = uploadPreset;
//       // Dynamically set the folder path based on username
//       request.fields['folder'] = '$folder/$username'; // Dynamic folder based on username

//       // Add authentication
//       request.headers['Authorization'] = 'Basic ${base64Encode(utf8.encode('$apiKey:$apiSecret'))}';

//       final response = await request.send();

//       if (response.statusCode == 200) {
//         final responseBody = await response.stream.bytesToString();
//         final responseData = jsonDecode(responseBody);
//         return responseData['secure_url']; // Return the secure image URL
//       } else {
//         print('Failed to upload image: ${response.statusCode}');
//         return null;
//       }
//     } catch (e) {
//       print('Error uploading image to Cloudinary: $e');
//       return null;
//     }
//   }
// }








