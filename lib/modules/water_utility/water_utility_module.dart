import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_city_container/core/services/api_client.dart';
import 'package:smart_city_container/core/utils/secure_token_storage.dart';
import 'presentation/providers/water_complaint_provider.dart';
import 'presentation/screens/raise_complaint_screen.dart';
import 'presentation/screens/my_complaints_screen.dart';
import 'presentation/screens/complaint_details_screen.dart';

// Main module switcher
class WaterUtilityModule extends StatefulWidget {
  const WaterUtilityModule({super.key});

  @override
  State<WaterUtilityModule> createState() => _WaterUtilityModuleState();
}

class _WaterUtilityModuleState extends State<WaterUtilityModule> {
  bool _isLoading = true;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await SecureTokenStorage.getRole();
    setState(() {
      _role = role;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    switch (_role) {
      case 'FIELD_OFFICER':
        return const WaterUtilityOfficerDashboard();
      case 'JUNIOR_ENGINEER':
        return const WaterUtilityJEDashboard();
      case 'OPERATOR':
        return const WaterUtilityOperatorDashboard();
      case 'COMMISSIONER':
        return const WaterUtilityCommissionerDashboard();
      case 'CITIZEN':
      default:
        return const WaterUtilityCitizenHomeScreen();
    }
  }
}

// CITIZEN SCREEN VIEW (Original Dashboard)
class WaterUtilityCitizenHomeScreen extends ConsumerStatefulWidget {
  const WaterUtilityCitizenHomeScreen({super.key});

