import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import '../models/water_complaint_model.dart';

class WaterComplaintLocalDataSource {
  static const String _fileName = "pending_water_complaints.json";
  
  // In-memory queue fallback for Web execution
  static final List<WaterComplaintModel> _webMemoryQueue = [];

  Future<dynamic> _getFile() async {
    if (kIsWeb) return null;
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/$_fileName");
  }

  Future<List<WaterComplaintModel>> getQueuedComplaints() async {
    if (kIsWeb) {
      return List.from(_webMemoryQueue);
    }
    try {
      final file = await _getFile();
      if (file == null || !await file.exists()) return [];

      final content = await file.readAsString();
      if (content.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((e) => WaterComplaintModel.fromJson(e)).toList();
    } catch (e) {
      print("Error reading offline queue: $e");
      return [];
    }
  }

  Future<void> saveQueue(List<WaterComplaintModel> complaints) async {
    if (kIsWeb) {
      _webMemoryQueue.clear();
      _webMemoryQueue.addAll(complaints);
      return;
    }
    try {
      final file = await _getFile();
      if (file == null) return;
      final jsonList = complaints.map((e) => e.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      print("Error writing offline queue: $e");
    }
  }

  Future<void> enqueueComplaint(WaterComplaintModel complaint) async {
    final queue = await getQueuedComplaints();
    queue.add(complaint);
    await saveQueue(queue);
  }

  Future<void> clearQueue() async {
    if (kIsWeb) {
      _webMemoryQueue.clear();
      return;
    }
    final file = await _getFile();
    if (file != null && await file.exists()) {
      await file.delete();
    }
  }
}
