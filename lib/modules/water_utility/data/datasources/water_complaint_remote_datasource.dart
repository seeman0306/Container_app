import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/services/api_client.dart';
import '../../../../core/utils/api_constants.dart';
import '../../../../core/utils/secure_token_storage.dart';
import '../models/water_complaint_model.dart';

class WaterComplaintRemoteDataSource {
  final String _baseUrl = ApiConstants.baseUrl;

  Future<List<WaterComplaintModel>> getMyComplaints({String? status}) async {
    final path = "/api/citizen/water-utility/my-complaints${status != null && status != 'All' ? '?status=$status' : ''}";
    final response = await ApiClient.get(path);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => WaterComplaintModel.fromJson(json)).toList();
    } else {
      throw Exception("Failed to fetch complaints: ${response.body}");
    }
  }

  Future<WaterComplaintModel> getComplaintDetail(int id) async {
    final path = "/api/citizen/water-utility/complaints/$id";
    final response = await ApiClient.get(path);

    if (response.statusCode == 200) {
      return WaterComplaintModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to fetch complaint detail: ${response.body}");
    }
  }

  Future<void> raiseComplaint(WaterComplaintModel complaint) async {
    final path = "/api/citizen/water-utility/complaints";
    final response = await ApiClient.post(path, complaint.toJson());

    if (response.statusCode != 201) {
      throw Exception("Failed to submit complaint: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> classifyImage(String imagePath) async {
    final url = Uri.parse("$_baseUrl/api/citizen/water-utility/classify");
    final request = http.MultipartRequest("POST", url);

    final token = await SecureTokenStorage.getAccessToken();
    if (token != null) {
      request.headers["Authorization"] = "Bearer $token";
    }

    request.files.add(await http.MultipartFile.fromPath("image", imagePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("AI classification failed: ${response.body}");
    }
  }
}
