import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kidicapp_flutter/services/auth/auth_service.dart';

class GrowthService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/growth-records';
  final AuthService _authService = AuthService();

  /// Get JWT token from AuthService (uses secure storage)
  Future<String?> _getToken() async {
    return await _authService.getToken();
  }

  /// Get the latest growth record for a specific child
  Future<Map<String, dynamic>?> getLatestGrowthRecord(int childId) async {
    try {
      final records = await getGrowthRecords(childId);
      if (records.isEmpty) return null;

      // Sort by date (newest first) and return the first one
      records.sort(
        (a, b) => DateTime.parse(
          b['dateOfRecord'],
        ).compareTo(DateTime.parse(a['dateOfRecord'])),
      );
      return records.first;
    } catch (e) {
      debugPrint('🔍 Growth Service - Error getting latest record: $e');
      return null;
    }
  }

  /// Get all growth records for a specific child
  Future<List<Map<String, dynamic>>> getGrowthRecords(int childId) async {
    try {
      debugPrint(
        '🔍 === GROWTH SERVICE: GETTING RECORDS FOR CHILD $childId ===',
      );

      final token = await _getToken();
      if (token == null) {
        debugPrint('🔍 Growth Service - No JWT token found');
        return [];
      }

      final url = Uri.parse('$baseUrl/children/$childId');
      debugPrint('🔍 Growth Service - GET request to: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('🔍 Growth Service - Response status: ${response.statusCode}');
      debugPrint('🔍 Growth Service - Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          debugPrint(
            '🔍 Growth Service - Response length: ${response.body.length} characters',
          );

          // First attempt: Try standard JSON parsing
          try {
            List<dynamic> jsonArray = json.decode(response.body);
            debugPrint(
              '🔍 Growth Service - Successfully parsed JSON array with ${jsonArray.length} records',
            );

            List<Map<String, dynamic>> records = [];
            for (var item in jsonArray) {
              if (item is Map<String, dynamic>) {
                // Extract only the essential growth record fields to avoid circular references
                Map<String, dynamic> cleanRecord = {
                  'id': item['id'],
                  'additionalInfo': item['additionalInfo'],
                  'dateOfRecord': item['dateOfRecord'],
                  'height': item['height'],
                  'weight': item['weight'],
                  'type': item['type'],
                  'status': item['status'],
                };
                records.add(cleanRecord);
                debugPrint(
                  '🔍 Growth Service - Extracted clean record: ID=${cleanRecord['id']}, Date=${cleanRecord['dateOfRecord']}',
                );
              }
            }

            debugPrint(
              '🔍 Growth Service - Successfully extracted ${records.length} clean records',
            );
            return records;
          } catch (jsonError) {
            debugPrint('🔍 Growth Service - JSON parsing failed: $jsonError');
            debugPrint(
              '🔍 Growth Service - Falling back to manual parsing due to circular references...',
            );

            // Fallback: Manual parsing for circular JSON
            String responseBody = response.body;
            List<Map<String, dynamic>> records = [];

            // First, try to extract the array start - backend returns JSON array format
            if (responseBody.startsWith('[')) {
              debugPrint(
                '🔍 Growth Service - Detected JSON array format for manual parsing',
              );

              // Try multiple parsing approaches to find all records

              // Approach 1: Find complete records with all fields together
              RegExp fullRecordPattern = RegExp(
                r'\{"id":(\d+),"additionalInfo":(null|"[^"]*"),"dateOfRecord":"([^"]+)","height":([^,}]+),"weight":([^,}]+),"type":"([^"]+)","status":"([^"]+)"',
                multiLine: true,
              );
              Iterable<RegExpMatch> fullMatches = fullRecordPattern.allMatches(
                responseBody,
              );
              debugPrint(
                '🔍 Growth Service - Full pattern matches: ${fullMatches.length}',
              );

              // Approach 2: Find all record starts and parse individually
              RegExp recordStartPattern = RegExp(
                r'\{"id":(\d+),"additionalInfo":(null|"[^"]*"),"dateOfRecord":"([^"]+)"',
                multiLine: true,
              );
              List<RegExpMatch> recordStarts = recordStartPattern
                  .allMatches(responseBody)
                  .toList();
              debugPrint(
                '🔍 Growth Service - Record start patterns: ${recordStarts.length}',
              );

              // Show what we found at the start of the response
              String responseStart = responseBody.length > 1000
                  ? responseBody.substring(0, 1000)
                  : responseBody;
              debugPrint(
                '🔍 Growth Service - Response start (first 1000 chars): $responseStart',
              );

              // If we found full matches, use them
              if (fullMatches.isNotEmpty) {
                for (RegExpMatch match in fullMatches) {
                  try {
                    int id = int.parse(match.group(1)!);
                    String? additionalInfo = match.group(2) == 'null'
                        ? null
                        : match.group(2)?.replaceAll('"', '');
                    String dateOfRecord = match.group(3)!;
                    double? height = match.group(4) == 'null'
                        ? null
                        : double.tryParse(match.group(4)!);
                    double? weight = match.group(5) == 'null'
                        ? null
                        : double.tryParse(match.group(5)!);
                    String type = match.group(6)!;
                    String status = match.group(7)!;

                    Map<String, dynamic> record = {
                      'id': id,
                      'additionalInfo': additionalInfo,
                      'dateOfRecord': dateOfRecord,
                      'height': height,
                      'weight': weight,
                      'type': type,
                      'status': status,
                    };

                    records.add(record);
                    debugPrint(
                      '🔍 Growth Service - Extracted complete record: ID=$id, Date=$dateOfRecord, Height=$height, Weight=$weight',
                    );
                  } catch (e) {
                    debugPrint(
                      '🔍 Growth Service - Error parsing complete record: $e',
                    );
                  }
                }
              } else {
                // Fallback: parse each record start individually
                debugPrint(
                  '🔍 Growth Service - Using fallback individual parsing for ${recordStarts.length} records',
                );

                for (int i = 0; i < recordStarts.length; i++) {
                  RegExpMatch startMatch = recordStarts[i];

                  // Extract a larger area around this record
                  int recordStart = startMatch.start;
                  int recordEnd = i + 1 < recordStarts.length
                      ? recordStarts[i + 1].start
                      : responseBody.length;
                  String recordArea = responseBody.substring(
                    recordStart,
                    recordEnd,
                  );

                  try {
                    Map<String, dynamic>? record = _extractRecordFromArea(
                      recordArea,
                      startMatch,
                    );
                    if (record != null) {
                      records.add(record);
                      debugPrint(
                        '🔍 Growth Service - Extracted individual record: ID=${record['id']}, Date=${record['dateOfRecord']}',
                      );
                    }
                  } catch (e) {
                    debugPrint(
                      '🔍 Growth Service - Error extracting individual record $i: $e',
                    );
                  }
                }
              }
            } else {
              debugPrint(
                '🔍 Growth Service - Falling back to original parsing approach...',
              );

              // Find all occurrences of growth record starts with dateOfRecord
              RegExp recordPattern = RegExp(
                r'\{"id":(\d+),"additionalInfo":(null|"[^"]*"),"dateOfRecord":"([^"]+)"',
              );
              List<RegExpMatch> recordStarts = recordPattern
                  .allMatches(responseBody)
                  .toList();

              debugPrint(
                '🔍 Growth Service - Found ${recordStarts.length} record starts with dates',
              );

              // Debug: Show what IDs we found
              for (int i = 0; i < recordStarts.length; i++) {
                int id = int.parse(recordStarts[i].group(1)!);
                String date = recordStarts[i].group(3)!;
                debugPrint(
                  '🔍 Growth Service - Found record start: ID=$id, Date=$date',
                );
              }

              for (int i = 0; i < recordStarts.length; i++) {
                RegExpMatch startMatch = recordStarts[i];
                int recordStart = startMatch.start;

                // Extract this record's data from the area around its start
                String recordArea = responseBody.substring(
                  recordStart,
                  (recordStart + 500 < responseBody.length)
                      ? recordStart + 500
                      : responseBody.length,
                );

                try {
                  // Extract individual fields from this record area
                  Map<String, dynamic>? record = _extractRecordFromArea(
                    recordArea,
                    startMatch,
                  );
                  if (record != null) {
                    records.add(record);
                    debugPrint(
                      '🔍 Growth Service - Extracted record: ${record['id']} from ${record['dateOfRecord']}',
                    );
                  }
                } catch (e) {
                  debugPrint(
                    '🔍 Growth Service - Error extracting record $i: $e',
                  );
                }
              }
            }

            debugPrint(
              '🔍 Growth Service - Found ${records.length} growth records (manual parsing)',
            );

            // Debug: Show each record's data
            for (int i = 0; i < records.length; i++) {
              debugPrint('🔍 Growth Service - Record $i: ${records[i]}');
            }

            return records;
          } // End of jsonError catch block
        } catch (e) {
          debugPrint(
            '🔍 Growth Service - JSON parsing error in getGrowthRecords: $e',
          );
          return []; // Return empty list if parsing fails
        }
      } else {
        debugPrint(
          '🔍 Growth Service - Error getting records: ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      debugPrint('🔍 Growth Service - Exception getting records: $e');
      return [];
    }
  }

  /// Add a new growth record for a child
  Future<Map<String, dynamic>> addGrowthRecord({
    required int childId,
    String?
    dateOfRecord, // Made optional, will use current date if not provided
    double? height,
    double? weight,
    String? type, // Will be determined automatically if not provided
    String? status, // Will be set to 'NORMAL' if not provided
    String? additionalInfo,
  }) async {
    try {
      debugPrint('🔍 === GROWTH SERVICE: ADDING RECORD FOR CHILD $childId ===');

      final token = await _getToken();
      if (token == null) {
        debugPrint('🔍 Growth Service - No JWT token found');
        return {'success': false, 'message': 'Authentication required'};
      }

      final url = Uri.parse('$baseUrl/children/$childId');
      debugPrint('🔍 Growth Service - POST request to: $url');

      // Use current date if not provided
      final String finalDate =
          dateOfRecord ?? DateTime.now().toIso8601String().split('T')[0];

      // Determine type based on what measurements are provided
      String recordType = type ?? _determineRecordType(height, weight);
      String recordStatus = status ?? _possibleStatuses[0]; // 'NORMAL'

      // Try different enum value variations for debugging
      debugPrint(
        '🔍 Growth Service - Trying recordType: $recordType, recordStatus: $recordStatus',
      );
      debugPrint('🔍 Growth Service - Date format: $finalDate');

      // Prepare form data
      final Map<String, String> formData = {
        'dateOfRecord': finalDate,
        'type': recordType,
        'status': recordStatus,
      };

      if (height != null) {
        formData['height'] = height.toString();
      }
      if (weight != null) {
        formData['weight'] = weight.toString();
      }
      if (additionalInfo != null && additionalInfo.isNotEmpty) {
        formData['additionalInfo'] = additionalInfo;
      }

      debugPrint('🔍 Growth Service - Form data: $formData');
      debugPrint('🔍 Growth Service - Date being sent: $finalDate');
      debugPrint('🔍 Growth Service - Available types: $_possibleTypes');
      debugPrint('🔍 Growth Service - Available statuses: $_possibleStatuses');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $token',
        },
        body: formData,
      );

      debugPrint('🔍 Growth Service - Response status: ${response.statusCode}');
      debugPrint('🔍 Growth Service - Response body: ${response.body}');

      if (response.statusCode == 201) {
        // Handle potentially circular JSON response safely
        try {
          final recordData = json.decode(response.body);
          debugPrint('🔍 Growth Service - Successfully added record');

          // Extract only the essential data to avoid circular references
          final cleanData = {
            'id': recordData['id'],
            'dateOfRecord': recordData['dateOfRecord'],
            'height': recordData['height'],
            'weight': recordData['weight'],
            'type': recordData['type'],
            'status': recordData['status'],
            'additionalInfo': recordData['additionalInfo'],
          };

          return {
            'success': true,
            'message': 'Growth record added successfully',
            'data': cleanData,
          };
        } catch (e) {
          debugPrint(
            '🔍 Growth Service - JSON parsing error (likely circular reference): $e',
          );
          // Even if JSON parsing fails, the record was created successfully (201 status)
          return {
            'success': true,
            'message': 'Growth record added successfully',
            'data': {'status': 'created'}, // Simple fallback data
          };
        }
      } else if (response.statusCode == 500 && response.body.contains('enum')) {
        // If we get an enum conversion error, try the next enum combinations
        debugPrint(
          '🔍 Growth Service - Enum error detected, trying alternative values...',
        );
        return await _tryAlternativeEnumValues(
          childId: childId,
          dateOfRecord: finalDate,
          height: height,
          weight: weight,
          additionalInfo: additionalInfo,
          currentTypeIndex: 0,
          currentStatusIndex: 0,
        );
      } else {
        debugPrint(
          '🔍 Growth Service - Error adding record: ${response.statusCode}',
        );
        return {
          'success': false,
          'message': 'Failed to add growth record: ${response.body}',
        };
      }
    } catch (e) {
      debugPrint('🔍 Growth Service - Exception adding record: $e');
      return {'success': false, 'message': 'Error adding growth record: $e'};
    }
  }

  /// Update an existing growth record
  Future<Map<String, dynamic>> updateGrowthRecord({
    required int childId,
    required int recordId,
    String? dateOfRecord,
    double? height,
    double? weight,
    String? type,
    String? status,
    String? additionalInfo,
  }) async {
    try {
      debugPrint(
        '🔍 === GROWTH SERVICE: UPDATING RECORD $recordId FOR CHILD $childId ===',
      );

      final token = await _getToken();
      if (token == null) {
        debugPrint('🔍 Growth Service - No JWT token found');
        return {'success': false, 'message': 'Authentication required'};
      }

      final url = Uri.parse('$baseUrl/children/$childId/$recordId');
      debugPrint('🔍 Growth Service - PUT request to: $url');

      // Prepare form data (only include non-null values)
      final Map<String, String> formData = {};

      if (dateOfRecord != null) {
        formData['dateOfRecord'] = dateOfRecord;
      }
      if (height != null) {
        formData['height'] = height.toString();
      }
      if (weight != null) {
        formData['weight'] = weight.toString();
      }
      if (type != null) {
        formData['type'] = type;
      }
      if (status != null) {
        formData['status'] = status;
      }
      if (additionalInfo != null) {
        formData['additionalInfo'] = additionalInfo;
      }

      debugPrint('🔍 Growth Service - Form data: $formData');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $token',
        },
        body: formData,
      );

      debugPrint('🔍 Growth Service - Response status: ${response.statusCode}');
      debugPrint('🔍 Growth Service - Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final recordData = json.decode(response.body);
          debugPrint('🔍 Growth Service - Successfully updated record');

          // Extract only essential data to avoid circular references
          final cleanData = {
            'id': recordData['id'],
            'dateOfRecord': recordData['dateOfRecord'],
            'height': recordData['height'],
            'weight': recordData['weight'],
            'type': recordData['type'],
            'status': recordData['status'],
            'additionalInfo': recordData['additionalInfo'],
          };

          return {
            'success': true,
            'message': 'Growth record updated successfully',
            'data': cleanData,
          };
        } catch (e) {
          debugPrint('🔍 Growth Service - JSON parsing error in update: $e');
          return {
            'success': true,
            'message': 'Growth record updated successfully',
            'data': {'status': 'updated'},
          };
        }
      } else {
        debugPrint(
          '🔍 Growth Service - Error updating record: ${response.statusCode}',
        );
        return {
          'success': false,
          'message': 'Failed to update growth record: ${response.body}',
        };
      }
    } catch (e) {
      debugPrint('🔍 Growth Service - Exception updating record: $e');
      return {'success': false, 'message': 'Error updating growth record: $e'};
    }
  }

  /// Delete a growth record
  Future<Map<String, dynamic>> deleteGrowthRecord({
    required int childId,
    required int recordId,
  }) async {
    try {
      debugPrint(
        '🔍 === GROWTH SERVICE: DELETING RECORD $recordId FOR CHILD $childId ===',
      );

      final token = await _getToken();
      if (token == null) {
        debugPrint('🔍 Growth Service - No JWT token found');
        return {'success': false, 'message': 'Authentication required'};
      }

      final url = Uri.parse('$baseUrl/children/$childId/$recordId');
      debugPrint('🔍 Growth Service - DELETE request to: $url');

      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('🔍 Growth Service - Response status: ${response.statusCode}');

      if (response.statusCode == 204) {
        debugPrint('🔍 Growth Service - Successfully deleted record');
        return {
          'success': true,
          'message': 'Growth record deleted successfully',
        };
      } else {
        debugPrint(
          '🔍 Growth Service - Error deleting record: ${response.statusCode}',
        );
        return {'success': false, 'message': 'Failed to delete growth record'};
      }
    } catch (e) {
      debugPrint('🔍 Growth Service - Exception deleting record: $e');
      return {'success': false, 'message': 'Error deleting growth record: $e'};
    }
  }

  /// Enhanced percentile calculation based on WHO Growth Standards
  /// This method calculates percentiles for height and weight based on age and gender
  static int calculatePercentile(
    double value,
    String type,
    int ageInMonths, {
    bool? isMale,
  }) {
    debugPrint(
      '🔍 Calculating percentile: value=$value, type=$type, age=${ageInMonths}months, isMale=$isMale',
    );

    switch (type.toUpperCase()) {
      case 'HEIGHT':
        return _calculateHeightPercentile(value, ageInMonths, isMale ?? true);
      case 'WEIGHT':
        return _calculateWeightPercentile(value, ageInMonths, isMale ?? true);
      default:
        return 50; // Default to 50th percentile
    }
  }

  /// Calculate height percentile based on WHO growth standards
  static int _calculateHeightPercentile(
    double heightCm,
    int ageInMonths,
    bool isMale,
  ) {
    // WHO Growth Standards approximation (simplified version)
    // In production, you would use the complete WHO growth charts

    if (ageInMonths <= 24) {
      // 0-24 months (infants and toddlers)
      return _getInfantHeightPercentile(heightCm, ageInMonths, isMale);
    } else if (ageInMonths <= 60) {
      // 2-5 years (preschoolers)
      return _getPreschoolHeightPercentile(heightCm, ageInMonths, isMale);
    } else {
      // 5+ years (school age)
      return _getSchoolAgeHeightPercentile(heightCm, ageInMonths, isMale);
    }
  }

  /// Calculate weight percentile based on WHO growth standards
  static int _calculateWeightPercentile(
    double weightKg,
    int ageInMonths,
    bool isMale,
  ) {
    if (ageInMonths <= 24) {
      // 0-24 months (infants and toddlers)
      return _getInfantWeightPercentile(weightKg, ageInMonths, isMale);
    } else if (ageInMonths <= 60) {
      // 2-5 years (preschoolers)
      return _getPreschoolWeightPercentile(weightKg, ageInMonths, isMale);
    } else {
      // 5+ years (school age)
      return _getSchoolAgeWeightPercentile(weightKg, ageInMonths, isMale);
    }
  }

  /// Infant height percentiles (0-24 months)
  static int _getInfantHeightPercentile(
    double heightCm,
    int ageInMonths,
    bool isMale,
  ) {
    // Approximate WHO standards for length/height
    Map<int, List<double>> maleHeightPercentiles = {
      0: [46.1, 49.9, 53.7], // 3rd, 50th, 97th percentiles at birth
      3: [57.3, 61.4, 65.5], // 3 months
      6: [63.3, 67.6, 71.9], // 6 months
      9: [68.0, 72.3, 76.5], // 9 months
      12: [71.7, 76.1, 80.5], // 12 months
      18: [77.7, 82.4, 87.0], // 18 months
      24: [82.3, 87.1, 91.9], // 24 months
    };

    Map<int, List<double>> femaleHeightPercentiles = {
      0: [45.4, 49.1, 52.9], // Birth
      3: [55.6, 59.8, 64.0], // 3 months
      6: [61.2, 65.7, 70.2], // 6 months
      9: [66.1, 70.6, 75.0], // 9 months
      12: [69.8, 74.3, 78.9], // 12 months
      18: [76.0, 80.7, 85.4], // 18 months
      24: [80.0, 84.9, 89.8], // 24 months
    };

    Map<int, List<double>> percentiles = isMale
        ? maleHeightPercentiles
        : femaleHeightPercentiles;
    return _getPercentileFromTable(heightCm, ageInMonths, percentiles);
  }

  /// Infant weight percentiles (0-24 months)
  static int _getInfantWeightPercentile(
    double weightKg,
    int ageInMonths,
    bool isMale,
  ) {
    Map<int, List<double>> maleWeightPercentiles = {
      0: [2.5, 3.3, 4.4], // Birth
      3: [5.0, 6.0, 7.5], // 3 months
      6: [6.4, 7.9, 9.8], // 6 months
      9: [7.6, 8.9, 10.9], // 9 months
      12: [8.4, 9.6, 11.8], // 12 months
      18: [9.6, 11.0, 13.0], // 18 months
      24: [10.5, 12.2, 14.3], // 24 months
    };

    Map<int, List<double>> femaleWeightPercentiles = {
      0: [2.4, 3.2, 4.2], // Birth
      3: [4.5, 5.5, 6.9], // 3 months
      6: [5.7, 7.3, 9.2], // 6 months
      9: [6.9, 8.2, 10.2], // 9 months
      12: [7.7, 8.9, 10.8], // 12 months
      18: [8.8, 10.2, 12.1], // 18 months
      24: [9.7, 11.2, 13.2], // 24 months
    };

    Map<int, List<double>> percentiles = isMale
        ? maleWeightPercentiles
        : femaleWeightPercentiles;
    return _getPercentileFromTable(weightKg, ageInMonths, percentiles);
  }

  /// Preschool height percentiles (2-5 years)
  static int _getPreschoolHeightPercentile(
    double heightCm,
    int ageInMonths,
    bool isMale,
  ) {
    Map<int, List<double>> maleHeightPercentiles = {
      36: [88.7, 93.9, 99.1], // 3 years
      48: [95.0, 100.9, 106.7], // 4 years
      60: [101.2, 107.4, 113.5], // 5 years
    };

    Map<int, List<double>> femaleHeightPercentiles = {
      36: [87.4, 93.0, 98.6], // 3 years
      48: [94.1, 100.3, 106.6], // 4 years
      60: [100.7, 107.2, 113.8], // 5 years
    };

    Map<int, List<double>> percentiles = isMale
        ? maleHeightPercentiles
        : femaleHeightPercentiles;
    return _getPercentileFromTable(heightCm, ageInMonths, percentiles);
  }

  /// Preschool weight percentiles (2-5 years)
  static int _getPreschoolWeightPercentile(
    double weightKg,
    int ageInMonths,
    bool isMale,
  ) {
    Map<int, List<double>> maleWeightPercentiles = {
      36: [11.3, 13.7, 16.9], // 3 years
      48: [12.7, 15.7, 19.8], // 4 years
      60: [14.1, 17.8, 22.7], // 5 years
    };

    Map<int, List<double>> femaleWeightPercentiles = {
      36: [10.8, 13.1, 16.5], // 3 years
      48: [12.3, 15.4, 19.9], // 4 years
      60: [13.7, 17.4, 23.0], // 5 years
    };

    Map<int, List<double>> percentiles = isMale
        ? maleWeightPercentiles
        : femaleWeightPercentiles;
    return _getPercentileFromTable(weightKg, ageInMonths, percentiles);
  }

  /// School age height percentiles (5+ years)
  static int _getSchoolAgeHeightPercentile(
    double heightCm,
    int ageInMonths,
    bool isMale,
  ) {
    // Simplified calculation for older children
    double ageInYears = ageInMonths / 12.0;

    if (isMale) {
      // Boys growth approximation
      double expectedHeight = 50 + (ageInYears * 6.5); // Rough approximation
      double heightDiff = heightCm - expectedHeight;

      if (heightDiff < -15) return 3;
      if (heightDiff < -10) return 10;
      if (heightDiff < -5) return 25;
      if (heightDiff < 5) return 50;
      if (heightDiff < 10) return 75;
      if (heightDiff < 15) return 90;
      return 97;
    } else {
      // Girls growth approximation
      double expectedHeight = 48 + (ageInYears * 6.0); // Rough approximation
      double heightDiff = heightCm - expectedHeight;

      if (heightDiff < -15) return 3;
      if (heightDiff < -10) return 10;
      if (heightDiff < -5) return 25;
      if (heightDiff < 5) return 50;
      if (heightDiff < 10) return 75;
      if (heightDiff < 15) return 90;
      return 97;
    }
  }

  /// School age weight percentiles (5+ years)
  static int _getSchoolAgeWeightPercentile(
    double weightKg,
    int ageInMonths,
    bool isMale,
  ) {
    // Simplified calculation for older children
    double ageInYears = ageInMonths / 12.0;

    if (isMale) {
      // Boys weight approximation
      double expectedWeight = 7 + (ageInYears * 2.3); // Rough approximation
      double weightDiff = weightKg - expectedWeight;

      if (weightDiff < -5) return 3;
      if (weightDiff < -3) return 10;
      if (weightDiff < -1) return 25;
      if (weightDiff < 1) return 50;
      if (weightDiff < 3) return 75;
      if (weightDiff < 5) return 90;
      return 97;
    } else {
      // Girls weight approximation
      double expectedWeight = 6.5 + (ageInYears * 2.1); // Rough approximation
      double weightDiff = weightKg - expectedWeight;

      if (weightDiff < -5) return 3;
      if (weightDiff < -3) return 10;
      if (weightDiff < -1) return 25;
      if (weightDiff < 1) return 50;
      if (weightDiff < 3) return 75;
      if (weightDiff < 5) return 90;
      return 97;
    }
  }

  /// Helper method to find percentile from data table
  static int _getPercentileFromTable(
    double value,
    int ageInMonths,
    Map<int, List<double>> percentileTable,
  ) {
    // Find the closest age entry
    int closestAge = percentileTable.keys.reduce(
      (a, b) => (ageInMonths - a).abs() < (ageInMonths - b).abs() ? a : b,
    );

    List<double> percentiles = percentileTable[closestAge]!;
    double p3 = percentiles[0]; // 3rd percentile
    double p50 = percentiles[1]; // 50th percentile
    double p97 = percentiles[2]; // 97th percentile

    // Enhanced percentile calculation with more granular ranges
    if (value <= p3 * 0.9) return 1;
    if (value <= p3) return 3;
    if (value <= p3 + (p50 - p3) * 0.3) return 10;
    if (value <= p3 + (p50 - p3) * 0.7) return 25;
    if (value <= p50) return 50;
    if (value <= p50 + (p97 - p50) * 0.3) return 75;
    if (value <= p50 + (p97 - p50) * 0.7) return 90;
    if (value <= p97) return 97;
    return 99;
  }

  /// Assess growth velocity between two measurements
  static Map<String, dynamic> assessGrowthVelocity({
    required double previousHeight,
    required double currentHeight,
    required double previousWeight,
    required double currentWeight,
    required DateTime previousDate,
    required DateTime currentDate,
    required int currentAgeInMonths,
    required bool isMale,
  }) {
    debugPrint('🔍 Assessing growth velocity over time period');

    int daysBetween = currentDate.difference(previousDate).inDays;
    double monthsBetween = daysBetween / 30.44; // Average days per month

    if (monthsBetween < 1) {
      return {
        'status': 'insufficient_time',
        'message':
            'Need at least 1 month between measurements for velocity assessment',
      };
    }

    double heightVelocity =
        (currentHeight - previousHeight) / monthsBetween; // cm per month
    double weightVelocity =
        (currentWeight - previousWeight) / monthsBetween; // kg per month

    // Expected growth rates by age group
    Map<String, double> expectedHeightVelocity = _getExpectedHeightVelocity(
      currentAgeInMonths,
    );
    Map<String, double> expectedWeightVelocity = _getExpectedWeightVelocity(
      currentAgeInMonths,
    );

    // Assess height velocity
    String heightVelocityStatus = _assessVelocity(
      heightVelocity,
      expectedHeightVelocity['normal']!,
      expectedHeightVelocity['min']!,
      expectedHeightVelocity['max']!,
    );

    // Assess weight velocity
    String weightVelocityStatus = _assessVelocity(
      weightVelocity,
      expectedWeightVelocity['normal']!,
      expectedWeightVelocity['min']!,
      expectedWeightVelocity['max']!,
    );

    return {
      'time_period_months': monthsBetween.round(),
      'height_velocity_cm_per_month': heightVelocity.toStringAsFixed(1),
      'weight_velocity_kg_per_month': weightVelocity.toStringAsFixed(2),
      'height_velocity_status': heightVelocityStatus,
      'weight_velocity_status': weightVelocityStatus,
      'overall_velocity_assessment': _getOverallVelocityAssessment(
        heightVelocityStatus,
        weightVelocityStatus,
      ),
      'recommendations': _getVelocityRecommendations(
        heightVelocityStatus,
        weightVelocityStatus,
      ),
    };
  }

  /// Get expected height velocity by age
  static Map<String, double> _getExpectedHeightVelocity(int ageInMonths) {
    if (ageInMonths <= 12) {
      return {'min': 1.5, 'normal': 2.0, 'max': 2.5}; // cm per month
    } else if (ageInMonths <= 24) {
      return {'min': 0.8, 'normal': 1.2, 'max': 1.6};
    } else if (ageInMonths <= 60) {
      return {'min': 0.4, 'normal': 0.6, 'max': 0.8};
    } else if (ageInMonths <= 120) {
      return {'min': 0.3, 'normal': 0.5, 'max': 0.7};
    } else {
      return {'min': 0.2, 'normal': 0.4, 'max': 1.0}; // Growth spurt possible
    }
  }

  /// Get expected weight velocity by age
  static Map<String, double> _getExpectedWeightVelocity(int ageInMonths) {
    if (ageInMonths <= 6) {
      return {'min': 0.4, 'normal': 0.6, 'max': 0.8}; // kg per month
    } else if (ageInMonths <= 12) {
      return {'min': 0.2, 'normal': 0.3, 'max': 0.5};
    } else if (ageInMonths <= 24) {
      return {'min': 0.1, 'normal': 0.2, 'max': 0.3};
    } else if (ageInMonths <= 60) {
      return {'min': 0.1, 'normal': 0.15, 'max': 0.25};
    } else {
      return {'min': 0.1, 'normal': 0.2, 'max': 0.4};
    }
  }

  /// Assess velocity against expected ranges
  static String _assessVelocity(
    double actual,
    double normal,
    double min,
    double max,
  ) {
    if (actual < min * 0.5) return 'very_slow';
    if (actual < min) return 'slow';
    if (actual <= max) return 'normal';
    if (actual <= max * 1.5) return 'fast';
    return 'very_fast';
  }

  /// Get overall velocity assessment
  static String _getOverallVelocityAssessment(
    String heightStatus,
    String weightStatus,
  ) {
    if ((heightStatus == 'very_slow' || weightStatus == 'very_slow') ||
        (heightStatus == 'slow' && weightStatus == 'slow')) {
      return 'concerning_slow_growth';
    }
    if (heightStatus == 'very_fast' && weightStatus == 'very_fast') {
      return 'concerning_rapid_growth';
    }
    if ((heightStatus == 'normal' || heightStatus == 'fast') &&
        (weightStatus == 'normal' || weightStatus == 'fast')) {
      return 'healthy_growth';
    }
    return 'monitor_growth_patterns';
  }

  /// Get recommendations based on growth velocity
  static List<String> _getVelocityRecommendations(
    String heightStatus,
    String weightStatus,
  ) {
    List<String> recommendations = [];

    if (heightStatus == 'very_slow' || weightStatus == 'very_slow') {
      recommendations.add(
        'Consult pediatrician immediately for growth evaluation',
      );
      recommendations.add(
        'Consider nutritional assessment and hormone testing',
      );
    } else if (heightStatus == 'slow' || weightStatus == 'slow') {
      recommendations.add(
        'Schedule pediatrician visit to discuss growth patterns',
      );
      recommendations.add(
        'Review nutrition and ensure adequate calories and nutrients',
      );
    }

    if (heightStatus == 'very_fast' || weightStatus == 'very_fast') {
      recommendations.add(
        'Monitor for signs of precocious puberty or other conditions',
      );
      recommendations.add('Discuss rapid growth with pediatrician');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Continue current healthy lifestyle and nutrition');
      recommendations.add('Maintain regular growth monitoring');
    }

    return recommendations;
  }

  /// Get health category based on percentile (High, Good, Low)
  static String getHealthCategory(int percentile) {
    if (percentile < 25) return 'Low';
    if (percentile <= 75) return 'Good';
    return 'High';
  }

  /// Get detailed health status based on percentile
  static String getDetailedHealthStatus(int percentile) {
    if (percentile < 3) return 'Significantly below average';
    if (percentile < 10) return 'Below average';
    if (percentile < 25) return 'Low normal';
    if (percentile <= 75) return 'Normal range';
    if (percentile < 90) return 'Above normal';
    if (percentile < 97) return 'Well above average';
    return 'Significantly above average';
  }

  /// Get health category color for UI display
  static Color getHealthCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'low':
        return Colors.orange.shade600;
      case 'good':
        return Colors.green.shade600;
      case 'high':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  /// Get health category icon for UI display
  static IconData getHealthCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'low':
        return Icons.trending_down;
      case 'good':
        return Icons.check_circle;
      case 'high':
        return Icons.trending_up;
      default:
        return Icons.help;
    }
  }

  /// Get health advice based on category and measurement type
  static String getHealthAdvice(String category, String measurementType) {
    String type = measurementType.toLowerCase();
    String cat = category.toLowerCase();

    if (type == 'height') {
      switch (cat) {
        case 'low':
          return 'Consider consulting your pediatrician about growth patterns. Ensure adequate nutrition and sleep.';
        case 'good':
          return 'Your child\'s height is in the normal range. Continue with healthy habits.';
        case 'high':
          return 'Your child is above average height. Monitor growth patterns during regular checkups.';
        default:
          return 'Consult your healthcare provider for personalized advice.';
      }
    } else if (type == 'weight') {
      switch (cat) {
        case 'low':
          return 'Consider discussing nutrition and appetite with your pediatrician. Focus on healthy weight gain.';
        case 'good':
          return 'Your child\'s weight is healthy. Maintain balanced nutrition and active lifestyle.';
        case 'high':
          return 'Monitor portion sizes and encourage physical activity. Consult pediatrician if concerned.';
        default:
          return 'Consult your healthcare provider for personalized advice.';
      }
    }

    return 'Regular monitoring and pediatric checkups are recommended.';
  }

  /// Comprehensive health assessment for a child based on height, weight, age, and gender
  ///
  /// This enhanced method provides a detailed analysis of a child's growth including:
  /// - Individual percentile calculations for height and weight
  /// - BMI analysis with age-appropriate ranges
  /// - Overall health status determination
  /// - Specific recommendations based on findings
  /// - Alerts for concerning measurements
  ///
  /// Parameters:
  /// - [height]: Child's height in centimeters (can be null)
  /// - [weight]: Child's weight in kilograms (can be null)
  /// - [ageInMonths]: Child's age in months (required)
  /// - [isMale]: Gender - true for male, false for female (required)
  ///
  /// Returns a Map containing:
  /// - overall_status: 'excellent', 'good', 'monitor', 'needs_attention', or 'unknown'
  /// - overall_description: Human-readable summary
  /// - height_analysis: Detailed height percentile analysis (if height provided)
  /// - weight_analysis: Detailed weight percentile analysis (if weight provided)
  /// - bmi_analysis: BMI analysis (if both height and weight provided)
  /// - recommendations: List of actionable recommendations
  /// - alerts: List of concerning findings that need attention
  /// - age_group: Classification like 'infant', 'toddler', 'preschooler', etc.
  ///
  /// Example usage:
  /// ```dart
  /// var assessment = GrowthService.assessChildGrowth(
  ///   height: 85.0, // 85 cm
  ///   weight: 12.5, // 12.5 kg
  ///   ageInMonths: 18, // 1.5 years old
  ///   isMale: true,
  /// );
  ///
  /// print(assessment['overall_status']); // 'good'
  /// print(assessment['overall_description']); // Detailed description
  /// print(GrowthService.formatAssessmentSummary(assessment)); // Formatted summary
  /// ```
  static Map<String, dynamic> assessChildGrowth({
    required double? height, // in cm
    required double? weight, // in kg
    required int ageInMonths,
    required bool isMale,
  }) {
    debugPrint(
      '🔍 Assessing child growth: height=$height cm, weight=$weight kg, age=${ageInMonths}months, isMale=$isMale',
    );

    Map<String, dynamic> assessment = {
      'overall_status': 'unknown',
      'overall_description': 'Insufficient data for assessment',
      'height_analysis': null,
      'weight_analysis': null,
      'bmi_analysis': null,
      'recommendations': <String>[],
      'alerts': <String>[],
      'age_group': _getAgeGroup(ageInMonths),
    };

    // Height analysis
    if (height != null && height > 0) {
      int heightPercentile = calculatePercentile(
        height,
        'HEIGHT',
        ageInMonths,
        isMale: isMale,
      );
      assessment['height_analysis'] = _analyzeMetric(
        heightPercentile,
        'height',
      );
    }

    // Weight analysis
    if (weight != null && weight > 0) {
      int weightPercentile = calculatePercentile(
        weight,
        'WEIGHT',
        ageInMonths,
        isMale: isMale,
      );
      assessment['weight_analysis'] = _analyzeMetric(
        weightPercentile,
        'weight',
      );
    }

    // BMI analysis (if both height and weight available)
    if (height != null && weight != null && height > 0 && weight > 0) {
      double bmi = _calculateBMI(weight, height);
      int bmiPercentile = _calculateBMIPercentile(bmi, ageInMonths, isMale);
      assessment['bmi_analysis'] = _analyzeBMI(bmiPercentile);
    }

    // Overall assessment
    assessment = _generateOverallAssessment(assessment);

    debugPrint(
      '🔍 Child growth assessment completed: ${assessment['overall_status']}',
    );
    return assessment;
  }

  /// Calculate BMI (Body Mass Index)
  static double _calculateBMI(double weightKg, double heightCm) {
    double heightM = heightCm / 100; // Convert cm to meters
    return weightKg / (heightM * heightM);
  }

  /// Calculate BMI percentile based on age and gender
  static int _calculateBMIPercentile(double bmi, int ageInMonths, bool isMale) {
    // Simplified BMI percentile calculation
    // In production, you would use official CDC BMI-for-age charts

    double ageInYears = ageInMonths / 12.0;

    // Age-appropriate BMI ranges (simplified)
    double normalBMILow, normalBMIHigh;

    if (ageInMonths < 24) {
      // Toddlers (0-2 years) - BMI is less reliable, use weight percentiles instead
      return 50; // Default to normal for very young children
    } else if (ageInMonths < 60) {
      // Preschoolers (2-5 years)
      normalBMILow = 14.0;
      normalBMIHigh = 17.0;
    } else if (ageInMonths < 120) {
      // School age (5-10 years)
      normalBMILow = 14.5 + (ageInYears - 5) * 0.3;
      normalBMIHigh = 18.0 + (ageInYears - 5) * 0.4;
    } else {
      // Older children (10+ years)
      normalBMILow = 16.0 + (ageInYears - 10) * 0.5;
      normalBMIHigh = 21.0 + (ageInYears - 10) * 0.6;
    }

    // Adjust for gender
    if (!isMale) {
      normalBMILow -= 0.5;
      normalBMIHigh -= 0.5;
    }

    // Calculate percentile based on position within normal range
    if (bmi < normalBMILow * 0.85) return 5; // Underweight
    if (bmi < normalBMILow) return 15;
    if (bmi < normalBMIHigh) return 50; // Normal
    if (bmi < normalBMIHigh * 1.15) return 85;
    return 95; // Overweight/Obese
  }

  /// Analyze individual metric (height, weight, BMI)
  static Map<String, dynamic> _analyzeMetric(
    int percentile,
    String metricType,
  ) {
    String category = getHealthCategory(percentile);
    String status = getDetailedHealthStatus(percentile);

    return {
      'percentile': percentile,
      'category': category,
      'status': status,
      'is_concerning': percentile < 5 || percentile > 95,
      'needs_attention': percentile < 10 || percentile > 90,
      'is_normal': percentile >= 25 && percentile <= 75,
      'metric_type': metricType,
    };
  }

  /// Analyze BMI specifically
  static Map<String, dynamic> _analyzeBMI(int bmiPercentile) {
    String category;
    String status;
    bool isConcerning = false;

    if (bmiPercentile < 5) {
      category = 'Underweight';
      status = 'Below healthy weight range';
      isConcerning = true;
    } else if (bmiPercentile < 85) {
      category = 'Normal';
      status = 'Healthy weight range';
    } else if (bmiPercentile < 95) {
      category = 'Overweight';
      status = 'Above healthy weight range';
      isConcerning = true;
    } else {
      category = 'Obese';
      status = 'Significantly above healthy weight range';
      isConcerning = true;
    }

    return {
      'percentile': bmiPercentile,
      'category': category,
      'status': status,
      'is_concerning': isConcerning,
      'needs_attention': bmiPercentile < 10 || bmiPercentile > 85,
      'is_normal': bmiPercentile >= 5 && bmiPercentile < 85,
      'metric_type': 'bmi',
    };
  }

  /// Generate overall assessment based on all metrics
  static Map<String, dynamic> _generateOverallAssessment(
    Map<String, dynamic> assessment,
  ) {
    List<String> recommendations = [];
    List<String> alerts = [];
    String overallStatus = 'good';
    String overallDescription =
        'Your child\'s growth appears to be developing normally.';

    var heightAnalysis = assessment['height_analysis'];
    var weightAnalysis = assessment['weight_analysis'];
    var bmiAnalysis = assessment['bmi_analysis'];

    // Check for concerning patterns
    bool hasConcerns = false;
    bool hasMinorIssues = false;

    // Height concerns
    if (heightAnalysis != null) {
      if (heightAnalysis['is_concerning']) {
        hasConcerns = true;
        alerts.add('Height is ${heightAnalysis['status'].toLowerCase()}');
        if (heightAnalysis['percentile'] < 5) {
          recommendations.add(
            'Consult pediatrician about potential growth hormone deficiency or nutritional issues',
          );
        } else {
          recommendations.add(
            'Monitor growth patterns and discuss with pediatrician if rapid growth continues',
          );
        }
      } else if (heightAnalysis['needs_attention']) {
        hasMinorIssues = true;
        recommendations.add(
          'Monitor height growth trends during regular checkups',
        );
      }
    }

    // Weight concerns
    if (weightAnalysis != null) {
      if (weightAnalysis['is_concerning']) {
        hasConcerns = true;
        alerts.add('Weight is ${weightAnalysis['status'].toLowerCase()}');
        if (weightAnalysis['percentile'] < 5) {
          recommendations.add(
            'Discuss nutrition and feeding strategies with pediatrician',
          );
        } else {
          recommendations.add(
            'Consider dietary modifications and increased physical activity',
          );
        }
      } else if (weightAnalysis['needs_attention']) {
        hasMinorIssues = true;
        recommendations.add(
          'Monitor weight trends and maintain healthy eating habits',
        );
      }
    }

    // BMI concerns
    if (bmiAnalysis != null) {
      if (bmiAnalysis['is_concerning']) {
        hasConcerns = true;
        String bmiCategory = bmiAnalysis['category'];
        alerts.add('BMI indicates $bmiCategory category');

        if (bmiCategory == 'Underweight') {
          recommendations.add(
            'Work with pediatrician to develop healthy weight gain plan',
          );
        } else if (bmiCategory == 'Overweight' || bmiCategory == 'Obese') {
          recommendations.add(
            'Implement healthy lifestyle changes including balanced diet and regular physical activity',
          );
          recommendations.add(
            'Consider consultation with pediatric nutritionist',
          );
        }
      }
    }

    // Determine overall status
    if (hasConcerns) {
      overallStatus = 'needs_attention';
      overallDescription =
          'Some measurements indicate areas that need attention. Please consult your pediatrician.';
    } else if (hasMinorIssues) {
      overallStatus = 'monitor';
      overallDescription =
          'Growth is generally good but should be monitored during regular checkups.';
    } else {
      overallStatus = 'excellent';
      overallDescription =
          'Your child\'s growth measurements are all within healthy ranges.';
    }

    // Add general recommendations
    recommendations.add('Maintain regular pediatric checkups');
    recommendations.add(
      'Ensure balanced nutrition with adequate fruits, vegetables, and protein',
    );
    recommendations.add('Encourage age-appropriate physical activity');
    recommendations.add('Ensure adequate sleep for optimal growth');

    assessment['overall_status'] = overallStatus;
    assessment['overall_description'] = overallDescription;
    assessment['recommendations'] = recommendations;
    assessment['alerts'] = alerts;

    return assessment;
  }

  /// Get age group classification
  static String _getAgeGroup(int ageInMonths) {
    if (ageInMonths < 12) return 'infant';
    if (ageInMonths < 24) return 'toddler';
    if (ageInMonths < 60) return 'preschooler';
    if (ageInMonths < 120) return 'school_age';
    if (ageInMonths < 216) return 'adolescent';
    return 'young_adult';
  }

  /// Simple current assessment - evaluates child's height and weight for their current age
  /// No historical data or growth velocity needed - just current measurements
  static Map<String, dynamic> simpleCurrentAssessment({
    required double? height, // in cm
    required double? weight, // in kg
    required int ageInMonths,
    required bool isMale,
  }) {
    debugPrint(
      '🔍 Simple assessment: height=$height cm, weight=$weight kg, age=${ageInMonths}months, isMale=$isMale',
    );

    Map<String, dynamic> result = {
      'is_good': false,
      'overall_status': 'insufficient_data',
      'message': 'Need both height and weight for assessment',
      'height_info': null,
      'weight_info': null,
      'recommendations': <String>[],
      'age_group': _getAgeGroup(ageInMonths),
    };

    bool hasHeight = height != null && height > 0;
    bool hasWeight = weight != null && weight > 0;

    // Height assessment
    if (hasHeight) {
      int heightPercentile = calculatePercentile(
        height,
        'HEIGHT',
        ageInMonths,
        isMale: isMale,
      );
      result['height_info'] = {
        'percentile': heightPercentile,
        'category': getHealthCategory(heightPercentile),
        'status': getDetailedHealthStatus(heightPercentile),
        'is_normal': heightPercentile >= 10 && heightPercentile <= 90,
        'is_good': heightPercentile >= 25 && heightPercentile <= 75,
      };
    }

    // Weight assessment
    if (hasWeight) {
      int weightPercentile = calculatePercentile(
        weight,
        'WEIGHT',
        ageInMonths,
        isMale: isMale,
      );
      result['weight_info'] = {
        'percentile': weightPercentile,
        'category': getHealthCategory(weightPercentile),
        'status': getDetailedHealthStatus(weightPercentile),
        'is_normal': weightPercentile >= 10 && weightPercentile <= 90,
        'is_good': weightPercentile >= 25 && weightPercentile <= 75,
      };
    }

    // Overall assessment
    if (hasHeight && hasWeight) {
      var heightInfo = result['height_info'];
      var weightInfo = result['weight_info'];

      bool heightGood = heightInfo['is_good'];
      bool weightGood = weightInfo['is_good'];
      bool heightNormal = heightInfo['is_normal'];
      bool weightNormal = weightInfo['is_normal'];

      if (heightGood && weightGood) {
        result['is_good'] = true;
        result['overall_status'] = 'excellent';
        result['message'] =
            '✅ Excellent! Both height and weight are in healthy ranges for age.';
      } else if (heightNormal && weightNormal) {
        result['is_good'] = true;
        result['overall_status'] = 'good';
        result['message'] = '✅ Good! Height and weight are normal for age.';
      } else if (heightInfo['percentile'] < 10 ||
          weightInfo['percentile'] < 10 ||
          heightInfo['percentile'] > 90 ||
          weightInfo['percentile'] > 90) {
        result['is_good'] = false;
        result['overall_status'] = 'needs_attention';
        result['message'] =
            '⚠️ Some measurements are outside normal ranges. Consider pediatrician consultation.';
      } else {
        result['is_good'] = true;
        result['overall_status'] = 'monitor';
        result['message'] =
            '⚠️ Generally good but monitor trends during checkups.';
      }
    } else if (hasHeight || hasWeight) {
      // Only one measurement available
      var availableInfo = hasHeight
          ? result['height_info']
          : result['weight_info'];
      String measurementType = hasHeight ? 'height' : 'weight';

      if (availableInfo['is_good']) {
        result['is_good'] = true;
        result['overall_status'] = 'partial_good';
        result['message'] =
            '✅ ${measurementType.toUpperCase()} is in healthy range. Provide ${hasHeight ? 'weight' : 'height'} for complete assessment.';
      } else if (availableInfo['is_normal']) {
        result['is_good'] = true;
        result['overall_status'] = 'partial_normal';
        result['message'] =
            '✅ ${measurementType.toUpperCase()} is normal. Provide ${hasHeight ? 'weight' : 'height'} for complete assessment.';
      } else {
        result['is_good'] = false;
        result['overall_status'] = 'partial_concern';
        result['message'] =
            '⚠️ ${measurementType.toUpperCase()} may need attention. Consider pediatrician consultation.';
      }
    }

    // Add simple recommendations
    if (result['overall_status'] == 'needs_attention' ||
        result['overall_status'] == 'partial_concern') {
      result['recommendations'].add(
        'Consult with pediatrician about growth patterns',
      );
      result['recommendations'].add(
        'Ensure balanced nutrition appropriate for age',
      );
    } else {
      result['recommendations'].add(
        'Continue healthy nutrition and active lifestyle',
      );
    }

    result['recommendations'].add('Regular pediatric checkups recommended');

    return result;
  }

  /// Quick assessment method - simplified version for quick checks
  static String quickGrowthAssessment({
    required double? height,
    required double? weight,
    required int ageInMonths,
    required bool isMale,
  }) {
    var assessment = simpleCurrentAssessment(
      height: height,
      weight: weight,
      ageInMonths: ageInMonths,
      isMale: isMale,
    );

    return assessment['message'];
  }

  /// Tell if child is good or not - simple yes/no answer
  static bool isChildGrowthGood({
    required double? height,
    required double? weight,
    required int ageInMonths,
    required bool isMale,
  }) {
    var assessment = simpleCurrentAssessment(
      height: height,
      weight: weight,
      ageInMonths: ageInMonths,
      isMale: isMale,
    );

    return assessment['is_good'] == true;
  }

  /// Get simple readable assessment
  static String getSimpleAssessment({
    required double? height,
    required double? weight,
    required int ageInMonths,
    required bool isMale,
  }) {
    var assessment = simpleCurrentAssessment(
      height: height,
      weight: weight,
      ageInMonths: ageInMonths,
      isMale: isMale,
    );

    String result = assessment['message'];

    // Add percentile information if available
    if (assessment['height_info'] != null) {
      result +=
          '\n📏 Height: ${assessment['height_info']['percentile']}th percentile (${assessment['height_info']['category']})';
    }

    if (assessment['weight_info'] != null) {
      result +=
          '\n⚖️ Weight: ${assessment['weight_info']['percentile']}th percentile (${assessment['weight_info']['category']})';
    }

    return result;
  }

  /// Complete growth evaluation - combines current measurements with historical data
  static Map<String, dynamic> completeGrowthEvaluation({
    required double? currentHeight,
    required double? currentWeight,
    required int currentAgeInMonths,
    required bool isMale,
    double? previousHeight,
    double? previousWeight,
    DateTime? previousDate,
  }) {
    debugPrint('🔍 Performing complete growth evaluation');

    // Current assessment
    var currentAssessment = assessChildGrowth(
      height: currentHeight,
      weight: currentWeight,
      ageInMonths: currentAgeInMonths,
      isMale: isMale,
    );

    Map<String, dynamic> completeEvaluation = {
      'current_assessment': currentAssessment,
      'has_historical_data': false,
      'velocity_assessment': null,
      'final_recommendation': '',
      'priority_level': 'routine', // routine, monitor, urgent
    };

    // Add velocity assessment if historical data is available
    if (previousHeight != null &&
        previousWeight != null &&
        previousDate != null &&
        currentHeight != null &&
        currentWeight != null) {
      completeEvaluation['has_historical_data'] = true;
      completeEvaluation['velocity_assessment'] = assessGrowthVelocity(
        previousHeight: previousHeight,
        currentHeight: currentHeight,
        previousWeight: previousWeight,
        currentWeight: currentWeight,
        previousDate: previousDate,
        currentDate: DateTime.now(),
        currentAgeInMonths: currentAgeInMonths,
        isMale: isMale,
      );
    }

    // Generate final recommendations
    completeEvaluation = _generateFinalRecommendation(completeEvaluation);

    return completeEvaluation;
  }

  /// Generate final recommendation based on all assessments
  static Map<String, dynamic> _generateFinalRecommendation(
    Map<String, dynamic> evaluation,
  ) {
    var currentAssessment = evaluation['current_assessment'];
    var velocityAssessment = evaluation['velocity_assessment'];

    String priorityLevel = 'routine';
    String finalRecommendation = '';

    // Determine priority based on current assessment
    String currentStatus = currentAssessment['overall_status'];
    if (currentStatus == 'needs_attention') {
      priorityLevel = 'urgent';
    } else if (currentStatus == 'monitor') {
      priorityLevel = 'monitor';
    }

    // Adjust priority based on velocity if available
    if (velocityAssessment != null) {
      String velocityStatus = velocityAssessment['overall_velocity_assessment'];
      if (velocityStatus == 'concerning_slow_growth' ||
          velocityStatus == 'concerning_rapid_growth') {
        priorityLevel = 'urgent';
      }
    }

    // Generate final recommendation
    switch (priorityLevel) {
      case 'urgent':
        finalRecommendation =
            '🚨 URGENT: Schedule pediatrician appointment within 1-2 weeks. ' +
            'Growth measurements or patterns indicate need for professional evaluation.';
        break;
      case 'monitor':
        finalRecommendation =
            '⚠️ MONITOR: Schedule routine pediatrician visit within 1-3 months. ' +
            'Continue monitoring growth trends and maintain healthy lifestyle.';
        break;
      default:
        finalRecommendation =
            '✅ ROUTINE: Continue regular pediatrician checkups. ' +
            'Growth appears healthy - maintain current nutrition and activity levels.';
    }

    evaluation['priority_level'] = priorityLevel;
    evaluation['final_recommendation'] = finalRecommendation;

    return evaluation;
  }

  /// Format assessment results for display - returns human-readable summary
  static String formatAssessmentSummary(Map<String, dynamic> assessment) {
    StringBuffer summary = StringBuffer();

    // Overall status
    summary.writeln('📊 GROWTH ASSESSMENT SUMMARY');
    summary.writeln('═' * 40);
    summary.writeln(
      'Overall Status: ${assessment['overall_status'].toString().toUpperCase()}',
    );
    summary.writeln(
      'Age Group: ${assessment['age_group'].toString().replaceAll('_', ' ').toUpperCase()}',
    );
    summary.writeln('');
    summary.writeln(assessment['overall_description']);
    summary.writeln('');

    // Individual metrics
    if (assessment['height_analysis'] != null) {
      var heightAnalysis = assessment['height_analysis'];
      summary.writeln(
        '📏 HEIGHT: ${heightAnalysis['percentile']}th percentile (${heightAnalysis['category']})',
      );
      summary.writeln('   Status: ${heightAnalysis['status']}');
    }

    if (assessment['weight_analysis'] != null) {
      var weightAnalysis = assessment['weight_analysis'];
      summary.writeln(
        '⚖️ WEIGHT: ${weightAnalysis['percentile']}th percentile (${weightAnalysis['category']})',
      );
      summary.writeln('   Status: ${weightAnalysis['status']}');
    }

    if (assessment['bmi_analysis'] != null) {
      var bmiAnalysis = assessment['bmi_analysis'];
      summary.writeln(
        '📋 BMI: ${bmiAnalysis['percentile']}th percentile (${bmiAnalysis['category']})',
      );
      summary.writeln('   Status: ${bmiAnalysis['status']}');
    }

    // Alerts
    if (assessment['alerts'] != null &&
        (assessment['alerts'] as List).isNotEmpty) {
      summary.writeln('');
      summary.writeln('🚨 ALERTS:');
      for (String alert in assessment['alerts']) {
        summary.writeln('• $alert');
      }
    }

    // Recommendations
    if (assessment['recommendations'] != null &&
        (assessment['recommendations'] as List).isNotEmpty) {
      summary.writeln('');
      summary.writeln('💡 RECOMMENDATIONS:');
      for (String recommendation in assessment['recommendations']) {
        summary.writeln('• $recommendation');
      }
    }

    return summary.toString();
  }

  /// Helper method to get status color based on percentile (legacy method)
  static Color getStatusColor(int percentile) {
    String category = getHealthCategory(percentile);
    return getHealthCategoryColor(category);
  }

  /// Helper method to get status text based on percentile (legacy method)
  static String getStatusText(int percentile) {
    return getDetailedHealthStatus(percentile);
  }

  /// Exact enum values from Java backend GrowthRecord entity
  static const List<String> _possibleTypes = [
    'PHYSICAL', // GrowthRecord.GrowthType.PHYSICAL
    'EMOTIONAL', // GrowthRecord.GrowthType.EMOTIONAL
    'COGNITION', // GrowthRecord.GrowthType.COGNITION
  ];

  static const List<String> _possibleStatuses = [
    'ACHIEVED', // GrowthRecord.StatusType.ACHIEVED
    'NOT_ACHIEVED', // GrowthRecord.StatusType.NOT_ACHIEVED
  ];

  /// Try alternative enum value combinations when the first attempt fails
  Future<Map<String, dynamic>> _tryAlternativeEnumValues({
    required int childId,
    required String dateOfRecord,
    double? height,
    double? weight,
    String? additionalInfo,
    required int currentTypeIndex,
    required int currentStatusIndex,
  }) async {
    // Try next status first, then next type
    int nextStatusIndex = currentStatusIndex + 1;
    int nextTypeIndex = currentTypeIndex;

    if (nextStatusIndex >= _possibleStatuses.length) {
      nextStatusIndex = 0;
      nextTypeIndex++;
    }

    // If we've exhausted all combinations, return failure
    if (nextTypeIndex >= _possibleTypes.length) {
      debugPrint('🔍 Growth Service - Exhausted all enum combinations');
      return {
        'success': false,
        'message': 'Could not find compatible enum values for backend',
      };
    }

    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Authentication required'};
      }

      final url = Uri.parse('$baseUrl/children/$childId');
      String recordType = _possibleTypes[nextTypeIndex];
      String recordStatus = _possibleStatuses[nextStatusIndex];

      debugPrint(
        '🔍 Growth Service - Attempting alternative: type[$nextTypeIndex]=$recordType, status[$nextStatusIndex]=$recordStatus',
      );

      final Map<String, String> formData = {
        'dateOfRecord': dateOfRecord,
        'type': recordType,
        'status': recordStatus,
      };

      if (height != null) formData['height'] = height.toString();
      if (weight != null) formData['weight'] = weight.toString();
      if (additionalInfo != null && additionalInfo.isNotEmpty) {
        formData['additionalInfo'] = additionalInfo;
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $token',
        },
        body: formData,
      );

      debugPrint(
        '🔍 Alternative attempt - Response status: ${response.statusCode}',
      );

      if (response.statusCode == 201) {
        try {
          final recordData = json.decode(response.body);
          debugPrint(
            '🔍 Growth Service - SUCCESS with alternative enum values!',
          );

          // Extract only essential data to avoid circular references
          final cleanData = {
            'id': recordData['id'],
            'dateOfRecord': recordData['dateOfRecord'],
            'height': recordData['height'],
            'weight': recordData['weight'],
            'type': recordData['type'],
            'status': recordData['status'],
            'additionalInfo': recordData['additionalInfo'],
          };

          return {
            'success': true,
            'message': 'Growth record added successfully',
            'data': cleanData,
          };
        } catch (e) {
          debugPrint(
            '🔍 Growth Service - JSON parsing error in alternative method: $e',
          );
          return {
            'success': true,
            'message': 'Growth record added successfully',
            'data': {'status': 'created'},
          };
        }
      } else if (response.statusCode == 500 && response.body.contains('enum')) {
        // Try next combination
        return await _tryAlternativeEnumValues(
          childId: childId,
          dateOfRecord: dateOfRecord,
          height: height,
          weight: weight,
          additionalInfo: additionalInfo,
          currentTypeIndex: nextTypeIndex,
          currentStatusIndex: nextStatusIndex,
        );
      } else {
        return {
          'success': false,
          'message': 'Failed to add growth record: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error with alternative enum values: $e',
      };
    }
  }

  /// Extract record data from a JSON area using individual field patterns
  Map<String, dynamic>? _extractRecordFromArea(
    String recordArea,
    RegExpMatch startMatch,
  ) {
    try {
      // Get basic info from the start match
      int id = int.parse(startMatch.group(1)!);
      String? additionalInfo = startMatch.group(2) == 'null'
          ? null
          : startMatch.group(2)?.replaceAll('"', '');
      String dateOfRecord = startMatch.group(3)!;

      // Extract height, weight, type, and status from the record area
      RegExp heightPattern = RegExp(r'"height":([^,}]+)');
      RegExp weightPattern = RegExp(r'"weight":([^,}]+)');
      RegExp typePattern = RegExp(r'"type":"([^"]+)"');
      RegExp statusPattern = RegExp(r'"status":"([^"]+)"');

      RegExpMatch? heightMatch = heightPattern.firstMatch(recordArea);
      RegExpMatch? weightMatch = weightPattern.firstMatch(recordArea);
      RegExpMatch? typeMatch = typePattern.firstMatch(recordArea);
      RegExpMatch? statusMatch = statusPattern.firstMatch(recordArea);

      // Only create record if we have essential fields
      if (typeMatch != null && statusMatch != null) {
        return {
          'id': id,
          'additionalInfo': additionalInfo,
          'dateOfRecord': dateOfRecord,
          'height': heightMatch?.group(1) == 'null'
              ? null
              : double.tryParse(heightMatch?.group(1) ?? ''),
          'weight': weightMatch?.group(1) == 'null'
              ? null
              : double.tryParse(weightMatch?.group(1) ?? ''),
          'type': typeMatch.group(1)!,
          'status': statusMatch.group(1)!,
        };
      }

      return null;
    } catch (e) {
      debugPrint('🔍 Growth Service - Error in _extractRecordFromArea: $e');
      return null;
    }
  }

  /// Determine the appropriate record type based on measurements provided
  String _determineRecordType(double? height, double? weight) {
    // Since we're tracking physical measurements (height/weight), use PHYSICAL type
    // This maps to GrowthRecord.GrowthType.PHYSICAL in the backend
    return _possibleTypes[0]; // 'PHYSICAL'
  }
}
