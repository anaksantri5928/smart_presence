class LoginResponse {
  final bool success;
  final String message;
  final LoginData? data;

  LoginResponse({required this.success, required this.message, this.data});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null ? LoginData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'data': data?.toJson()};
  }
}

class LoginData {
  final int id;
  final String nama;
  final String role;
  final String token;

  LoginData({
    required this.id,
    required this.nama,
    required this.role,
    required this.token,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      id: json['id'],
      nama: json['nama'],
      role: json['role'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nama': nama, 'role': role, 'token': token};
  }
}

class LoginRequest {
  final String username;
  final String role;

  LoginRequest({required this.username, required this.role});

  Map<String, dynamic> toJson() {
    return {'username': username, 'role': role};
  }
}
