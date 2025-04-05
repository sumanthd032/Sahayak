import 'package:flutter/material.dart';

class UserInfoSection extends StatefulWidget {
  final Map<String, dynamic> userData;
  const UserInfoSection({super.key, required this.userData});

  @override
  State<UserInfoSection> createState() => _UserInfoSectionState();
}

class _UserInfoSectionState extends State<UserInfoSection> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: ExpansionTile(
        title: Text("View More Information"),
        trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
        onExpansionChanged: (value) => setState(() => expanded = value),
        children: [
          ListTile(
            title: Text("Age"),
            subtitle: Text(widget.userData['age']?.toString() ?? "-"),
          ),
          ListTile(
            title: Text("Locality"),
            subtitle: Text(widget.userData['locality'] ?? "-"),
          ),
          ListTile(
            title: Text("Interests"),
            subtitle: Text(widget.userData['interests'] ?? "-"),
          ),
          ListTile(
            title: Text("Preferred Language"),
            subtitle: Text(widget.userData['preferred_language'] ?? "-"),
          ),
        ],
      ),
    );
  }
}
