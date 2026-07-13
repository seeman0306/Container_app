import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smart_city_container/core/utils/api_constants.dart';
import 'package:smart_city_container/core/utils/token_storage.dart';
import 'package:smart_city_container/core/services/location_service.dart';
import 'package:smart_city_container/core/theme/app_colors.dart';

class RaiseComplaint extends StatefulWidget {
  const RaiseComplaint({super.key});

  @override
  State<RaiseComplaint> createState() => _RaiseComplaintState();
}

class _RaiseComplaintState extends State<RaiseComplaint> with WidgetsBindingObserver {
  final _addressCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _wardCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  bool loading = false;
  String? category;
  String? severity;
  Position? currentPosition;
  XFile? _image;
  bool _isAnalyzing = false;
  String? _mlCategory;
  String? _mlSeverity;
  bool _manualEntry = false;

  final ImagePicker _picker = ImagePicker();

  final List<String> categories = [
    "Pipe Breakage",
    "Leakage",
    "Overflow",
    "Sinkhole",
    "Manhole Missing",
    "Clogged Drain",
    "Others"
  ];

  // Map ML Model output to UI labels
  final Map<String, String> _mlToUiMap = {
    "Breakage": "Pipe Breakage",
    "Pipe_Leak": "Leakage",
    "Overflow": "Overflow",
    "Sinkhole": "Sinkhole",
    "Manhole_Missing": "Manhole Missing",
    "Clogged_Drain": "Clogged Drain",
    "Others": "Others",
  };

