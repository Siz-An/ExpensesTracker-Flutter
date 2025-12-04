import 'package:flutter/material.dart';
import 'dart:math' as math;

class BalanceCard extends StatelessWidget {
  final double incomeTotal;
  final double expenseTotal;
  final List<Map<String, dynamic>> expenseHistory; // Add expense history data

  const BalanceCard({
    Key? key,
    required this.incomeTotal,
    required this.expenseTotal,
    this.expenseHistory = const [], // Default to empty list
  }) : super(key: key);

  // Linear Regression Algorithm for expense forecasting
  // Formula: y = mx + b
  // Where:
  // m (slope) = (n*Σxy - Σx*Σy) / (n*Σx² - (Σx)²)
  // b (intercept) = (Σy - m*Σx) / n
  double _predictNextMonthExpense() {
    if (expenseHistory.length < 2) {
      // Not enough data for prediction, return current expense total
      return expenseTotal;
    }

    try {
      // Prepare data points (month index, expense amount)
      List<double> xValues = []; // Month indices
      List<double> yValues = []; // Expense amounts
      
      // Extract and organize data by months
      Map<int, double> monthlyExpenses = {};
      
      for (var entry in expenseHistory) {
        if (entry['type'] == 'expense' && entry['date'] is DateTime && entry['amount'] is num) {
          DateTime date = entry['date'];
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
        return expenseTotal;
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
        return expenseTotal;
      }
      
      double slope = (n * sumXY - sumX * sumY) / denominator;
      double intercept = (sumY - slope * sumX) / n;
      
      // Predict next month (next index)
      double nextMonthIndex = (n - 1) + 1; // Next month index
      double predictedExpense = slope * nextMonthIndex + intercept;
      
      // Ensure prediction is non-negative
      return math.max(0, predictedExpense);
    } catch (e) {
      // If any error occurs, return current expense total
      return expenseTotal;
    }
  }

  @override
  Widget build(BuildContext context) {
    double predictedNextMonthExpense = _predictNextMonthExpense();
    
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.width / 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: (incomeTotal - expenseTotal) >= 0
              ? [const Color(0xFF0D47A1), const Color(0xFF1976D2)] // Positive balance colors
              : [const Color(0xFFB71C1C), const Color(0xFFD32F2F)], // Negative balance colors
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Balance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Icon(Icons.credit_card, color: Colors.white),
              ],
            ),
            Text(
              'Rs.${(incomeTotal - expenseTotal).toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Add predicted expense information
            if (expenseHistory.isNotEmpty) ...[
              const Divider(color: Colors.white30, height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expected Spending',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '(Next Month)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Rs.${predictedNextMonthExpense.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Income (credit)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Rs.${incomeTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expenses (debit)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Rs.${expenseTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}