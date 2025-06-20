import 'package:coincraze/Constants/Colors.dart';
import 'package:flutter/material.dart';

class BankDetailsScreen extends StatelessWidget {
  const BankDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'KYC Verification',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey.shade100,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator with Line
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStep(context, "Personal info", true, 1),
                Expanded(child: _buildProgressLine(1.0)),
                _buildStep(context, "ID proof", true, 2),
                Expanded(child: _buildProgressLine(1.0)),
                _buildStep(context, "Bank details", true, 3),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'BANK DETAILS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            // Bank Name Field
            _buildTextField('BANK NAME', 'Enter your bank name'),
            const SizedBox(height: 15),
            // Account Number Field
            _buildTextField('ACCOUNT NUMBER', 'Enter your account number'),
            const SizedBox(height: 15),
            // IFSC Code Field
            _buildTextField('IFSC CODE', 'Enter your IFSC code'),
            const SizedBox(height: 30),
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle KYC submission
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('KYC Submitted Successfully!')),
                  );
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black ?? const Color.fromARGB(255, 11, 11, 11),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 15),
            // I'll do it later Button
            Center(
              child: TextButton(
                onPressed: () {},
                child: Text(
                  "I'LL DO IT LATER",
                  style: TextStyle(
                    color: AppColors.black ?? Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, String title, bool isActive, int stepNumber) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isActive ? (AppColors.black ?? Colors.green) : Colors.grey.shade300,
          child: isActive
              ? const Icon(Icons.check, color: Colors.white, size: 24)
              : Text(
                  stepNumber.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.grey.shade300,
        color: AppColors.black ?? Colors.green,
        minHeight: 3,
      ),
    );
  }

  Widget _buildTextField(String label, String hint) {
    return TextField(
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
    );
  }
}