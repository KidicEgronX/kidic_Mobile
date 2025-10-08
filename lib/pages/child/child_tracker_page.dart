import 'package:flutter/material.dart';
import 'package:kidicapp_flutter/pages/child/vaccines_connected.dart';
import 'package:kidicapp_flutter/pages/child/milestones.dart';
import 'package:kidicapp_flutter/pages/child/growth_page.dart';

class ChildTrackerPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const ChildTrackerPage({super.key, this.arguments});

  @override
  State<ChildTrackerPage> createState() => _ChildTrackerPageState();
}

class _ChildTrackerPageState extends State<ChildTrackerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Get initial tab from arguments, default to 0 (growth)
    final int initialTab = widget.arguments?['initialTab'] ?? 0;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Child Tracker',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header with description
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: const Text(
              'Monitor your child\'s development, growth, and health milestones',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),

          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.blue,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Growth'),
                Tab(text: 'Vaccines'),
                Tab(text: 'Milestones'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                GrowthTab(selectedChildId: widget.arguments?['childId']),
                VaccinesTab(childId: widget.arguments?['childId']),
                MilestonesTab(childId: widget.arguments?['childId']),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
