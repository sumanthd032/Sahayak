import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("About"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "Sahayak is your all-in-one assistant designed to help users with everyday tasks, fun activities, and information access in a modern and inclusive way.",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
