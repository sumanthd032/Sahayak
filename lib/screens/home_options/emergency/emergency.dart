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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFamilyNumber();
  }

  // Fetch the family emergency number from Firestore
  Future<void> fetchFamilyNumber() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      setState(() {
        isLoading = false;  // Stop loading if no user is logged in
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        // Fetch the family_emergency_no field from the document
        final emergencyContact = doc.data()?['family_emergency_no'];

        if (emergencyContact != null && emergencyContact is String) {
          setState(() {
            familyNumber = emergencyContact;
          });
        } else {
          setState(() {
            familyNumber = null;  // No valid emergency contact found
          });
        }
      } else {
        // Document does not exist or is empty
        setState(() {
          familyNumber = null;
        });
      }
    } catch (e) {
      debugPrint('Error fetching emergency number: $e');
      setState(() {
        familyNumber = null;  // Handle error by setting familyNumber to null
      });
    }

    setState(() {
      isLoading = false;  // Stop the loading spinner after data is fetched
    });
  }

  // Call the number using the device's dialer
  Future<void> _callNumber(String number) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: number);
    try {
      if (await canLaunch(phoneUri.toString())) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch dialer';
      }
    } catch (e) {
      // Show an error message when dialer cannot be launched
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to launch dialer. Please check your device settings.')),
      );
    }
  }

  // Build emergency tile for each emergency contact
  Widget buildEmergencyTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        height: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: Text(
          'Emergency',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      buildEmergencyTile(
                        icon: Icons.family_restroom,
                        label: 'Family',
                        onTap: () {
                          if (familyNumber != null) {
                            _callNumber(familyNumber!);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No family number found in profile.'),
                              ),
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
              ),
            ),
    );
  }
}