  final List<String> severities = ["Low", "Medium", "High"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showLocationDialog());
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Force user to choose
      builder: (context) => AlertDialog(
        title: const Text("Use Location?"),
        content: const Text(
            "To automatically fill your address, we need access to your location."),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _manualEntry = true);
              Navigator.pop(context); // Close dialog
            },
            child: const Text("DENY", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _manualEntry = false);
              Navigator.pop(context); // Close dialog
              _fetchLocation(); // Start fetching
            },
            child: const Text("ALLOW",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _addressCtrl.dispose();
    _streetCtrl.dispose();
    _areaCtrl.dispose();
    _wardCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Retry fetching location if it's missing or if we were waiting for GPS activation
      if (currentPosition == null) {
        _fetchLocation();
      }
    }
  }

  Future<void> _fetchLocation() async {
    setState(() => loading = true);
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Fetching GPS location..."),
            duration: Duration(seconds: 1)),
      );

      final pos = await LocationService.getCurrentLocation();
      currentPosition = pos;

      if (kIsWeb) {
        _addressCtrl.text = "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
        _cityCtrl.text = "Rajapalayam";

        final detectedWard = await LocationService.getWardFromLocation(pos.latitude, pos.longitude);
        if (detectedWard != null) {
          _wardCtrl.text = detectedWard;
        }
      } else {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            pos.latitude,
            pos.longitude,
          );
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            _addressCtrl.text = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}";
            _streetCtrl.text = place.street ?? place.name ?? "";
            _cityCtrl.text = "Rajapalayam";

            String detectedArea = "";
            bool isVenganallur = false;
            List<String?> allFields = [
              place.subLocality, place.locality, place.street, place.name,
              place.subAdministrativeArea, place.administrativeArea,
              place.thoroughfare, place.subThoroughfare
            ];

            for (var field in allFields) {
              if (field != null && field.toLowerCase().contains("venganallur")) {
                isVenganallur = true;
                break;
              }
            }

            if (isVenganallur) {
              detectedArea = "Vadaku Venganallur";
            } else {
              detectedArea = (place.subLocality != null && place.subLocality!.isNotEmpty)
                  ? place.subLocality!
                  : (place.locality != null && place.locality!.isNotEmpty)
                      ? place.locality!
                      : (place.subAdministrativeArea ?? place.name ?? "");
            }
            _areaCtrl.text = detectedArea;

            String ward = "";
            try {
              final token = await TokenStorage.getToken();
              final wardResponse = await http.get(
                Uri.parse("${ApiConstants.baseUrl}/api/citizen/ward?lat=${pos.latitude}&lng=${pos.longitude}"),
                headers: {"Authorization": "Bearer $token"},
              );
              if (wardResponse.statusCode == 200) {
                final wardData = jsonDecode(wardResponse.body);
                if (wardData['ward'] != null && wardData['ward'].toString().trim().isNotEmpty) {
                  ward = wardData['ward'].toString();
                }
              }
            } catch (_) {}

            if (ward.isEmpty) {
              RegExp wardRegex = RegExp(r'Ward\s*(?:No\.?)?\s*(\d+)', caseSensitive: false);
              for (var field in allFields) {
                if (field != null) {
                  Match? match = wardRegex.firstMatch(field);
                  if (match != null) {
                    ward = match.group(1) ?? "";
                    break;
                  }
                }
              }
            }
            _wardCtrl.text = ward;
          }
        } catch (e) {
          _addressCtrl.text = "Lat: ${pos.latitude}, Lng: ${pos.longitude}";
        }
      }
    } catch (e) {
      String errorMsg = e.toString().replaceAll("Exception: ", "");
      if (errorMsg.contains("Location services are disabled")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Location is disabled. Enable to auto-fill?"),
            action: SnackBarAction(
              label: "ENABLE",
              onPressed: () async => await Geolocator.openLocationSettings(),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location Error: $errorMsg")),
        );
      }
    }
    setState(() => loading = false);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (photo != null) {
        setState(() => _image = photo);
        _fetchLocation();
        _analyzeImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to capture photo")),
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) return;
    setState(() {
      _isAnalyzing = true;
      _mlCategory = null;
      _mlSeverity = null;
    });
    try {
      final token = await TokenStorage.getToken();
      var request = http.MultipartRequest('POST', Uri.parse("${ApiConstants.baseUrl}/api/citizen/predict"));
      request.headers['Authorization'] = "Bearer $token";
      if (kIsWeb) {
        final bytes = await _image!.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: _image!.name));
      } else {
        request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
      }
      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _mlCategory = data['category'];
          _mlSeverity = data['severity'];
          if (_mlCategory != null && _mlToUiMap.containsKey(_mlCategory)) {
            final uiCategory = _mlToUiMap[_mlCategory];
            if (uiCategory != "Others") category = uiCategory;
          }
          if (_mlSeverity != "NA" && _mlSeverity != null) severity = _mlSeverity;
        });
      }
    } catch (_) {}
    finally { setState(() => _isAnalyzing = false); }
  }

  Future<void> _submitComplaint() async {
    if (category == null || severity == null || _addressCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }
    setState(() => loading = true);
    try {
      final token = await TokenStorage.getToken();
      var request = http.MultipartRequest('POST', Uri.parse("${ApiConstants.baseUrl}/api/citizen/complaints"));
      request.headers['Authorization'] = "Bearer $token";
      request.fields['category'] = category!;
      request.fields['severity'] = severity!;
      request.fields['latitude'] = currentPosition?.latitude.toString() ?? "0";
      request.fields['longitude'] = currentPosition?.longitude.toString() ?? "0";
      request.fields['street'] = _streetCtrl.text;
      request.fields['area'] = _areaCtrl.text;
      request.fields['ward'] = _wardCtrl.text;
      request.fields['city'] = _cityCtrl.text;
      final locMap = {"address": _addressCtrl.text, "lat": currentPosition?.latitude, "lng": currentPosition?.longitude};
      request.fields['location_json'] = jsonEncode(locMap);
      if (_image != null) {
        if (kIsWeb) {
          final bytes = await _image!.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: _image!.name));
        } else {
          request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
        }
      }
      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Complaint raised successfully!")));
        Navigator.pop(context);
      } else {
        throw Exception("Server Error: ${response.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Raise Complaint")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              color: AppColors.primary.withOpacity(0.05),
              child: Row(
                children: [
                  const Icon(Icons.info, size: 18, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      currentPosition == null
                          ? (_manualEntry ? "Enter Location Manually" : "Fetching your location...")
                          : "Location accurately detected",
                      style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (currentPosition == null && !_manualEntry)
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionHeader("LOCATION DETAILS"),
                      TextButton.icon(
                        onPressed: _fetchLocation,
                        icon: const Icon(Icons.my_location, size: 16),
                        label: const Text("Use Current Location", style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        _buildStyledField(_streetCtrl, "Street", Icons.map),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(child: _buildStyledField(_areaCtrl, "Area", Icons.location_city)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildStyledField(_wardCtrl, "Ward No.", Icons.tag)),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildStyledField(_cityCtrl, "City", Icons.business),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _sectionHeader("COMPLAINT DETAILS"),
                  const SizedBox(height: 12),
                  const Text("Category", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((c) => ChoiceChip(
                      label: Text(c),
                      selected: category == c,
                      onSelected: (selected) => setState(() => category = selected ? c : null),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(color: category == c ? Colors.white : Colors.black87),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text("Severity", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: severities.map((s) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Center(child: Text(s)),
                          selected: severity == s,
                          onSelected: (selected) => setState(() => severity = selected ? s : null),
                          selectedColor: s == "High" ? AppColors.error : (s == "Medium" ? AppColors.warning : AppColors.success),
                          labelStyle: TextStyle(color: severity == s ? Colors.white : Colors.black87),
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 32),
                  _sectionHeader("PHOTO EVIDENCE"),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                        image: _image != null
                            ? DecorationImage(
                                image: kIsWeb ? NetworkImage(_image!.path) : FileImage(File(_image!.path)) as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _image == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.camera_alt, size: 32, color: AppColors.primary),
                                const SizedBox(height: 12),
                                const Text("Capture Photo", style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: loading ? null : _submitComplaint,
                      child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text("SUBMIT REPORT"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1.5));
  }

  Widget _buildStyledField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
        border: InputBorder.none,
      ),
    );
  }
}
