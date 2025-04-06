import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        title: const Text(
          "About Sahayak",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intro Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: const [
                    Text(
                      "Sahayak is an AI-powered companion app designed with love and care for senior citizens.",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Our mission is to provide comfort, safety, and connection through smart technology that understands and supports the unique needs of elders.",
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "With intuitive design and helpful features, Sahayak aims to bridge the digital gap and ensure that no senior ever feels alone or helpless.",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Key Features Section
            const Text(
              "🌟 Key Features",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildFeatureTile("🤖 AI-Powered Assistance", "Get personalized help with daily tasks and reminders."),
            _buildFeatureTile("🧠 Memory Aid", "Journal moments and set memory prompts to cherish important memories."),
            _buildFeatureTile("🗺️ Assisted Navigation", "Navigate familiar and new places safely with ease."),
            _buildFeatureTile("😄 Emotion Detection", "Understand and respond to your emotional well-being."),
            _buildFeatureTile("🌐 Multilingual & Cultural Support", "Connect in your native language with relevant content."),
            _buildFeatureTile("🚨 Smart Emergency Handling", "Quick access to emergency contacts and services when needed."),

            const SizedBox(height: 30),

            // Why Sahayak
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "❤️ Why Sahayak?",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "We believe in creating a world where technology empowers and includes our elders.",
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Sahayak is more than just an app — it’s a reliable friend, a patient listener, and a gentle guide.",
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Developed with ❤️ by: Team NOVA",
                      style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.white,
        leading: const Icon(Icons.star, color: Colors.indigo),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }
}
