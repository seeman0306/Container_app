import 'package:flutter/material.dart';

class AiSuggestionCard extends StatelessWidget {
  final String detectedIssue;
  final double confidence;
  final String suggestedSeverity;
  final VoidCallback onApply;

  const AiSuggestionCard({
    super.key,
    required this.detectedIssue,
    required this.confidence,
    required this.suggestedSeverity,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final Color severityColor;
    switch (suggestedSeverity.toLowerCase()) {
      case 'critical':
        severityColor = Colors.red.shade900;
        break;
      case 'high':
        severityColor = Colors.red.shade600;
        break;
      case 'medium':
        severityColor = Colors.orange.shade700;
        break;
      default:
        severityColor = Colors.green.shade700;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade100, width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50.withOpacity(0.5), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.blue.shade800, size: 28),
                const SizedBox(width: 8),
                const Text(
                  "AI Analysis Result",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "YOLOv11 Active",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                )
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn("Detected Issue", detectedIssue, Colors.black87),
                _buildInfoColumn("Confidence", "${confidence.toStringAsFixed(1)}%", Colors.blue.shade800),
                _buildInfoColumn(
                  "Priority",
                  suggestedSeverity,
                  severityColor,
                  isBadge: true,
                  badgeBg: severityColor.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onApply,
              icon: const Icon(Icons.check, size: 18),
              label: const Text("APPLY AI SUGGESTIONS"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 44),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color valueColor, {bool isBadge = false, Color? badgeBg}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        if (isBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
      ],
    );
  }
}
