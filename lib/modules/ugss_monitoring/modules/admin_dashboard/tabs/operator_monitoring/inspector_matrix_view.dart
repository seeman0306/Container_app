import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../models/operator_analytics.dart';

class InspectorMatrixView extends StatefulWidget {
  final DateTimeRange? dateRange;

  const InspectorMatrixView({super.key, this.dateRange});

  @override
  State<InspectorMatrixView> createState() => _InspectorMatrixViewState();
}

class _InspectorMatrixViewState extends State<InspectorMatrixView> {
  final AdminService _adminService = AdminService();
  late Future<InspectorTaskMatrix> _future;

  @override
  void initState() {
    super.initState();
    _future = _buildFuture();
  }

  @override
  void didUpdateWidget(InspectorMatrixView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dateRange != widget.dateRange) {
      setState(() {
        _future = _buildFuture();
      });
    }
  }

  Future<InspectorTaskMatrix> _buildFuture() {
    final refDate = widget.dateRange?.end ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(refDate);
    return _adminService.getInspectorTaskMatrix(date: dateStr);
  }

  @override
  Widget build(BuildContext context) {
    final refDate = widget.dateRange?.end ?? DateTime.now();
    final dateLabel = DateFormat('yyyy-MM-dd').format(refDate);

    return Column(
      children: [
        /// HEADER
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inspector Compliance Matrix',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Ref Date: $dateLabel',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),

        /// LIST OF CARDS
        Expanded(
          child: FutureBuilder<InspectorTaskMatrix>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red)),
                );
              } else if (!snapshot.hasData || snapshot.data!.tasks.isEmpty) {
                return const Center(
                    child: Text('No inspector compliance data found.'));
              }

              final tasks = snapshot.data!.tasks;

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 24, left: 12, right: 12),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  String displayRole = task.role;
                  if (task.role == 'JUNIOR_ENGINEER') {
                    displayRole = 'Sanitary Inspector';
                  } else if (task.role == 'COMMISSIONER') {
                    displayRole = 'Health Inspector';
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// INSPECTOR INFO
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.teal.shade100,
                                child: Text(
                                  task.inspectorName.isNotEmpty
                                      ? task.inspectorName[0].toUpperCase()
                                      : 'I',
                                  style: TextStyle(
                                      color: Colors.teal.shade900,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.inspectorName,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      displayRole,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          /// STATUS MATRIX
                          Row(
                            children: [
                              Expanded(
                                  child: _buildStatusColumn(
                                      'Daily',
                                      task.daily.isNotEmpty
                                          ? task.daily.values.first
                                          : 'Pending')),
                              Expanded(
                                  child: _buildStatusColumn(
                                      'Weekly',
                                      task.weekly.isNotEmpty
                                          ? task.weekly.values.first
                                          : 'Pending')),
                              Expanded(
                                  child: _buildStatusColumn(
                                      'Monthly',
                                      task.monthly.isNotEmpty
                                          ? task.monthly.values.first
                                          : 'Pending')),
                              Expanded(
                                  child: _buildStatusColumn(
                                      'Yearly',
                                      task.yearly.isEmpty
                                          ? 'Pending'
                                          : task.yearly)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusColumn(String title, String statusText) {
    final String normalized = statusText.toLowerCase().trim();
    Color color = Colors.orange;
    String label = 'Pending';
    String? datePart;

    if (normalized.startsWith('completed') ||
        normalized.startsWith('done') ||
        normalized.startsWith('submitted')) {
      color = Colors.green;
      label = 'Done';
    } else if (normalized.startsWith('missed') ||
        normalized.startsWith('overdue') ||
        normalized.startsWith('failed')) {
      color = Colors.red;
      label = 'Missed';
    }

    final match = RegExp(r'\(([^)]+)\)').firstMatch(statusText);
    if (match != null) {
      datePart = match.group(1);
    }

    return Column(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ),
        if (datePart != null && datePart.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              datePart,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}
