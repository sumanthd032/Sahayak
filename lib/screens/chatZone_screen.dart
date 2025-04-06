import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sahayak/chatZOne/custom.dart';
import 'package:sahayak/chatZOne/general_knowledge.dart';
import 'package:sahayak/chatZOne/normal.dart';
import 'package:sahayak/chatZOne/religious_mode.dart';
import 'package:sahayak/chatZOne/travel_mode.dart';
import 'package:sahayak/chatZOne/wellness_mode.dart';

class ChatZoneScreen extends StatelessWidget {
  const ChatZoneScreen({super.key});

  final List<Map<String, dynamic>> modes = const [
    {
      'title': 'Normal Mode',
      'description': 'Everyday chats',
      'icon': Icons.chat_bubble_outline,
      'color': Colors.blue,
    },
    {
      'title': 'Religious Mode',
      'description': 'Spiritual talk',
      'icon': Icons.self_improvement,
      'color': Colors.green,
    },
    {
      'title': 'Wellness Mode',
      'description': 'Mental & physical health',
      'icon': Icons.health_and_safety,
      'color': Colors.pink,
    },
    {
      'title': 'Travel Mode',
      'description': 'Explore places',
      'icon': Icons.travel_explore,
      'color': Colors.orange,
    },
    {
      'title': 'Custom Mode',
      'description': 'Your way',
      'icon': Icons.tune,
      'color': Colors.purple,
    },
    {
      'title': 'Knowledge Mode',
      'description': 'Learn & grow',
      'icon': Icons.lightbulb_outline,
      'color': Colors.teal,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "ChatZone",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            itemCount: modes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final mode = modes[index];
              return GestureDetector(
                onTap: () {
                  if (mode['title'] == 'Wellness Mode') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => WellnessModeScreen()),
                    );
                  } else if (mode['title'] == 'Religious Mode') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ReligiousModeScreen()),
                    );
                  } else if (mode['title'] == 'Normal Mode') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NormalMOdeSCreen()),
                    );
                  } else if (mode['title'] == 'Travel Mode') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TravelMode()),
                    );
                  } else if (mode['title'] == 'Custom Mode') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CustomModeScreen()),
                    );
                  } else if (mode['title'] == 'Knowledge Mode') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => GeneralKnowledgeModeScreen()),
                    );
                  }
                },
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  color: mode['color'],
                  shadowColor: mode['color'].withOpacity(0.4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 32,
                          child: Icon(
                            mode['icon'],
                            size: 32,
                            color: mode['color'],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          mode['title'],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          mode['description'],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
