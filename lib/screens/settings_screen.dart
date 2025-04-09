import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sahayak/screens/user_info_screen';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
        }
      } catch (e) {
        print("Error fetching user data: $e");
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> updateUserInfo(Map<String, dynamic> updatedData) async {
    if (user != null) {
      try {
        final docRef = FirebaseFirestore.instance.collection('users').doc(user!.uid);
        await docRef.update(updatedData);
        setState(() {
          userData = updatedData;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated!')));
      } catch (e) {
        print("Error updating user data: $e");
      }
    }
  }

  Future<void> changePassword() async {
    try {
      await user!.updatePassword("new_password_here"); // Update this based on user input
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password changed successfully!')));
    } catch (e) {
      print("Error changing password: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to change password')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildListTile('Profile', Icons.person, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => UserInfoScreen()));
          }),
          _buildListTile('Change Password', Icons.lock, () async {
            await _changePasswordDialog();
          }),
          _buildListTile('Preferred Language', Icons.language, () async {
            await _changePreferredLanguageDialog();
          }),
          _buildListTile('Family Emergency Number', Icons.phone, () async {
            await _changeFamilyEmergencyNoDialog();
          }),
          _buildListTile('Log Out', Icons.exit_to_app, () async {
            await _logOut();
          }),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        leading: Icon(icon, color: Colors.blue, size: 28),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        onTap: onTap,
      ),
    );
  }

  Future<void> _changePasswordDialog() async {
    TextEditingController currentPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField('Current Password', currentPasswordController, obscureText: true),
                _buildTextField('New Password', newPasswordController, obscureText: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // You can add validation for the password input here
                changePassword();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePreferredLanguageDialog() async {
    TextEditingController preferredLanguageController =
        TextEditingController(text: userData['preferred_language']);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Preferred Language'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField('Preferred Language', preferredLanguageController),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Map<String, dynamic> updatedData = {
                  'preferred_language': preferredLanguageController.text,
                };
                updateUserInfo(updatedData);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeFamilyEmergencyNoDialog() async {
    TextEditingController familyEmergencyNoController =
        TextEditingController(text: userData['family_emergency_no']);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add/Update Family Emergency Number'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField('Family Emergency Number', familyEmergencyNoController),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Map<String, dynamic> updatedData = {
                  'family_emergency_no': familyEmergencyNoController.text,
                };
                updateUserInfo(updatedData);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Fixed logout functionality
  Future<void> _logOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login'); // Replace with your login route
    } catch (e) {
      print("Error during logout: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to log out')));
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
