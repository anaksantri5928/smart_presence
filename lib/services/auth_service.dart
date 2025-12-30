import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/login_response.dart';

class AuthService {
  static const String baseUrl =
      'http://localhost:8000'; // Change this to your actual API URL

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 400) {
        return LoginResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Login failed with status: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
}
