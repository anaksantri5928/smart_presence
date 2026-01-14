import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RekapScreen extends StatefulWidget {
  final int classId;

  const RekapScreen({super.key, required this.classId});

  @override
  _RekapScreenState createState() => _RekapScreenState();
}

class _RekapScreenState extends State<RekapScreen> {
  Map<String, dynamic>? _recapData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchRecap();
  }

  Future<void> _fetchRecap() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      setState(() {
        _errorMessage = 'Token tidak ditemukan. Silakan login kembali.';
        _isLoading = false;
      });
      return;
    }

    final String apiUrl =
        'http://localhost:8000/api/attendance/recap/${widget.classId}';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() {
            _recapData = data['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Gagal memuat rekap.';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        setState(() {
          _errorMessage = data['message'] ?? 'Akses ditolak.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat rekap absensi.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Tidak dapat terhubung ke server.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rekap Absensi'),
        backgroundColor: Colors.blue.shade600,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
            ? Center(
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 18),
                ),
              )
            : _recapData == null
            ? Center(
                child: Text(
                  'Data tidak tersedia.',
                  style: TextStyle(fontSize: 18),
                ),
              )
            : Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade100,
                              Colors.blue.shade200,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.class_,
                                    color: Colors.blue.shade800,
                                    size: 28,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${_recapData!['class']['name'] ?? 'Unknown'}',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    color: Colors.blue.shade700,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Total Mahasiswa: ${_recapData!['total_mahasiswa'] ?? 0}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade700,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Total Hadir: ${_recapData!['total_hadir'] ?? 0}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: (_recapData!['total_mahasiswa'] ?? 0) > 0
                                    ? (_recapData!['total_hadir'] ?? 0) /
                                          (_recapData!['total_mahasiswa'] ?? 1)
                                    : 0,
                                backgroundColor: Colors.blue.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.green.shade600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${((_recapData!['total_hadir'] ?? 0) / (_recapData!['total_mahasiswa'] ?? 1) * 100).toStringAsFixed(1)}% Kehadiran',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.list_alt,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Daftar Absensi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount:
                            (_recapData!['absensi'] as List<dynamic>?)
                                ?.length ??
                            0,
                        itemBuilder: (context, index) {
                          final absensi = _recapData!['absensi'][index];
                          if (absensi is! Map<String, dynamic>)
                            return SizedBox();
                          final mahasiswa =
                              absensi['mahasiswa'] as Map<String, dynamic>?;
                          final name =
                              mahasiswa?['name'] as String? ?? 'Unknown';
                          final confidence = absensi['confidence'] as double?;
                          final timestamp = absensi['timestamp'] as String?;
                          Color confidenceColor = Colors.grey;
                          if (confidence != null) {
                            if (confidence >= 0.9)
                              confidenceColor = Colors.green;
                            else if (confidence >= 0.7)
                              confidenceColor = Colors.orange;
                            else
                              confidenceColor = Colors.red;
                          }
                          return Card(
                            elevation: 3,
                            margin: EdgeInsets.symmetric(vertical: 6.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.white, Colors.grey.shade50],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: confidenceColor,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.verified,
                                          size: 16,
                                          color: confidenceColor,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Confidence: ${confidence != null ? '${(confidence * 100).toStringAsFixed(1)}%' : 'N/A'}',
                                          style: TextStyle(
                                            color: confidenceColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Waktu: ${timestamp ?? 'N/A'}',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
