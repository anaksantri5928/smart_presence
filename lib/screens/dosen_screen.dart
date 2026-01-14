import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'rekap_screen.dart';
import 'login_screen.dart';

class DosenScreen extends StatefulWidget {
  const DosenScreen({super.key});

  @override
  State<DosenScreen> createState() => _DosenScreenState();
}

class _DosenScreenState extends State<DosenScreen> {
  List<dynamic> _classes = [];
  bool _isLoading = true;
  String _errorMessage = '';

  static const String baseUrl = 'http://127.0.0.1:8000/api';

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  // ================= FETCH CLASSES =================
  Future<void> _fetchClasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() {
        _errorMessage = 'Token tidak ditemukan. Silakan login ulang.';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/classes/my'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['status'] == true) {
          setState(() {
            _classes = json['data'];
          });
        } else {
          _errorMessage = json['message'] ?? 'Gagal memuat kelas.';
        }
      } else {
        _errorMessage = 'Server error (${response.statusCode})';
      }
    } catch (e) {
      _errorMessage = 'Tidak dapat terhubung ke server.';
    }

    setState(() => _isLoading = false);
  }

  // ================= CREATE CLASS =================
  Future<void> _createClass(String className) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Token tidak ditemukan')));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/classes'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': className}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);

        if (json['status'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kelas berhasil dibuat')),
          );
          _fetchClasses();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(json['message'] ?? 'Gagal membuat kelas')),
          );
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal membuat kelas')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat terhubung ke server')),
      );
    }
  }

  // ================= LOGOUT =================
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  // ================= DIALOG =================
  void _showCreateClassDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Kelas Baru'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nama Kelas',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final className = controller.text.trim();
              if (className.isEmpty) return;

              Navigator.pop(context);
              _createClass(className);
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dosen Dashboard'),
        backgroundColor: Colors.blue.shade600,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade600,
        onPressed: _showCreateClassDialog,
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    if (_classes.isEmpty) {
      return const Center(child: Text('Belum ada kelas'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _classes.length,
      itemBuilder: (context, index) {
        final item = _classes[index] as Map<String, dynamic>;
        final name = item['name'] ?? 'Tanpa Nama';
        final dosen = item['dosen'] ?? '-';
        final initial = name.toString().isNotEmpty
            ? name.toString()[0].toUpperCase()
            : '?';

        return Card(
          elevation: 6,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.blue.shade50],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade600,
                radius: 24,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 4),
                  Text(
                    'Dosen: $dosen',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: Colors.blue.shade600,
              ),
              onTap: () {
                final classId = item['id'] as int?;
                if (classId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RekapScreen(classId: classId),
                    ),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}
