import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderThingsScreen extends StatelessWidget {
  const OrderThingsScreen({super.key});

  Future<void> _promptAndSearch(BuildContext context, String site) async {
    final TextEditingController searchController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Search on $site", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
          content: TextField(
            controller: searchController,
            style: GoogleFonts.poppins(fontSize: 18),
            decoration: InputDecoration(
              hintText: "Enter product name/item",
              hintStyle: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel", style: GoogleFonts.poppins(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () {
                String query = searchController.text.trim();
                if (query.isNotEmpty) {
                  Navigator.of(context).pop();
                  _launchSearch(site, query);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: Text("Search", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _launchSearch(String site, String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    String url;

    if (site == 'Amazon') {
      url = 'https://www.amazon.in/s?k=$encodedQuery';
    } else if (site == 'Flipkart') {
      url = 'https://www.flipkart.com/search?q=$encodedQuery';
    } else if (site == 'Swiggy') {
      url = 'https://www.swiggy.com/search?q=$encodedQuery';
    } else if (site == 'Zomato') {
      url = 'https://www.zomato.com/bangalore/search?q=$encodedQuery';
    } else {
      throw Exception('Unsupported site: $site');
    }

    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> options = [
      {
        'title': 'Amazon',
        'icon': 'assets/amazon_logo.jpeg',
        'color': Colors.orange.shade400,
      },
      {
        'title': 'Flipkart',
        'icon': 'assets/flipkart_logo.png',
        'color': Colors.indigo.shade400,
      },
      {
        'title': 'Swiggy',
        'icon': 'assets/swiggy_logo.jpeg',
        'color': Colors.deepOrange.shade300,
      },
      {
        'title': 'Zomato',
        'icon': 'assets/zomato_logo.jpeg',
        'color': Colors.red.shade300,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Order Things",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.pink.shade50,
        child: GridView.builder(
          itemCount: options.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            final option = options[index];
            return GestureDetector(
              onTap: () => _promptAndSearch(context, option['title'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: option['color'],
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: option['color'].withOpacity(0.4),
                      offset: const Offset(0, 6),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(option['icon'], height: 70),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        option['title'],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
