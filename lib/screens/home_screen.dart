import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sahayak/screens/chatZone_screen.dart';
import 'package:sahayak/screens/community/community_screen.dart';
import 'package:sahayak/screens/home_options/contacts/contacts_screen.dart';
import 'package:sahayak/screens/home_options/emergency/emergency.dart';
import 'package:sahayak/screens/home_options/fun%20zone/splash_screen.dart';
import 'package:sahayak/screens/home_options/memory/memory_screen.dart';
import 'package:sahayak/screens/home_options/order/order_screen.dart';
import 'package:sahayak/screens/home_options/pension/pension_screen.dart';
import 'package:sahayak/screens/home_options/story.dart';
import 'package:sahayak/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? userName;

  final List<Map<String, dynamic>> options = [
    {'title': 'Chatzone', 'icon': Icons.chat_bubble},
    {'title': 'Emergency', 'icon': Icons.emergency},
    {'title': 'Contacts', 'icon': Icons.contacts},
    {'title': 'Order Things', 'icon': Icons.shopping_cart},
    {'title': 'Memory', 'icon': Icons.note},
    {'title': 'Storyzone', 'icon': Icons.menu_book},
    {'title': 'Pension', 'icon': Icons.money},
    {'title': 'Funzone', 'icon': Icons.emoji_emotions},
  ];

  final List<Widget> _tabs = [
    const Placeholder(), // Home tab
    CommunityScreen(), // Community tab
    ChatZoneScreen(), // ChatZone screen
    const ProfileScreen(), // Profile screen
  ];

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        setState(() {
          userName = doc.data()?['full_name'] ?? 'User';
        });
      } catch (e) {
        setState(() {
          userName = 'User';
        });
        print('Error fetching name from Firestore: $e');
      }
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _selectedIndex == 0
              ? buildHomeTab(context)
              : Center(child: _tabs[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chatzone'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget buildHomeTab(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Greeting
            Text(
              'Namaste, ${userName ?? "User"} 🙏',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Home Banner
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/home_banner.jpeg',
                height: MediaQuery.of(context).size.width * 2 / 3,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),

            // Options Grid
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: options.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.2, // Adjust aspect ratio for better spacing
              ),
              itemBuilder: (context, index) {
                String title = options[index]['title'];
                IconData icon = options[index]['icon'];
                return OptionItem(
                  title: title,
                  icon: icon,
                  onTap: () {
                    if (title == 'Memory') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MemoryNotesScreen(),
                        ),
                      );
                    } else if (title == 'Funzone') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SplashScreen()),
                      );
                    } else if (title == 'Order Things') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderThingsScreen()),
                      );
                    } else if (title == 'Pension') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PensionScreen()),
                      );
                    } else if (title == 'Storyzone') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => StoryZoneScreen()),
                      );
                    } else if (title == 'Contacts') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ContactScreen()),
                      );
                    } else if (title == 'Emergency') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EmergencyScreen()),
                      );
                    } else if (title == 'Chatzone') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChatZoneScreen()),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class OptionItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const OptionItem({
    required this.title,
    required this.icon,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            // Adding shadow for better UI
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.deepPurple),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
