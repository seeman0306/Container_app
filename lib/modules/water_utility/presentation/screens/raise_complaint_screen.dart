import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/utils/secure_token_storage.dart';
import '../../domain/entities/water_complaint.dart';
import '../providers/water_complaint_provider.dart';
import '../widgets/ai_suggestion_card.dart';

class RaiseComplaintScreen extends ConsumerStatefulWidget {
  const RaiseComplaintScreen({super.key});

  @override
  ConsumerState<RaiseComplaintScreen> createState() => _RaiseComplaintScreenState();
}

class _RaiseComplaintScreenState extends ConsumerState<RaiseComplaintScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _street;
  String? _area;
  String? _city;
  String? _wardNumber;
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;

  String? _selectedReason;
  String _selectedSeverity = "Medium";
  File? _imageFile;
  String? _base64Image;

  final List<String> _reasons = [
    "Pipe Breakage",
    "Leakage",
    "Overflow",
    "Sinkhole",
    "Manhole Missing",
    "Clogged Drain",
    "Water Contamination",
    "Low Water Pressure",
    "No Water Supply",
    "Illegal Connection",
    "Valve Damage",
    "Water Meter Issue",
    "Others"
  ];

  final List<String> _severities = ["Low", "Medium", "High", "Critical"];

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final pos = await LocationService.getCurrentLocation();
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });

      // Fetch Ward
      final ward = await LocationService.getWardFromLocation(pos.latitude, pos.longitude);
      setState(() {
        _wardNumber = ward ?? "1"; // Fallback to Ward 1
      });

      // Reverse Geocoding
      try {
        final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          setState(() {
            _street = place.street ?? "Street Info Unavailable";
            _area = place.subLocality ?? place.locality ?? "Area Info Unavailable";
            _city = place.locality ?? place.subAdministrativeArea ?? "City Info Unavailable";
          });
        }
      } catch (_) {
        // Fallback for emulators/desktops where reverse geocoding might fail
        setState(() {
          _street = "Main Street";
          _area = "Sector ${_wardNumber ?? '1'}";
          _city = "Smart City";
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location Error: ${e.toString()}")),
        );
      }
      // Set simulated location on error/denial to allow testing
      setState(() {
        _latitude = 13.0827;
        _longitude = 80.2707;
        _wardNumber = "5";
        _street = "Simulated Street";
        _area = "Simulated Area";
        _city = "Simulated City";
      });
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(source: source, imageQuality: 85);
      if (image != null) {
        final file = File(image.path);
        final bytes = await file.readAsBytes();
        setState(() {
          _imageFile = file;
          _base64Image = base64Encode(bytes);
        });

        // Trigger AI Classification
        ref.read(aiClassificationProvider.notifier).classify(image.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick image: $e")),
      );
    }
  }

  void _applyAiSuggestion(String reason, String severity) {
    setState(() {
      _selectedReason = _reasons.firstWhere(
        (r) => r.toLowerCase() == reason.toLowerCase(),
        orElse: () => "Others",
      );
      _selectedSeverity = _severities.firstWhere(
        (s) => s.toLowerCase() == severity.toLowerCase(),
        orElse: () => "Medium",
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("AI suggestion applied successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a complaint reason")),
      );
      return;
    }

    final phone = await SecureTokenStorage.getPhone() ?? "9999999999";
    final aiState = ref.read(aiClassificationProvider);

    final complaint = WaterComplaint(
      userPhone: phone,
      category: "Water Utility",
      wardNo: int.tryParse(_wardNumber ?? "1") ?? 1,
      location: "${_street ?? ''}, ${_area ?? ''}, ${_city ?? ''}".trim(),
      latitude: _latitude ?? 0.0,
      longitude: _longitude ?? 0.0,
      reason: _selectedReason!,
      severity: _selectedSeverity,
      complaintPhoto: _base64Image,
      aiDetectedIssue: aiState.predictedIssue,
      aiConfidence: aiState.confidence,
      status: "Pending",
    );

    // Call submit provider
    await ref.read(raiseComplaintProvider.notifier).submitComplaint(complaint);
  }

  @override
  Widget build(BuildContext context) {
    final raiseState = ref.watch(raiseComplaintProvider);
    final aiState = ref.watch(aiClassificationProvider);

    // Listen to raise state changes
    ref.listen<AsyncValue<void>?>(raiseComplaintProvider, (previous, next) {
      if (next != null) {
        next.when(
          data: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Complaint raised successfully!"),
                backgroundColor: Colors.green,
              ),
            );
            ref.read(myComplaintsProvider.notifier).fetchComplaints();
            ref.read(offlineCountProvider.notifier).checkOfflineCount();
            ref.read(aiClassificationProvider.notifier).clear();
            Navigator.pop(context);
          },
          error: (err, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(err.toString().replaceAll("Exception: ", "")),
                backgroundColor: err.toString().contains("offline") ? Colors.orange : Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
            if (err.toString().contains("offline") || err.toString().contains("unreachable")) {
              ref.read(myComplaintsProvider.notifier).fetchComplaints();
              ref.read(offlineCountProvider.notifier).checkOfflineCount();
              ref.read(aiClassificationProvider.notifier).clear();
              Navigator.pop(context);
            }
          },
          loading: () {},
        );
      }
    });

    final isSubmitting = raiseState?.isLoading ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Raise Water Complaint", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade900,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: Location Details
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Location Details",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              if (_isLocating)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                TextButton.icon(
                                  onPressed: _fetchCurrentLocation,
                                  icon: const Icon(Icons.my_location, size: 16),
                                  label: const Text("Refetch Location", style: TextStyle(fontSize: 12)),
                                ),
                            ],
                          ),
                          const Divider(),
                          if (_latitude != null && _longitude != null) ...[
                            _buildLocationRow("Address", "${_street ?? ''}, ${_area ?? ''}, ${_city ?? ''}"),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _buildLocationRow("Ward", "Ward ${_wardNumber ?? 'N/A'}")),
                                Expanded(child: _buildLocationRow("Latitude", _latitude!.toStringAsFixed(6))),
                                Expanded(child: _buildLocationRow("Longitude", _longitude!.toStringAsFixed(6))),
                              ],
                            ),
                          ] else ...[
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Text("Detecting location..."),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section: Image Upload
                  Text(
                    "Photo Evidence",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _imageFile != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _imageFile!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black.withOpacity(0.5),
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      onPressed: () {
                                        setState(() {
                                          _imageFile = null;
                                          _base64Image = null;
                                        });
                                        ref.read(aiClassificationProvider.notifier).clear();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                const Text("Upload image for AI classification", style: TextStyle(color: Colors.grey)),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _pickImage(ImageSource.camera),
                                      icon: const Icon(Icons.camera),
                                      label: const Text("Camera"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade800,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton.icon(
                                      onPressed: () => _pickImage(ImageSource.gallery),
                                      icon: const Icon(Icons.photo),
                                      label: const Text("Gallery"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section: AI Suggestion Card
                  if (aiState.isLoading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 8),
                            Text(
                              "YOLOv11 analyzing image...",
                              style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (aiState.predictedIssue != null)
                    AiSuggestionCard(
                      detectedIssue: aiState.predictedIssue!,
                      confidence: aiState.confidence!,
                      suggestedSeverity: aiState.suggestedSeverity!,
                      onApply: () => _applyAiSuggestion(
                        aiState.predictedIssue!,
                        aiState.suggestedSeverity!,
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Section: Complaint Reason (Selectable Chips)
                  Text(
                    "Complaint Reason",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _reasons.map((reason) {
                      final isSelected = _selectedReason == reason;
                      return ChoiceChip(
                        label: Text(reason),
                        selected: isSelected,
                        selectedColor: Colors.blue.shade100,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.blue.shade900 : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedReason = selected ? reason : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Section: Severity Levels
                  Text(
                    "Severity Level",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _severities.map((severity) {
                      final isSelected = _selectedSeverity == severity;
                      Color severityColor = Colors.blue;
                      switch (severity.toLowerCase()) {
                        case 'low':
                          severityColor = Colors.green;
                          break;
                        case 'medium':
                          severityColor = Colors.orange;
                          break;
                        case 'high':
                          severityColor = Colors.red;
                          break;
                        case 'critical':
                          severityColor = Colors.red.shade900;
                          break;
                      }

                      return ChoiceChip(
                        label: Text(severity),
                        selected: isSelected,
                        selectedColor: severityColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? severityColor : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedSeverity = severity;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  ElevatedButton(
                    onPressed: isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "SUBMIT COMPLAINT",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Submitting Complaint...", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
