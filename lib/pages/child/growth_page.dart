import 'package:flutter/material.dart';
import 'package:kidicapp_flutter/services/auth/auth_service.dart';
import 'package:kidicapp_flutter/services/child/growth_service.dart';

class GrowthTab extends StatefulWidget {
  final int? selectedChildId;

  const GrowthTab({super.key, this.selectedChildId});

  @override
  State<GrowthTab> createState() => _GrowthTabState();
}

class _GrowthTabState extends State<GrowthTab> {
  final AuthService _authService = AuthService();
  final GrowthService _growthService = GrowthService();

  List<Map<String, dynamic>> _children = [];
  Map<String, dynamic>? _selectedChild;
  List<Map<String, dynamic>> _growthRecords = [];
  bool _isLoadingChildren = true;
  bool _isLoadingRecords = false;

  // Pagination for recent measurements
  int _displayedRecordsCount = 3;
  static const int _recordsPerPage = 3;

  // Processed growth data for display
  Map<String, dynamic> _processedGrowthData = {
    'height': {
      'value': 0.0,
      'unit': 'cm',
      'percentile': 0,
      'healthCategory': 'Good',
      'healthStatus': 'Normal range',
      'healthAdvice': '',
      'lastUpdated': 'Never',
      'records': <Map<String, dynamic>>[],
    },
    'weight': {
      'value': 0.0,
      'unit': 'kg',
      'percentile': 0,
      'healthCategory': 'Good',
      'healthStatus': 'Normal range',
      'healthAdvice': '',
      'lastUpdated': 'Never',
      'records': <Map<String, dynamic>>[],
    },
    'headCircumference': {
      'value': 0.0,
      'unit': 'cm',
      'percentile': 0,
      'healthCategory': 'Good',
      'healthStatus': 'Normal range',
      'healthAdvice': '',
      'lastUpdated': 'Never',
      'records': <Map<String, dynamic>>[],
    },
  };

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  /// Load children data from family API
  Future<void> _loadChildren() async {
    try {
      debugPrint('🔍 === GROWTH PAGE: LOADING CHILDREN ===');
      setState(() {
        _isLoadingChildren = true;
      });

      final familyData = await _authService.getFamilyData();
      if (familyData != null) {
        final childrenList = familyData['children'] as List<dynamic>? ?? [];
        debugPrint('🔍 Growth Page - Found ${childrenList.length} children');

        final processedChildren = childrenList.map((child) {
          final childMap = child as Map<String, dynamic>;
          return {
            'id': childMap['id'],
            'name': childMap['name'] ?? 'Unknown Child',
            'gender': childMap['gender'],
            'dateOfBirth': childMap['dateOfBirth'],
            'age': _calculateAge(childMap['dateOfBirth']),
          };
        }).toList();

        setState(() {
          _children = List<Map<String, dynamic>>.from(processedChildren);
          _isLoadingChildren = false;

          // Auto-select specific child if selectedChildId is provided, otherwise select first child
          if (_children.isNotEmpty) {
            if (widget.selectedChildId != null) {
              // Try to find the specific child by ID
              final specificChild = _children.firstWhere(
                (child) => child['id'] == widget.selectedChildId,
                orElse: () => _children.first,
              );
              _selectedChild = specificChild;
              debugPrint(
                '🔍 Growth Page - Auto-selected child: ${specificChild['name']} (ID: ${widget.selectedChildId})',
              );
            } else {
              _selectedChild = _children.first;
              debugPrint(
                '🔍 Growth Page - Auto-selected first child: ${_children.first['name']}',
              );
            }
            _loadGrowthRecords();
          }
        });
      } else {
        setState(() {
          _children = [];
          _isLoadingChildren = false;
        });
      }
    } catch (e) {
      debugPrint('🔍 Growth Page - Error loading children: $e');
      setState(() {
        _children = [];
        _isLoadingChildren = false;
      });
    }
  }

