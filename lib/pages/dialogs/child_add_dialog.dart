import 'package:flutter/material.dart';
import 'package:kidicapp_flutter/services/child/child_service.dart';

class ChildAddDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddSuccess;

  const ChildAddDialog({super.key, required this.onAddSuccess});

  @override
  State<ChildAddDialog> createState() => _ChildAddDialogState();
}

class _ChildAddDialogState extends State<ChildAddDialog> {
  late TextEditingController nameController;
  late TextEditingController medicalNotesController;
  bool? selectedGender;
  DateTime? selectedDateOfBirth;
  bool isLoading = false;
  final ChildService _childService = ChildService();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    medicalNotesController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    medicalNotesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime.now().subtract(
        const Duration(days: 365 * 18),
      ), // 18 years ago
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: Colors.blue.shade600),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDateOfBirth) {
      setState(() {
        selectedDateOfBirth = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date of birth';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateForApi(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _addChild() async {
    // Basic validation
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter child\'s name'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    if (selectedDateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select child\'s date of birth'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    if (selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select child\'s gender'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // Validate using ChildService
    final validationErrors = _childService.validateChildData(
      name: nameController.text.trim(),
      gender: selectedGender,
      dateOfBirth: _formatDateForApi(selectedDateOfBirth),
      medicalNotes: medicalNotesController.text.trim(),
    );

    if (validationErrors.isNotEmpty) {
      // Show first validation error
      final firstError = validationErrors.values.first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(firstError),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await _childService.createChild(
        name: nameController.text.trim(),
        gender: selectedGender!,
        dateOfBirth: _formatDateForApi(selectedDateOfBirth!),
        medicalNotes: medicalNotesController.text.trim().isNotEmpty
            ? medicalNotesController.text.trim()
            : null,
      );

      if (result['success'] == true) {
        // Create child data for UI
        final newChildData = {
          'id': result['data']?['id'] ?? 0,
          'name': nameController.text.trim(),
          'gender': selectedGender,
          'dateOfBirth': _formatDateForApi(selectedDateOfBirth!),
          'medicalNotes': medicalNotesController.text.trim().isNotEmpty
              ? medicalNotesController.text.trim()
              : null,
          // Add calculated fields
          'genderDisplay': selectedGender == true
              ? 'Male'
              : (selectedGender == false ? 'Female' : 'Not specified'),
          'initials': _getChildInitials(nameController.text.trim()),
          'age': _calculateAge(_formatDateForApi(selectedDateOfBirth!)),
        };

        // Update parent widget
        widget.onAddSuccess(newChildData);

        // Close dialog
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Child added successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to add child'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding child: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// Calculate age from date of birth string (duplicated from ChildService for UI)
  String _calculateAge(String? dateOfBirthString) {
    if (dateOfBirthString == null || dateOfBirthString.isEmpty) {
      return 'Age unknown';
    }

    try {
      final dateOfBirth = DateTime.parse(dateOfBirthString);
      final now = DateTime.now();
      final difference = now.difference(dateOfBirth);

      final years = (difference.inDays / 365).floor();
      final months = ((difference.inDays % 365) / 30).floor();

      if (years > 0) {
        if (months > 0) {
          return '$years years $months months';
        } else {
          return '$years ${years == 1 ? 'year' : 'years'}';
        }
      } else if (months > 0) {
        return '$months ${months == 1 ? 'month' : 'months'}';
      } else {
        final days = difference.inDays;
        return '$days ${days == 1 ? 'day' : 'days'}';
      }
    } catch (e) {
      return 'Age unknown';
    }
  }

  /// Get initials from child name for avatar display (duplicated from ChildService for UI)
  String _getChildInitials(String? name) {
    if (name == null || name.isEmpty) return 'C';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(size.width * 0.04),
      ),
      child: Container(
        width: size.width * 0.9,
        constraints: BoxConstraints(maxHeight: size.height * 0.85),
        padding: EdgeInsets.all(size.width * 0.05),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(size.width * 0.025),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_circle,
                      color: Colors.green.shade600,
                      size: size.width * 0.06,
                    ),
                  ),
                  SizedBox(width: size.width * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Child',
                          style: TextStyle(
                            fontSize: size.width * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Add a child to your family',
                          style: TextStyle(
                            fontSize: size.width * 0.035,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLoading)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: Colors.grey.shade600,
                    ),
                ],
              ),

              SizedBox(height: size.height * 0.025),

              // Child Picture Section
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: size.width * 0.12,
                      backgroundColor: Colors.green.withOpacity(0.1),
                      child: Text(
                        _getChildInitials(nameController.text),
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: size.width * 0.08,
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.01),
                    Text(
                      'Profile photo coming soon',
                      style: TextStyle(
                        fontSize: size.width * 0.03,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: size.height * 0.03),

              // Name Field
              Text(
                'Child\'s Full Name *',
                style: TextStyle(
                  fontSize: size.width * 0.035,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: size.height * 0.008),
              TextField(
                controller: nameController,
                enabled: !isLoading,
                style: TextStyle(fontSize: size.width * 0.035),
                onChanged: (value) {
                  setState(() {}); // Rebuild to update avatar initials
                },
                decoration: InputDecoration(
                  hintText: 'Enter child\'s full name',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: size.width * 0.035,
                  ),
                  prefixIcon: Icon(
                    Icons.child_care,
                    color: Colors.green.shade600,
                    size: size.width * 0.05,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(size.width * 0.02),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(size.width * 0.02),
                    borderSide: BorderSide(
                      color: Colors.green.shade600,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.04,
                    vertical: size.height * 0.015,
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.02),

              // Gender Selection
              Text(
                'Gender *',
                style: TextStyle(
                  fontSize: size.width * 0.035,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: size.height * 0.01),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: isLoading
                          ? null
                          : () {
                              setState(() {
                                selectedGender = true; // Male
                              });
                            },
                      borderRadius: BorderRadius.circular(size.width * 0.02),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: size.height * 0.015,
                        ),
                        decoration: BoxDecoration(
                          color: selectedGender == true
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(
                            size.width * 0.02,
                          ),
                          border: Border.all(
                            color: selectedGender == true
                                ? Colors.green.shade600
                                : Colors.grey.shade300,
                            width: selectedGender == true ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.male,
                              color: selectedGender == true
                                  ? Colors.green.shade600
                                  : Colors.grey.shade600,
                              size: size.width * 0.045,
                            ),
                            SizedBox(width: size.width * 0.02),
                            Text(
                              'Male',
                              style: TextStyle(
                                fontSize: size.width * 0.035,
                                color: selectedGender == true
                                    ? Colors.green.shade600
                                    : Colors.grey.shade700,
                                fontWeight: selectedGender == true
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: size.width * 0.03),
                  Expanded(
                    child: InkWell(
                      onTap: isLoading
                          ? null
                          : () {
                              setState(() {
                                selectedGender = false; // Female
                              });
                            },
                      borderRadius: BorderRadius.circular(size.width * 0.02),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: size.height * 0.015,
                        ),
                        decoration: BoxDecoration(
                          color: selectedGender == false
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(
                            size.width * 0.02,
                          ),
                          border: Border.all(
                            color: selectedGender == false
                                ? Colors.green.shade600
                                : Colors.grey.shade300,
                            width: selectedGender == false ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.female,
                              color: selectedGender == false
                                  ? Colors.green.shade600
                                  : Colors.grey.shade600,
                              size: size.width * 0.045,
                            ),
                            SizedBox(width: size.width * 0.02),
                            Text(
                              'Female',
                              style: TextStyle(
                                fontSize: size.width * 0.035,
                                color: selectedGender == false
                                    ? Colors.green.shade600
                                    : Colors.grey.shade700,
                                fontWeight: selectedGender == false
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: size.height * 0.02),

              // Date of Birth Field
              Text(
                'Date of Birth *',
                style: TextStyle(
                  fontSize: size.width * 0.035,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: size.height * 0.008),
              InkWell(
                onTap: isLoading ? null : _selectDateOfBirth,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.04,
                    vertical: size.height * 0.015,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selectedDateOfBirth != null
                          ? Colors.green.shade600
                          : Colors.grey.shade300,
                      width: selectedDateOfBirth != null ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(size.width * 0.02),
                    color: selectedDateOfBirth != null
                        ? Colors.green.withOpacity(0.05)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: selectedDateOfBirth != null
                            ? Colors.green.shade600
                            : Colors.grey.shade600,
                        size: size.width * 0.05,
                      ),
                      SizedBox(width: size.width * 0.03),
                      Expanded(
                        child: Text(
                          _formatDate(selectedDateOfBirth),
                          style: TextStyle(
                            fontSize: size.width * 0.035,
                            color: selectedDateOfBirth != null
                                ? Colors.green.shade700
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.02),

              // Medical Notes Field
              Text(
                'Medical Notes (Optional)',
                style: TextStyle(
                  fontSize: size.width * 0.035,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: size.height * 0.008),
              TextField(
                controller: medicalNotesController,
                enabled: !isLoading,
                maxLines: 3,
                style: TextStyle(fontSize: size.width * 0.035),
                decoration: InputDecoration(
                  hintText: 'Enter any medical notes or conditions...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: size.width * 0.035,
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: size.height * 0.04),
                    child: Icon(
                      Icons.medical_information,
                      color: Colors.green.shade600,
                      size: size.width * 0.05,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(size.width * 0.02),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(size.width * 0.02),
                    borderSide: BorderSide(
                      color: Colors.green.shade600,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.04,
                    vertical: size.height * 0.015,
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.03),

              // Required fields note
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey.shade600,
                    size: size.width * 0.035,
                  ),
                  SizedBox(width: size.width * 0.01),
                  Text(
                    '* Required fields',
                    style: TextStyle(
                      fontSize: size.width * 0.03,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),

              SizedBox(height: size.height * 0.02),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: size.height * 0.015,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            size.width * 0.02,
                          ),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: size.width * 0.035,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: size.width * 0.03),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _addChild,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: size.height * 0.015,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            size.width * 0.02,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: size.width * 0.04,
                              height: size.width * 0.04,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Add Child',
                              style: TextStyle(
                                fontSize: size.width * 0.035,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
