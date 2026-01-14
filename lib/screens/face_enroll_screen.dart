import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FaceEnrollScreen extends StatefulWidget {
  const FaceEnrollScreen({super.key});

  @override
  State<FaceEnrollScreen> createState() => _FaceEnrollScreenState();
}

class _FaceEnrollScreenState extends State<FaceEnrollScreen> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];
  bool _isLoading = false;

  Future<void> pickImages() async {
    final pickedFiles = await _picker.pickMultiImage(imageQuality: 85);

    print('Picked images count: ${pickedFiles.length}');

    if (pickedFiles.isNotEmpty) {
      if (pickedFiles.length > 5) {
        print('Error: more than 5 images selected');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maksimal 5 foto')),
        );
        return;
      }

      setState(() {
        _images = pickedFiles;
      });
    }
  }

  Future<void> enrollFace() async {
    if (_images.isEmpty) {
      print('Enroll failed: no images selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 foto wajah')),
      );
      return;
    }

    setState(() => _isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    print('Token exists: ${token != null}');
    print('Images to upload: ${_images.length}');

    if (token == null) {
      print('Enroll failed: token is null');
      setState(() => _isLoading = false);
      return;
    }

    final uri = Uri.parse('http://localhost:8000/api/face/enroll');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';

    for (var image in _images) {
      Uint8List bytes = await image.readAsBytes();
      print('Adding file: ${image.name}, size: ${bytes.length} bytes');

      request.files.add(
        http.MultipartFile.fromBytes(
          'images',
          bytes,
          filename: image.name,
        )

      );
    }

    print('Sending request to /api/face/enroll');

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    print('Response status code: ${response.statusCode}');
    print('Response body: $responseBody');

    final data = jsonDecode(responseBody);

    setState(() => _isLoading = false);

    if (response.statusCode == 200 && data['status'] == true) {
      print('Enroll success');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'])),
      );
      Navigator.pop(context);
    } else {
      print('Enroll failed: ${data['message']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Gagal enroll wajah')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Wajah'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Pilih Foto Wajah'),
              onPressed: pickImages,
            ),
            const SizedBox(height: 12),
            if (_images.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _images.map((img) {
                  return FutureBuilder<Uint8List>(
                    future: img.readAsBytes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox(
                          width: 90,
                          height: 90,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      return Image.memory(
                        snapshot.data!,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      );
                    },
                  );
                }).toList(),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : enrollFace,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enroll Wajah'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
