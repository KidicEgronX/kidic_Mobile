import 'package:flutter/material.dart';
import 'package:kidicapp_flutter/pages/main/home_page.dart';
import 'package:kidicapp_flutter/pages/profile/profile.dart';
import 'package:kidicapp_flutter/pages/main/notifications_page.dart';
import 'package:kidicapp_flutter/pages/features/chatbot_page.dart';

class MainNavigationPage extends StatefulWidget {
  final int initialIndex;
  final bool showWelcome;

  const MainNavigationPage({
    super.key,
    this.initialIndex = 0,
    this.showWelcome = false,
  });

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  late int _currentIndex;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // Initialize pages with user data
    _pages = [
      const HomePage(),
      const _EmbeddedChatbotPage(), // Embedded version without Scaffold
      const NotificationsPage(),
      ProfilePage(showWelcome: widget.showWelcome),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology),
              label: 'AI Assistant',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class ActivitiesPage extends StatelessWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Activities',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return _buildActivityCard(
                      title: 'Daily Check-up',
                      subtitle: 'Completed on ${_getDateString(index)}',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDateString(int index) {
    final now = DateTime.now();
    final date = now.subtract(Duration(days: index));
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildActivityCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey.shade400,
          size: 16,
        ),
      ),
    );
  }
}

// Embedded chatbot page without Scaffold - to be used within main navigation
class _EmbeddedChatbotPage extends StatefulWidget {
  const _EmbeddedChatbotPage();

  @override
  State<_EmbeddedChatbotPage> createState() => _EmbeddedChatbotPageState();
}

class _EmbeddedChatbotPageState extends State<_EmbeddedChatbotPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: SafeArea(
        child: Column(
          children: [
            // Use the actual ChatbotPage content
            const Expanded(child: ChatbotPage()),
          ],
        ),
      ),
    );
  }
}
