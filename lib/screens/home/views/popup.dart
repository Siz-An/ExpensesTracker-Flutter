import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../stats/limitsetter.dart';

class LimitExceededPopup {
  static void show(BuildContext context, String note, int amount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Limit Exceeded'),
          content: Text('Expense of amount \Rs.${amount} with exceeds the set limit.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); //Close the pop-up
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

// New popup for category limit exceeded
class CategoryLimitExceededPopup {
  static void show(BuildContext context, String category, double categoryTotal, int limit) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Category Limit Exceeded'),
          content: Text(
              'Your expenses in the "$category" category (Rs.${categoryTotal.toInt()}) '
              'have exceeded the set limit of Rs.$limit.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to limit setter screen using GetX
                Get.to(() => const LimitSetter());
              },
              child: const Text('Adjust Limit'),
            ),
          ],
        );
      },
    );
  }
}