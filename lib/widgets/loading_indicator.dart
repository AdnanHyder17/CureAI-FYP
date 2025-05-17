// lib/widgets/loading_indicator.dart
import 'package:flutter/material.dart';
import 'package:p1/theme.dart'; // Assuming your AppColors are defined here

class LoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color color;
  final String? message; // Optional message to display below the indicator

  const LoadingIndicator({
    super.key,
    this.size = 30.0,
    this.strokeWidth = 3.0,
    this.color = AppColors.primary,
    this.message, // Added message parameter
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // So the Column doesn't take full height
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeWidth: strokeWidth,
            ),
          ),
          if (message != null && message!.isNotEmpty) // Display message if provided
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.dark.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
