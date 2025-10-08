import 'package:flutter/material.dart';
import 'package:kidicapp_flutter/services/health/vaccine_service.dart';
import 'package:kidicapp_flutter/services/auth/auth_service.dart';

class VaccinesTab extends StatefulWidget {
  final int? childId; // Optional: if null, will use first child

  const VaccinesTab({super.key, this.childId});

  @override
  State<VaccinesTab> createState() => _VaccinesTabState();
}

class _VaccinesTabState extends State<VaccinesTab> {
  final VaccineService _vaccineService = VaccineService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> vaccines = [];
  List<Map<String, dynamic>> _children = [];
  Map<String, dynamic>? _selectedChild;
  bool _isLoading = true;
  int? _selectedChildId;

  @override
  void initState() {
    super.initState();
    _loadChildrenAndVaccines();
  }

  /// Calculate age from date of birth
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
        return '$years years $months months';
      } else if (months > 0) {
        return '$months months';
      } else {
        return '${difference.inDays} days';
      }
    } catch (e) {
      return 'Age unknown';
    }
  }

  /// Load children list and vaccines
  Future<void> _loadChildrenAndVaccines() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get family data to populate children list
      final familyData = await _authService.getFamilyData();
      if (familyData != null) {
        final children = familyData['children'] as List<dynamic>?;
        if (children != null && children.isNotEmpty) {
          _children = children.map((child) {
            return {
              'id': child['id'],
              'name': child['name'],
              'age': _calculateAge(child['dateOfBirth']),
              'dateOfBirth': child['dateOfBirth'],
            };
          }).toList();

          // Auto-select child based on widget.childId or use first child
          if (widget.childId != null) {
            _selectedChild = _children.firstWhere(
              (child) => child['id'] == widget.childId,
              orElse: () => _children[0],
            );
          } else {
            _selectedChild = _children[0];
          }
          _selectedChildId = _selectedChild?['id'];
        }
      }

      // Now load vaccines for selected child
      await _loadVaccines();
    } catch (e) {
      debugPrint('❌ Error loading children: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Load vaccines from API
  Future<void> _loadVaccines() async {
    if (_selectedChildId == null) {
      debugPrint('❌ No child ID available');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch vaccines from API
      final fetchedVaccines = await _vaccineService.getVaccinesByChildId(
        _selectedChildId!,
      );

      if (mounted) {
        setState(() {
          vaccines = fetchedVaccines;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading vaccines: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Generate 6 default vaccines
  Future<void> _generateDefaultVaccines() async {
    if (_selectedChildId == null) {
      _showMessage('No child selected', Colors.red);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _vaccineService.generateDefaultVaccines(
      _selectedChildId!,
    );

    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      if (result['success']) {
        _showMessage('6 default vaccines generated!', Colors.green);
        _loadVaccines(); // Refresh list
      } else {
        _showMessage(
          result['message'] ?? 'Failed to generate vaccines',
          Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_children.isEmpty) {
      return const Center(child: Text('Please add a child first'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vaccination Schedule Header
          Row(
            children: [
              const Icon(Icons.medical_services, color: Colors.black),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vaccination Schedule',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Keep track of your child\'s immunizations',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (vaccines.isEmpty)
                ElevatedButton.icon(
                  onPressed: _generateDefaultVaccines,
                  icon: const Icon(Icons.auto_awesome, size: 20),
                  label: const Text('Generate Vaccines'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              if (vaccines.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _showAddVaccineDialog(context),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Record Vaccine'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Child Selector Dropdown
          if (_children.length > 1)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.04,
                vertical: size.height * 0.015,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size.width * 0.03),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Map<String, dynamic>>(
                  value: _selectedChild,
                  hint: const Text('Select a child'),
                  isExpanded: true,
                  onChanged: (Map<String, dynamic>? newValue) {
                    setState(() {
                      _selectedChild = newValue;
                      _selectedChildId = newValue?['id'];
                    });
                    if (newValue != null) {
                      _loadVaccines();
                    }
                  },
                  items: _children.map<DropdownMenuItem<Map<String, dynamic>>>((
                    Map<String, dynamic> child,
                  ) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: child,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: size.width * 0.03,
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            child: Text(
                              child['name']?.substring(0, 1).toUpperCase() ??
                                  'C',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: size.width * 0.025,
                              ),
                            ),
                          ),
                          SizedBox(width: size.width * 0.03),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  child['name'] ?? 'Unknown Child',
                                  style: TextStyle(
                                    fontSize: size.width * 0.04,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  child['age'] ?? 'Age unknown',
                                  style: TextStyle(
                                    fontSize: size.width * 0.03,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          if (_children.length > 1) const SizedBox(height: 24),

          // Show message if no vaccines
          if (vaccines.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(
                    Icons.medical_services_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No vaccines yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate 6 default vaccines to get started',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),

          // Vaccine list
          ...vaccines.map((vaccine) => _buildVaccineItem(vaccine)),
        ],
      ),
    );
  }

  Widget _buildVaccineItem(Map<String, dynamic> vaccine) {
    final String status = vaccine['status'] ?? 'due';
    final Color statusColor = _vaccineService.getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 16),

          // Vaccine info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vaccine['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vaccine['date'] != null
                      ? 'Date: ${vaccine['date']}'
                      : 'No date recorded',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Action buttons
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 20, color: Colors.grey[400]),
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                  _showEditVaccineDialog(context, vaccine);
                  break;
                case 'delete':
                  _confirmDelete(vaccine);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Confirm delete vaccine
  void _confirmDelete(Map<String, dynamic> vaccine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vaccine?'),
        content: Text('Are you sure you want to delete "${vaccine['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteVaccine(vaccine['id']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Delete vaccine
  Future<void> _deleteVaccine(int vaccineId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _vaccineService.deleteVaccine(vaccineId);

    if (mounted) {
      Navigator.pop(context); // Close loading

      if (result['success']) {
        _showMessage('Vaccine deleted', Colors.orange);
        _loadVaccines(); // Refresh
      } else {
        _showMessage(result['message'] ?? 'Failed to delete', Colors.red);
      }
    }
  }

  void _showAddVaccineDialog(BuildContext context) {
    final nameController = TextEditingController();
    final dateController = TextEditingController();
    String selectedStatus = 'due';
    bool isDateTodayOrPast =
        false; // Track if selected date allows status change

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.medical_services,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Record Vaccine',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vaccine Name
                    const Text(
                      'Vaccine Name *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'e.g., DTaP (2nd dose)',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Date
                    const Text(
                      'Date Given',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: 'Select date',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        suffixIcon: Icon(
                          Icons.calendar_today,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() {
                            dateController.text =
                                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

                            // Check if selected date is today or in the past
                            final now = DateTime.now();
                            final today = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            );
                            final selectedDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                            );

                            isDateTodayOrPast =
                                selectedDate.isBefore(today) ||
                                selectedDate.isAtSameMomentAs(today);

                            // If future date, reset status to 'due'
                            if (!isDateTodayOrPast) {
                              selectedStatus = 'due';
                            }
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // Status
                    const Text(
                      'Status *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDateTodayOrPast
                            ? Colors.grey.shade50
                            : Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      items:
                          (isDateTodayOrPast
                                  ? ['completed', 'due', 'overdue']
                                  : ['due'])
                              .map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(status.toUpperCase()),
                                );
                              })
                              .toList(),
                      onChanged: isDateTodayOrPast
                          ? (value) {
                              setState(() {
                                selectedStatus = value!;
                              });
                            }
                          : null, // Only enabled if date is today or past
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    debugPrint('🔵 Add Vaccine button pressed');

                    // Check if child ID is available
                    if (_selectedChildId == null) {
                      debugPrint('❌ No child ID available');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'No child selected. Please try again.',
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                      return;
                    }

                    // Validation
                    if (nameController.text.trim().isEmpty) {
                      debugPrint('❌ Validation failed: Name is empty');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Please enter vaccine name'),
                          backgroundColor: Colors.orange,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                      return;
                    }

                    debugPrint('✅ Validation passed');
                    debugPrint('📋 Name: ${nameController.text.trim()}');
                    debugPrint('📋 Status: $selectedStatus');
                    debugPrint('📋 Date: ${dateController.text}');
                    debugPrint('📋 Child ID: $_selectedChildId');

                    // Close the input dialog first
                    Navigator.of(context).pop();

                    // Show loading dialog
                    showDialog(
                      context: this.context,
                      barrierDismissible: false,
                      builder: (loadingContext) => WillPopScope(
                        onWillPop: () async => false,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  'Recording vaccine...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );

                    try {
                      debugPrint('🚀 Calling API...');

                      // Call API
                      final result = await _vaccineService.addVaccine(
                        childId: _selectedChildId!,
                        name: nameController.text.trim(),
                        status: selectedStatus,
                        date: dateController.text.trim().isNotEmpty
                            ? dateController.text.trim()
                            : null,
                      );

                      debugPrint('📥 API Response: $result');

                      if (mounted) {
                        // Close loading dialog
                        Navigator.of(this.context).pop();

                        if (result['success'] == true) {
                          debugPrint('✅ Vaccine recorded successfully');
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                '✅ Vaccine recorded successfully!',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                          await _loadVaccines();
                        } else {
                          debugPrint(
                            '❌ Failed to record vaccine: ${result['message']}',
                          );
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '❌ ${result['message'] ?? 'Failed to record vaccine'}',
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint('❌ Exception during API call: $e');

                      if (mounted) {
                        // Close loading dialog
                        Navigator.of(this.context).pop();

                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Error: $e'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Save Record',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditVaccineDialog(
    BuildContext context,
    Map<String, dynamic> vaccine,
  ) {
    final nameController = TextEditingController(text: vaccine['name']);
    final dateController = TextEditingController(
      text: vaccine['date']?.toString() ?? '',
    );
    String selectedStatus = vaccine['status'] ?? 'due';

    // Check if current vaccine date is today or past
    bool isDateTodayOrPast = false;
    if (vaccine['date'] != null) {
      try {
        final vaccineDate = DateTime.parse(vaccine['date']);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final dateOnly = DateTime(
          vaccineDate.year,
          vaccineDate.month,
          vaccineDate.day,
        );
        isDateTodayOrPast =
            dateOnly.isBefore(today) || dateOnly.isAtSameMomentAs(today);
      } catch (e) {
        isDateTodayOrPast = false;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Edit Vaccine',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vaccine Name
                    const Text(
                      'Vaccine Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Date
                    const Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: 'YYYY-MM-DD',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() {
                            dateController.text =
                                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Status
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDateTodayOrPast
                            ? Colors.white
                            : Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items:
                          (isDateTodayOrPast
                                  ? ['completed', 'due', 'overdue']
                                  : ['due'])
                              .map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(status.toUpperCase()),
                                );
                              })
                              .toList(),
                      onChanged: isDateTodayOrPast
                          ? (value) {
                              setState(() {
                                selectedStatus = value!;
                              });
                            }
                          : null, // Only enabled if date is today or past
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    debugPrint('🔵 Update Vaccine button pressed');

                    // Validation
                    if (nameController.text.trim().isEmpty) {
                      debugPrint('❌ Validation failed: Name is empty');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Please enter vaccine name'),
                          backgroundColor: Colors.orange,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                      return;
                    }

                    debugPrint('✅ Validation passed');
                    debugPrint('📋 Vaccine ID: ${vaccine['id']}');
                    debugPrint('📋 Name: ${nameController.text.trim()}');
                    debugPrint('📋 Status: $selectedStatus');
                    debugPrint('📋 Date: ${dateController.text}');

                    // Close edit dialog
                    Navigator.of(context).pop();

                    // Show loading dialog
                    showDialog(
                      context: this.context,
                      barrierDismissible: false,
                      builder: (loadingContext) => WillPopScope(
                        onWillPop: () async => false,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  'Updating vaccine...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );

                    try {
                      debugPrint('🚀 Calling update API...');

                      final result = await _vaccineService.updateVaccine(
                        vaccineId: vaccine['id'],
                        name: nameController.text.trim(),
                        status: selectedStatus,
                        date: dateController.text.trim().isNotEmpty
                            ? dateController.text.trim()
                            : null,
                      );

                      debugPrint('📥 API Response: $result');

                      if (mounted) {
                        // Close loading dialog
                        Navigator.of(this.context).pop();

                        if (result['success'] == true) {
                          debugPrint('✅ Vaccine updated successfully');
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                '✅ Vaccine updated successfully!',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                          await _loadVaccines();
                        } else {
                          debugPrint(
                            '❌ Failed to update vaccine: ${result['message']}',
                          );
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '❌ ${result['message'] ?? 'Failed to update vaccine'}',
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint('❌ Exception during API call: $e');

                      if (mounted) {
                        // Close loading dialog
                        Navigator.of(this.context).pop();

                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Error: $e'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Update',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
