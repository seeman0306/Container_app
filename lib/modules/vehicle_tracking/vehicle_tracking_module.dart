import 'package:flutter/material.dart';
import 'package:smart_city_container/core/utils/secure_token_storage.dart';

class VehicleTrackingModule extends StatefulWidget {
  const VehicleTrackingModule({super.key});

  @override
  State<VehicleTrackingModule> createState() => _VehicleTrackingModuleState();
}

class _VehicleTrackingModuleState extends State<VehicleTrackingModule> {
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
      appBar: AppBar(title: const Text("Transit Vehicle Track")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.directions_bus, color: Colors.blue),
              title: Text("Bus 29B (Route Center)"),
              subtitle: Text("Approaching St. 4 in 5 mins"),
              trailing: Chip(label: Text("On Time")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficerLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Field Vehicle Allocation")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.car_rental, color: Colors.green),
              title: Text("Inspection Jeep #5"),
              subtitle: Text("Fuel Level: 82%"),
              trailing: Icon(Icons.gps_fixed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJELayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Fleet Management (JE)")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatCard("Municipal Fleet Active", "48/50 Vehicles", Colors.green),
            const SizedBox(height: 12),
            _buildStatCard("Out of Service", "2 Units (Maintenance)", Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Route Dispatcher")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map, size: 64, color: Colors.indigo),
            const SizedBox(height: 12),
            const Text("GPS Dispatch Status: Active"),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text("SYNC ROUTE MAPS"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionerLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Municipal Transit Control")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatCard("Monthly Fuel Offset", "₹ 2.4 Lakhs", Colors.green),
            const SizedBox(height: 12),
            _buildStatCard("Total Fleet Value", "₹ 3.2 Crores", Colors.blue),
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
