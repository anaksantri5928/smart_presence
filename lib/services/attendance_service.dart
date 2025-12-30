import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendanceService {
  static const String baseUrl =
      'http://localhost:8000'; // Change this to your actual API URL

  Future<AttendanceResponse> submitAttendance({
    required String token,
    required String nim,
    required String mataKuliah,
  }) async {
    print('=== ATTENDANCE API CALL STARTED ===');
    print('NIM: $nim');
    print('Mata Kuliah: $mataKuliah');
    print('Token: ${token.substring(0, 10)}...');

    // Try with Token format first
    try {
      return await _makeRequest(token, nim, mataKuliah, 'Token');
    } catch (e) {
      print('Token format failed: $e');

      // If Token format fails, try Bearer format
      try {
        return await _makeRequest(token, nim, mataKuliah, 'Bearer');
      } catch (e2) {
        print('Bearer format also failed: $e2');
        throw Exception('Both Token and Bearer formats failed');
      }
    }
  }

  Future<AttendanceResponse> _makeRequest(
    String token,
    String nim,
    String mataKuliah,
    String authType,
  ) async {
    print('--- Trying $authType authentication ---');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': '$authType $token',
    };

    print('Headers being sent: $headers');

    final response = await http.post(
      Uri.parse('$baseUrl/api/absen/'),
      headers: headers,
      body: jsonEncode({'nim': nim, 'mata_kuliah': mataKuliah}),
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 201) {
      print('$authType authentication SUCCESS!');
      return AttendanceResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 400) {
      print('$authType authentication: Bad request (400)');
      return AttendanceResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 403) {
      print('$authType authentication: Forbidden (403)');
      throw Exception('Authentication failed with $authType format');
    } else {
      print(
        '$authType authentication: Unexpected status ${response.statusCode}',
      );
      throw Exception('API error with $authType: ${response.statusCode}');
    }
  }

  Future<AttendanceHistoryResponse> getAttendanceHistory({
    required String token,
    required String nim,
  }) async {
    print('=== ATTENDANCE HISTORY API CALL STARTED ===');
    print('NIM: $nim');
    print('Token: ${token.substring(0, 10)}...');

    // Try with Token format first
    try {
      return await _makeHistoryRequest(token, nim, 'Token');
    } catch (e) {
      print('Token format failed: $e');

      // If Token format fails, try Bearer format
      try {
        return await _makeHistoryRequest(token, nim, 'Bearer');
      } catch (e2) {
        print('Bearer format also failed: $e2');
        throw Exception('Both Token and Bearer formats failed');
      }
    }
  }

  Future<AttendanceHistoryResponse> _makeHistoryRequest(
    String token,
    String nim,
    String authType,
  ) async {
    print('--- Trying $authType authentication for history ---');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': '$authType $token',
    };

    print('Headers being sent: $headers');

    final response = await http.get(
      Uri.parse('$baseUrl/api/absen/riwayat/?nim=$nim'),
      headers: headers,
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      print('$authType authentication SUCCESS!');
      return AttendanceHistoryResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 403) {
      print('$authType authentication: Forbidden (403)');
      return AttendanceHistoryResponse.fromJson(jsonDecode(response.body));
    } else {
      print(
        '$authType authentication: Unexpected status ${response.statusCode}',
      );
      throw Exception('API error with $authType: ${response.statusCode}');
    }
  }

  Future<LecturerAttendanceResponse> getLecturerAttendanceRecap({
    required String token,
  }) async {
    print('=== LECTURER ATTENDANCE RECAP API CALL STARTED ===');
    print('Token: ${token.substring(0, 10)}...');

    // Try with Token format first
    try {
      return await _makeLecturerRecapRequest(token, 'Token');
    } catch (e) {
      print('Token format failed: $e');

      // If Token format fails, try Bearer format
      try {
        return await _makeLecturerRecapRequest(token, 'Bearer');
      } catch (e2) {
        print('Bearer format also failed: $e2');
        throw Exception('Both Token and Bearer formats failed');
      }
    }
  }

  Future<LecturerAttendanceResponse> _makeLecturerRecapRequest(
    String token,
    String authType,
  ) async {
    print('--- Trying $authType authentication for lecturer recap ---');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': '$authType $token',
    };

    print('Headers being sent: $headers');

    final response = await http.get(
      Uri.parse('$baseUrl/api/dosen/absen/'),
      headers: headers,
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      print('$authType authentication SUCCESS!');
      return LecturerAttendanceResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 403) {
      print('$authType authentication: Forbidden (403)');
      return LecturerAttendanceResponse.fromJson(jsonDecode(response.body));
    } else {
      print(
        '$authType authentication: Unexpected status ${response.statusCode}',
      );
      throw Exception('API error with $authType: ${response.statusCode}');
    }
  }
}

class AttendanceResponse {
  final bool success;
  final String message;
  final AttendanceData? data;

  AttendanceResponse({required this.success, required this.message, this.data});

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null ? AttendanceData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'data': data?.toJson()};
  }
}

class AttendanceData {
  final String tanggal;
  final String waktu;
  final String status;

  AttendanceData({
    required this.tanggal,
    required this.waktu,
    required this.status,
  });

  factory AttendanceData.fromJson(Map<String, dynamic> json) {
    return AttendanceData(
      tanggal: json['tanggal'],
      waktu: json['waktu'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'tanggal': tanggal, 'waktu': waktu, 'status': status};
  }
}

class AttendanceHistoryResponse {
  final bool success;
  final String message;
  final List<AttendanceHistoryData>? data;

  AttendanceHistoryResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AttendanceHistoryResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? (json['data'] as List)
              .map((item) => AttendanceHistoryData.fromJson(item))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.map((item) => item.toJson()).toList(),
    };
  }
}

class AttendanceHistoryData {
  final String tanggal;
  final String mataKuliah;
  final String status;

  AttendanceHistoryData({
    required this.tanggal,
    required this.mataKuliah,
    required this.status,
  });

  factory AttendanceHistoryData.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryData(
      tanggal: json['tanggal'],
      mataKuliah: json['mata_kuliah'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'tanggal': tanggal, 'mata_kuliah': mataKuliah, 'status': status};
  }
}

class LecturerAttendanceResponse {
  final bool success;
  final String message;
  final List<LecturerAttendanceData>? data;

  LecturerAttendanceResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory LecturerAttendanceResponse.fromJson(Map<String, dynamic> json) {
    return LecturerAttendanceResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? (json['data'] as List)
              .map((item) => LecturerAttendanceData.fromJson(item))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.map((item) => item.toJson()).toList(),
    };
  }
}

class LecturerAttendanceData {
  final String nim;
  final String nama;
  final String mataKuliah;
  final String tanggal;
  final String status;

  LecturerAttendanceData({
    required this.nim,
    required this.nama,
    required this.mataKuliah,
    required this.tanggal,
    required this.status,
  });

  factory LecturerAttendanceData.fromJson(Map<String, dynamic> json) {
    return LecturerAttendanceData(
      nim: json['nim'],
      nama: json['nama'],
      mataKuliah: json['mata_kuliah'],
      tanggal: json['tanggal'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nim': nim,
      'nama': nama,
      'mata_kuliah': mataKuliah,
      'tanggal': tanggal,
      'status': status,
    };
  }
}
