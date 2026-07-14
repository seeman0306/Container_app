import 'package:flutter/material.dart';
import 'package:smart_city_container/core/utils/secure_token_storage.dart';
import 'screens/garbage_home_page.dart';

class GarbageMonitoringModule extends StatefulWidget {
  const GarbageMonitoringModule({super.key});

  @override
  State<GarbageMonitoringModule> createState() => _GarbageMonitoringModuleState();
}

class _GarbageMonitoringModuleState extends State<GarbageMonitoringModule> {
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
    return const GarbageHomePage();
  }

  Widget _buildOfficerLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Sanitation Maintenance Work")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.warning, color: Colors.orange),
              title: Text("Dumpster Overflow Report"),
              subtitle: Text("Assigned: Ward 8, Market Square"),
              trailing: Chip(label: Text("In Progress")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJELayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Sanitation Operations (JE)")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatCard("Trash Collection Rate", "91% Bins Cleared", Colors.green),
            const SizedBox(height: 12),
            _buildStatCard("Truck Fleet Online", "14/15 Active", Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("Truck Driver Weigh-In")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.scale, size: 64, color: Colors.green),
            const SizedBox(height: 12),
            const Text("Weigh Station Status: Online"),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text("RECORD BIN WEIGHT"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionerLayout() {
    return Scaffold(
      appBar: AppBar(title: const Text("City Waste Budget Council")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatCard("Total Recycled Waste Today", "4.2 Tons", Colors.green),
            const SizedBox(height: 12),
            _buildStatCard("Landfill Lifespan Status", "Healthy (4.2 Years remaining)", Colors.blue),
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
