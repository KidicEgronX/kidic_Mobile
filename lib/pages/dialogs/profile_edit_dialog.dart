import 'package:flutter/material.dart';
import 'package:kidicapp_flutter/services/auth/auth_service.dart';

class ProfileEditDialog extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onUpdateSuccess;

  const ProfileEditDialog({
    super.key,
    required this.userData,
    required this.onUpdateSuccess,
  });

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  bool? selectedGender;
  bool isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Pre-populate with current data
    nameController = TextEditingController(text: widget.userData['name'] ?? '');
    phoneController = TextEditingController(
      text: widget.userData['phone'] ?? '',
    );
    selectedGender = widget.userData['gender'] is bool
        ? widget.userData['gender']
        : null;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  String _formatGenderDisplay(dynamic gender) {
    if (gender == null) return 'Not specified';
    if (gender is bool) {
      return gender ? 'Male' : 'Female';
    }
    if (gender is String) {
      return gender.toLowerCase() == 'male'
          ? 'Male'
          : gender.toLowerCase() == 'female'
          ? 'Female'
          : 'Not specified';
    }
    return 'Not specified';
  }

  Future<void> _updateProfile() async {
    // Basic validation
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your name'),
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
      final result = await _authService.updateUserProfile(
        name: nameController.text.trim(),
        phone: phoneController.text.trim().isNotEmpty
            ? phoneController.text.trim()
            : null,
        gender: selectedGender,
      );

      if (result['success'] == true) {
        // Update parent widget
        widget.onUpdateSuccess({
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim().isNotEmpty
              ? phoneController.text.trim()
              : 'No phone',
          'gender': selectedGender,
        });

        // Close dialog
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Profile updated successfully!'),
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
            content: Text(result['message'] ?? 'Failed to update profile'),
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
          content: Text('Error updating profile: $e'),
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

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(size.width * 0.04),
      ),
      child: Container(
        width: size.width * 0.9,
        constraints: BoxConstraints(maxHeight: size.height * 0.8),
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
                      color: const Color(0xFF6C5CE7).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit,
                      color: const Color(0xFF6C5CE7),
                      size: size.width * 0.06,
                    ),
                  ),
                  SizedBox(width: size.width * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: size.width * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Update your personal information',
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

              // Profile Picture Section
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: size.width * 0.12,
                      backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: size.width * 0.12,
                        color: const Color(0xFF6C5CE7),
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

              // Email Field (Read-only)
              Text(
                'Email Address',
                style: TextStyle(
                  fontSize: size.width * 0.035,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: size.height * 0.008),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.04,
                  vertical: size.height * 0.015,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(size.width * 0.02),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.email,
                      color: Colors.grey.shade500,
                      size: size.width * 0.04,
                    ),
                    SizedBox(width: size.width * 0.03),
                    Expanded(
                      child: Text(
                        widget.userData['email'] ?? 'No email',
                        style: TextStyle(
                          fontSize: size.width * 0.035,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.lock,
                      color: Colors.grey.shade400,
                      size: size.width * 0.035,
                    ),
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.005),
              Text(
                'Email cannot be changed',
                style: TextStyle(
                  fontSize: size.width * 0.028,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),

              SizedBox(height: size.height * 0.02),

              // Name Field
              Text(
                'Full Name',
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
                decoration: InputDecoration(
                  hintText: 'Enter your full name',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: size.width * 0.035,
                  ),
                  prefixIcon: Icon(
                    Icons.person,
                    color: const Color(0xFF6C5CE7),
                    size: size.width * 0.05,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(size.width * 0.02),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(size.width * 0.02),
                    borderSide: const BorderSide(
                      color: Color(0xFF6C5CE7),
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

              // Phone Field
              Text(
                'Phone Number',
                style: TextStyle(
                  fontSize: size.width * 0.035,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: size.height * 0.008),
              TextField(
                controller: phoneController,
                enabled: !isLoading,
                keyboardType: TextInputType.phone,
                style: TextStyle(fontSize: size.width * 0.035),
                decoration: InputDecoration(
                  hintText: 'Enter your phone number',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: size.width * 0.035,
                  ),
                  prefixIcon: Icon(
                    Icons.phone,
                    color: const Color(0xFF6C5CE7),
                    size: size.width * 0.05,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(size.width * 0.02),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(size.width * 0.02),
                    borderSide: const BorderSide(
                      color: Color(0xFF6C5CE7),
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
                'Gender',
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
                              ? const Color(0xFF6C5CE7).withOpacity(0.1)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(
                            size.width * 0.02,
                          ),
                          border: Border.all(
                            color: selectedGender == true
                                ? const Color(0xFF6C5CE7)
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
                                  ? const Color(0xFF6C5CE7)
                                  : Colors.grey.shade600,
                              size: size.width * 0.045,
                            ),
                            SizedBox(width: size.width * 0.02),
                            Text(
                              'Male',
                              style: TextStyle(
                                fontSize: size.width * 0.035,
                                color: selectedGender == true
                                    ? const Color(0xFF6C5CE7)
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
                              ? const Color(0xFF6C5CE7).withOpacity(0.1)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(
                            size.width * 0.02,
                          ),
                          border: Border.all(
                            color: selectedGender == false
                                ? const Color(0xFF6C5CE7)
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
                                  ? const Color(0xFF6C5CE7)
                                  : Colors.grey.shade600,
                              size: size.width * 0.045,
                            ),
                            SizedBox(width: size.width * 0.02),
                            Text(
                              'Female',
                              style: TextStyle(
                                fontSize: size.width * 0.035,
                                color: selectedGender == false
                                    ? const Color(0xFF6C5CE7)
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

              SizedBox(height: size.height * 0.03),

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
                      onPressed: isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
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
                              'Save Changes',
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
