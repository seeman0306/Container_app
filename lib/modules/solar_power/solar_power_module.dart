import 'package:flutter/material.dart';
import 'package:smart_city_container/core/utils/secure_token_storage.dart';

class SolarPowerModule extends StatefulWidget {
  const SolarPowerModule({super.key});

  @override
  State<SolarPowerModule> createState() => _SolarPowerModuleState();
}

class _SolarPowerModuleState extends State<SolarPowerModule> {
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
      appBar: AppBar(title: const Text("Citizen Solar Portal")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatCard("Green Energy Generated Today", "148 kWh", Colors.orange),
            const SizedBox(height: 12),
            _buildStatCard("Your Residential Offset", "14.2 kg CO₂ Saved", Colors.green),
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                leading: Icon(Icons.solar_power, color: Colors.orange),
                title: Text("Net Metering Application"),
                subtitle: Text("Status: Approved"),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficerLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Solar Field Maintenance")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.warning, color: Colors.orange),
              title: Text("Inverter Node-3 Fault"),
              subtitle: Text("Assigned: Sector 4 Solar Farm"),
              trailing: Chip(label: Text("Pending Action")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJELayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Solar Generation Grid (JE)")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildStatCard("Grid Capacity Factor", "84.2%", Colors.blue),
          const SizedBox(height: 12),
          _buildStatCard("Active Panel Count", "1,248 Units", Colors.green),
        ],
      ),
    );
  }

  Widget _buildOperatorLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Solar Farm Operator Board")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.power, size: 64, color: Colors.green),
            const SizedBox(height: 12),
            const Text("Main Grid Connection: Active", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text("EMERGENCY SHUTDOWN"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionerLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Clean Energy Invest Board")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatCard("Total Capital Invested", "₹ 1.2 Crores", Colors.blue),
            const SizedBox(height: 12),
            _buildStatCard("Yearly Carbon Savings", "4,200 Tons CO₂", Colors.green),
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
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
