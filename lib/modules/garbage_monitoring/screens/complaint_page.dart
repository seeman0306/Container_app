import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:smart_city_container/core/utils/api_constants.dart';
import 'package:smart_city_container/core/utils/secure_token_storage.dart';
import 'package:smart_city_container/core/services/api_client.dart';
import 'package:smart_city_container/core/theme/app_colors.dart';
import 'success_page.dart';

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _wardController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  List<String> _selectedCategories = [];
  String? _selectedSeverity;
  DateTime? _noticedDate;
  XFile? _pickedImage;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'Garbage Overflow',
    'Illegal Dumping',
    'Dead Animal',
    'Littering',
    'Bin Damaged',
    'Others'
  ];

  final List<String> _severities = ['Low', 'Medium', 'High'];
  final TextEditingController _otherCategoryController = TextEditingController();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _pickedImage = image;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _submitComplaint() async {
    if (_selectedCategories.isEmpty || _selectedSeverity == null || _streetController.text.isEmpty || _noticedDate == null || _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields and upload a photo')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final bytes = await _pickedImage!.readAsBytes();
      final imageBase64 = base64Encode(bytes);

      final Map<String, dynamic> payload = {
        'module_id': 6, // Solid Waste
        'title': _selectedCategories.join(', '),
        'description': _selectedCategories.contains('Others')
            ? _otherCategoryController.text
            : 'Issue noticed on ${_noticedDate!.day}/${_noticedDate!.month}/${_noticedDate!.year}',
        'ward_no': int.tryParse(_wardController.text) ?? 1,
        'address': '${_streetController.text}, ${_areaController.text}, ${_cityController.text}',
        'latitude': 0.0,
        'longitude': 0.0,
        'photo': imageBase64,
      };

      final response = await ApiClient.post('/api/citizen/complaints', payload);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SuccessPage()),
          );
        }
      } else {
        String errorMsg = 'Server error';
        try {
          final errorData = jsonDecode(response.body);
          errorMsg = errorData['error'] ?? errorMsg;
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint("Complaint submission error: $e");
      String displayError = e.toString().replaceAll('Exception: ', '');
      if (displayError.contains('OperationError')) {
        displayError = "Connection failed. Please ensure the backend is running and image size is small.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $displayError'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Raise Complaint'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppColors.primary.withOpacity(0.1),
              child: const Row(
                children: [
                  Icon(Icons.location_on, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Provide issue location details',
                      style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('LOCATION DETAILS'),
                  const SizedBox(height: 12),
                  _buildTextField(_streetController, 'Street', Icons.map_outlined),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_areaController, 'Area', Icons.location_city)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          _wardController,
                          'Ward No',
                          Icons.grid_3x3,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(_cityController, 'City', Icons.apartment),

                  const SizedBox(height: 30),

                  _buildSectionTitle('COMPLAINT DETAILS'),
                  const SizedBox(height: 8),
                  const Text('Category', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) => _buildChip(cat)).toList(),
                  ),

                  if (_selectedCategories.contains('Others')) ...[
                    const SizedBox(height: 16),
                    const Text('Please describe the issue', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 8),
                    _buildTextField(_otherCategoryController, 'Enter details for "Others"', Icons.edit_note, maxLines: 3),
                  ],

                  const SizedBox(height: 20),
                  const Text('Severity', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: _severities.map((sev) => Expanded(child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: _buildSeverityButton(sev),
                    ))).toList(),
                  ),

                  const SizedBox(height: 20),
                  const Text('Date Problem Noticed *', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _noticedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _noticedDate == null
                                ? 'Select Date'
                                : '${_noticedDate!.day}/${_noticedDate!.month}/${_noticedDate!.year}',
                            style: TextStyle(color: _noticedDate == null ? Colors.grey : Colors.black87),
                          ),
                          const Icon(Icons.calendar_month, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  _buildSectionTitle('PHOTO EVIDENCE'),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _pickedImage == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Tap to capture photo (Compulsory) *', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            )
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                kIsWeb
                                    ? Image.network(_pickedImage!.path, fit: BoxFit.cover)
                                    : Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    radius: 14,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, size: 14, color: Colors.white),
                                      onPressed: () => setState(() => _pickedImage = null),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitComplaint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'SUBMIT COMPLAINT',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF455A64), letterSpacing: 1),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 18, color: Colors.black54),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    bool isSelected = _selectedCategories.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedCategories.remove(label);
          } else {
            _selectedCategories.add(label);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D47A1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityButton(String label) {
    bool isSelected = _selectedSeverity == label;
    Color activeColor;
    if (label == 'Low') activeColor = Colors.green;
    else if (label == 'Medium') activeColor = Colors.orange;
    else activeColor = Colors.red;

    return GestureDetector(
      onTap: () => setState(() => _selectedSeverity = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? activeColor : Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
