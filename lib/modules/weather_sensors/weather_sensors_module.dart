import 'package:flutter/material.dart';
import 'package:smart_city_container/core/utils/secure_token_storage.dart';

class WeatherSensorsModule extends StatefulWidget {
  const WeatherSensorsModule({super.key});

  @override
  State<WeatherSensorsModule> createState() => _WeatherSensorsModuleState();
}

class _WeatherSensorsModuleState extends State<WeatherSensorsModule> {
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
      appBar: AppBar(title: const Text("City Weather Sensors")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatCard("Live Temperature", "32°C", Colors.orange),
            const SizedBox(height: 12),
            _buildStatCard("Relative Humidity", "61% RH", Colors.blue),
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                leading: Icon(Icons.wb_sunny, color: Colors.amber),
                title: Text("Forecast: Clear Skies"),
                subtitle: Text("UV Index: 5 (Moderate)"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficerLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Sensor Diagnostic Field Checks")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.warning, color: Colors.orange),
              title: Text("Rain Gauge Node-12 Error"),
              subtitle: Text("Assigned: Central Park Meteorological Station"),
              trailing: Chip(label: Text("Inspect")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJELayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Meteorological Analytics (JE)")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatCard("Sensor Node Count", "12 Active Stations", Colors.blue),
            const SizedBox(height: 12),
            _buildStatCard("Barometric Trend", "1012 hPa (Stable)", Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Barometer Node Calibration")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_sync, size: 64, color: Colors.blue),
            const SizedBox(height: 12),
            const Text("Last Sync: 10 Mins Ago"),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text("FORCE SYNC ALL NODES"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionerLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Disaster Management Control")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatCard("Severe Weather Warnings", "0 Active Alarms", Colors.green),
            const SizedBox(height: 12),
            _buildStatCard("Climate Action Budget", "₹ 25.0 Lakhs", Colors.blue),
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
