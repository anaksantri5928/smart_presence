import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AIService {
  static const String baseUrl =
      'http://localhost:8000'; // Change this to your actual API URL

  Future<AIValidationResponse> validatePhoto(File photoFile) async {
    try {
      if (kIsWeb) {
        // Web implementation
        return await _validatePhotoWeb(photoFile);
      } else {
        // Mobile/Desktop implementation
        return await _validatePhotoMobile(photoFile);
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      throw Exception('AI validation failed: $e');
    }
  }

  Future<AIValidationResponse> _validatePhotoMobile(File photoFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/ai/validate/'),
    );

    // Add photo file
    var photo = await http.MultipartFile.fromPath(
      'foto',
      photoFile.path,
      contentType: MediaType('image', 'jpeg'),
    );
    request.files.add(photo);

    final response = await request.send();
    final responseData = await response.stream.toBytes();
    final responseString = String.fromCharCodes(responseData);

    if (response.statusCode == 200) {
      return AIValidationResponse.fromJson(jsonDecode(responseString));
    } else {
      return AIValidationResponse.fromJson(jsonDecode(responseString));
    }
  }

  Future<AIValidationResponse> _validatePhotoWeb(File photoFile) async {
    // For web, we'll use a simpler approach with base64 encoding
    final bytes = await photoFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse('$baseUrl/api/ai/validate/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'foto': base64Image, 'filename': 'photo.jpg'}),
    );

    if (response.statusCode == 200) {
      return AIValidationResponse.fromJson(jsonDecode(response.body));
    } else {
      return AIValidationResponse.fromJson(jsonDecode(response.body));
    }
  }
}

class AIValidationResponse {
  final bool success;
  final String? message;
  final AIResult? aiResult;

  AIValidationResponse({required this.success, this.message, this.aiResult});

  factory AIValidationResponse.fromJson(Map<String, dynamic> json) {
    return AIValidationResponse(
      success: json['success'],
      message: json['message'],
      aiResult: json['ai_result'] != null
          ? AIResult.fromJson(json['ai_result'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'ai_result': aiResult?.toJson(),
    };
  }
}

class AIResult {
  final String status;
  final double confidence;

  AIResult({required this.status, required this.confidence});

  factory AIResult.fromJson(Map<String, dynamic> json) {
    return AIResult(
      status: json['status'],
      confidence: json['confidence'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'confidence': confidence};
  }

  bool get isValid => status.toLowerCase() == 'valid';
  String get confidenceText => '${(confidence * 100).toInt()}%';
}
