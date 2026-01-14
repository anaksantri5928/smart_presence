import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isLoading = true;
  List<dynamic> histories = [];

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) return;

    const String apiUrl = 'http://localhost:8000/api/attendance/history';

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
            histories = data['data'];
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
  }

  String formatDate(String isoDate) {
    final dateTime = DateTime.parse(isoDate);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histori Absensi'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : histories.isEmpty
              ? const Center(child: Text('Belum ada histori absensi'))
              : ListView.builder(
                  itemCount: histories.length,
                  itemBuilder: (context, index) {
                    final item = histories[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        title: Text(
                          item['class_info']['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Waktu: ${formatDate(item['timestamp'])}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Confidence',
                              style: TextStyle(fontSize: 11),
                            ),
                            Text(
                              '${(item['confidence'] * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