  @override
  ConsumerState<WaterUtilityCitizenHomeScreen> createState() => _WaterUtilityCitizenHomeScreenState();
}

class _WaterUtilityCitizenHomeScreenState extends ConsumerState<WaterUtilityCitizenHomeScreen> {
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(myComplaintsProvider.notifier).fetchComplaints();
      ref.read(offlineCountProvider.notifier).checkOfflineCount();
    });
  }

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    try {
      await ref.read(offlineCountProvider.notifier).sync();
      ref.read(myComplaintsProvider.notifier).fetchComplaints();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Offline complaints synced successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sync failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final offlineCount = ref.watch(offlineCountProvider);
    final complaintsAsync = ref.watch(myComplaintsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Water Utility Citizen Portal", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade900,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderBanner(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (offlineCount > 0) _buildOfflineSyncCard(offlineCount),
                  const SizedBox(height: 16),
                  _buildActionsGrid(context),
                  const SizedBox(height: 24),
                  _buildStatisticsSection(complaintsAsync),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recent Reports",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MyComplaintsScreen()),
                          );
                        },
                        child: const Text("View All"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildRecentReportsList(complaintsAsync),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.water_drop, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            "Report Water Infrastructure Issues",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "AI-powered image analysis detects pipe breakages, leakages, water contamination and maps complaints instantly to ward field officers.",
            style: TextStyle(color: Colors.white.withAlpha(230), fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineSyncCard(int count) {
    return Card(
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange.shade200, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.wifi_off_outlined, color: Colors.orange.shade800, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$count Pending Sync",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Complaints submitted offline are saved. Press Sync to upload to servers.",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _isSyncing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.orange),
                  )
                : TextButton(
                    onPressed: _handleSync,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("SYNC", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context,
            "Report Issue",
            "Raise new water complaint",
            Icons.add_photo_alternate,
            Colors.blue.shade800,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RaiseComplaintScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            context,
            "My Complaints",
            "View and track status",
            Icons.list_alt_rounded,
            Colors.indigo.shade800,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyComplaintsScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha(25),
                radius: 28,
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(AsyncValue<List<dynamic>> complaintsAsync) {
    return complaintsAsync.when(
      data: (complaints) {
        final total = complaints.length;
        final pending = complaints.where((e) => e.status.toLowerCase().contains("pending")).length;
        final resolved = complaints.where((e) => e.status.toLowerCase().contains("completed")).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Overview Statistics",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard("Total Reports", total.toString(), Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard("Pending", pending.toString(), Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard("Resolved", resolved.toString(), Colors.green)),
              ],
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReportsList(AsyncValue<List<dynamic>> complaintsAsync) {
    return complaintsAsync.when(
      data: (complaints) {
        if (complaints.isEmpty) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text("No complaints filed yet", style: TextStyle(color: Colors.grey))),
            ),
          );
        }

        final recent = complaints.take(3).toList();
        return Column(
          children: recent.map((complaint) => _buildRecentComplaintItem(complaint)).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text("Error fetching recent reports: $err", style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildRecentComplaintItem(dynamic complaint) {
    final DateTime? date = complaint.createdAt;
    final formattedDate = date != null ? DateFormat('dd MMM, hh:mm a').format(date) : "N/A";

    final Color statusColor;
    switch (complaint.status.toLowerCase()) {
      case 'pending':
      case 'pending (offline)':
        statusColor = Colors.orange;
        break;
      case 'accepted':
        statusColor = Colors.blue;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          complaint.reason,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
        ),
        subtitle: Text(
          "${complaint.location} • $formattedDate",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            complaint.status,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComplaintDetailsScreen(complaintId: complaint.complaintId ?? 0),
            ),
          );
        },
      ),
    );
  }
}

// 1. FIELD OFFICER VIEW FOR WATER UTILITY (Real API Integration)
class WaterUtilityOfficerDashboard extends StatefulWidget {
  const WaterUtilityOfficerDashboard({super.key});

  @override
  State<WaterUtilityOfficerDashboard> createState() => _WaterUtilityOfficerDashboardState();
}

class _WaterUtilityOfficerDashboardState extends State<WaterUtilityOfficerDashboard> {
  List<dynamic> _workOrders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWorkOrders();
  }

  Future<void> _fetchWorkOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.get("/api/field-officer/work-orders");
      if (response.statusCode == 200) {
        final List<dynamic> orders = jsonDecode(response.body);
        // Filter water utility orders (by title or module)
        setState(() {
          _workOrders = orders.where((order) {
            final title = (order['title'] as String).toLowerCase();
            return title.contains("water") || title.contains("supply") || title.contains("leak");
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load: ${response.body}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _actionWorkOrder(int orderId, String action, [String reason = ""]) async {
    try {
      final response = await ApiClient.post(
        "/api/field-officer/work-order/$orderId/action",
        {"action": action, "reason": reason},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Work order successfully $action-ed!")),
        );
        _fetchWorkOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Action failed: ${response.body}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Action error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Water Field Officer Console", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade900,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchWorkOrders),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text("Error: $_error", style: const TextStyle(color: Colors.red)))
              : _workOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
                          const SizedBox(height: 16),
                          const Text("No pending water issues", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text("All complaints resolved in your assigned wards.", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _workOrders.length,
                      itemBuilder: (context, index) {
                        final order = _workOrders[index];
                        final orderId = order['work_order_id'];
                        final isPending = (order['status'] as String).toLowerCase() == 'pending';

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Work Order #$orderId", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                    Chip(
                                      label: Text(order['status']),
                                      backgroundColor: isPending ? Colors.orange.shade50 : Colors.blue.shade50,
                                      labelStyle: TextStyle(color: isPending ? Colors.orange.shade900 : Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(order['title'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                                const SizedBox(height: 4),
                                Text("Ward: ${order['ward']} • Date: ${DateFormat('dd MMM, hh:mm a').format(DateTime.tryParse(order['assigned_date']) ?? DateTime.now())}", style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                if (isPending) ...[
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () => _actionWorkOrder(orderId, "Reject", "Cannot service this location"),
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text("REJECT"),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed: () => _actionWorkOrder(orderId, "Accept"),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
                                        child: const Text("ACCEPT WORK"),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

// 2. JUNIOR ENGINEER VIEW FOR WATER UTILITY (Analytics & Metrics)
class WaterUtilityJEDashboard extends StatelessWidget {
  const WaterUtilityJEDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Water Quality & Grid Analytics (JE)", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade900,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCardRow(),
            const SizedBox(height: 20),
            _buildSectionTitle("Grid Water Pressure Map (Ward 1-10)"),
            _buildPressureCard(),
            const SizedBox(height: 20),
            _buildSectionTitle("Active Technical Logs"),
            _buildTechnicalLogsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
    );
  }

  Widget _buildStatCardRow() {
    return Row(
      children: [
        Expanded(child: _buildJEStatCard("Water Quality", "98.2%", "pH 7.1", Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildJEStatCard("Main Reservoir", "86%", "Normal Flow", Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildJEStatCard("Escalated Issues", "3 Active", "Ward 5, 12, 18", Colors.red)),
      ],
    );
  }

  Widget _buildJEStatCard(String title, String value, String sub, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(fontSize: 10, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildPressureCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Sensor Node-5A", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Status: Normal (3.2 Bar)", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: 0.72, backgroundColor: Colors.blue.shade100, color: Colors.blue.shade800),
            const SizedBox(height: 8),
            const Text("Fluctuations detected during peak hour (08:00 AM - 10:00 AM). Auto-valve calibration enabled.", style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalLogsList() {
    final logs = [
      {"loc": "Overhead Tank B", "msg": "Chlorine dosing calibration completed.", "time": "2 hours ago", "icon": Icons.tune, "color": Colors.green},
      {"loc": "Ward 8 Mainline", "msg": "Leak detection team dispatched.", "time": "4 hours ago", "icon": Icons.engineering, "color": Colors.orange},
      {"loc": "Inlet Valve Node 3", "msg": "Telemeter communication failure alert.", "time": "1 day ago", "icon": Icons.warning, "color": Colors.red},
    ];

    return Column(
      children: logs.map((log) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (log['color'] as Color).withAlpha(25),
              child: Icon(log['icon'] as IconData, color: log['color'] as Color),
            ),
            title: Text(log['loc'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(log['msg'] as String, style: const TextStyle(fontSize: 12)),
            trailing: Text(log['time'] as String, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ),
        );
      }).toList(),
    );
  }
}

// 3. OPERATOR CONSOLE FOR WATER UTILITY
class WaterUtilityOperatorDashboard extends StatefulWidget {
  const WaterUtilityOperatorDashboard({super.key});

  @override
  State<WaterUtilityOperatorDashboard> createState() => _WaterUtilityOperatorDashboardState();
}

class _WaterUtilityOperatorDashboardState extends State<WaterUtilityOperatorDashboard> {
  bool pump1Status = true;
  bool pump2Status = false;
  double flowRate = 120.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Pumping Station Operator Console", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade900,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Station ID: WPS-10B", style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Main Discharge Pump 1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Switch(
                          value: pump1Status,
                          onChanged: (v) => setState(() => pump1Status = v),
                          activeColor: Colors.green,
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Discharge Pump 2 (Backup)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Switch(
                          value: pump2Status,
                          onChanged: (v) => setState(() => pump2Status = v),
                          activeColor: Colors.green,
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text("Flow Rate Control", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Current Flow Rate", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("${flowRate.toStringAsFixed(0)} Liters/sec", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                    Slider(
                      value: flowRate,
                      min: 0,
                      max: 300,
                      divisions: 6,
                      label: "${flowRate.round()}",
                      onChanged: (v) => setState(() => flowRate = v),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 4. COMMISSIONER CITY BUDGET PANEL
class WaterUtilityCommissionerDashboard extends StatelessWidget {
  const WaterUtilityCommissionerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("City Water Infrastructure Board", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade900,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Infrastructure Budget FY 2026-27", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("₹ 4.8 Crores", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Allocated: 62%"),
                        Text("Remaining: ₹ 1.82 Cr"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: 0.62, backgroundColor: Colors.grey.shade200, color: Colors.blue.shade900),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Approval Requests", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildApprovalItem(context, "Ward 22 Pipe Relaying", "Budget Estimate: ₹ 14.5 Lakhs", "Urgent request from J.E. due to repeated valve breaks"),
            _buildApprovalItem(context, "Reservoir B Desilting", "Budget Estimate: ₹ 28.0 Lakhs", "Annual maintenance work request"),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalItem(BuildContext context, String title, String cost, String desc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(cost, style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(onPressed: () {}, child: const Text("REJECT")),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
                  child: const Text("APPROVE"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
