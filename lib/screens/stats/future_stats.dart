import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

class FutureStatsScreen extends StatefulWidget {
  const FutureStatsScreen({Key? key}) : super(key: key);

  @override
  State<FutureStatsScreen> createState() => _FutureStatsScreenState();
}

class _FutureStatsScreenState extends State<FutureStatsScreen> {
  late Future<List<Map<String, dynamic>>> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = _fetchExpenseData();
  }

  Future<List<Map<String, dynamic>>> _fetchExpenseData() async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) throw Exception('User not authenticated');

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('expenses')
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
          'type': 'expense',
        };
      }).toList();

      return transactions;
    } catch (e) {
      throw Exception('Failed to fetch expense data: $e');
    }
  }

  // Linear Regression Algorithm for expense forecasting
  // Formula: y = mx + b
  // Where:
  // m (slope) = (n*Σxy - Σx*Σy) / (n*Σx² - (Σx)²)
  // b (intercept) = (Σy - m*Σx) / n
  Map<String, dynamic> _predictNextMonthExpense(List<Map<String, dynamic>> expenseHistory) {
    if (expenseHistory.length < 2) {
      return {
        'predictedAmount': 0.0,
        'trend': 'insufficient_data',
        'message': 'Not enough data for prediction'
      };
    }

    try {
      // Prepare data points (month index, expense amount)
      List<double> xValues = []; // Month indices
      List<double> yValues = []; // Expense amounts
      
      // Extract and organize data by months
      Map<int, double> monthlyExpenses = {};
      
      for (var entry in expenseHistory) {
        if (entry['date'] is Timestamp && entry['amount'] is num) {
          DateTime date = (entry['date'] as Timestamp).toDate();
          int monthKey = date.year * 12 + date.month; // Unique identifier for each month
          double amount = (entry['amount'] as num).toDouble();
          
          if (monthlyExpenses.containsKey(monthKey)) {
            monthlyExpenses[monthKey] = monthlyExpenses[monthKey]! + amount;
          } else {
            monthlyExpenses[monthKey] = amount;
          }
        }
      }
      
      // Convert to sorted list of data points
      List<MapEntry<int, double>> sortedEntries = monthlyExpenses.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      
      if (sortedEntries.length < 2) {
        return {
          'predictedAmount': 0.0,
          'trend': 'insufficient_data',
          'message': 'Not enough data for prediction'
        };
      }
      
      // Create sequential indices for x values
      for (int i = 0; i < sortedEntries.length; i++) {
        xValues.add(i.toDouble());
        yValues.add(sortedEntries[i].value);
      }
      
      // Calculate linear regression coefficients
      int n = xValues.length;
      double sumX = xValues.reduce((a, b) => a + b);
      double sumY = yValues.reduce((a, b) => a + b);
      double sumXY = 0;
      double sumXX = 0;
      
      for (int i = 0; i < n; i++) {
        sumXY += xValues[i] * yValues[i];
        sumXX += xValues[i] * xValues[i];
      }
      
      // Calculate slope (m) and intercept (b)
      double denominator = n * sumXX - sumX * sumX;
      if (denominator == 0) {
        // Avoid division by zero
        return {
          'predictedAmount': yValues.last,
          'trend': 'stable',
          'message': 'Stable spending pattern'
        };
      }
      
      double slope = (n * sumXY - sumX * sumY) / denominator;
      double intercept = (sumY - slope * sumX) / n;
      
      // Predict next month (next index)
      double nextMonthIndex = (n - 1) + 1; // Next month index
      double predictedExpense = slope * nextMonthIndex + intercept;
      
      // Determine trend
      String trend = slope > 0 ? 'increasing' : slope < 0 ? 'decreasing' : 'stable';
      String message = slope > 0 
          ? 'Spending is increasing over time' 
          : slope < 0 
              ? 'Spending is decreasing over time' 
              : 'Spending remains stable';
      
      // Ensure prediction is non-negative
      return {
        'predictedAmount': math.max(0, predictedExpense),
        'trend': trend,
        'message': message,
        'slope': slope,
        'intercept': intercept,
        'dataPoints': sortedEntries.length,
      };
    } catch (e) {
      // If any error occurs, return default values
      return {
        'predictedAmount': 0.0,
        'trend': 'error',
        'message': 'Error in prediction: $e'
      };
    }
  }

  // Calculate category-wise predictions
  Map<String, double> _predictCategoryExpenses(List<Map<String, dynamic>> expenseHistory) {
    Map<String, List<Map<String, dynamic>>> categoryExpenses = {};
    
    // Group expenses by category
    for (var entry in expenseHistory) {
      String category = entry['category'] as String? ?? 'Unknown';
      if (!categoryExpenses.containsKey(category)) {
        categoryExpenses[category] = [];
      }
      categoryExpenses[category]!.add(entry);
    }
    
    Map<String, double> categoryPredictions = {};
    
    // Predict for each category
    categoryExpenses.forEach((category, expenses) {
      double prediction = _predictSimpleAverage(expenses);
      categoryPredictions[category] = prediction;
    });
    
    return categoryPredictions;
  }
  
  // Simple average prediction for categories with insufficient data
  double _predictSimpleAverage(List<Map<String, dynamic>> expenses) {
    if (expenses.isEmpty) return 0.0;
    
    double total = 0.0;
    for (var expense in expenses) {
      if (expense['amount'] is num) {
        total += (expense['amount'] as num).toDouble();
      }
    }
    
    return total / expenses.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Future Spending Stats'),
        backgroundColor: const Color(0xFF232526),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (snapshot.hasData) {
            List<Map<String, dynamic>> expenseData = snapshot.data!;
            Map<String, dynamic> prediction = _predictNextMonthExpense(expenseData);
            Map<String, double> categoryPredictions = _predictCategoryExpenses(expenseData);
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Prediction Card
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: prediction['trend'] == 'increasing' 
                            ? [const Color(0xFFB71C1C), const Color(0xFFD32F2F)]
                            : prediction['trend'] == 'decreasing'
                                ? [const Color(0xFF388E3C), const Color(0xFF66BB6A)]
                                : [const Color(0xFF1976D2), const Color(0xFF42A5F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Next Month Prediction',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Rs.${(prediction['predictedAmount'] as double).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            prediction['message'] as String,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          if (prediction.containsKey('slope')) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Based on ${prediction['dataPoints']} months of data',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Category Predictions
                  const Text(
                    'Category-wise Predictions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Category prediction cards
                  ...categoryPredictions.entries.map((entry) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text(entry.key),
                        trailing: Text(
                          'Rs.${entry.value.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  
                  const SizedBox(height: 20),
                  
                  // Information section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How predictions work:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Uses Linear Regression to analyze your spending patterns\n'
                          '• Predicts next month\'s expenses based on historical data\n'
                          '• Shows category-wise predictions for better budgeting\n'
                          '• Requires at least 2 months of expense data for accuracy',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}