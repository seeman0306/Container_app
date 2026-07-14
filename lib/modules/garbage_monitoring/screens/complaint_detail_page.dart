import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:smart_city_container/core/theme/app_colors.dart';

class ComplaintDetailPage extends StatelessWidget {
  final Map<String, dynamic> complaint;

  const ComplaintDetailPage({super.key, required this.complaint});

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'received':
      case 'pending': return Colors.blue;
      case 'in progress': return Colors.orange;
      case 'completed': return Colors.green;
      case 'closed': return Colors.grey;
      case 'rejected': return Colors.red;
      default: return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Complaint #${complaint['id'] ?? complaint['complaint_id']}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(complaint['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(complaint['status'])),
                  ),
                  child: Text(
                    (complaint['status'] ?? 'PENDING').toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(complaint['status']),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 40),
            _buildDetailItem('Title', complaint['title'] ?? complaint['complaint_title']),
            _buildDetailItem('Ward No', complaint['ward'] ?? complaint['ward_no']),
            _buildDetailItem('Date Submitted', _formatDate(complaint['created_at'])),
            _buildDetailItem('Location', complaint['address'] ?? complaint['complaint_address']),
            const SizedBox(height: 20),
            const Text(
              'Description',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                (complaint['description'] ?? complaint['complaint_description'] ?? 'No description provided.'),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Attachments',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (complaint['photo'] != null && complaint['photo'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(complaint['photo']),
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildNoPhoto(),
                ),
              )
            else
              _buildNoPhoto(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPhoto() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
            Text('No photo attached', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value?.toString() ?? 'N/A',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
