import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://api.vuelo.email/api';

  Future<Map<String, dynamic>> registerUser(
    String username,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/users');

    print('---------------------------');
    print(username);
    print(password);
    print(url);

    print('---------------------------');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      print('---------------------------');
      print(response.body);
      print('---------------------------');

      // Log or handle the actual status code (201 expected)
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Return successful response. The API might return the created user JSON here.
        // Assuming it's JSON if it's not empty
        if (response.body.isNotEmpty) {
          return jsonDecode(response.body);
        }
        return {'success': true};
      } else {
        // Handle API errors like "El usuario ya existe"
        // Try to parse error message from API if available
        String errorMessage = 'Failed to register';
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            if (errorData['message'] != null) {
              errorMessage = errorData['message'];
            } else if (errorData['error'] != null) {
              errorMessage = errorData['error'];
            }
          } catch (_) {}
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('---------------------------');
      print(e);
      print('---------------------------');
      throw Exception('Network or API Error: ${e.toString()}');
    }
  }
}
