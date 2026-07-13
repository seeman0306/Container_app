import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/water_complaint_provider.dart';

class ComplaintDetailsScreen extends ConsumerWidget {
  final int complaintId;

  const ComplaintDetailsScreen({super.key, required this.complaintId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaintAsync = ref.watch(complaintDetailsProvider(complaintId));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Complaint Details", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade900,
        elevation: 0,
      ),
      body: complaintAsync.when(
        data: (complaint) {
          final DateTime? date = complaint.createdAt;
          final formattedDate = date != null ? DateFormat('dd MMMM yyyy, hh:mm a').format(date) : "N/A";

          final Color statusColor;
          switch (complaint.status.toLowerCase()) {
            case 'pending':
            case 'pending (offline)':
              statusColor = Colors.orange;
              break;
            case 'accepted':
              statusColor = Colors.blue;
              break;
            case 'in progress':
              statusColor = Colors.indigo;
              break;
            case 'completed':
              statusColor = Colors.green;
              break;
            case 'rejected':
              statusColor = Colors.red;
              break;
            case 'escalated':
              statusColor = Colors.purple;
              break;
            default:
              statusColor = Colors.grey;
          }

          final Color severityColor;
          switch (complaint.severity.toLowerCase()) {
            case 'critical':
              severityColor = Colors.red.shade900;
              break;
            case 'high':
              severityColor = Colors.red;
              break;
            case 'medium':
              severityColor = Colors.orange.shade700;
              break;
            default:
              severityColor = Colors.green;
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header image
                _buildImageHeader(complaint.complaintPhoto),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status and date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              complaint.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title (Reason) and Category
                      Text(
                        complaint.reason,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Category: ${complaint.category}",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section: Parameters
                      _buildSectionTitle("Parameters"),
                      _buildParameterGrid(complaint, severityColor),
                      const SizedBox(height: 20),

                      // Section: AI Detection Results
                      _buildSectionTitle("AI Model Classification"),
                      _buildAiAnalysisCard(complaint),
                      const SizedBox(height: 20),

                      // Section: Assigned Officer Info
                      _buildSectionTitle("Field Officer Assignment"),
                      _buildOfficerCard(complaint),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  "Failed to load details",
                  style: TextStyle(fontSize: 18, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(err.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(complaintDetailsProvider(complaintId));
                  },
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageHeader(String? photo) {
    if (photo == null || photo.isEmpty) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 64, color: Colors.white70),
            SizedBox(height: 8),
            Text(
              "No Photo Attached",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    if (!photo.startsWith("http")) {
      try {
        final decodedBytes = base64Decode(photo);
        return Image.memory(
          decodedBytes,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } catch (_) {}
    }

    return Image.network(
      photo,
      height: 220,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        height: 220,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildParameterGrid(dynamic complaint, Color severityColor) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildGridItem("Complaint ID", "${complaint.complaintId != null && complaint.complaintId! >= 0 ? complaint.complaintId : 'Draft/Offline'}")),
                Expanded(child: _buildGridItem("Ward Number", "Ward ${complaint.wardNo}")),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(child: _buildGridItem("Severity", complaint.severity, valueColor: severityColor, isBoldValue: true)),
                Expanded(child: _buildGridItem("Citizen Phone", complaint.userPhone)),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Location Details",
                        style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        complaint.location,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(child: _buildGridItem("Latitude", complaint.latitude.toStringAsFixed(6))),
                Expanded(child: _buildGridItem("Longitude", complaint.longitude.toStringAsFixed(6))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(String label, String value, {Color? valueColor, bool isBoldValue = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBoldValue ? FontWeight.bold : FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildAiAnalysisCard(dynamic complaint) {
    final hasAiData = complaint.aiDetectedIssue != null && complaint.aiDetectedIssue!.isNotEmpty;

    return Card(
      elevation: 0,
      color: hasAiData ? Colors.blue.shade50.withOpacity(0.3) : Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: hasAiData ? Colors.blue.shade100 : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: hasAiData
            ? Row(
                children: [
                  Icon(Icons.psychology, color: Colors.blue.shade800, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Detected Issue: ${complaint.aiDetectedIssue}",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Model Confidence: ${(complaint.aiConfidence ?? 0.0).toStringAsFixed(1)}%",
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Analyzed via YOLOv11 Classification",
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Icon(Icons.psychology_outlined, color: Colors.grey.shade400, size: 40),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "No AI Data Available",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "AI classification was not performed or skipped.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOfficerCard(dynamic complaint) {
    final officerName = complaint.assignedOfficer ?? "Unassigned";
    final officerId = complaint.assignedOfficerId ?? 0;
    final isAssigned = officerName != "Unassigned" && officerId > 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isAssigned ? Colors.blue.shade100 : Colors.grey.shade200,
              radius: 24,
              child: Icon(
                isAssigned ? Icons.person : Icons.person_outline,
                color: isAssigned ? Colors.blue.shade800 : Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    officerName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isAssigned ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAssigned
                        ? "Officer ID: #$officerId (Ward ${complaint.wardNo} Field Officer)"
                        : "Waiting for automatic assignment based on Ward number.",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
