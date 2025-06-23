import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:flutter/services.dart';

class AddExpense extends StatefulWidget {
  const AddExpense({super.key});

  @override
  State<AddExpense> createState() => _AddExpenseState();
}
class _AddExpenseState extends State<AddExpense> {
  TextEditingController expenseController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  DateTime selectDate = DateTime.now();

  // Dropdown for type (Expenses/Income)
  String selectedType = 'Expenses'; // Default selection
  List<String> types = ['Expenses', 'Income'];

  // Dropdown for category (initialized with the first option in the list)
  String selectedCategory = 'Food & Dining'; // Default category selection
  List<String> categories = [
    'Food & Dining', 'Transport', 'Housing', 'Entertainment', 'Health & Fitness',
    'Shopping', 'Education', 'Bills & Subscriptions', 'Savings & Investments',
    'Miscellaneous'
  ];

  @override
  void initState() {
    dateController.text = DateFormat('yyyy/MM/dd').format(DateTime.now());
    super.initState();
  }

  Future<void> saveData() async {
    String amount = expenseController.text;
    String note = noteController.text;
    String date = dateController.text;
    String category = selectedCategory;

    if (amount.isEmpty || note.isEmpty || date.isEmpty || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    String? userId = user?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    CollectionReference collection =
    FirebaseFirestore.instance.collection(selectedType.toLowerCase());

    try {
      await collection.add({
        'userId': userId,
        'amount': double.parse(amount),
        'note': note,
        'date': date,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$selectedType added successfully")),
      );

      // Pop the screen and return true to indicate that a new transaction was added
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add $selectedType: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define categories based on selectedType
    final expenseCategories = [
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
    final incomeCategories = [
      'Salary',
      'Bonus',
      'Gifts',
      'Rents',
      'Investments',
      'Freelance',
      'Interest',
      'Refunds',
      'Grants',
      'Other Income'
    ];
    final categories = selectedType == 'Expenses' ? expenseCategories : incomeCategories;

    // Ensure selectedCategory is valid for the current type
    if (!categories.contains(selectedCategory)) {
      selectedCategory = categories.first;
    }

    // 2025 UI style colors and gradients
    final gradient = LinearGradient(
      colors: [Color(0xFF232526), Color(0xFF414345)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final cardGradient = LinearGradient(
      colors: [Color(0xFFf8fafc), Color(0xFFe0e7ef)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: Color(0xFFF4F6FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(
          decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF232526), Color(0xFF414345)], //  gradient
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
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Add Transaction',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.10),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
              gradient: cardGradient,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glassmorphic header card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    gradient: LinearGradient(
                      colors: [Color(0xFF232526).withOpacity(0.95), Color(0xFF414345).withOpacity(0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        selectedType == 'Expenses' ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedType == 'Expenses' ? "Expense" : "Income",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    children: [
                      // Type Switch
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 250),
                                decoration: BoxDecoration(
                                  color: selectedType == 'Expenses'
                                      ? Colors.black.withOpacity(0.85)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    setState(() {
                                      selectedType = 'Expenses';
                                      selectedCategory = expenseCategories.first;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: Text(
                                        'Expense',
                                        style: TextStyle(
                                          color: selectedType == 'Expenses'
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 250),
                                decoration: BoxDecoration(
                                  color: selectedType == 'Income'
                                      ? Colors.green[700]
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    setState(() {
                                      selectedType = 'Income';
                                      selectedCategory = incomeCategories.first;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: Text(
                                        'Income',
                                        style: TextStyle(
                                          color: selectedType == 'Income'
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Amount
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.grey[100]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.06),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: expenseController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(9),
                          ],
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.attach_money_rounded,
                              color: selectedType == 'Expenses' ? Colors.redAccent : Colors.green,
                              size: 28,
                            ),
                            labelText: 'Amount',
                            labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            filled: true,
                            fillColor: Colors.transparent,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      // Note
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.white,
                        ),
                        child: TextFormField(
                          controller: noteController,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp('[a-zA-Z ]')),
                          ],
                          style: TextStyle(fontSize: 18),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.note_alt_outlined, color: Colors.black38),
                            labelText: 'Title',
                            filled: true,
                            fillColor: Colors.transparent,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      // Category Dropdown
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.white,
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedCategory,
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value!;
                            });
                          },
                          items: categories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.label_rounded,
                                    color: Colors.blueGrey[300],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(category, style: TextStyle(fontSize: 16)),
                                ],
                              ),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                            labelText: 'Category',
                            prefixIcon: const Icon(Icons.category_outlined, color: Colors.black38),
                            filled: true,
                            fillColor: Colors.transparent,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      // Date Picker
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.white,
                        ),
                        child: TextFormField(
                          controller: dateController,
                          readOnly: true,
                          style: TextStyle(fontSize: 16),
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.black,
                                      onPrimary: Colors.white,
                                      surface: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                    dialogBackgroundColor: Colors.white,
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                selectDate = picked;
                                dateController.text = DateFormat('yyyy/MM/dd').format(picked);
                              });
                            }
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.date_range_rounded, color: Colors.black38),
                            labelText: 'Date',
                            filled: true,
                            fillColor: Colors.transparent,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: saveData,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: selectedType == 'Expenses'
                                ? Colors.black
                                : Colors.green[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 4,
                            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            shadowColor: Colors.black26,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.save_rounded,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Save',
                                style: TextStyle(color: Colors.white, letterSpacing: 1.1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
