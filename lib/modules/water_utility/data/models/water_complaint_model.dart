import '../../domain/entities/water_complaint.dart';

class WaterComplaintModel extends WaterComplaint {
  const WaterComplaintModel({
    super.complaintId,
    required super.userPhone,
    required super.category,
    required super.wardNo,
    super.assignedOfficerId,
    super.assignedOfficer,
    required super.location,
    required super.latitude,
    required super.longitude,
    required super.reason,
    required super.severity,
    super.complaintPhoto,
    super.aiDetectedIssue,
    super.aiConfidence,
    required super.status,
    super.createdAt,
  });

  factory WaterComplaintModel.fromJson(Map<String, dynamic> json) {
    return WaterComplaintModel(
      complaintId: json['complaint_id'] as int?,
      userPhone: json['user_phone'] as String? ?? '',
      category: json['category'] as String? ?? 'Water Utility',
      wardNo: json['ward_no'] as int? ?? 0,
      assignedOfficerId: json['assigned_officer_id'] as int?,
      assignedOfficer: json['assigned_officer'] as String?,
      location: json['location'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] as String? ?? '',
      severity: json['severity'] as String? ?? 'Medium',
      complaintPhoto: json['complaint_photo'] as String?,
      aiDetectedIssue: json['ai_detected_issue'] as String?,
      aiConfidence: (json['ai_confidence'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'Pending',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (complaintId != null) 'complaint_id': complaintId,
      'user_phone': userPhone,
      'category': category,
      'ward_no': wardNo,
      if (assignedOfficerId != null) 'assigned_officer_id': assignedOfficerId,
      if (assignedOfficer != null) 'assigned_officer': assignedOfficer,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'reason': reason,
      'severity': severity,
      if (complaintPhoto != null) 'complaint_photo': complaintPhoto,
      if (aiDetectedIssue != null) 'ai_detected_issue': aiDetectedIssue,
      if (aiConfidence != null) 'ai_confidence': aiConfidence,
      'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  factory WaterComplaintModel.fromEntity(WaterComplaint entity) {
    return WaterComplaintModel(
      complaintId: entity.complaintId,
      userPhone: entity.userPhone,
      category: entity.category,
      wardNo: entity.wardNo,
      assignedOfficerId: entity.assignedOfficerId,
      assignedOfficer: entity.assignedOfficer,
      location: entity.location,
      latitude: entity.latitude,
      longitude: entity.longitude,
      reason: entity.reason,
      severity: entity.severity,
      complaintPhoto: entity.complaintPhoto,
      aiDetectedIssue: entity.aiDetectedIssue,
      aiConfidence: entity.aiConfidence,
      status: entity.status,
      createdAt: entity.createdAt,
    );
  }
}
