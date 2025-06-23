import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LimitSetter extends StatefulWidget {
  const LimitSetter({Key? key}) : super(key: key);

  @override
  State<LimitSetter> createState() => _LimitSetterState();
}

class _LimitSetterState extends State<LimitSetter> {
  final TextEditingController _limitController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? userId;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          userId = user.uid;
        });
        _loadLimit();
      } else {
        // Handle the case when no user is logged in
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user is logged in.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize user: $e')),
      );
    }
  }

  Future<void> _loadLimit() async {
    if (userId == null) return;
    try {
      DocumentSnapshot snapshot =
      await _firestore.collection('limits').doc(userId).get();

      if (snapshot.exists && snapshot.data() != null) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        int limit = data['expense_limit'] ?? 0;

        setState(() {
          _limitController.text = limit.toString();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load limit: $e')),
      );
    }
  }
//limit module
  Future<void> _saveLimit() async {
    if (userId == null) return;
    int? newLimit = int.tryParse(_limitController.text);
    if (newLimit != null) {
      try {
        await _firestore.collection('limits').doc(userId).set(
          {'expense_limit': newLimit},
          SetOptions(merge: true),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense limit updated successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update limit: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF232526), Color(0xFF414345)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Expense Limit',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        letterSpacing: 1.2,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 8), // increased top margin
          decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
          ),
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            size: 56,
            color: theme.colorScheme.primary.withOpacity(0.85),
          ),
          const SizedBox(height: 10),
          Text(
            "Set Your Monthly Limit",
            style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            "Stay on track by setting a monthly expense limit.",
            style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _limitController,
            decoration: InputDecoration(
          labelText: 'Expense Limit',
          prefixText: 'Rs. ',
          filled: true,
          fillColor: theme.colorScheme.surface.withOpacity(0.95),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
            ),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
          onPressed: _saveLimit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            elevation: 3,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.save_rounded, size: 22),
              SizedBox(width: 8),
              Text(
            'Save Limit',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ],
          ),
            ),
          ),
        ],
          ),
        ),
      ),);
  }
}