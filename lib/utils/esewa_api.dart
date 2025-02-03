// lib/utils/esewa_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class EsewaApi {
  // Test credentials (use secure storage or environment variables in production)
  static const String esewaId = "9806800001"; // Choose one for testing
  static const String password = "Nepal@123";
  static const String mpin = "1122"; // Application-specific MPIN
  static const String merchantId = "EPAYTEST";
  static const String token = "123456";
  
  // For Epay-v2 integration:
  static const String secretKey = "8gBm/:&EnhH.1/q";

  // The base URL for the eSewa Epay-v2 API (verify this with the official docs)
  static const String baseUrl = "https://uat.esewa.com.np/epay/main"; // Example URL

  /// Process payment using eSewa's Epay-v2 API.
  ///
  /// [userId]: the user’s ID (optional for your backend logging).
  /// [amount]: the fare amount to be charged.
  /// [busOperatorId]: the operator receiving the funds.
  ///
  /// Returns a Map with 'status' and 'reference' (if available).
  static Future<Map<String, dynamic>> processPayment({
    required String userId,
    required double amount,
    required String busOperatorId,
  }) async {
    try {
      // Build the request body according to eSewa's Epay-v2 API requirements.
      // NOTE: The parameter names below are hypothetical. Adjust based on actual docs.
      final Map<String, dynamic> requestBody = {
        'merchant_id': merchantId,
        'token': token,
        'amount': amount.toString(), // Often as a string
        'order_id': "ORDER-${DateTime.now().millisecondsSinceEpoch}",
        // Additional parameters can include device details, user info, etc.
      };

      // Create a signature using the secretKey.
      // Typically, this might involve concatenating certain fields and hashing them.
      // Replace this with the exact signature algorithm as provided in the documentation.
      String signature = _createSignature(requestBody);
      requestBody['signature'] = signature;

      // Log the request (optional; remove in production)
      print("eSewa Request Body: ${jsonEncode(requestBody)}");

      // Define the endpoint URL.
      // The endpoint path may vary; check the documentation.
      final Uri url = Uri.parse("$baseUrl/epay-v2");

      // Send a POST request.
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // Log the raw response (optional)
      print("eSewa Response: ${response.body}");

      // Check the response status code.
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // The response structure depends on eSewa's API.
        // Assume a successful response contains a field 'status' with value 'success'
        // and a 'reference' field for the transaction reference.
        if (responseData['status'] == 'success') {
          return {
            'status': 'success',
            'reference': responseData['reference'] ?? '',
          };
        } else {
          // Payment failed according to eSewa
          return {
            'status': 'failed',
            'reference': '',
          };
        }
      } else {
        // Handle non-200 responses.
        print("eSewa HTTP Error: ${response.statusCode}");
        return {
          'status': 'failed',
          'reference': '',
        };
      }
    } catch (e) {
      // In case of exception, log the error and return a failure.
      print("eSewa Payment Exception: $e");
      return {
        'status': 'failed',
        'reference': '',
      };
    }
  }

  /// Generate a signature for the request.
  ///
  /// This is a dummy implementation. Replace it with the exact method
  /// prescribed by eSewa (often HMAC or SHA-based using the secretKey).
  static String _createSignature(Map<String, dynamic> data) {
    // For demonstration, we concatenate all the values.
    // In production, you might use HMAC with the secretKey:
    // e.g., using crypto package: Hmac(sha256, utf8.encode(secretKey)).convert(utf8.encode(concatenated))
    String concatenated = data.entries
        .map((entry) => entry.value.toString())
        .join('');
    // Return the concatenated string as a dummy signature (replace with actual logic)
    return concatenated;
  }
}