  /// Load growth records for selected child
  Future<void> _loadGrowthRecords() async {
    if (_selectedChild == null) return;

    try {
      debugPrint(
        '🔍 === GROWTH PAGE: LOADING RECORDS FOR ${_selectedChild!['name']} ===',
      );
      setState(() {
        _isLoadingRecords = true;
      });

      final childId = _selectedChild!['id'] as int;
      final records = await _growthService.getGrowthRecords(childId);

      setState(() {
        _growthRecords = records;
        _isLoadingRecords = false;
        // Reset pagination when new data is loaded
        _displayedRecordsCount = _recordsPerPage;
        _processGrowthData();
      });

      debugPrint('🔍 Growth Page - Loaded ${records.length} growth records');
    } catch (e) {
      debugPrint('🔍 Growth Page - Error loading growth records: $e');
      setState(() {
        _growthRecords = [];
        _isLoadingRecords = false;
        // Reset pagination on error as well
        _displayedRecordsCount = _recordsPerPage;
        _processGrowthData();
      });
    }
  }

  /// Process growth records into display format
  void _processGrowthData() {
    debugPrint(
      '🔍 Growth Page - Processing ${_growthRecords.length} growth records',
    );

    // Reset processed data
    _processedGrowthData = {
      'height': {
        'value': 0.0,
        'unit': 'cm',
        'percentile': 0,
        'healthCategory': 'Good',
        'healthStatus': 'Normal range',
        'healthAdvice': '',
        'lastUpdated': 'Never',
        'records': <Map<String, dynamic>>[],
      },
      'weight': {
        'value': 0.0,
        'unit': 'kg',
        'percentile': 0,
        'healthCategory': 'Good',
        'healthStatus': 'Normal range',
        'healthAdvice': '',
        'lastUpdated': 'Never',
        'records': <Map<String, dynamic>>[],
      },
      'headCircumference': {
        'value': 0.0,
        'unit': 'cm',
        'percentile': 0,
        'healthCategory': 'Good',
        'healthStatus': 'Normal range',
        'healthAdvice': '',
        'lastUpdated': 'Never',
        'records': <Map<String, dynamic>>[],
      },
    };

    if (_growthRecords.isEmpty) {
      debugPrint('🔍 Growth Page - No records to process');
      return;
    }

    // Sort all records by date (newest first) for proper history display
    _growthRecords.sort((a, b) {
      final dateA = DateTime.parse(a['dateOfRecord']);
      final dateB = DateTime.parse(b['dateOfRecord']);
      debugPrint(
        '🔍 Comparing dates: ${a['dateOfRecord']} ($dateA) vs ${b['dateOfRecord']} ($dateB)',
      );
      final comparison = dateB.compareTo(dateA);
      debugPrint('🔍 Comparison result: $comparison');
      return comparison;
    });

    debugPrint('🔍 Growth Page - Records sorted by date (newest first)');

    // Debug: Print all records in order
    for (int i = 0; i < _growthRecords.length; i++) {
      final record = _growthRecords[i];
      debugPrint(
        '🔍 Record $i: ${record['dateOfRecord']} - Height: ${record['height']}, Weight: ${record['weight']}',
      );
    }

    // Group records by type and find latest values
    final heightRecords = _growthRecords
        .where((r) => r['height'] != null)
        .toList();
    final weightRecords = _growthRecords
        .where((r) => r['weight'] != null)
        .toList();

    // Calculate age in months for percentile calculation
    final ageInMonths = _getAgeInMonths();

    // Get child's gender for percentile calculation
    final bool isMale = _selectedChild?['gender'] == true;

    // Process height data - find actual latest by date comparison
    if (heightRecords.isNotEmpty) {
      final latestHeight = heightRecords.reduce((a, b) {
        final dateA = DateTime.parse(a['dateOfRecord']);
        final dateB = DateTime.parse(b['dateOfRecord']);
        return dateA.isAfter(dateB) ? a : b;
      });

      debugPrint(
        '🔍 Latest height record: ${latestHeight['dateOfRecord']} - ${latestHeight['height']} cm',
      );

      final heightValue = (latestHeight['height'] as num).toDouble();
      final percentile = GrowthService.calculatePercentile(
        heightValue,
        'HEIGHT',
        ageInMonths,
        isMale: isMale,
      );

      final healthCategory = GrowthService.getHealthCategory(percentile);
      final healthStatus = GrowthService.getDetailedHealthStatus(percentile);
      final healthAdvice = GrowthService.getHealthAdvice(
        healthCategory,
        'height',
      );

      _processedGrowthData['height'] = {
        'value': heightValue,
        'unit': 'cm',
        'percentile': percentile,
        'healthCategory': healthCategory,
        'healthStatus': healthStatus,
        'healthAdvice': healthAdvice,
        'lastUpdated': _formatDate(latestHeight['dateOfRecord']),
        'records': heightRecords,
      };
    }

    // Process weight data - find actual latest by date comparison
    if (weightRecords.isNotEmpty) {
      final latestWeight = weightRecords.reduce((a, b) {
        final dateA = DateTime.parse(a['dateOfRecord']);
        final dateB = DateTime.parse(b['dateOfRecord']);
        return dateA.isAfter(dateB) ? a : b;
      });

      debugPrint(
        '🔍 Latest weight record: ${latestWeight['dateOfRecord']} - ${latestWeight['weight']} kg',
      );

      final weightValue = (latestWeight['weight'] as num).toDouble();
      final percentile = GrowthService.calculatePercentile(
        weightValue,
        'WEIGHT',
        ageInMonths,
        isMale: isMale,
      );

      final healthCategory = GrowthService.getHealthCategory(percentile);
      final healthStatus = GrowthService.getDetailedHealthStatus(percentile);
      final healthAdvice = GrowthService.getHealthAdvice(
        healthCategory,
        'weight',
      );

      _processedGrowthData['weight'] = {
        'value': weightValue,
        'unit': 'kg',
        'percentile': percentile,
        'healthCategory': healthCategory,
        'healthStatus': healthStatus,
        'healthAdvice': healthAdvice,
        'lastUpdated': _formatDate(latestWeight['dateOfRecord']),
        'records': weightRecords,
      };
    }
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

  /// Get age in months for percentile calculation
  int _getAgeInMonths() {
    if (_selectedChild == null || _selectedChild!['dateOfBirth'] == null)
      return 12;

    try {
      final dateOfBirth = DateTime.parse(_selectedChild!['dateOfBirth']);
      final now = DateTime.now();
      final difference = now.difference(dateOfBirth);
      return (difference.inDays / 30).round();
    } catch (e) {
      return 12;
    }
  }

  /// Format date for display
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadChildren();
          if (_selectedChild != null) {
            await _loadGrowthRecords();
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(size.width * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Growth Records Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      flex: 2,
                      child: Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: Colors.black,
                            size: size.width * 0.06,
                          ),
                          SizedBox(width: size.width * 0.02),
                          Flexible(
                            child: Text(
                              'Growth Records',
                              style: TextStyle(
                                fontSize: size.width * 0.055,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: size.width * 0.02),
                    Flexible(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: _selectedChild != null
                            ? () {
                                _showAddMeasurementDialog(context);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[400],
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.025,
                            vertical: size.height * 0.01,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              size.width * 0.02,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: size.width * 0.035),
                            SizedBox(width: size.width * 0.008),
                            Flexible(
                              child: Text(
                                'Add',
                                style: TextStyle(
                                  fontSize: size.width * 0.032,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: size.height * 0.015),

                Text(
                  'Monitor your child\'s physical development',
                  style: TextStyle(
                    fontSize: size.width * 0.04,
                    color: Colors.grey[600],
                  ),
                ),

                SizedBox(height: size.height * 0.03),

                // Child Selection Dropdown
                if (_isLoadingChildren)
                  Container(
                    padding: EdgeInsets.all(size.width * 0.04),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: size.width * 0.03),
                        Text('Loading children...'),
                      ],
                    ),
                  )
                else if (_children.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(size.width * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(size.width * 0.03),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.child_care,
                          size: size.width * 0.12,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: size.height * 0.01),
                        Text(
                          'No children found',
                          style: TextStyle(
                            fontSize: size.width * 0.04,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          'Add children to track their growth',
                          style: TextStyle(
                            fontSize: size.width * 0.035,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
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
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        value: _selectedChild,
                        hint: Text('Select a child'),
                        isExpanded: true,
                        onChanged: (Map<String, dynamic>? newValue) {
                          setState(() {
                            _selectedChild = newValue;
                          });
                          if (newValue != null) {
                            _loadGrowthRecords();
                          }
                        },
                        items: _children
                            .map<DropdownMenuItem<Map<String, dynamic>>>((
                              Map<String, dynamic> child,
                            ) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: child,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: size.width * 0.03,
                                      backgroundColor: Colors.blue.withOpacity(
                                        0.1,
                                      ),
                                      child: Text(
                                        child['name']
                                                ?.substring(0, 1)
                                                .toUpperCase() ??
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                            })
                            .toList(),
                      ),
                    ),
                  ),

                if (_selectedChild != null) ...[
                  SizedBox(height: size.height * 0.03),

                  if (_isLoadingRecords)
                    Container(
                      padding: EdgeInsets.all(size.width * 0.04),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: size.width * 0.03),
                          Text('Loading growth records...'),
                        ],
                      ),
                    )
                  else ...[
                    // Growth Cards
                    _buildGrowthCard(
                      context,
                      size,
                      icon: Icons.height,
                      title: 'Height',
                      value:
                          '${_processedGrowthData['height']['value']} ${_processedGrowthData['height']['unit']}',
                      percentile:
                          '${_processedGrowthData['height']['percentile']}th percentile',
                      healthCategory:
                          _processedGrowthData['height']['healthCategory'] ??
                          'Good',
                      healthStatus:
                          _processedGrowthData['height']['healthStatus'] ??
                          'Normal range',
                      healthAdvice:
                          _processedGrowthData['height']['healthAdvice'] ?? '',
                      lastUpdated:
                          'Last updated: ${_processedGrowthData['height']['lastUpdated']}',
                      percentileValue:
                          _processedGrowthData['height']['percentile'] / 100,
                      color: Colors.blue,
                    ),

                    SizedBox(height: size.height * 0.02),

                    _buildGrowthCard(
                      context,
                      size,
                      icon: Icons.monitor_weight,
                      title: 'Weight',
                      value:
                          '${_processedGrowthData['weight']['value']} ${_processedGrowthData['weight']['unit']}',
                      percentile:
                          '${_processedGrowthData['weight']['percentile']}th percentile',
                      healthCategory:
                          _processedGrowthData['weight']['healthCategory'] ??
                          'Good',
                      healthStatus:
                          _processedGrowthData['weight']['healthStatus'] ??
                          'Normal range',
                      healthAdvice:
                          _processedGrowthData['weight']['healthAdvice'] ?? '',
                      lastUpdated:
                          'Last updated: ${_processedGrowthData['weight']['lastUpdated']}',
                      percentileValue:
                          _processedGrowthData['weight']['percentile'] / 100,
                      color: Colors.green,
                    ),

                    SizedBox(height: size.height * 0.04),

                    // Growth History Section
                    _buildGrowthHistory(size),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrowthCard(
    BuildContext context,
    Size size, {
    required IconData icon,
    required String title,
    required String value,
    required String percentile,
    required String healthCategory,
    required String healthStatus,
    required String healthAdvice,
    required String lastUpdated,
    required double percentileValue,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.width * 0.05),
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
          // Header with icon and title
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
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          SizedBox(height: size.height * 0.02),

          // Value
          Text(
            value,
            style: TextStyle(
              fontSize: size.width * 0.08,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          SizedBox(height: size.height * 0.015),

          // Percentile and Health Category Row
          Row(
            children: [
              Expanded(
                child: Text(
                  percentile,
                  style: TextStyle(
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.025,
                  vertical: size.height * 0.005,
                ),
                decoration: BoxDecoration(
                  color: GrowthService.getHealthCategoryColor(
                    healthCategory,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(size.width * 0.03),
                  border: Border.all(
                    color: GrowthService.getHealthCategoryColor(healthCategory),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      GrowthService.getHealthCategoryIcon(healthCategory),
                      size: size.width * 0.035,
                      color: GrowthService.getHealthCategoryColor(
                        healthCategory,
                      ),
                    ),
                    SizedBox(width: size.width * 0.01),
                    Text(
                      healthCategory,
                      style: TextStyle(
                        fontSize: size.width * 0.032,
                        fontWeight: FontWeight.bold,
                        color: GrowthService.getHealthCategoryColor(
                          healthCategory,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: size.height * 0.01),

          // Health Status
          Text(
            healthStatus,
            style: TextStyle(
              fontSize: size.width * 0.035,
              fontWeight: FontWeight.w500,
              color: GrowthService.getHealthCategoryColor(healthCategory),
            ),
          ),

          SizedBox(height: size.height * 0.015),

          // Progress bar
          Container(
            width: double.infinity,
            height: size.height * 0.008,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(size.width * 0.02),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentileValue,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GrowthService.getHealthCategoryColor(
                        healthCategory,
                      ).withOpacity(0.6),
                      GrowthService.getHealthCategoryColor(healthCategory),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(size.width * 0.02),
                ),
              ),
            ),
          ),

          SizedBox(height: size.height * 0.015),

          // Health Advice (if available)
          if (healthAdvice.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(size.width * 0.03),
              decoration: BoxDecoration(
                color: GrowthService.getHealthCategoryColor(
                  healthCategory,
                ).withOpacity(0.05),
                borderRadius: BorderRadius.circular(size.width * 0.02),
                border: Border.all(
                  color: GrowthService.getHealthCategoryColor(
                    healthCategory,
                  ).withOpacity(0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: size.width * 0.04,
                    color: GrowthService.getHealthCategoryColor(healthCategory),
                  ),
                  SizedBox(width: size.width * 0.02),
                  Expanded(
                    child: Text(
                      healthAdvice,
                      style: TextStyle(
                        fontSize: size.width * 0.032,
                        color: GrowthService.getHealthCategoryColor(
                          healthCategory,
                        ).withOpacity(0.8),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.height * 0.015),
          ],

          // Last updated
          Text(
            lastUpdated,
            style: TextStyle(
              fontSize: size.width * 0.035,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthHistory(Size size) {
    // Get records to display (limited by pagination) and reverse the order
    final recordsToShow = _growthRecords.take(_displayedRecordsCount).toList();
    final hasMoreRecords = _growthRecords.length > _displayedRecordsCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Measurements',
              style: TextStyle(
                fontSize: size.width * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            if (_growthRecords.isNotEmpty)
              Text(
                '${_growthRecords.length} records',
                style: TextStyle(
                  fontSize: size.width * 0.035,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        SizedBox(height: size.height * 0.015),

        if (_growthRecords.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(size.width * 0.04),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(size.width * 0.03),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.trending_up,
                  size: size.width * 0.08,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: size.height * 0.01),
                Text(
                  'No growth records yet',
                  style: TextStyle(
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: size.height * 0.005),
                Text(
                  'Add measurements to track growth over time',
                  style: TextStyle(
                    fontSize: size.width * 0.035,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else ...[
          // Display paginated records
          Column(
            children: recordsToShow.asMap().entries.map((entry) {
              final record = entry.value;

              // Find the actual latest record by comparing all dates
              final latestRecord = _growthRecords.reduce((a, b) {
                final dateA = DateTime.parse(a['dateOfRecord']);
                final dateB = DateTime.parse(b['dateOfRecord']);
                return dateA.isAfter(dateB) ? a : b;
              });

              final isLatest = record['id'] == latestRecord['id'];
              debugPrint(
                '🔍 Record ${record['dateOfRecord']} - isLatest: $isLatest (ID: ${record['id']}, Latest ID: ${latestRecord['id']})',
              );

              return Container(
                margin: EdgeInsets.only(bottom: size.height * 0.015),
                child: _buildRecordCard(
                  size,
                  record: record,
                  isLatest: isLatest,
                ),
              );
            }).toList(),
          ),

          // See more button - Enhanced UI with proper spacing
          if (hasMoreRecords) ...[
            SizedBox(height: size.height * 0.02),
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(
                bottom: size.height * 0.03,
              ), // Extra spacing from bottom
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _displayedRecordsCount += _recordsPerPage;
                    // Ensure we don't exceed total records
                    if (_displayedRecordsCount > _growthRecords.length) {
                      _displayedRecordsCount = _growthRecords.length;
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: Colors.blue.withOpacity(0.3),
                  padding: EdgeInsets.symmetric(
                    vertical: size.height * 0.018,
                    horizontal: size.width * 0.04,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(size.width * 0.04),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(size.width * 0.015),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(size.width * 0.02),
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: size.width * 0.05,
                      ),
                    ),
                    SizedBox(width: size.width * 0.03),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Show More Records',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size.width * 0.04,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_growthRecords.length - _displayedRecordsCount} more available',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: size.width * 0.032,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Additional bottom padding to ensure it's above navigation bar
            SizedBox(height: size.height * 0.08),
          ],
        ],
      ],
    );
  }

  Widget _buildRecordCard(
    Size size, {
    required Map<String, dynamic> record,
    required bool isLatest,
  }) {
    final String formattedDate = _formatDate(record['dateOfRecord']);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size.width * 0.03),
        border: isLatest
            ? Border.all(color: Colors.blue.shade300, width: 2)
            : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: isLatest
                ? Colors.blue.withOpacity(0.1)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date and latest indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.025,
                      vertical: size.height * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: isLatest
                          ? Colors.blue.shade50
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(size.width * 0.02),
                    ),
                    child: Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: size.width * 0.035,
                        color: isLatest
                            ? Colors.blue.shade700
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isLatest) ...[
                    SizedBox(width: size.width * 0.02),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.02,
                        vertical: size.height * 0.003,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(size.width * 0.015),
                      ),
                      child: Text(
                        'Latest',
                        style: TextStyle(
                          fontSize: size.width * 0.03,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              PopupMenuButton<String>(
                onSelected: (String value) {
                  if (value == 'edit') {
                    _showEditMeasurementDialog(context, record);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(context, record);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit,
                          size: size.width * 0.04,
                          color: Colors.blue,
                        ),
                        SizedBox(width: size.width * 0.02),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          size: size.width * 0.04,
                          color: Colors.red,
                        ),
                        SizedBox(width: size.width * 0.02),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
                child: Icon(
                  Icons.more_vert,
                  size: size.width * 0.04,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          SizedBox(height: size.height * 0.015),

          // Measurements display
          Row(
            children: [
              if (record['height'] != null) ...[
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(size.width * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(size.width * 0.02),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Height',
                          style: TextStyle(
                            fontSize: size.width * 0.03,
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${record['height']} cm',
                          style: TextStyle(
                            fontSize: size.width * 0.04,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (record['weight'] != null)
                  SizedBox(width: size.width * 0.02),
              ],
              if (record['weight'] != null) ...[
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(size.width * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(size.width * 0.02),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weight',
                          style: TextStyle(
                            fontSize: size.width * 0.03,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${record['weight']} kg',
                          style: TextStyle(
                            fontSize: size.width * 0.04,
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Additional info if present
          if (record['additionalInfo'] != null &&
              (record['additionalInfo'] as String).isNotEmpty) ...[
            SizedBox(height: size.height * 0.01),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(size.width * 0.03),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(size.width * 0.02),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: size.width * 0.03,
                      color: Colors.orange.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    record['additionalInfo'],
                    style: TextStyle(
                      fontSize: size.width * 0.035,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Show edit measurement dialog
  void _showEditMeasurementDialog(
    BuildContext context,
    Map<String, dynamic> record,
  ) {
    if (_selectedChild == null) return;

    final Size size = MediaQuery.of(context).size;
    final TextEditingController heightController = TextEditingController(
      text: record['height']?.toString() ?? '',
    );
    final TextEditingController weightController = TextEditingController(
      text: record['weight']?.toString() ?? '',
    );
    final TextEditingController additionalInfoController =
        TextEditingController(text: record['additionalInfo']?.toString() ?? '');

    DateTime selectedDate = DateTime.parse(record['dateOfRecord']);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(size.width * 0.03),
              ),
              child: Container(
                width: size.width * 0.85,
                padding: EdgeInsets.all(size.width * 0.04),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(size.width * 0.02),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit,
                            color: Colors.orange.shade600,
                            size: size.width * 0.05,
                          ),
                        ),
                        SizedBox(width: size.width * 0.03),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Growth Record',
                                style: TextStyle(
                                  fontSize: size.width * 0.045,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'For ${_selectedChild!['name']}',
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

                    SizedBox(height: size.height * 0.02),

                    // Date Selection
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.03,
                          vertical: size.height * 0.015,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(
                            size.width * 0.015,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: size.width * 0.04),
                            SizedBox(width: size.width * 0.03),
                            Text(
                              'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: TextStyle(fontSize: size.width * 0.035),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.015),

                    // Height Input
                    TextField(
                      controller: heightController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: size.width * 0.035),
                      decoration: InputDecoration(
                        labelText: 'Height (cm)',
                        labelStyle: TextStyle(fontSize: size.width * 0.032),
                        hintText: 'Enter height in centimeters',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            size.width * 0.015,
                          ),
                        ),
                        prefixIcon: Icon(Icons.height, size: size.width * 0.04),
                      ),
                    ),

                    SizedBox(height: size.height * 0.015),

                    // Weight Input
                    TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: size.width * 0.035),
                      decoration: InputDecoration(
                        labelText: 'Weight (kg)',
                        labelStyle: TextStyle(fontSize: size.width * 0.032),
                        hintText: 'Enter weight in kilograms',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            size.width * 0.015,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.monitor_weight,
                          size: size.width * 0.04,
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.015),

                    // Additional Info
                    TextField(
                      controller: additionalInfoController,
                      style: TextStyle(fontSize: size.width * 0.035),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Additional Notes (Optional)',
                        labelStyle: TextStyle(fontSize: size.width * 0.032),
                        hintText: 'Any notes about this measurement',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            size.width * 0.015,
                          ),
                        ),
                        prefixIcon: Icon(Icons.note, size: size.width * 0.04),
                      ),
                    ),

                    SizedBox(height: size.height * 0.02),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                },
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: size.width * 0.032,
                            ),
                          ),
                        ),
                        SizedBox(width: size.width * 0.015),
                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  setState(() {
                                    isLoading = true;
                                  });

                                  try {
                                    final height =
                                        heightController.text.isNotEmpty
                                        ? double.tryParse(heightController.text)
                                        : null;
                                    final weight =
                                        weightController.text.isNotEmpty
                                        ? double.tryParse(weightController.text)
                                        : null;

                                    final result = await _growthService
                                        .updateGrowthRecord(
                                          childId: _selectedChild!['id'] as int,
                                          recordId: record['id'] as int,
                                          dateOfRecord: selectedDate
                                              .toIso8601String()
                                              .split('T')[0],
                                          height: height,
                                          weight: weight,
                                          additionalInfo:
                                              additionalInfoController.text
                                                  .trim()
                                                  .isNotEmpty
                                              ? additionalInfoController.text
                                                    .trim()
                                              : null,
                                        );

                                    setState(() {
                                      isLoading = false;
                                    });

                                    Navigator.of(context).pop();

                                    if (result['success'] == true) {
                                      _loadGrowthRecords();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Growth record updated successfully!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            result['message'] ??
                                                'Failed to update record',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                    Navigator.of(context).pop();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text('Update Record'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation(
    BuildContext context,
    Map<String, dynamic> record,
  ) {
    final Size size = MediaQuery.of(context).size;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size.width * 0.03),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: size.width * 0.06),
              SizedBox(width: size.width * 0.02),
              Text('Delete Record?'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this growth record? This action cannot be undone.',
            style: TextStyle(fontSize: size.width * 0.035),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                final result = await _growthService.deleteGrowthRecord(
                  childId: _selectedChild!['id'] as int,
                  recordId: record['id'] as int,
                );

                if (result['success'] == true) {
                  _loadGrowthRecords();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Growth record deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['message'] ?? 'Failed to delete record',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showAddMeasurementDialog(BuildContext context) {
    if (_selectedChild == null) return;

    final Size size = MediaQuery.of(context).size;
    final TextEditingController heightController = TextEditingController();
    final TextEditingController weightController = TextEditingController();
    final TextEditingController additionalInfoController =
        TextEditingController();

    DateTime selectedDate = DateTime.now();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(size.width * 0.03),
              ),
              child: Container(
                width: size.width * 0.85,
                padding: EdgeInsets.all(size.width * 0.04),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(size.width * 0.02),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.trending_up,
                            color: Colors.blue.shade600,
                            size: size.width * 0.05,
                          ),
                        ),
                        SizedBox(width: size.width * 0.03),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Growth Record',
                                style: TextStyle(
                                  fontSize: size.width * 0.045,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'For ${_selectedChild!['name']}',
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

                    SizedBox(height: size.height * 0.02),

                    // Date Selection
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.03,
                          vertical: size.height * 0.015,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(
                            size.width * 0.015,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: size.width * 0.04),
                            SizedBox(width: size.width * 0.03),
                            Text(
                              'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: TextStyle(fontSize: size.width * 0.035),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.015),

                    // Height Input
                    TextField(
                      controller: heightController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: size.width * 0.035),
                      decoration: InputDecoration(
                        labelText: 'Height (cm)',
                        labelStyle: TextStyle(fontSize: size.width * 0.032),
                        hintText: 'Enter height in centimeters',
                        hintStyle: TextStyle(fontSize: size.width * 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            size.width * 0.015,
                          ),
                        ),
                        prefixIcon: Icon(Icons.height, size: size.width * 0.04),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.03,
                          vertical: size.height * 0.012,
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.015),

                    // Weight Input
                    TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: size.width * 0.035),
                      decoration: InputDecoration(
                        labelText: 'Weight (kg)',
                        labelStyle: TextStyle(fontSize: size.width * 0.032),
                        hintText: 'Enter weight in kilograms',
                        hintStyle: TextStyle(fontSize: size.width * 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            size.width * 0.015,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.monitor_weight,
                          size: size.width * 0.04,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.03,
                          vertical: size.height * 0.012,
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.015),

                    // Additional Info
                    TextField(
                      controller: additionalInfoController,
                      style: TextStyle(fontSize: size.width * 0.035),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Additional Notes (Optional)',
                        labelStyle: TextStyle(fontSize: size.width * 0.032),
                        hintText: 'Any notes about this measurement',
                        hintStyle: TextStyle(fontSize: size.width * 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            size.width * 0.015,
                          ),
                        ),
                        prefixIcon: Icon(Icons.note, size: size.width * 0.04),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.03,
                          vertical: size.height * 0.012,
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.02),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                },
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: size.width * 0.032,
                            ),
                          ),
                        ),
                        SizedBox(width: size.width * 0.015),
                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  // Validate input
                                  final height = double.tryParse(
                                    heightController.text,
                                  );
                                  final weight = double.tryParse(
                                    weightController.text,
                                  );

                                  if (height == null && weight == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Please enter at least height or weight',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() {
                                    isLoading = true;
                                  });

                                  try {
                                    // Call growth service - type will be determined automatically
                                    final result = await _growthService
                                        .addGrowthRecord(
                                          childId: _selectedChild!['id'] as int,
                                          dateOfRecord: selectedDate
                                              .toIso8601String()
                                              .split('T')[0],
                                          height: height,
                                          weight: weight,
                                          additionalInfo:
                                              additionalInfoController.text
                                                  .trim()
                                                  .isNotEmpty
                                              ? additionalInfoController.text
                                                    .trim()
                                              : null,
                                        );
                                    setState(() {
                                      isLoading = false;
                                    });

                                    Navigator.of(context).pop();

                                    if (result['success'] == true) {
                                      // Refresh growth records
                                      _loadGrowthRecords();

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            result['message'] ??
                                                'Growth record added successfully!',
                                          ),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            result['message'] ??
                                                'Failed to add growth record',
                                          ),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                    Navigator.of(context).pop();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.04,
                              vertical: size.height * 0.01,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                size.width * 0.015,
                              ),
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Save Record',
                                  style: TextStyle(
                                    fontSize: size.width * 0.032,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
