import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'base_provider.dart';
import '../constants/api_constants.dart';

class PaymentProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;

  bool isLoading = false;
  String? error;
  bool paymentSuccess = false;

  PaymentProvider(this._baseProvider);

  Future<bool> processPayment(int orderId) async {
    isLoading = true;
    error = null;
    paymentSuccess = false;
    notifyListeners();

    try {
      final response = await _baseProvider.post<Map<String, dynamic>>(
        '${ApiConstants.payments}/create-intent',
        data: {'orderId': orderId},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      final clientSecret = response['clientSecret'] as String;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Spotter',
          style: ThemeMode.system,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      paymentSuccess = true;
      isLoading = false;
      notifyListeners();
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        try {
          await _baseProvider.post<void>(
            '${ApiConstants.orders}/$orderId/cancel',
            data: {},
            fromJson: (_) {},
          );
        } catch (_) {}
        error = 'Payment cancelled.';
      } else {
        error = e.error.localizedMessage ?? 'Payment failed.';
      }
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}
