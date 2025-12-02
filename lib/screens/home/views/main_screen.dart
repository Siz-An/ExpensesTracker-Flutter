import 'package:expenses_tracker/screens/home/views/popup.dart';
import 'package:expenses_tracker/screens/home/views/profile.dart';
import 'package:expenses_tracker/screens/home/views/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../stats/card.dart';
import '../../stats/extra_widget.dart';
import '../../stats/limitsetter.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedTab = 0; // 0: ALL, 1: Income, 2: Expenses
  int _currentLimit = 0;

  @override
  void initState() {
    super.initState();
    _loadLimitAndCheckExpenses();
  }

  /// Load the limit from Firestore and check expenses
  Future<void> _loadLimitAndCheckExpenses() async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) throw Exception('User not authenticated');

      DocumentSnapshot limitSnapshot = await FirebaseFirestore.instance
          .collection('limits')
          .doc(userId)
          .get();

      if (limitSnapshot.exists) {
        int limit = limitSnapshot['expense_limit'] ?? 0;

        setState(() {
          _currentLimit = limit;
        });

        double totalExpenses = await getTotalAmount('expenses');

        if (totalExpenses > limit) {
          LimitExceededPopup.show(
              context, 'Total Expenses', totalExpenses.toInt());
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading limit or expenses: $e')),
      );
    }
  }

  /// Get the total amount for a collection (e.g., income or expenses)
  Future<double> getTotalAmount(String collection) async {
    double total = 0.0;
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in snapshot.docs) {
      total += doc['amount'];
    }
    return total;
  }

  Future<Map<String, dynamic>> getUserData() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      throw Exception('User not authenticated');
    }
    DocumentSnapshot userDoc =
    await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    // Fix: Check if document exists before casting
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    } else {
      // Return empty map or default user data if document doesn't exist
      return {
        'username': 'User',
        // Add other default fields as needed
      };
    }
  }

  Future<List<Map<String, dynamic>>> getTransactionDetails(String collection) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .get();

    List<Map<String, dynamic>> transactions = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      return {
        'id': doc.id,
        'category': data['category'] ?? 'Unknown',
        'note': data['note'] ?? '',
        'date': data['createdAt'] ?? Timestamp.now(),
        'amount': data['amount'] ?? 0.0,
        'type': collection,
      };
    }).toList();

    transactions.sort((a, b) {
      DateTime dateA = (a['date'] as Timestamp).toDate();
      DateTime dateB = (b['date'] as Timestamp).toDate();
      return dateB.compareTo(dateA);
    });

    return transactions;
  }

  Future<void> deleteTransaction(String collection, String docId) async {
    try {
      await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
      setState(() {}); // Refresh UI after deletion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete transaction: $e')),
      );
    }
  }

  void _onTabChange(int newTab) {
    setState(() {
      _selectedTab = newTab;
    });
  }

  /// Add a new transaction to Firestore (either income or expenses)
  Future<void> addTransaction(String collection, Map<String, dynamic> transactionData) async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) throw Exception('User not authenticated');

      // Add the transaction to Firestore
      await FirebaseFirestore.instance.collection(collection).add(transactionData);

      // Reload the entire screen
      Get.off(() => const MainScreen());
      Get.to(() => const MainScreen());

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add transaction: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
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
                
                  const SizedBox(width: 10),
                  const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Expense Tracker',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
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
                  IconButton(
                    onPressed: () => Get.to(() => const LimitSetter()),
                    icon: const Icon(Icons.notifications, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () => Get.to(() => const SearchScreen()),
                    icon: const Icon(Icons.search, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () => Get.to(() => ProfileScreen()),
                    icon: const Icon(Icons.settings, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadLimitAndCheckExpenses();
        },
        child: FutureBuilder(
          future: Future.wait([
            getUserData(),
            getTotalAmount('income'),
            getTotalAmount('expenses'),
            getTransactionDetails('income'),
            getTransactionDetails('expenses')
          ]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              var userData = snapshot.data![0] as Map<String, dynamic>;
              double incomeTotal = snapshot.data![1] as double;
              double expenseTotal = snapshot.data![2] as double;
              List<Map<String, dynamic>> incomeDetails = snapshot.data![3];
              List<Map<String, dynamic>> expenseDetails = snapshot.data![4];

              List<Map<String, dynamic>> allDetails = [
                ...incomeDetails,
                ...expenseDetails
              ];

              List<Map<String, dynamic>> selectedDetails =
                  _selectedTab == 0
                      ? allDetails
                      : _selectedTab == 1
                          ? incomeDetails
                          : expenseDetails;

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFe0eafc), Color(0xFFcfdef3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.10),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFF232526),
                          child: Text(
                            userData['username']?[0]?.toUpperCase() ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                userData['username'] ?? '',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF232526),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: FutureBuilder<DocumentSnapshot>(
                            future: _currentLimit > 0 
                                ? null 
                                : FirebaseFirestore.instance.collection('category_limits').doc(FirebaseAuth.instance.currentUser?.uid).get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Row(
                                  children: const [
                                    Icon(Icons.flag, color: Color(0xFF414345), size: 20),
                                    SizedBox(width: 6),
                                    Text(
                                      'Loading...',
                                      style: TextStyle(
                                        color: Color(0xFF414345),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                );
                              }
                              
                              if (snapshot.hasData && snapshot.data!.exists) {
                                Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
                                int totalCategoryLimit = 0;
                                
                                // Calculate total of all category limits
                                data.forEach((key, value) {
                                  if (value is int) {
                                    totalCategoryLimit += value;
                                  }
                                });
                                
                                return Row(
                                  children: [
                                    const Icon(Icons.flag, color: Color(0xFF414345), size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Total Limit: Rs.$totalCategoryLimit',
                                      style: const TextStyle(
                                        color: Color(0xFF414345),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                );
                              }
                              
                              // Fallback to current limit if no category limits found
                              return Row(
                                children: [
                                  const Icon(Icons.flag, color: Color(0xFF414345), size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Total Limit: Rs.$_currentLimit',
                                    style: const TextStyle(
                                      color: Color(0xFF414345),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              );
                            }
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  BalanceCard(
                    incomeTotal: incomeTotal,
                    expenseTotal: expenseTotal,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.07),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ExtraWidget(
                      selectedTab: _selectedTab,
                      onTabChange: _onTabChange,
                      selectedDetails: selectedDetails,
                      deleteTransaction: deleteTransaction,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Add a floating action button style add button
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ),

    );
  }
}
