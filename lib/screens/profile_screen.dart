import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sahayak/screens/about_screen.dart';
import 'package:sahayak/screens/auth%20screen/login_screen.dart';
import 'package:sahayak/screens/settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahayak/screens/user_info_screen';  

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic> userData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    if (user != null) {
      try {
        final docRef = FirebaseFirestore.instance.collection('users').doc(user!.uid);
        final doc = await docRef.get();

        if (doc.exists) {
          setState(() {
            userData = doc.data()!;
            isLoading = false;
          });
        } else {
          await docRef.set({
            'full_name': '',
            'email': user!.email ?? '',
            'phone': '',
          });
          setState(() {
            userData = {
              'full_name': '',
              'email': user!.email ?? '',
              'phone': '',
            };
            isLoading = false;
          });
        }
      } catch (e) {
        print("Error fetching user data: $e");
        setState(() => isLoading = false);
      }
    }
  }

  void signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = userData['full_name'] ?? '';
    final String email = user?.email ?? '';
    final String phone = userData['phone'] ?? '';
    final String initials = name.isNotEmpty ? name[0].toUpperCase() : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Profile",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),  // Use Poppins font
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildProfileHeader(name, initials),
                  const SizedBox(height: 10),
                  _buildUserInfoOptions(),
                  const SizedBox(height: 10),
                  _buildAboutTile(),
                  const SizedBox(height: 10),
                  _buildSettingsTile(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(String name, String initials) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue,
            child: Text(
              initials,
              style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
            ), // Display the first letter as the avatar
          ),
          const SizedBox(height: 10),
          Text(
            name.isNotEmpty ? name : "No Name Provided",
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold), // Use Poppins font
          ),
          const SizedBox(height: 6),
          Text(
            user?.email ?? '',
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),  // Use Poppins font
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoOptions() {
    return _buildProfileOptionCard(
      title: "User Info",
      icon: Icons.person_outline,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserInfoScreen()),
        );
      },
    );
  }

  Widget _buildAboutTile() {
    return _buildProfileOptionCard(
      title: "About App",
      icon: Icons.info_outline,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AboutScreen()),
        );
      },
    );
  }

  Widget _buildSettingsTile() {
    return _buildProfileOptionCard(
      title: "Settings",
      icon: Icons.settings,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      },
    );
  }

  Widget _buildProfileOptionCard({required String title, required IconData icon, required VoidCallback onTap}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Reduced padding
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.normal), // Use Poppins font
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
