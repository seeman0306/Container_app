import 'package:flutter/material.dart';
import 'package:smart_city_container/core/utils/secure_token_storage.dart';

class SmartLightingModule extends StatefulWidget {
  const SmartLightingModule({super.key});

  @override
  State<SmartLightingModule> createState() => _SmartLightingModuleState();
}

class _SmartLightingModuleState extends State<SmartLightingModule> {
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
      appBar: AppBar(title: const Text("Smart Streetlights (Citizen)")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatCard("Streetlight Outages Reported", "1 Nearby (Scheduled for repair)", Colors.orange),
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                leading: Icon(Icons.lightbulb, color: Colors.amber),
                title: Text("Auto-Brightness Level"),
                subtitle: Text("Energy Save Mode Active (Dimmed by 20%)"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficerLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Lighting Maintenance Orders")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.warning, color: Colors.red),
              title: Text("Broken LED Pole-4C"),
              subtitle: Text("Assigned: Ring Road Sector 1"),
              trailing: Chip(label: Text("Pending Replacement")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJELayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Streetlight Load Grid (JE)")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatCard("Energy Consumed Tonight", "420 kWh", Colors.blue),
            const SizedBox(height: 12),
            _buildStatCard("Auto Dimming Threshold", "45% (Based on Ambient Lux)", Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Smart Lighting Controller")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lightbulb_outline, size: 64, color: Colors.amber),
            const SizedBox(height: 12),
            const Text("Lighting Controller: Auto Mode"),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text("FORCE ON ALL STREETLIGHTS"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionerLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Smart Grid Energy Council")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatCard("LED Transition Budget Saved", "₹ 2.4 Lakhs This Month", Colors.green),
            const SizedBox(height: 12),
            _buildStatCard("Total Lighting Grid Count", "4,200 Poles", Colors.blue),
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
