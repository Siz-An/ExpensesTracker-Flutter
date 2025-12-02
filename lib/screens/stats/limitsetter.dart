import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LimitSetter extends StatefulWidget {
  const LimitSetter({Key? key}) : super(key: key);

  @override
  State<LimitSetter> createState() => _LimitSetterState();
}

class _LimitSetterState extends State<LimitSetter> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? userId;
  
  // Category-wise limits storage
  Map<String, TextEditingController> _categoryControllers = {};
  final List<String> _expenseCategories = [
    'Food & Dining',
    'Transport',
    'Housing',
    'Entertainment',
    'Health & Fitness',
    'Shopping',
    'Education',
    'Bills & Subscriptions',
    'Savings & Investments',
    'Miscellaneous'
  ];

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
        _loadCategoryLimits();
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

  Future<void> _loadCategoryLimits() async {
    if (userId == null) return;
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('category_limits').doc(userId).get();

      if (snapshot.exists && snapshot.data() != null) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        
        setState(() {
          // Initialize controllers for each category
          for (String category in _expenseCategories) {
            int limit = data[category] ?? 0;
            _categoryControllers[category] = TextEditingController(text: limit.toString());
          }
        });
      } else {
        // Initialize with empty controllers if no data exists
        setState(() {
          for (String category in _expenseCategories) {
            _categoryControllers[category] = TextEditingController(text: '0');
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load limits: $e')),
      );
    }
  }

  Future<void> _saveCategoryLimits() async {
    if (userId == null) return;
    
    try {
      Map<String, int> limits = {};
      
      // Collect limits from all controllers
      _categoryControllers.forEach((category, controller) {
        int? limit = int.tryParse(controller.text) ?? 0;
        limits[category] = limit;
      });
      
      await _firestore.collection('category_limits').doc(userId).set(
        limits,
        SetOptions(merge: true),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category limits updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update limits: $e')),
      );
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
                      'Category Limits',
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
          margin: const EdgeInsets.only(top: 30, left: 16, right: 16, bottom: 16),
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
                Icons.category_rounded,
                size: 56,
                color: theme.colorScheme.primary.withOpacity(0.85),
              ),
              const SizedBox(height: 10),
              Text(
                "Set Category-wise Limits",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                "Set spending limits for each expense category.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Category limit inputs with improved UI
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Header row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Category',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Limit (Rs.)',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Category rows
                    ..._expenseCategories.map((category) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: theme.dividerColor.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  category,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: TextField(
                                    controller: _categoryControllers[category],
                                    decoration: InputDecoration(
                                      prefixText: 'Rs. ',
                                      prefixStyle: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: theme.colorScheme.outline.withOpacity(0.5),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: theme.colorScheme.outline.withOpacity(0.5),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                          color: theme.colorScheme.primary,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 14,
                                      ),
                                    ),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveCategoryLimits,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                      Icon(Icons.save_rounded, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Save Category Limits',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enter 0 for no limit on a category',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    // Dispose all controllers
    _categoryControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }
}