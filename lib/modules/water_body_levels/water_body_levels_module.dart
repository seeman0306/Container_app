import 'package:flutter/material.dart';
import 'package:smart_city_container/core/utils/secure_token_storage.dart';

class WaterBodyLevelsModule extends StatefulWidget {
  const WaterBodyLevelsModule({super.key});

  @override
  State<WaterBodyLevelsModule> createState() => _WaterBodyLevelsModuleState();
}

class _WaterBodyLevelsModuleState extends State<WaterBodyLevelsModule> {
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
      appBar: AppBar(title: const Text("City Water Body Levels")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatCard("Central Reservoir (Normal)", "86% Full", Colors.blue),
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                leading: Icon(Icons.waves, color: Colors.blue),
                title: Text("Gate Spillways Status"),
                subtitle: Text("All 4 gates closed. Normal release flow."),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficerLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Reservoir Field Check")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.security, color: Colors.green),
              title: Text("Spillway Inspection"),
              subtitle: Text("Assigned: North Dam Site"),
              trailing: Chip(label: Text("Scheduled")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJELayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Hydro Analytics (JE)")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatCard("Average Inflow Rate", "340 m³/s", Colors.blue),
            const SizedBox(height: 12),
            _buildStatCard("Siltation Index", "Safe (12%)", Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Reservoir Gate Controls")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text("North Gate Valve: Off"),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text("TOGGLE SPILLWAY GATES"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionerLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Water Resource Council")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatCard("Total Reservoir Reserves", "14,800 Million Liters", Colors.blue),
            const SizedBox(height: 12),
            _buildStatCard("City Supply Target Status", "Safe (105 days reserve)", Colors.green),
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
