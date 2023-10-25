import 'dart:async';

import 'package:flutter/services.dart';

part 'hyperpay_const.dart';

class HyperpayFlutter {
  String channelName = "hyperpay_flutter";

  HyperpayFlutter();

  static const platform = MethodChannel('hyperpay_flutter');

  static const String methodName = 'gethyperpayresponse';

  Future<String> getPlatformVersion() async {
    try {
      final String result = await platform.invokeMethod('getPlatformVersion');
      return result;
    } on PlatformException catch (e) {
      return e.message ?? 'error';
    }
  }

  /// This function allows the user to make payments using their stored cards.
  /// It accepts an argument of type StoredCards and makes a call to the implementPaymentStoredCards
  /// function with the values required for the payment.
  /// It returns a Future<PaymentResultData> which is the outcome of the payment.
  Future<String> payWithHyperPayUsingStoredPayment(
      {required String checkoutId,
      required String shopperResultUrl,
      required String merchantId,
      required String amount,
      required String tokenId,
      required String brand,
      required String cvv,
      required String mode}) async {
    try {
      final String result = await platform.invokeMethod(methodName, {
        "type": "storedPayment",
        "shopperResultUrl": shopperResultUrl,
        "merchantId": merchantId,
        "checkoutid": checkoutId,
        "mode": mode,
        "tokenId": tokenId,
        "brand": brand,
        "cvv": cvv,
      });
      return result;
    } on PlatformException catch (e) {
      return e.message ?? 'error';
    }
  }

  /// This method is used for making ApplePay payments .
  /// It takes in the required ApplePay input and returns a PaymentResultData String.
  Future<String> payWithHyperPayUsingApplePay({required String checkoutId, required String shopperResultUrl, required String merchantId, required String amount, required String mode}) async {
    try {
      final String result = await platform.invokeMethod(methodName, {
        "type": "APPLEPAY",
        "mode": mode,
        "shopperResultUrl": shopperResultUrl,
        "merchantId": merchantId,
        "checkoutid": checkoutId,
        "Amount": double.parse(amount),
      });
      return result;
    } on PlatformException catch (e) {
      return e.message ?? 'error';
    }
  }

  /// This method is used for making custom UI payments with cards.
  /// It takes in the required CustomUI input and returns a PaymentResultData String.
  Future<String> storeCardWithHyperPay(
      {required String checkoutId,
      required String shopperResultUrl,
      required String merchantId,
      required String brand,
      required String cardNumber,
      required String holderName,
      required String expiryDate,
      required String cvv,
      required String mode}) async {
    try {
      final String result = await platform.invokeMethod(methodName, {
        "type": "CustomUI",
        "mode": mode,
        "checkoutid": checkoutId,
        "shopperResultUrl": shopperResultUrl,
        "merchantId": merchantId,
        "brand": brand,
        "card_number": cardNumber.replaceAll(' ', ''),
        "holder_name": holderName,
        "month": expiryDate.split('/')[0],
        "year": '20' + expiryDate.split('/')[1],
        "cvv": cvv,
        "MadaRegexV": PaymentRegex.madaRegexV,
        "MadaRegexM": PaymentRegex.madaRegexM,
        "Amount": 1.00
      });
      return result;
    } on PlatformException catch (e) {
      return e.message ?? 'error';
    }
  }

  /// This method is used for making STCPAY payments .
  /// It takes in the required STCPAY input and returns a PaymentResultData String.
  // Future<String> payWithHyperPayUsingSTCPay({required String checkoutId, required String shopperResultUrl, required String phoneNumber, required String amount, required String mode}) async {
  //   try {
  //     final String result = await platform.invokeMethod(methodName, {
  //       "type": "STCPAY",
  //       "mode": mode,
  //       "shopperResultUrl": shopperResultUrl,
  //       "phone_number": phoneNumber,
  //       "checkoutid": checkoutId,
  //       "Amount": double.parse(amount),
  //     });
  //     return result;
  //   } on PlatformException catch (e) {
  //     return e.message ?? 'error';
  //   }
  // }
}
