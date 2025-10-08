import 'package:flutter/material.dart';
import 'package:kidicapp_flutter/routes.dart';
import 'package:kidicapp_flutter/services/auth/auth_service.dart';
import 'package:kidicapp_flutter/services/child/growth_service.dart';
import 'package:kidicapp_flutter/services/child/child_service.dart';
import 'package:kidicapp_flutter/pages/child/child_profile_page.dart';
import 'package:kidicapp_flutter/pages/features/doctor_page.dart';
import 'package:kidicapp_flutter/pages/dialogs/child_add_dialog.dart';
import 'package:kidicapp_flutter/main.dart' show routeObserver;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver, RouteAware {
  final AuthService _authService = AuthService();
  final GrowthService _growthService = GrowthService();
  final ChildService _childService = ChildService();
  String _userName = 'User'; // Default fallback name
  bool _isLoadingUserData = true;
  List<Map<String, dynamic>> _children = []; // Family children data
  bool _isLoadingChildren = true;
  List<Map<String, dynamic>> _latestGrowthRecords =
      []; // Latest growth records for each child
  bool _isLoadingGrowthRecords = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _loadFamilyData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, refresh data
      debugPrint('🔍 === HOME PAGE: APP RESUMED - REFRESHING DATA ===');
      _refreshAllData();
    }
  }

  // RouteAware methods
  @override
  void didPopNext() {
    // Called when a route has been popped off, and the current route shows up again (user came back)
    debugPrint('🔍 === HOME PAGE: USER CAME BACK - REFRESHING DATA ===');
    _refreshAllData();
  }

  @override
  void didPushNext() {
    // Called when the current route has been pushed to and is now the current route
    debugPrint('🔍 === HOME PAGE: NAVIGATED TO ANOTHER PAGE ===');
  }

  /// Refresh all data when app becomes active or user navigates back
  Future<void> _refreshAllData() async {
    debugPrint('🔍 === HOME PAGE: REFRESHING ALL DATA ===');
    // First load user data and family data (which includes children list)
    await _loadUserData();
    await _loadFamilyData(); // This already calls _loadLatestGrowthRecords()

    // But to ensure we have the absolute latest growth data,
    // force refresh growth records one more time
    if (_children.isNotEmpty && mounted) {
      debugPrint('🔍 === HOME PAGE: DOUBLE-CHECK LATEST GROWTH RECORDS ===');
      await _loadLatestGrowthRecords();
    }
  }

  /// Load user data from JWT token and backend API
  Future<void> _loadUserData() async {
    try {
      debugPrint('🔍 === HOME PAGE: LOADING USER DATA ===');

      // Check if user is logged in first
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        debugPrint('🔍 Home Page - User not logged in');
        if (mounted) {
          setState(() {
            _userName = 'Guest';
            _isLoadingUserData = false;
          });
        }
        return;
      }

      // Get complete user profile using JWT token
      // This calls GET /api/parent endpoint with Authorization: Bearer <token>
      // Same method used in ProfilePage for consistency
      final userProfile = await _authService.getCompleteUserProfile();

      if (userProfile != null && mounted) {
        final userName = userProfile['name'] as String?;
        debugPrint('🔍 Home Page - Got user name from API: $userName');

        setState(() {
          // Extract first name only for welcome message and capitalize properly
          final firstName = userName?.split(' ').first ?? 'User';
          _userName = _capitalizeFirstLetter(firstName);
          _isLoadingUserData = false;
        });
      } else {
        debugPrint('🔍 Home Page - API failed, trying JWT token fallback');

        // Fallback: try to get basic info from JWT token
        final tokenInfo = await _authService.getCurrentUserInfo();
        if (tokenInfo != null && mounted) {
          // Try to extract name from token or use email
          final tokenName = tokenInfo['name'] as String?;
          final tokenEmail = tokenInfo['email'] as String?;

          String firstName = 'User';
          if (tokenName != null && tokenName.isNotEmpty) {
            firstName = tokenName.split(' ').first;
          } else if (tokenEmail != null && tokenEmail.isNotEmpty) {
            firstName = tokenEmail.split('@').first;
          }

          setState(() {
            _userName = _capitalizeFirstLetter(firstName);
            _isLoadingUserData = false;
          });

          debugPrint(
            '🔍 Home Page - Using JWT token fallback name: $firstName',
          );
        } else if (mounted) {
          setState(() {
            _userName = 'User';
            _isLoadingUserData = false;
          });
        }
      }
    } catch (e) {
      debugPrint('🔍 Home Page - Error loading user data: $e');
      if (mounted) {
        setState(() {
          _userName = 'User';
          _isLoadingUserData = false;
        });
      }
    }
    debugPrint('🔍 === END HOME PAGE USER DATA LOAD ===');
  }

  /// Load family data (children and parents) from backend API using JWT token
  Future<void> _loadFamilyData() async {
    try {
      debugPrint('🔍 === HOME PAGE: LOADING FAMILY DATA ===');

      setState(() {
        _isLoadingChildren = true;
      });

      // Check if user is logged in first
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        debugPrint('🔍 Home Page - User not logged in for family data');
        if (mounted) {
          setState(() {
            _children = [];
            _isLoadingChildren = false;
          });
        }
        return;
      }

      // Get complete family data using JWT token
      // This calls GET /api/family endpoint with Authorization: Bearer <token>
      final familyData = await _authService.getFamilyData();

      if (familyData != null && mounted) {
        final childrenList = familyData['children'] as List<dynamic>? ?? [];
        debugPrint(
          '🔍 Home Page - Got ${childrenList.length} children from API',
        );

        // Convert children data to our format
        final processedChildren = childrenList.map((child) {
          final childMap = child as Map<String, dynamic>;
          final dateOfBirth = childMap['dateOfBirth'] as String?;

          return {
            'id': childMap['id'],
            'name': childMap['name'] ?? 'Unknown Child',
            'gender': childMap['gender'], // true = male, false = female
            'dateOfBirth': dateOfBirth,
            'age': _calculateAge(dateOfBirth),
            'medicalNotes': childMap['medicalNotes'],
          };
        }).toList();

        setState(() {
          _children = List<Map<String, dynamic>>.from(processedChildren);
          _isLoadingChildren = false;
        });

        debugPrint('🔍 Home Page - Processed ${_children.length} children');
        for (var child in _children) {
          debugPrint('🔍 Child: ${child['name']} - Age: ${child['age']}');
        }

        // Load growth records for each child after loading children
        _loadLatestGrowthRecords();
      } else {
        debugPrint('🔍 Home Page - No family data found');
        if (mounted) {
          setState(() {
            _children = [];
            _isLoadingChildren = false;
            _latestGrowthRecords = [];
            _isLoadingGrowthRecords = false;
          });
        }
      }
    } catch (e) {
      debugPrint('🔍 Home Page - Error loading family data: $e');
      if (mounted) {
        setState(() {
          _children = [];
          _isLoadingChildren = false;
          _latestGrowthRecords = [];
          _isLoadingGrowthRecords = false;
        });
      }
    }
    debugPrint('🔍 === END HOME PAGE FAMILY DATA LOAD ===');
  }

  /// Load latest growth records for all children
  Future<void> _loadLatestGrowthRecords() async {
    if (_children.isEmpty) {
      setState(() {
        _latestGrowthRecords = [];
        _isLoadingGrowthRecords = false;
      });
      return;
    }

    try {
      debugPrint('🔍 === HOME PAGE: LOADING LATEST GROWTH RECORDS ===');
      setState(() {
        _isLoadingGrowthRecords = true;
      });

      List<Map<String, dynamic>> growthRecords = [];

      // Load growth records for all children, but only add those that have records
      // Force refresh to get the absolute latest data from the server
      for (var child in _children) {
        final childId = child['id'] as int;
        debugPrint(
          '🔍 Home Page - Loading LATEST growth record for child: ${child['name']} (ID: $childId)',
        );

        // This fetches the most recent growth record from the server
        final latestRecord = await _growthService.getLatestGrowthRecord(
          childId,
        );
        if (latestRecord != null) {
          // Only add children who have growth records
          final combinedRecord = {
            'childId': childId,
            'childName': child['name'],
            'childAge': child['age'],
            'height': latestRecord['height'],
            'weight': latestRecord['weight'],
            'dateOfRecord': latestRecord['dateOfRecord'],
            'additionalInfo': latestRecord['additionalInfo'],
            'type': latestRecord['type'],
            'status': latestRecord['status'],
          };
          growthRecords.add(combinedRecord);
          debugPrint(
            '✅ Home Page - Loaded LATEST growth record for ${child['name']}: ${latestRecord['dateOfRecord']} (H: ${latestRecord['height']}cm, W: ${latestRecord['weight']}kg)',
          );
        } else {
          debugPrint(
            '🔍 Home Page - No growth records found for ${child['name']} - skipping card',
          );
        }
      }

      setState(() {
        _latestGrowthRecords = growthRecords;
        _isLoadingGrowthRecords = false;
      });

      debugPrint(
        '✅ Home Page - Successfully loaded ${growthRecords.length} latest growth records',
      );
    } catch (e) {
      debugPrint('❌ Home Page - Error loading growth records: $e');
      setState(() {
        _latestGrowthRecords = [];
        _isLoadingGrowthRecords = false;
      });
    }
    debugPrint('🔍 === END HOME PAGE GROWTH RECORDS LOAD ===');
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
      debugPrint('Error calculating age: $e');
      return 'Age unknown';
    }
  }

  /// Get initials from child name for avatar display
  String _getChildInitials(String? name) {
    if (name == null || name.isEmpty) return 'C';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

  /// Helper method to capitalize the first letter of a name
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Get specific child data using the getChild endpoint
  /// This demonstrates how to call the ChildController.getChild() from your Java backend
  Future<void> _viewChildProfile(int childId) async {
    try {
      debugPrint('🔍 === HOME PAGE: GETTING SPECIFIC CHILD DATA ===');
      debugPrint('🔍 Child ID: $childId');

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Call the getChild endpoint through ChildService
      // This will make a GET request to /api/child/{id} with JWT token
      final childData = await _childService.getChild(childId);

      // Hide loading indicator
      Navigator.pop(context);

      if (childData != null) {
        debugPrint('✅ Child data retrieved successfully');
        debugPrint('🔍 Child Name: ${childData['name']}');
        debugPrint('🔍 Child Age: ${childData['age']}');
        debugPrint('🔍 Child Gender: ${childData['genderDisplay']}');

        // Navigate to child profile page with the retrieved data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChildProfilePage(childId: childId),
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load child profile'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error viewing child profile: $e');

      // Hide loading indicator if still showing
      try {
        Navigator.pop(context);
      } catch (_) {}

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Show options for child (View Profile or Go to Tracker)
  void _showChildOptions(BuildContext context, Map<String, dynamic> child) {
    final Size size = MediaQuery.of(context).size;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(size.width * 0.05),
        ),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(size.width * 0.06),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: size.width * 0.05,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Text(
                    _getChildInitials(child['name']),
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: size.width * 0.035,
                    ),
                  ),
                ),
                SizedBox(width: size.width * 0.03),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child['name'] ?? 'Unknown Child',
                      style: TextStyle(
                        fontSize: size.width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      child['age'] ?? 'Age unknown',
                      style: TextStyle(
                        fontSize: size.width * 0.035,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: size.height * 0.03),

            // Option 1: View Detailed Profile (uses getChild endpoint)
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(size.width * 0.02),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(size.width * 0.02),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.green,
                  size: size.width * 0.05,
                ),
              ),
              title: Text(
                'View Detailed Profile',
                style: TextStyle(
                  fontSize: size.width * 0.04,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Get complete child information from backend',
                style: TextStyle(
                  fontSize: size.width * 0.035,
                  color: Colors.grey.shade600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _viewChildProfile(child['id'] as int);
              },
            ),

            // Option 2: Go to Child Tracker (existing functionality)
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(size.width * 0.02),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(size.width * 0.02),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: Colors.blue,
                  size: size.width * 0.05,
                ),
              ),
              title: Text(
                'Go to Child Tracker',
                style: TextStyle(
                  fontSize: size.width * 0.04,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'View milestones, vaccines, and growth',
                style: TextStyle(
                  fontSize: size.width * 0.035,
                  color: Colors.grey.shade600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.childTracker,
                  arguments: {'childId': child['id']},
                );
              },
            ),

            SizedBox(height: size.height * 0.02),
          ],
        ),
      ),
    );
  }

  void _showAddChildDialog(BuildContext context, Size size) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChildAddDialog(
        onAddSuccess: (Map<String, dynamic> newChildData) {
          // Add the new child to the UI
          setState(() {
            _children.add(newChildData);
          });

          debugPrint('✅ New child added to family: ${newChildData['name']}');

          // Optionally reload family data to get the latest info from server
          _loadFamilyData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _refreshAllData,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(size.width * 0.06), // Responsive padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: size.height * 0.05), // Responsive spacing
                // Welcome Header
                Row(
                  children: [
                    Flexible(
                      child: _isLoadingUserData
                          ? Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Loading...',
                                  style: TextStyle(
                                    fontSize: size.width * 0.06,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Welcome back, $_userName! ',
                              style: TextStyle(
                                fontSize:
                                    size.width * 0.06, // Responsive font size
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                    ),
                    if (!_isLoadingUserData)
                      Text('👋', style: TextStyle(fontSize: size.width * 0.06)),
                  ],
                ),
                SizedBox(height: size.height * 0.01),
                Text(
                  'Here\'s what\'s happening with your little ones today.',
                  style: TextStyle(
                    fontSize: size.width * 0.04, // Responsive font size
                    color: Colors.grey,
                  ),
                ),

                SizedBox(height: size.height * 0.04),

                // Feature Cards Grid (2x3 layout)
                Row(
                  children: [
                    Expanded(
                      child: _buildFeatureCard(
                        context,
                        size,
                        icon: Icons.trending_up,
                        title: 'Tracker',
                        color: Colors.blue,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.childTracker,
                          arguments: {
                            'initialTab': 0,
                          }, // Navigate to growth tab (index 0)
                        ),
                      ),
                    ),
                    SizedBox(width: size.width * 0.04),
                    Expanded(
                      child: _buildFeatureCard(
                        context,
                        size,
                        icon: Icons.school,
                        title: 'Education',
                        color: Colors.orange,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.education),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: size.height * 0.02),

                Row(
                  children: [
                    Expanded(
                      child: _buildFeatureCard(
                        context,
                        size,
                        icon: Icons.local_hospital,
                        title: 'Doctor',
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DoctorPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: size.width * 0.04),
                    Expanded(
                      child: _buildFeatureCard(
                        context,
                        size,
                        icon: Icons.warning,
                        title: 'Emergency',
                        color: Colors.red,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.emergency),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: size.height * 0.02),

                Row(
                  children: [
                    Expanded(
                      child: _buildFeatureCard(
                        context,
                        size,
                        icon: Icons.restaurant_menu,
                        title: 'Meals',
                        color: Colors.amber,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.meals);
                        },
                      ),
                    ),
                    SizedBox(width: size.width * 0.04),
                    Expanded(
                      child: _buildFeatureCard(
                        context,
                        size,
                        icon: Icons.shopping_bag,
                        title: 'Smart Store',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.smartStore);
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: size.height * 0.04),

                // Your Children Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.child_care, color: Colors.grey),
                        SizedBox(width: size.width * 0.02),
                        Text(
                          'Your Children',
                          style: TextStyle(
                            fontSize: size.width * 0.05, // Responsive font size
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: size.height * 0.02),

                // Dynamic Children List
                if (_isLoadingChildren)
                  Container(
                    padding: EdgeInsets.all(size.width * 0.04),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue.shade400,
                            ),
                          ),
                        ),
                        SizedBox(width: size.width * 0.03),
                        Text(
                          'Loading children...',
                          style: TextStyle(
                            fontSize: size.width * 0.04,
                            color: Colors.grey,
                          ),
                        ),
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
                          'No children added yet',
                          style: TextStyle(
                            fontSize: size.width * 0.04,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: size.height * 0.005),
                        Text(
                          'Add your first child to start tracking their journey',
                          style: TextStyle(
                            fontSize: size.width * 0.035,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...(_children.asMap().entries.map((entry) {
                    final index = entry.key;
                    final child = entry.value;
                    final isLast = index == _children.length - 1;

                    return Column(
                      children: [
                        _buildChildCard(
                          size: size,
                          name: child['name'] ?? 'Unknown Child',
                          age: child['age'] ?? 'Age unknown',
                          initial: _getChildInitials(child['name']),
                          onTap: () => _showChildOptions(context, child),
                        ),
                        if (!isLast) SizedBox(height: size.height * 0.015),
                      ],
                    );
                  }).toList()),

                SizedBox(height: size.height * 0.02),

                // Add Child Button
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: size.width * 0.02),
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Add child functionality
                      _showAddChildDialog(context, size);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: Colors.blue.shade300,
                      padding: EdgeInsets.symmetric(
                        vertical: size.height * 0.025,
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
                          padding: EdgeInsets.all(size.width * 0.025),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.child_care,
                            color: Colors.white,
                            size: size.width * 0.07,
                          ),
                        ),
                        SizedBox(width: size.width * 0.04),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Add Child to Family',
                                style: TextStyle(
                                  fontSize: size.width * 0.05,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Start tracking your child\'s journey',
                                style: TextStyle(
                                  fontSize: size.width * 0.035,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(size.width * 0.02),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: size.width * 0.05,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.04),

                // Two Column Layout - Make responsive for mobile
                size.width > 600
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column - Recent Milestones
                          Expanded(child: _buildLeftColumn(size)),

                          SizedBox(width: size.width * 0.06),

                          // Right Column - Upcoming Reminders & Quick Access
                          Expanded(child: _buildRightColumn(size)),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLeftColumn(size),
                          SizedBox(height: size.height * 0.03),
                          _buildRightColumn(size),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    Size size, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(size.width * 0.06), // Responsive padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            size.width * 0.03,
          ), // Responsive border radius
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: size.width * 0.08, // Responsive icon size
              color: color,
            ),
            SizedBox(height: size.height * 0.015), // Responsive spacing
            Text(
              title,
              style: TextStyle(
                fontSize: size.width * 0.04, // Responsive font size
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildCard({
    required Size size,
    required String name,
    required String age,
    required String initial,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(size.width * 0.04), // Responsive padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            size.width * 0.03,
          ), // Responsive border radius
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
            CircleAvatar(
              radius: size.width * 0.06, // Responsive avatar size
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Text(
                initial,
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: size.width * 0.035, // Responsive font size
                ),
              ),
            ),
            SizedBox(width: size.width * 0.04), // Responsive spacing
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: size.width * 0.04, // Responsive font size
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    age,
                    style: TextStyle(
                      fontSize: size.width * 0.035, // Responsive font size
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.03,
                vertical: size.height * 0.008,
              ), // Responsive padding
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(size.width * 0.04),
              ),
              child: Text(
                'View Profile',
                style: TextStyle(
                  fontSize: size.width * 0.03, // Responsive font size
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessItem({
    required Size size,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(size.width * 0.03),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size.width * 0.02),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: size.width * 0.05, color: Colors.grey[600]),
            SizedBox(width: size.width * 0.03),
            Text(
              title,
              style: TextStyle(
                fontSize: size.width * 0.035,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftColumn(Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('📈 ', style: TextStyle(fontSize: size.width * 0.045)),
            Text(
              'Recent Growth Records',
              style: TextStyle(
                fontSize: size.width * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: size.height * 0.02),

        // Growth Records Display
        if (_isLoadingGrowthRecords)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(size.width * 0.04),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade400,
                    ),
                  ),
                ),
                SizedBox(width: size.width * 0.03),
                Text(
                  'Loading growth records...',
                  style: TextStyle(
                    fontSize: size.width * 0.04,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          )
        else if (_latestGrowthRecords.isEmpty)
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
                  'When records are added, we will show them here',
                  style: TextStyle(
                    fontSize: size.width * 0.035,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          // Show all children who have growth records
          Column(
            children: _latestGrowthRecords.map((record) {
              return Container(
                margin: EdgeInsets.only(bottom: size.height * 0.015),
                child: _buildGrowthRecordCard(size, record),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildGrowthRecordCard(Size size, Map<String, dynamic> record) {
    final String childName = record['childName'] ?? 'Unknown Child';
    final String childAge = record['childAge'] ?? 'Age unknown';
    final double? height = record['height'];
    final double? weight = record['weight'];
    final String dateOfRecord = record['dateOfRecord'] ?? '';
    final String? additionalInfo = record['additionalInfo'];

    // Format date for display
    String formattedDate = '';
    if (dateOfRecord.isNotEmpty) {
      try {
        final date = DateTime.parse(dateOfRecord);
        formattedDate = '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        formattedDate = dateOfRecord;
      }
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.childTracker,
        arguments: {'initialTab': 0, 'childId': record['childId']},
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(size.width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size.width * 0.03),
          border: Border.all(color: Colors.blue.shade200),
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
            // Header with child name and age
            Row(
              children: [
                CircleAvatar(
                  radius: size.width * 0.04,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Text(
                    childName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: size.width * 0.035,
                    ),
                  ),
                ),
                SizedBox(width: size.width * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        childName,
                        style: TextStyle(
                          fontSize: size.width * 0.04,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '$childAge • $formattedDate',
                        style: TextStyle(
                          fontSize: size.width * 0.03,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: size.width * 0.03,
                  color: Colors.grey.shade400,
                ),
              ],
            ),

            SizedBox(height: size.height * 0.015),

            // Measurements row
            Row(
              children: [
                if (height != null) ...[
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(size.width * 0.025),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(size.width * 0.02),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.height,
                                size: size.width * 0.035,
                                color: Colors.blue.shade600,
                              ),
                              SizedBox(width: size.width * 0.01),
                              Text(
                                'Height',
                                style: TextStyle(
                                  fontSize: size.width * 0.03,
                                  color: Colors.blue.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${height.toStringAsFixed(1)} cm',
                            style: TextStyle(
                              fontSize: size.width * 0.035,
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (weight != null) SizedBox(width: size.width * 0.02),
                ],
                if (weight != null) ...[
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(size.width * 0.025),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(size.width * 0.02),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.monitor_weight,
                                size: size.width * 0.035,
                                color: Colors.green.shade600,
                              ),
                              SizedBox(width: size.width * 0.01),
                              Text(
                                'Weight',
                                style: TextStyle(
                                  fontSize: size.width * 0.03,
                                  color: Colors.green.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${weight.toStringAsFixed(1)} kg',
                            style: TextStyle(
                              fontSize: size.width * 0.035,
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
            if (additionalInfo != null && additionalInfo.isNotEmpty) ...[
              SizedBox(height: size.height * 0.01),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(size.width * 0.025),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(size.width * 0.02),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.note,
                          size: size.width * 0.035,
                          color: Colors.orange.shade600,
                        ),
                        SizedBox(width: size.width * 0.01),
                        Text(
                          'Notes',
                          style: TextStyle(
                            fontSize: size.width * 0.03,
                            color: Colors.orange.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      additionalInfo,
                      style: TextStyle(
                        fontSize: size.width * 0.03,
                        color: Colors.orange.shade800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRightColumn(Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.notifications,
              color: Colors.grey,
              size: size.width * 0.05,
            ),
            SizedBox(width: size.width * 0.02),
            Text(
              'Upcoming Reminders',
              style: TextStyle(
                fontSize: size.width * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: size.height * 0.02),

        // TODO: Load upcoming reminders from backend API
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
                Icons.notifications_none,
                size: size.width * 0.08,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: size.height * 0.01),
              Text(
                'No upcoming reminders',
                style: TextStyle(
                  fontSize: size.width * 0.04,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: size.height * 0.005),
              Text(
                'Reminders will appear here when scheduled',
                style: TextStyle(
                  fontSize: size.width * 0.035,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        SizedBox(height: size.height * 0.03),

        // Quick Access Section
        Text(
          'Quick Access',
          style: TextStyle(
            fontSize: size.width * 0.045,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),

        SizedBox(height: size.height * 0.02),

        _buildQuickAccessItem(
          size: size,
          icon: Icons.warning,
          title: 'Emergency Protocols',
          onTap: () => Navigator.pushNamed(context, AppRoutes.emergency),
        ),

        SizedBox(height: size.height * 0.015),

        _buildQuickAccessItem(
          size: size,
          icon: Icons.local_hospital,
          title: 'Find Doctors',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DoctorPage()),
            );
          },
        ),

        SizedBox(height: size.height * 0.015),

        Builder(
          builder: (context) => _buildQuickAccessItem(
            size: size,
            icon: Icons.calendar_today,
            title: 'Vaccine Schedule',
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.childTracker,
              arguments: {
                'initialTab': 1,
              }, // Navigate to vaccines tab (index 1)
            ),
          ),
        ),

        SizedBox(height: size.height * 0.015),

        Builder(
          builder: (context) => _buildQuickAccessItem(
            size: size,
            icon: Icons.trending_up,
            title: 'Growth Records',
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.childTracker,
              arguments: {'initialTab': 0}, // Navigate to growth tab (index 0)
            ),
          ),
        ),
      ],
    );
  }
}
