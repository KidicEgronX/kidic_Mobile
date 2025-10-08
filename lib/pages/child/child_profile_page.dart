import 'package:flutter/material.dart';
import 'package:kidicapp_flutter/services/child/child_service.dart';
import 'package:kidicapp_flutter/services/auth/auth_service.dart';
import 'package:kidicapp_flutter/pages/dialogs/child_edit_dialog.dart';

class ChildProfilePage extends StatefulWidget {
  final int childId;

  const ChildProfilePage({super.key, required this.childId});

  @override
  State<ChildProfilePage> createState() => _ChildProfilePageState();
}

class _ChildProfilePageState extends State<ChildProfilePage> {
  final ChildService _childService = ChildService();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _childData;
  List<Map<String, dynamic>> _parents = [];
  bool _isLoading = true;
  bool _isLoadingParents = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChildData();
    _loadParentData();
  }

  /// Load specific child data using the getChild endpoint
  Future<void> _loadChildData() async {
    try {
      debugPrint('🔍 Loading child data for ID: ${widget.childId}');

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Call the getChild endpoint through ChildService
      final childData = await _childService.getChild(widget.childId);

      if (childData != null) {
        setState(() {
          _childData = childData;
          _isLoading = false;
        });
        debugPrint('✅ Child data loaded successfully: ${childData['name']}');
      } else {
        setState(() {
          _errorMessage = 'Child not found or access denied';
          _isLoading = false;
        });
        debugPrint('❌ Failed to load child data');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading child data: $e';
        _isLoading = false;
      });
      debugPrint('❌ Error in _loadChildData: $e');
    }
  }

  /// Load parent data from family information
  Future<void> _loadParentData() async {
    try {
      debugPrint('🔍 Loading parent data from family...');

      setState(() {
        _isLoadingParents = true;
      });

      // Get family data using AuthService
      final familyData = await _authService.getFamilyData();

      if (familyData != null) {
        final parentsList = familyData['parents'] as List<dynamic>? ?? [];
        debugPrint('🔍 Found ${parentsList.length} parents in family data');

        // Process parent data
        final processedParents = parentsList.map((parent) {
          final parentMap = parent as Map<String, dynamic>;
          return {
            'id': parentMap['id'],
            'name': parentMap['name'] ?? 'Unknown Parent',
            'email': parentMap['email'] ?? '',
            'phone': parentMap['phone'] ?? '',
            'gender': parentMap['gender'], // true = male, false = female
            'genderDisplay': parentMap['gender'] == true
                ? 'Male'
                : (parentMap['gender'] == false ? 'Female' : 'Not specified'),
            'initials': _getParentInitials(parentMap['name']),
          };
        }).toList();

        setState(() {
          _parents = List<Map<String, dynamic>>.from(processedParents);
          _isLoadingParents = false;
        });

        debugPrint('✅ Loaded ${_parents.length} parents successfully');
        for (var parent in _parents) {
          debugPrint('🔍 Parent: ${parent['name']} - ${parent['email']}');
        }
      } else {
        setState(() {
          _parents = [];
          _isLoadingParents = false;
        });
        debugPrint('❌ No family data found');
      }
    } catch (e) {
      setState(() {
        _parents = [];
        _isLoadingParents = false;
      });
      debugPrint('❌ Error loading parent data: $e');
    }
  }

  /// Get initials from parent name for avatar display
  String _getParentInitials(String? name) {
    if (name == null || name.isEmpty) return 'P';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

  /// Show child edit dialog
  void _showEditDialog() {
    if (_childData == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChildEditDialog(
        childData: _childData!,
        onUpdateSuccess: _onChildUpdateSuccess,
      ),
    );
  }

  /// Handle successful child profile update
  void _onChildUpdateSuccess(Map<String, dynamic> updatedChildData) {
    setState(() {
      _childData = updatedChildData;
    });

    debugPrint('✅ Child profile updated successfully in UI');
    debugPrint(
      '🔍 Updated child data: ${updatedChildData['name']} - ${updatedChildData['age']}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _childData != null
              ? '${_childData!['name']}\'s Profile'
              : 'Child Profile',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_childData != null && !_isLoading)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue.shade600, size: 24),
              onPressed: _showEditDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          // Header with description
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Text(
              _childData != null
                  ? 'Viewing detailed information for ${_childData!['name']}'
                  : 'Loading child information...',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),

          // Main content
          Expanded(child: _buildContent(size)),
        ],
      ),
    );
  }

  Widget _buildContent(Size size) {
    if (_isLoading) {
      return _buildLoadingState(size);
    } else if (_errorMessage != null) {
      return _buildErrorState(size);
    } else if (_childData != null) {
      return _buildChildProfile(size);
    } else {
      return _buildEmptyState(size);
    }
  }

  Widget _buildLoadingState(Size size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
          SizedBox(height: size.height * 0.02),
          Text(
            'Loading child profile...',
            style: TextStyle(
              fontSize: size.width * 0.04,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Size size) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(size.width * 0.06),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: size.width * 0.16,
              color: Colors.red.shade400,
            ),
            SizedBox(height: size.height * 0.02),
            Text(
              'Error Loading Profile',
              style: TextStyle(
                fontSize: size.width * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(height: size.height * 0.01),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: TextStyle(
                fontSize: size.width * 0.04,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size.height * 0.03),
            ElevatedButton.icon(
              onPressed: () {
                _loadChildData();
                _loadParentData();
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Try Again',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.06,
                  vertical: size.height * 0.015,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(size.width * 0.02),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Size size) {
    return Center(
      child: Text(
        'No child data available',
        style: TextStyle(
          fontSize: size.width * 0.04,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildChildProfile(Size size) {
    final child = _childData!;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(size.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Child Avatar and Basic Info
            _buildChildHeader(size, child),

            SizedBox(height: size.height * 0.03),

            // Child Details Cards
            _buildDetailCard(
              size,
              'Basic Information',
              Icons.person,
              Colors.blue,
              [
                _buildDetailRow('Full Name', child['name'] ?? 'Unknown'),
                _buildDetailRow(
                  'Gender',
                  child['genderDisplay'] ?? 'Not specified',
                ),
                _buildDetailRow('Age', child['age'] ?? 'Unknown'),
                _buildDetailRow(
                  'Date of Birth',
                  _formatDate(child['dateOfBirth']),
                ),
              ],
            ),

            SizedBox(height: size.height * 0.02),

            // Medical Information
            if (child['medicalNotes'] != null &&
                child['medicalNotes'].toString().isNotEmpty) ...[
              _buildDetailCard(
                size,
                'Medical Information',
                Icons.medical_services,
                Colors.red,
                [
                  _buildDetailRow(
                    'Medical Notes',
                    child['medicalNotes'] ?? 'None',
                  ),
                ],
              ),
              SizedBox(height: size.height * 0.02),
            ],

            // Parent Information Section
            _buildParentsSection(size),

            SizedBox(height: size.height * 0.04),
          ],
        ),
      ),
    );
  }

  Widget _buildChildHeader(Size size, Map<String, dynamic> child) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.width * 0.06),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size.width * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Child Avatar
          CircleAvatar(
            radius: size.width * 0.08,
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Text(
              child['initials'] ?? 'C',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
                fontSize: size.width * 0.05,
              ),
            ),
          ),

          SizedBox(width: size.width * 0.04),

          // Child Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child['name'] ?? 'Unknown Child',
                  style: TextStyle(
                    fontSize: size.width * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: size.height * 0.005),
                Text(
                  '${child['age'] ?? 'Unknown age'} • ${child['genderDisplay'] ?? 'Unknown gender'}',
                  style: TextStyle(
                    fontSize: size.width * 0.035,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    Size size,
    String title,
    IconData icon,
    Color color,
    List<Widget> details,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size.width * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(size.width * 0.02),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(size.width * 0.02),
                ),
                child: Icon(icon, color: color, size: size.width * 0.05),
              ),
              SizedBox(width: size.width * 0.03),
              Text(
                title,
                style: TextStyle(
                  fontSize: size.width * 0.045,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          SizedBox(height: size.height * 0.02),

          // Card Content
          ...details,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final Size size = MediaQuery.of(context).size;

    return Padding(
      padding: EdgeInsets.only(bottom: size.height * 0.01),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: size.width * 0.25,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: size.width * 0.035,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: size.width * 0.035,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build parents information section
  Widget _buildParentsSection(Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: EdgeInsets.only(bottom: size.height * 0.015),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(size.width * 0.02),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(size.width * 0.02),
                ),
                child: Icon(
                  Icons.family_restroom,
                  color: Colors.green,
                  size: size.width * 0.05,
                ),
              ),
              SizedBox(width: size.width * 0.03),
              Text(
                'Family Parents',
                style: TextStyle(
                  fontSize: size.width * 0.045,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (_isLoadingParents) ...[
                SizedBox(width: size.width * 0.03),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Parents Cards
        if (_isLoadingParents)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(size.width * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size.width * 0.03),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
                SizedBox(width: size.width * 0.03),
                Text(
                  'Loading parent information...',
                  style: TextStyle(
                    fontSize: size.width * 0.035,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else if (_parents.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(size.width * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size.width * 0.03),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey.shade400,
                  size: size.width * 0.05,
                ),
                SizedBox(width: size.width * 0.03),
                Text(
                  'No parent information available',
                  style: TextStyle(
                    fontSize: size.width * 0.035,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: _parents.asMap().entries.map((entry) {
              final index = entry.key;
              final parent = entry.value;
              final isLast = index == _parents.length - 1;

              return Column(
                children: [
                  _buildParentCard(size, parent),
                  if (!isLast) SizedBox(height: size.height * 0.015),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }

  /// Build individual parent card
  Widget _buildParentCard(Size size, Map<String, dynamic> parent) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size.width * 0.03),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Parent Avatar
          CircleAvatar(
            radius: size.width * 0.06,
            backgroundColor: Colors.green.withOpacity(0.1),
            child: Text(
              parent['initials'] ?? 'P',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: size.width * 0.035,
              ),
            ),
          ),

          SizedBox(width: size.width * 0.04),

          // Parent Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parent['name'] ?? 'Unknown Parent',
                  style: TextStyle(
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: size.height * 0.005),
                if (parent['email'] != null &&
                    parent['email'].toString().isNotEmpty)
                  Text(
                    parent['email'],
                    style: TextStyle(
                      fontSize: size.width * 0.035,
                      color: Colors.grey.shade600,
                    ),
                  ),
                if (parent['phone'] != null &&
                    parent['phone'].toString().isNotEmpty) ...[
                  SizedBox(height: size.height * 0.002),
                  Text(
                    parent['phone'],
                    style: TextStyle(
                      fontSize: size.width * 0.035,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Gender Badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.025,
              vertical: size.height * 0.005,
            ),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(size.width * 0.03),
            ),
            child: Text(
              parent['genderDisplay'] ?? 'Unknown',
              style: TextStyle(
                fontSize: size.width * 0.03,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Not specified';
    }

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }
}
