import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderThingsScreen extends StatelessWidget {
  const OrderThingsScreen({super.key});

  Future<void> _promptAndSearch(BuildContext context, String site) async {
    final TextEditingController searchController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: Text("Search on $site", style: const TextStyle(fontSize: 20)),
          content: TextField(
            controller: searchController,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              hintText: "Enter product name/item",
              hintStyle: TextStyle(fontSize: 18),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel", style: TextStyle(fontSize: 18)),
            ),
            TextButton(
              onPressed: () async {
                String query = searchController.text.trim();
                if (query.isNotEmpty) {
                  Navigator.of(context).pop();
                  _launchSearch(site, query);
                }
              },
              child: const Text("Search", style: TextStyle(fontSize: 18)),
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
        'color': Colors.orange.shade300,
      },
      {
        'title': 'Flipkart',
        'icon': 'assets/flipkart_logo.png',
        'color': Colors.blue.shade400,
      },
      {
        'title': 'Swiggy',
        'icon': 'assets/swiggy_logo.jpeg',
        'color': Colors.red.shade400,
      },
      {
        'title': 'Zomato',
        'icon': 'assets/zomato_logo.jpeg',
        'color': Colors.lime.shade600,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Things", style: TextStyle(fontSize: 24)),
        backgroundColor: Colors.deepPurple,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: options.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final option = options[index];
          return GestureDetector(
            onTap: () => _promptAndSearch(context, option['title'] as String),
            child: Container(
              decoration: BoxDecoration(
                color: option['color'],
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(blurRadius: 6, color: Colors.black26)
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(option['icon'] as String, height: 70),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      option['title'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
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
    );
  }
}
