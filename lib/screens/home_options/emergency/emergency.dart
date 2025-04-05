import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  String? familyNumber;

  @override
  void initState() {
    super.initState();
    fetchFamilyNumber();
  }

  Future<void> fetchFamilyNumber() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data()?['emergencyContact'] != null) {
        setState(() {
          familyNumber = doc.data()!['emergencyContact'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching emergency number: $e');
    }
  }

  Future<void> _callNumber(String number) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to launch dialer.')),
      );
    }
  }

  Widget buildEmergencyTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade100,
              blurRadius: 6,
              offset: const Offset(2, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.redAccent),
            const SizedBox(height: 10),
            Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: const Text('Emergency'),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            buildEmergencyTile(
              icon: Icons.family_restroom,
              label: 'Family',
              onTap: () {
                if (familyNumber != null) {
                  _callNumber(familyNumber!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No family number found in profile.')),
                  );
                }
              },
            ),
            buildEmergencyTile(
              icon: Icons.local_police,
              label: 'Police',
              onTap: () => _callNumber('100'),
            ),
            buildEmergencyTile(
              icon: Icons.local_hospital,
              label: 'Ambulance',
              onTap: () => _callNumber('108'),
            ),
            buildEmergencyTile(
              icon: Icons.fire_extinguisher,
              label: 'Fire',
              onTap: () => _callNumber('101'),
            ),
            buildEmergencyTile(
              icon: Icons.elderly,
              label: 'Senior Citizen',
              onTap: () => _callNumber('14567'),
            ),
          ],
        ),
      ),
    );
  }
}
