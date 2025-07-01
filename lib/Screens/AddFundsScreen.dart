import 'package:coincraze/Services/RazorpayService.dart';
import 'package:coincraze/Services/Stripe_service.dart';
import 'package:coincraze/Services/api_service.dart';
import 'package:flutter/material.dart';

class AddFundsScreen extends StatefulWidget {
  final String userId;
  final String currency;

  AddFundsScreen({required this.userId, required this.currency});

  @override
  _AddFundsScreenState createState() => _AddFundsScreenState();
}

class _AddFundsScreenState extends State<AddFundsScreen> {
  final _amountController = TextEditingController();
  String _paymentMethod = 'stripe';

  @override
  void initState() {
    super.initState();
    StripeService.init();
  }

  Future<void> _addFunds() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid amount')));
      return;
    }

    try {
      if (_paymentMethod == 'stripe') {
        final response = await ApiService().initiateStripePayment(widget.userId, amount, widget.currency);
        await StripeService.makePayment(response['clientSecret']);
      } else {
        final response = await ApiService().initiateRazorpayPayment(widget.userId, amount, widget.currency);
        final razorpay = RazorpayService();
        await razorpay.makePayment(response['orderId'], response['key'], amount, widget.currency);
        razorpay.dispose();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment initiated')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Funds')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Amount (${widget.currency})'),
            ),
            DropdownButton<String>(
              value: _paymentMethod,
              items: [
                DropdownMenuItem(value: 'stripe', child: Text('Stripe (Card)')),
                DropdownMenuItem(value: 'razorpay', child: Text('Razorpay (UPI/Card)')),
              ],
              onChanged: (value) {
                setState(() {
                  _paymentMethod = value!;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addFunds,
              child: Text('Add Funds'),
            ),
          ],
        ),
      ),
    );
  }
}