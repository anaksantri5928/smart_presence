import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceScreen extends StatefulWidget {
  final int classId;
  final String className;

  const AttendanceScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  File? _imageFile; // Mobile
  Uint8List? _webImage; // Web
  bool _isLoading = false;
  String? _resultMessage;

  final ImagePicker _picker = ImagePicker();

  /// Ambil foto
  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImage = bytes;
          _imageFile = null;
        });
      } else {
        setState(() {
          _imageFile = File(picked.path);
          _webImage = null;
        });
      }

      setState(() {
        _resultMessage = null;
      });
    }
  }

  /// Kirim absensi
  Future<void> _checkin() async {
    if (_imageFile == null && _webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan ambil foto wajah')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) return;

    const String url = 'http://localhost:8000/api/attendance/checkin';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['class_id'] = widget.classId.toString();

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            _webImage!,
            filename: 'checkin.jpg',
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            _imageFile!.path,
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (response.statusCode == 200 && data['status'] == true) {
        setState(() {
          _resultMessage =
              '✅ Absensi berhasil\nConfidence: ${data['data']['confidence']}';
        });
      } else {
        setState(() {
          _resultMessage = '❌ ${data['message']}';
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = 'Terjadi kesalahan saat absensi';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildImagePreview() {
    if (_imageFile == null && _webImage == null) {
      return const Center(child: Text('Belum ada foto'));
    }

    if (kIsWeb) {
      return Image.memory(_webImage!, fit: BoxFit.cover);
    } else {
      return Image.file(_imageFile!, fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi Wajah'),
        backgroundColor: Colors.green.shade600,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              widget.className,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _buildImagePreview(),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Ambil Foto Wajah'),
            ),

            const SizedBox(height: 20),

            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _checkin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('CHECK-IN'),
                  ),

            const SizedBox(height: 20),

            if (_resultMessage != null)
              Text(
                _resultMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}
