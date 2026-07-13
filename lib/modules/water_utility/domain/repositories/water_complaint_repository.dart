import '../entities/water_complaint.dart';

abstract class WaterComplaintRepository {
  Future<List<WaterComplaint>> getMyComplaints({String? status});
  Future<WaterComplaint> getComplaintDetail(int id);
  Future<void> raiseComplaint(WaterComplaint complaint);
  Future<Map<String, dynamic>> classifyImage(String imagePath);
  Future<void> syncOfflineComplaints();
  Future<int> getOfflineCount();
}
