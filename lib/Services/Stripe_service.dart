
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeService {
  static Future<void> init() async {
    Stripe.publishableKey = 'pk_test_51PM1NoRvs0ULQ5UtZGEPqe29jrnZrIsFUccOAFpuAt3zlGDOlUY86xRWOH0wETc0Y1O2xuLH6etdX2c0ZdLUmkfg00cvQk3Yys';
    await Stripe.instance.applySettings();
  }

  static Future<void> makePayment(String clientSecret) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Coin Craze',
        ),
      );
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      throw Exception('Payment failed: $e');
    }
  }
}