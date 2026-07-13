import 'package:flutter/material.dart';
import 'package:smart_city_container/core/utils/secure_token_storage.dart';

class PollutionMonitoringModule extends StatefulWidget {
  const PollutionMonitoringModule({super.key});

  @override
  State<PollutionMonitoringModule> createState() => _PollutionMonitoringModuleState();
}

class _PollutionMonitoringModuleState extends State<PollutionMonitoringModule> {
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
      appBar: AppBar(title: const Text("Air Quality Index (Citizen)")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatCard("Live AQI (Moderate)", "142", Colors.orange),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.masks, size: 40, color: Colors.blue),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text("Wear masks if you have respiratory issues. Outdoor exercises should be minimized."),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficerLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Pollution Inspections")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.business, color: Colors.red),
              title: Text("Industrial Exhaust Violation"),
              subtitle: Text("Sector 3 Steel Factory"),
              trailing: Chip(label: Text("Inspect")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJELayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Pollution Data Analytics")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildStatCard("Active Air Sensors", "24/24 Online", Colors.green),
          const SizedBox(height: 12),
          _buildStatCard("Highest Reading Zone", "Industrial Zone (AQI 210)", Colors.red),
        ],
      ),
    );
  }

  Widget _buildOperatorLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Pollution Sensor Calibration")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings_input_component, size: 64, color: Colors.blue),
            const SizedBox(height: 12),
            const Text("Last Calibration: 3 Days Ago"),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text("RUN DIAGNOSTICS"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionerLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("City Green Action Control")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatCard("Industrial Fine Collection", "₹ 4.5 Lakhs Today", Colors.green),
            const SizedBox(height: 12),
            _buildStatCard("Total Sensor Budget", "₹ 15.0 Lakhs", Colors.blue),
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
