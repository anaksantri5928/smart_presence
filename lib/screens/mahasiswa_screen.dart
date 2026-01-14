import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import 'attendance_screen.dart';
import 'face_enroll_screen.dart';
import 'history_screen.dart';


class MahasiswaScreen extends StatefulWidget {
  @override
  _MahasiswaScreenState createState() => _MahasiswaScreenState();
}

class _MahasiswaScreenState extends State<MahasiswaScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> classes = [];

  @override
  void initState() {
    super.initState();
    fetchClasses();
  }

  Future<void> fetchClasses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      _logout();
      return;
    }

    const String apiUrl = 'http://localhost:8000/api/classes/my';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == true) {
          setState(() {
            classes = List<Map<String, dynamic>>.from(data['data']);
            isLoading = false;
          });
        } else {
          isLoading = false;
        }
      } else {
        isLoading = false;
      }
    } catch (e) {
      isLoading = false;
    }

    setState(() {});
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mahasiswa Dashboard'),
        backgroundColor: Colors.green.shade600,
        actions: [
          IconButton(
            icon: const Icon(Icons.face),
            tooltip: 'Enroll Wajah',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FaceEnrollScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Histori Absensi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : classes.isEmpty
              ? const Center(child: Text('Tidak ada kelas tersedia'))
              : ListView.builder(
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final classItem = classes[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.class_,
                          color: Colors.green,
                        ),
                        title: Text(
                          classItem['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Dosen: ${classItem['dosen']}',
                        ),
                        trailing: const Icon(Icons.camera_alt),
                        onTap: () {
                          // 👉 Masuk halaman absensi
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AttendanceScreen(
                                classId: classItem['id'],
                                className: classItem['name'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
