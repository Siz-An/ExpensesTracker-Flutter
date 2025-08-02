import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class PieChartScreen extends StatefulWidget {
  const PieChartScreen({Key? key}) : super(key: key);

  @override
  _PieChartScreenState createState() => _PieChartScreenState();
}

// A reusable stat chip widget for displaying income/expense summary
class _StatChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const _StatChip({
    Key? key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      backgroundColor: color.withOpacity(0.1),
      avatar: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Icon(icon, color: color, size: 20),
      ),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            "Rs.${value.toStringAsFixed(2)}",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _PieChartScreenState extends State<PieChartScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? userId; // Current user ID
  double totalIncome = 0;
  double totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserId();
  }

  void _fetchUserId() {
    final User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
      _fetchData();
    } else {
      debugPrint('No user is logged in.');
    }
  }

  Future<void> _fetchData() async {
    if (userId == null) return;

    try {
      final incomeQuery = await _firestore
          .collection('income')
          .where('userId', isEqualTo: userId)
          .get();
      final expenseQuery = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .get();

      double incomeSum = 0;
      for (var doc in incomeQuery.docs) {
        incomeSum += (doc['amount'] as num).toDouble();
      }

      double expenseSum = 0;
      for (var doc in expenseQuery.docs) {
        expenseSum += (doc['amount'] as num).toDouble();
      }

      setState(() {
        totalIncome = incomeSum;
        totalExpense = expenseSum;
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
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
          
          const SizedBox(width: 10),
          const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'OverView',
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
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white, size: 28),
            tooltip: "Download PDF",
            onPressed: () async {
              // Show loading dialog
              showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              try {
            final notes = await _fetchNotes();
            await _generateAndDownloadPdf(context, notes);
              } finally {
            Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
              }
            },
          ),
            ],
          ),
        ),
          ),
        ),
      ),body: userId == null
          ? const Center(child: CircularProgressIndicator())
          : totalIncome == 0 && totalExpense == 0
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pie_chart_outline, size: 64, color: theme.colorScheme.primary.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        "No data yet",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const CircularProgressIndicator(),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        color: theme.colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                          child: Column(
                            children: [
                              Text(
                                "Income vs Expense",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 170, // made smaller
                                width: 170,  // made smaller
                                child: PieChart(
                                  PieChartData(
                                    sections: _generatePieChartSections(),
                                    centerSpaceRadius: 15, // slightly smaller
                                    borderData: FlBorderData(show: false),
                                    sectionsSpace: 4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: _StatChip(
                                      label: "Income",
                                      value: totalIncome,
                                      color: Colors.green,
                                      icon: Icons.arrow_downward_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _StatChip(
                                      label: "Expense",
                                      value: totalExpense,
                                      color: Colors.red,
                                      icon: Icons.arrow_upward_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Recent Activity",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onBackground,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: FutureBuilder(
                          future: _fetchNotes(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(child: Text("Error: ${snapshot.error}"));
                            } else if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
                              return Center(
                                child: Text(
                                  "No recent activity.",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onBackground.withOpacity(0.5),
                                  ),
                                ),
                              );
                            }

                            final notes = snapshot.data as List<Map<String, dynamic>>;
                            notes.sort((a, b) => b['amount'].compareTo(a['amount']));
                            return ListView.separated(
                              itemCount: notes.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final note = notes[index];
                                final isIncome = note['type'] == 'income';
                                return Container(
                                  decoration: BoxDecoration(
                                    color: isIncome
                                        ? Colors.green.withOpacity(0.08)
                                        : Colors.red.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isIncome
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.red.withOpacity(0.2),
                                      child: Icon(
                                        isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                        color: isIncome ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    title: Text(
                                      note['note'],
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: theme.colorScheme.onBackground,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "Category: ${note['category']}",
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onBackground.withOpacity(0.7),
                                      ),
                                    ),
                                    trailing: Text(
                                      "${isIncome ? '+' : '-'}Rs.${note['amount'].toStringAsFixed(2)}",
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: isIncome ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontFeatures: const [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  //fetch note
  Future<List<Map<String, dynamic>>> _fetchNotes() async {
    if (userId == null) return [];

    List<Map<String, dynamic>> notes = [];

    try {
      final incomeQuery = await _firestore
          .collection('income')
          .where('userId', isEqualTo: userId)
          .get();
      final expenseQuery = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in incomeQuery.docs) {
        notes.add({
          'note': doc['note'],
          'amount': (doc['amount'] as num).toDouble(),
          'category': doc['category'],
          'type': 'income',
          'date': doc['date'], // assuming you have a date field
        });
      }
      for (var doc in expenseQuery.docs) {
        notes.add({
          'note': doc['note'],
          'amount': (doc['amount'] as num).toDouble(),
          'category': doc['category'],
          'type': 'expense',
          'date': doc['date'], // assuming you have a date field
        });
      }
    } catch (e) {
      debugPrint('Error fetching notes: $e');
    }

    return notes;
  }

  List<PieChartSectionData> _generatePieChartSections() {
    final total = totalIncome + totalExpense;
    if (total == 0) return [];

    return [
      PieChartSectionData(
        color: Colors.green,
        value: totalIncome,
        title: "${((totalIncome / total) * 100).toStringAsFixed(1)}%",
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: totalExpense,
        title: "${((totalExpense / total) * 100).toStringAsFixed(1)}%",
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  // Generate a trial balance style PDF with totals inside the table and date
  Future<void> _generateAndDownloadPdf(BuildContext context, List<Map<String, dynamic>> notes) async {
    final pdf = pw.Document();

    // Get current date
    final now = DateTime.now();
    final formattedDate = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";

    // Group by category and type for trial balance, but also keep the latest date for each category/type
    final Map<String, Map<String, dynamic>> incomeByCategory = {};
    final Map<String, Map<String, dynamic>> expenseByCategory = {};

    for (var note in notes) {
      String category = note['category'];
      String type = note['type'];
      double amount = note['amount'];
      var date = note['date'];

      // Format date
      String dateStr = '';
      if (date != null) {
        try {
          if (date is Timestamp) {
            final dt = (date as Timestamp).toDate();
            dateStr = "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
          } else if (date is DateTime) {
            final dt = date as DateTime;
            dateStr = "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
          } else if (date is String) {
            dateStr = date;
          }
        } catch (_) {
          dateStr = date.toString();
        }
      }

      if (type == 'income') {
        if (!incomeByCategory.containsKey(category)) {
          incomeByCategory[category] = {
            'amount': amount,
            'date': dateStr,
          };
        } else {
          incomeByCategory[category]!['amount'] += amount;
          // Keep the latest date (assuming notes are not sorted)
          if ((incomeByCategory[category]!['date'] as String).compareTo(dateStr) < 0) {
            incomeByCategory[category]!['date'] = dateStr;
          }
        }
      } else if (type == 'expense') {
        if (!expenseByCategory.containsKey(category)) {
          expenseByCategory[category] = {
            'amount': amount,
            'date': dateStr,
          };
        } else {
          expenseByCategory[category]!['amount'] += amount;
          // Keep the latest date (assuming notes are not sorted)
          if ((expenseByCategory[category]!['date'] as String).compareTo(dateStr) < 0) {
            expenseByCategory[category]!['date'] = dateStr;
          }
        }
      }
    }

    // Prepare trial balance rows with date
    final List<List<String>> trialBalanceRows = [];
    final allCategories = <String>{
      ...incomeByCategory.keys,
      ...expenseByCategory.keys,
    };

    for (final category in allCategories) {
      final income = incomeByCategory[category]?['amount'] ?? 0.0;
      final incomeDate = incomeByCategory[category]?['date'] ?? '';
      final expense = expenseByCategory[category]?['amount'] ?? 0.0;
      final expenseDate = expenseByCategory[category]?['date'] ?? '';
      trialBalanceRows.add([
        category,
        income != 0 ? 'Rs.${income.toStringAsFixed(2)}' : '',
        incomeDate,
        expense != 0 ? 'Rs.${expense.toStringAsFixed(2)}' : '',
        expenseDate,
      ]);
    }

    // Totals
    final totalIncomeStr = 'Rs.${totalIncome.toStringAsFixed(2)}';
    final totalExpenseStr = 'Rs.${totalExpense.toStringAsFixed(2)}';

    // Add totals as the last row in the trial balance table
    trialBalanceRows.add([
      'Total',
      totalIncomeStr,
      '',
      totalExpenseStr,
      '',
    ]);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Trial Balance', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Date: $formattedDate', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.normal)),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFBDBDBD), width: 1),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1.2),
                  2: const pw.FlexColumnWidth(1.2),
                  3: const pw.FlexColumnWidth(1.2),
                  4: const pw.FlexColumnWidth(1.2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE0E0E0)),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Credit (Income)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Income Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Debit (Expense)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Expense Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                  ...trialBalanceRows.asMap().entries.map((entry) {
                    final i = entry.key;
                    final row = entry.value;
                    final isTotal = i == trialBalanceRows.length - 1;
                    return pw.TableRow(
                      decoration: isTotal
                          ? pw.BoxDecoration(color: PdfColor.fromInt(0xFFB3E5FC))
                          : null,
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            row[0],
                            style: isTotal
                                ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)
                                : pw.TextStyle(fontSize: 12),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            row[1],
                            style: isTotal
                                ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColor.fromInt(0xFF388E3C))
                                : pw.TextStyle(fontSize: 12),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            row[2],
                            style: pw.TextStyle(fontSize: 12),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            row[3],
                            style: isTotal
                                ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColor.fromInt(0xFFD32F2F))
                                : pw.TextStyle(fontSize: 12),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            row[4],
                            style: pw.TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Text('Recent Activity', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                headers: ['Note', 'Amount', 'Category', 'Type', 'Date'],
                data: notes.map((note) {
                  String dateStr = '';
                  if (note['date'] != null) {
                    try {
                      // If Firestore Timestamp
                      if (note['date'] is Timestamp) {
                        final dt = (note['date'] as Timestamp).toDate();
                        dateStr = "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
                      } else if (note['date'] is DateTime) {
                        final dt = note['date'] as DateTime;
                        dateStr = "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
                      } else if (note['date'] is String) {
                        dateStr = note['date'];
                      }
                    } catch (_) {
                      dateStr = note['date'].toString();
                    }
                  }
                  return [
                    note['note'],
                    'Rs.${note['amount'].toStringAsFixed(2)}',
                    note['category'],
                    note['type'],
                    dateStr,
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                cellStyle: pw.TextStyle(fontSize: 11),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFE0E0E0)),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'trial_balance_$formattedDate.pdf',
    );
  }
}