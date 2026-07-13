class WaterComplaint {
  final int? complaintId;
  final String userPhone;
  final String category;
  final int wardNo;
  final int? assignedOfficerId;
  final String? assignedOfficer;
  final String location;
  final double latitude;
  final double longitude;
  final String reason;
  final String severity;
  final String? complaintPhoto;
  final String? aiDetectedIssue;
  final double? aiConfidence;
  final String status;
  final DateTime? createdAt;

  const WaterComplaint({
    this.complaintId,
    required this.userPhone,
    required this.category,
    required this.wardNo,
    this.assignedOfficerId,
    this.assignedOfficer,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.reason,
    required this.severity,
    this.complaintPhoto,
    this.aiDetectedIssue,
    this.aiConfidence,
    required this.status,
    this.createdAt,
  });

  WaterComplaint copyWith({
    int? complaintId,
    String? userPhone,
    String? category,
    int? wardNo,
    int? assignedOfficerId,
    String? assignedOfficer,
    String? location,
    double? latitude,
    double? longitude,
    String? reason,
    String? severity,
    String? complaintPhoto,
    String? aiDetectedIssue,
    double? aiConfidence,
    String? status,
    DateTime? createdAt,
  }) {
    return WaterComplaint(
      complaintId: complaintId ?? this.complaintId,
      userPhone: userPhone ?? this.userPhone,
      category: category ?? this.category,
      wardNo: wardNo ?? this.wardNo,
      assignedOfficerId: assignedOfficerId ?? this.assignedOfficerId,
      assignedOfficer: assignedOfficer ?? this.assignedOfficer,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      reason: reason ?? this.reason,
      severity: severity ?? this.severity,
      complaintPhoto: complaintPhoto ?? this.complaintPhoto,
      aiDetectedIssue: aiDetectedIssue ?? this.aiDetectedIssue,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
