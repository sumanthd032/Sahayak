import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PensionScreen extends StatefulWidget {
  const PensionScreen({super.key});

  @override
  State<PensionScreen> createState() => _PensionScreenState();
}

class _PensionScreenState extends State<PensionScreen> {
  final CollectionReference _pensionRef = FirebaseFirestore.instance.collection('pensions');

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final List<String> _months = const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  final Color _primaryColor = Colors.blue;
  final Color _secondaryColor = Colors.blueAccent;
  final Color _bgColor = Colors.white;
  final Color _textColor = Colors.black87;

  bool _isLoading = true;
  List<Map<String, dynamic>> _pensions = [];
  late String _uid;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _uid = user.uid;
      _loadPensions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not logged in')));
      Navigator.pop(context);
    }
  }

  Future<void> _loadPensions() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _pensionRef.where('uid', isEqualTo: _uid).get();
      final pensionList = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'],
          'amount': data['amount'],
          'phone': data['phone'] ?? '',
          'monthlyStatus': List<bool>.from(data['monthlyStatus'] ?? List.filled(12, false)),
        };
      }).toList();
      setState(() {
        _pensions = pensionList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Fetch error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load pensions')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addPension() async {
    final name = _nameController.text.trim();
    final amountText = _amountController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || amountText.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all fields')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be a positive number')),
      );
      return;
    }

    final newPension = {
      'uid': _uid,
      'name': name,
      'amount': amount,
      'phone': phone,
      'monthlyStatus': List<bool>.filled(12, false),
    };

    try {
      await _pensionRef.add(newPension);
      Navigator.pop(context);
      _nameController.clear();
      _amountController.clear();
      _phoneController.clear();
      _loadPensions();
    } catch (e) {
      debugPrint('Add error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add pension')));
    }
  }

  Future<void> _toggleMonth(String id, int monthIndex, bool newValue) async {
    try {
      final pension = _pensions.firstWhere((p) => p['id'] == id);
      final updatedStatus = List<bool>.from(pension['monthlyStatus']);

      if (newValue) {
        if (monthIndex == 0 || updatedStatus[monthIndex - 1]) {
          updatedStatus[monthIndex] = true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mark previous month first')),
          );
          return;
        }
      } else {
        updatedStatus[monthIndex] = false;
      }

      await _pensionRef.doc(id).update({'monthlyStatus': updatedStatus});
      _loadPensions();
    } catch (e) {
      debugPrint('Update error: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update month')));
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Pension', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Pension Name')),
            const SizedBox(height: 10),
            TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount')),
            const SizedBox(height: 10),
            TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Help Phone Number')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _nameController.clear();
              _amountController.clear();
              _phoneController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(onPressed: _addPension, child: const Text('Add')),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch call')));
    }
  }

  Widget _buildMonthBox(String id, int monthIndex, bool received) {
    return GestureDetector(
      onTap: () => _toggleMonth(id, monthIndex, !received),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: received ? _secondaryColor : _bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _secondaryColor),
        ),
        child: Text(
          _months[monthIndex],
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: received ? Colors.white : _textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildPensionTile(Map<String, dynamic> pension) {
    final id = pension['id'];
    final name = pension['name'];
    final amount = pension['amount'];
    final phone = pension['phone'];
    final monthlyStatus = List<bool>.from(pension['monthlyStatus']);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 4,
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            Text('₹ ${NumberFormat('#,##0.00', 'en_IN').format(amount)}', style: GoogleFonts.poppins()),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: 12,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 3,
              ),
              itemBuilder: (_, i) => _buildMonthBox(id, i, monthlyStatus[i]),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => _makePhoneCall(phone),
            icon: const Icon(Icons.phone, color: Colors.green),
            label: Text('Call Help', style: GoogleFonts.poppins(color: Colors.green)),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: Text('Pension Tracker', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pensions.isEmpty
              ? Center(child: Text('No pension records found.', style: GoogleFonts.poppins()))
              : ListView.builder(
                  itemCount: _pensions.length,
                  itemBuilder: (_, index) => _buildPensionTile(_pensions[index]),
                ),
    );
  }
} 
