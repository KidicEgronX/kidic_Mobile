import 'package:flutter/material.dart';
import 'package:kidicapp_flutter/services/child/milestone_service.dart';
import 'package:kidicapp_flutter/services/auth/auth_service.dart';

class MilestonesTab extends StatefulWidget {
  final int? childId; // Optional: if null, will use first child

  const MilestonesTab({super.key, this.childId});

  @override
  State<MilestonesTab> createState() => _MilestonesTabState();
}

class _MilestonesTabState extends State<MilestonesTab> {
  final MilestoneService _milestoneService = MilestoneService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> milestones = [];
  List<Map<String, dynamic>> _children = [];
  Map<String, dynamic>? _selectedChild;
  bool _isLoading = true;
  int? _selectedChildId;

  @override
  void initState() {
    super.initState();
    _loadChildrenAndMilestones();
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

  /// Load children list and milestones
  Future<void> _loadChildrenAndMilestones() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get family data to load children
      final familyData = await _authService.getFamilyData();

      if (familyData != null) {
        final childrenData = familyData['children'] as List<dynamic>?;

        if (childrenData != null && childrenData.isNotEmpty) {
          final processedChildren = childrenData.map((child) {
            return {
              'id': child['id'],
              'name': child['name'],
              'age': _calculateAge(child['dateOfBirth']),
              'dateOfBirth': child['dateOfBirth'],
            };
          }).toList();

          setState(() {
            _children = List<Map<String, dynamic>>.from(processedChildren);
          });

          // Auto-select specific child if childId is provided, otherwise select first child
          if (_children.isNotEmpty) {
            if (widget.childId != null) {
              // Find and select the specific child
              final specificChild = _children.firstWhere(
                (child) => child['id'] == widget.childId,
                orElse: () => _children.first,
              );
              _selectedChild = specificChild;
              _selectedChildId = specificChild['id'];
            } else {
              _selectedChild = _children.first;
              _selectedChildId = _children.first['id'];
            }

            // Load milestones for selected child
            await _loadMilestones();
          }
        } else {
          setState(() {
            _children = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading children: $e');
      setState(() {
        _children = [];
        _isLoading = false;
      });
    }
  }

  /// Load milestones from API
  Future<void> _loadMilestones() async {
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
      // Fetch milestones from API
      final fetchedMilestones = await _milestoneService.getMilestonesByChildId(
        _selectedChildId!,
      );

      if (mounted) {
        setState(() {
          milestones = fetchedMilestones;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading milestones: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Generate 10 built-in milestones
  Future<void> _generateBuiltInMilestones() async {
    if (_selectedChildId == null) {
      _showMessage('No child selected', Colors.red);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _milestoneService.generateBuiltInMilestones(
      _selectedChildId!,
    );

    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      if (result['success']) {
        _showMessage('10 built-in milestones generated!', Colors.green);
        _loadMilestones(); // Refresh list
      } else {
        _showMessage(
          result['message'] ?? 'Failed to generate milestones',
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
          // Development Milestones Header
          Row(
            children: [
              const Icon(Icons.psychology, color: Colors.black),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Development Milestones',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Track your child\'s developmental progress',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (milestones.isEmpty)
                ElevatedButton.icon(
                  onPressed: _generateBuiltInMilestones,
                  icon: const Icon(Icons.auto_awesome, size: 20),
                  label: const Text('Generate Milestones'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              if (milestones.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _showAddMilestoneDialog(context),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Custom'),
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
                      _loadMilestones();
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
                            backgroundColor: Colors.purple.withOpacity(0.1),
                            child: Text(
                              child['name']?.substring(0, 1).toUpperCase() ??
                                  'C',
                              style: TextStyle(
                                color: Colors.purple,
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

          // Show message if no milestones
          if (milestones.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(
                    Icons.psychology_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No milestones yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate 10 built-in milestones to get started',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),

          // Milestone list
          ...milestones.map((milestone) => _buildMilestoneItem(milestone)),
        ],
      ),
    );
  }

  Widget _buildMilestoneItem(Map<String, dynamic> milestone) {
    final String status = milestone['status'] ?? 'PENDING';
    final Color statusColor = _milestoneService.getStatusColor(status);
    final bool isBuiltIn = milestone['isBuiltIn'] ?? false;

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

          // Milestone info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        milestone['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    if (isBuiltIn)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Built-in',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${milestone['milestoneTypeDisplay'] ?? milestone['milestoneType']} • ${_getDateDisplay(milestone)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                if (milestone['description'] != null &&
                    milestone['description'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      milestone['description'],
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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
              milestone['statusDisplay'] ?? status,
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
                case 'complete':
                  await _markAsCompleted(milestone);
                  break;
                case 'edit':
                  _showEditMilestoneDialog(context, milestone);
                  break;
                case 'delete':
                  _confirmDelete(milestone);
                  break;
              }
            },
            itemBuilder: (context) => [
              if (status != 'COMPLETED')
                const PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 20, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Mark as Completed'),
                    ],
                  ),
                ),
              // Only show Edit for custom milestones (not built-in)
              if (!isBuiltIn)
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
              // Only show Delete for custom milestones (not built-in)
              if (!isBuiltIn)
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

  String _getDateDisplay(Map<String, dynamic> milestone) {
    final status = milestone['status'] ?? 'PENDING';
    if (status == 'COMPLETED' && milestone['actualDate'] != null) {
      return 'Completed: ${milestone['actualDate']}';
    } else {
      final expectedAge =
          milestone['expectedAgeDisplay'] ??
          _milestoneService.formatAgeDisplay(
            milestone['expectedAgeMonths'] ?? 0,
          );
      return 'Expected: $expectedAge';
    }
  }

  /// Mark milestone as completed
  Future<void> _markAsCompleted(Map<String, dynamic> milestone) async {
    final int milestoneId = milestone['id'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _milestoneService.markAsCompleted(
      milestoneId: milestoneId,
    );

    if (mounted) {
      Navigator.pop(context); // Close loading

      if (result['success']) {
        _showMessage('Milestone completed! 🎉', Colors.green);
        _loadMilestones(); // Refresh
      } else {
        _showMessage(result['message'] ?? 'Failed to update', Colors.red);
      }
    }
  }

  /// Confirm delete milestone
  void _confirmDelete(Map<String, dynamic> milestone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Milestone?'),
        content: Text(
          'Are you sure you want to delete "${milestone['title']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteMilestone(milestone['id']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Delete milestone
  Future<void> _deleteMilestone(int milestoneId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _milestoneService.deleteMilestone(milestoneId);

    if (mounted) {
      Navigator.pop(context); // Close loading

      if (result['success']) {
        _showMessage('Milestone deleted', Colors.orange);
        _loadMilestones(); // Refresh
      } else {
        _showMessage(result['message'] ?? 'Failed to delete', Colors.red);
      }
    }
  }

  void _showAddMilestoneDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final ageController = TextEditingController();
    String selectedCategory = 'PHYSICAL';

    // Category display names and icons
    final Map<String, Map<String, dynamic>> categoryInfo = {
      'PHYSICAL': {
        'name': 'Physical',
        'icon': Icons.directions_run,
        'color': Colors.blue,
      },
      'COGNITIVE': {
        'name': 'Cognitive',
        'icon': Icons.psychology,
        'color': Colors.purple,
      },
      'SOCIAL': {'name': 'Social', 'icon': Icons.people, 'color': Colors.green},
      'EMOTIONAL': {
        'name': 'Emotional',
        'icon': Icons.favorite,
        'color': Colors.pink,
      },
      'LANGUAGE': {
        'name': 'Language',
        'icon': Icons.chat_bubble,
        'color': Colors.orange,
      },
    };

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
                      Icons.add_circle_outline,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'New Milestone',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Text(
                        'Milestone Title *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleController,
                        maxLength: 200,
                        decoration: InputDecoration(
                          hintText: 'e.g., First day at daycare',
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
                          counterText: '',
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Category selection
                      const Text(
                        'Category *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categoryInfo.entries.map((entry) {
                          final isSelected = selectedCategory == entry.key;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategory = entry.key;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? entry.value['color'].withOpacity(0.15)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? entry.value['color']
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    entry.value['icon'],
                                    size: 18,
                                    color: isSelected
                                        ? entry.value['color']
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    entry.value['name'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? entry.value['color']
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Expected Age
                      const Text(
                        'Expected Age *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter age in months (e.g., 24)',
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
                      ),

                      const SizedBox(height: 20),

                      // Description
                      const Text(
                        'Description (Optional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        maxLength: 1000,
                        decoration: InputDecoration(
                          hintText: 'Add any additional notes or details...',
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
                          contentPadding: const EdgeInsets.all(16),
                          counterText: '',
                        ),
                      ),
                    ],
                  ),
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
                    debugPrint('🔵 Create Milestone button pressed');

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
                    if (titleController.text.trim().isEmpty) {
                      debugPrint('❌ Validation failed: Title is empty');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Please enter a milestone title'),
                          backgroundColor: Colors.orange,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                      return;
                    }

                    if (titleController.text.trim().length > 200) {
                      debugPrint('❌ Validation failed: Title too long');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Title must not exceed 200 characters',
                          ),
                          backgroundColor: Colors.orange,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                      return;
                    }

                    if (ageController.text.trim().isEmpty) {
                      debugPrint('❌ Validation failed: Age is empty');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Please enter the expected age'),
                          backgroundColor: Colors.orange,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                      return;
                    }

                    final age = int.tryParse(ageController.text.trim());
                    if (age == null || age <= 0) {
                      debugPrint('❌ Validation failed: Invalid age');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Age must be a positive number'),
                          backgroundColor: Colors.orange,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                      return;
                    }

                    if (descriptionController.text.trim().length > 1000) {
                      debugPrint('❌ Validation failed: Description too long');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Description must not exceed 1000 characters',
                          ),
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
                    debugPrint('📋 Title: ${titleController.text.trim()}');
                    debugPrint('📋 Category: $selectedCategory');
                    debugPrint('📋 Age: $age months');
                    debugPrint('📋 Child ID: $_selectedChildId');

                    // Close the input dialog first
                    Navigator.of(context).pop();

                    // Show loading dialog on parent context
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
                                  'Creating milestone...',
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
                      final result = await _milestoneService.createMilestone(
                        childId: _selectedChildId!,
                        title: titleController.text.trim(),
                        milestoneType: selectedCategory,
                        expectedAgeMonths: age,
                        description:
                            descriptionController.text.trim().isNotEmpty
                            ? descriptionController.text.trim()
                            : null,
                      );

                      debugPrint('📥 API Response: $result');

                      if (mounted) {
                        // Close loading dialog
                        Navigator.of(this.context).pop();

                        if (result['success'] == true) {
                          debugPrint('✅ Milestone created successfully');
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                '✅ Milestone created successfully!',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                          await _loadMilestones();
                        } else {
                          debugPrint(
                            '❌ Failed to create milestone: ${result['message']}',
                          );
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '❌ ${result['message'] ?? 'Failed to create milestone'}',
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
                        'Create Milestone',
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

  void _showEditMilestoneDialog(
    BuildContext context,
    Map<String, dynamic> milestone,
  ) {
    final titleController = TextEditingController(text: milestone['title']);
    final descriptionController = TextEditingController(
      text: milestone['description'] ?? '',
    );
    final ageController = TextEditingController(
      text: milestone['expectedAgeMonths'].toString(),
    );
    String selectedCategory = milestone['milestoneType'] ?? 'PHYSICAL';
    String selectedStatus = milestone['status'] ?? 'PENDING';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Edit Milestone',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Milestone Title',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
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

                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
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

                    // Category
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items:
                          [
                            'PHYSICAL',
                            'COGNITIVE',
                            'SOCIAL',
                            'EMOTIONAL',
                            'LANGUAGE',
                          ].map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                        });
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: ['PENDING', 'COMPLETED', 'OVERDUE'].map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Expected Age
                    const Text(
                      'Expected Age (months)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
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
                    debugPrint('🔵 Update Milestone button pressed');

                    // Validation
                    if (titleController.text.trim().isEmpty) {
                      debugPrint('❌ Validation failed: Title is empty');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Please enter a milestone title'),
                          backgroundColor: Colors.orange,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                      return;
                    }

                    final age = int.tryParse(ageController.text.trim());
                    if (age == null || age <= 0) {
                      debugPrint('❌ Validation failed: Invalid age');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Age must be a positive number'),
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
                    debugPrint('📋 Milestone ID: ${milestone['id']}');
                    debugPrint('📋 Title: ${titleController.text.trim()}');
                    debugPrint('📋 Category: $selectedCategory');
                    debugPrint('📋 Status: $selectedStatus');
                    debugPrint('📋 Age: $age months');

                    // Close edit dialog
                    Navigator.of(context).pop();

                    // Show loading dialog on parent context
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
                                  'Updating milestone...',
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

                      final result = await _milestoneService.updateMilestone(
                        milestoneId: milestone['id'],
                        title: titleController.text.trim(),
                        description:
                            descriptionController.text.trim().isNotEmpty
                            ? descriptionController.text.trim()
                            : null,
                        milestoneType: selectedCategory,
                        expectedAgeMonths: age,
                        status: selectedStatus,
                      );

                      debugPrint('📥 API Response: $result');

                      if (mounted) {
                        // Close loading dialog
                        Navigator.of(this.context).pop();

                        if (result['success'] == true) {
                          debugPrint('✅ Milestone updated successfully');
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                '✅ Milestone updated successfully!',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                          await _loadMilestones();
                        } else {
                          debugPrint(
                            '❌ Failed to update milestone: ${result['message']}',
                          );
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '❌ ${result['message'] ?? 'Failed to update milestone'}',
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
