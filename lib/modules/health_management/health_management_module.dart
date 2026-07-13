import 'package:flutter/material.dart';
import 'package:smart_city_container/core/utils/secure_token_storage.dart';

class HealthManagementModule extends StatefulWidget {
  const HealthManagementModule({super.key});

  @override
  State<HealthManagementModule> createState() => _HealthManagementModuleState();
}

class _HealthManagementModuleState extends State<HealthManagementModule> {
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    switch (_role) {
      case 'FIELD_OFFICER':
        return _buildOfficerLayout();
      case 'JUNIOR_ENGINEER':
        return _buildJELayout();
      case 'OPERATOR':
        return _buildOperatorLayout();
      case 'COMMISSIONER':
        return _buildCommissionerLayout();
      case 'CITIZEN':
      default:
        return _buildCitizenLayout();
    }
  }

  Widget _buildCitizenLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("City Health Portal")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatCard("Live ICU Bed Availability", "105 Available", Colors.green),
            const SizedBox(height: 12),
            _buildStatCard("Ambulance Services Active", "24 On-Call", Colors.purple),
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                leading: Icon(Icons.local_hospital, color: Colors.purple),
                title: Text("Nearest Hospital"),
                subtitle: Text("City Hospital (1.2 km away)"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficerLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Health Inspection Orders")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.healing, color: Colors.orange),
              title: Text("Sanitary Violation Audit"),
              subtitle: Text("Assigned: Sector 2 Food Court"),
              trailing: Chip(label: Text("Inspect")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJELayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Health Infrastructure Board (JE)")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatCard("Total Hospital Sensors", "48 Online", Colors.blue),
            const SizedBox(height: 12),
            _buildStatCard("Average Response Time", "12 Mins (Normal)", Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Ambulance Dispatch Control")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emergency, size: 64, color: Colors.red),
            const SizedBox(height: 12),
            const Text("Dispatch Status: Live"),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text("DISPATCH AMBULANCE"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionerLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Health & Emergency Resource Board")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatCard("Emergency Funds Allocated", "₹ 48.0 Lakhs This Month", Colors.red),
            const SizedBox(height: 12),
            _buildStatCard("Total Emergency Incidents", "12 Resolved Today", Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
