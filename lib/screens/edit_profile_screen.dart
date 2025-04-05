import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final User? user = FirebaseAuth.instance.currentUser;

  late TextEditingController fullNameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController addressController;
  late TextEditingController dobController;
  String? gender;

  @override
  void initState() {
    super.initState();
    fullNameController = TextEditingController(text: widget.userData['full_name'] ?? '');
    phoneController = TextEditingController(text: widget.userData['phone'] ?? '');
    emailController = TextEditingController(text: widget.userData['email'] ?? '');
    addressController = TextEditingController(text: widget.userData['address'] ?? '');
    dobController = TextEditingController(text: widget.userData['dob'] ?? '');
    gender = widget.userData['gender'];
  }

  Future<void> saveProfile() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'full_name': fullNameController.text,
        'phone': phoneController.text,
        'email': emailController.text,
        'address': addressController.text,
        'dob': dobController.text,
        'gender': gender,
      });
      Navigator.pop(context);
    }
  }

  Widget buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelStyle: const TextStyle(color: Colors.indigo),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  Widget buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<String>(
        value: gender,
        decoration: InputDecoration(
          labelText: "Gender",
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        items: ['Male', 'Female', 'Other']
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (value) => setState(() => gender = value),
        validator: (value) => value == null ? 'Please select gender' : null,
      ),
    );
  }

  Future<void> pickDate() async {
    DateTime initialDate = DateTime.tryParse(dobController.text) ?? DateTime(2000);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1960),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Widget buildDateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: dobController,
        readOnly: true,
        onTap: pickDate,
        decoration: InputDecoration(
          labelText: "Date of Birth",
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'Please select date of birth' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildTextField("Full Name", fullNameController),
              buildTextField("Phone", phoneController, keyboardType: TextInputType.phone),
              buildTextField("Email", emailController, keyboardType: TextInputType.emailAddress),
              buildTextField("Address", addressController),
              buildGenderDropdown(),
              buildDateField(),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Save Changes", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
