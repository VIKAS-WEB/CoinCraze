import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late Razorpay _razorpay;

  RazorpayService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Handle success (webhook will update balance)
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    throw Exception('Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet
  }

  Future<void> makePayment(String orderId, String key, double amount, String currency) async {
    var options = {
      'key': key,
      'amount': (amount * 100).toInt(),
      'currency': currency,
      'order_id': orderId,
      'name': 'Your App Name',
      'description': 'Wallet Top-up',
      'prefill': {'contact': '', 'email': ''},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      throw Exception('Payment failed: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}