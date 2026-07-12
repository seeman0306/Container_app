import 'package:flutter/material.dart';
import '../core/services/location_service.dart';
import '../modules/ugss_monitoring/ugss_module.dart';
import '../modules/water_utility/water_utility_module.dart';
import '../modules/solar_power/solar_power_module.dart';
import '../modules/pollution_monitoring/pollution_monitoring_module.dart';
import '../modules/vehicle_tracking/vehicle_tracking_module.dart';
import '../modules/water_body_levels/water_body_levels_module.dart';
import '../modules/garbage_monitoring/garbage_monitoring_module.dart';
import '../modules/smart_lighting/smart_lighting_module.dart';
import '../modules/weather_sensors/weather_sensors_module.dart';
import '../modules/health_management/health_management_module.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _detectedWard;
  bool _isDetectingLocation = false;

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      final pos = await LocationService.getCurrentLocation();
      final ward = await LocationService.getWardFromLocation(pos.latitude, pos.longitude);
      setState(() => _detectedWard = ward);
    } catch (e) {
      print("Location detection failed: $e");
    } finally {
      setState(() => _isDetectingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Urban Smart City Dashboard", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (_isDetectingLocation)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_detectedWard != null)
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Chip(
                avatar: const Icon(Icons.location_on, size: 16, color: Colors.blue),
                label: Text("Ward $_detectedWard", style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.blue.shade50,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildModuleTile(
                  "UGSS Monitoring",
                  "95% flow normal",
                  Icons.waves,
                  Colors.green,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UgssModule()),
                    );
                  },
                ),
                _buildModuleTile(
                  "Water Utility",
                  "Usage: 720 KL/day",
                  Icons.water_drop,
                  Colors.blue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WaterUtilityModule()),
                    );
                  },
                ),
                _buildModuleTile(
                  "Solar Power",
                  "68 kWh generated",
                  Icons.sunny,
                  Colors.orange,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SolarPowerModule()),
                    );
                  },
                ),
                _buildModuleTile(
                  "Pollution Monitoring",
                  "AQI 142 (Moderate)",
                  Icons.factory,
                  Colors.red,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PollutionMonitoringModule()),
                    );
                  },
                ),
                _buildModuleTile(
                  "Vehicle Tracking",
                  "48/50 online",
                  Icons.local_shipping,
                  Colors.cyan,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const VehicleTrackingModule()),
                    );
                  },
                ),
                _buildModuleTile(
                  "Water Body Levels",
                  "Tank A: 72% full",
                  Icons.pool,
                  Colors.indigo,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WaterBodyLevelsModule()),
                    );
                  },
                ),
                _buildModuleTile(
                  "Garbage Monitoring",
                  "91% bins emptied",
                  Icons.delete_sweep,
                  Colors.green.shade700,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GarbageMonitoringModule()),
                    );
                  },
                ),
                _buildModuleTile(
                  "Smart Lighting",
                  "58% ON (Auto)",
                  Icons.lightbulb,
                  Colors.amber,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SmartLightingModule()),
                    );
                  },
                ),
                _buildModuleTile(
                  "Weather Sensors",
                  "32°C, 61% RH",
                  Icons.cloud,
                  Colors.blueGrey,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WeatherSensorsModule()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildHealthManagementCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthManagementCard() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HealthManagementModule()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.purple, size: 28),
                const SizedBox(width: 8),
                const Text("Health Management", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Icon(Icons.show_chart, color: Colors.purple.shade200),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHealthStat("Hospitals", "12 Nearby", Icons.local_hospital),
                _buildHealthStat("ICU Beds", "105 Available", Icons.bed),
                _buildHealthStat("Ambulances", "24 Available", Icons.emergency),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade400),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
      ],
    );
  }
}
