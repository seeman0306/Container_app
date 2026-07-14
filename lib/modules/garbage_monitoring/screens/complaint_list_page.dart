import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_city_container/core/utils/api_constants.dart';
import 'package:smart_city_container/core/utils/secure_token_storage.dart';
import 'package:smart_city_container/core/theme/app_colors.dart';
import 'complaint_detail_page.dart';

class ComplaintListPage extends StatefulWidget {
  const ComplaintListPage({super.key});

  @override
  State<ComplaintListPage> createState() => _ComplaintListPageState();
}

class _ComplaintListPageState extends State<ComplaintListPage> {
  List<dynamic> _complaints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    setState(() => _isLoading = true);
    try {
      final token = await SecureTokenStorage.getAccessToken();
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/api/citizen/my-complaints"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> allComplaints = jsonDecode(response.body);
        // Filter for Garbage Monitoring (Module ID 6)
        setState(() {
          _complaints = allComplaints.where((c) => c['module_id'] == 6).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching complaints: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Submissions"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchComplaints),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _complaints.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text("No submissions found", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _complaints.length,
                  itemBuilder: (context, index) {
                    final complaint = _complaints[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          complaint['title'] ?? complaint['complaint_title'] ?? "No Title",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text("Ward: ${complaint['ward'] ?? complaint['ward_no']}"),
                            Text("Date: ${complaint['created_at']?.split('T')[0] ?? ''}"),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(complaint['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (complaint['status'] ?? "Pending").toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(complaint['status']),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ComplaintDetailPage(complaint: complaint),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'in progress':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }
}
