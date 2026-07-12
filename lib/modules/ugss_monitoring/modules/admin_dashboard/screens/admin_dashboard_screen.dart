import 'package:flutter/material.dart';
import 'package:smart_city_container/core/theme/app_colors.dart';
import 'overview_tab.dart';
import 'complaint_analytics_tab.dart';
import '../tabs/operator_monitoring/operator_monitoring_tab.dart';
import '../tabs/operator_monitoring/inspector_matrix_view.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 4 Tabs: Overview, Complaints, Inspector Matrix, Operations
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Complaints'),
            Tab(text: 'Inspector Matrix'),
            Tab(text: 'Operations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          OverviewTab(),
          ComplaintAnalyticsTab(),
          InspectorMatrixView(),
          OperatorMonitoringTab(),
        ],
      ),
    );
  }
}


