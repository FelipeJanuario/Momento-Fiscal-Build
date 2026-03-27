import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:pay/pay.dart';
import 'package:momentofiscal/core/services/billing/stripe_service.dart';
import 'package:momentofiscal/core/models/purchasable_product.dart';
import 'package:momentofiscal/core/services/api/api_request_service.dart';
import 'package:momentofiscal/core/models/plan_stripe.dart';
import 'package:momentofiscal/core/models/price_stripe.dart';
import 'package:momentofiscal/core/models/subscription.dart';
import 'package:momentofiscal/core/utilities/logger.dart';
import 'package:momentofiscal/core/services/billing/payment_configuration.dart' as payment_configurations;

/// Service for managing in-app purchases and subscriptions
/// WEB-ONLY: Now uses Stripe for all purchases (no more mobile app stores)
class InAppPurchaseService {
  InAppPurchaseService._();

  static InAppPurchaseService? _instance;
  static InAppPurchaseService get instance => InAppPurchaseService._getOrCreateInstance();

  InAppPurchase get _inAppPurchase => InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  Future<bool> get isAvailable => _inAppPurchase.isAvailable();

  List<PurchasableProduct> products = [];
  
  Future<void> initialize() async {
    Logger.log('Initializing InAppPurchaseService');

    try {
      if (!await _inAppPurchase.isAvailable()) {
        Logger.log('Google Play Store and Apple App Store are not available', level: LoggerLevel.warning);
        return; // Stop early if not available to avoid unnecessary calls
      }

      // _listenToPurchaseUpdates();
    } catch (e) {
      Logger.log('Error initializing InAppPurchaseService: $e', level: LoggerLevel.error, error: e);
    }
  }

  static InAppPurchaseService _getOrCreateInstance() {
    _instance ??= InAppPurchaseService._();
    return _instance!;
  }

  Future<List<PurchasableProduct>> getProducts() async {
    if (products.isNotEmpty) {
      return products;
    }

    // WEB-ONLY: Always use Stripe (no more app stores)
    try {
      products = await StripeService().getProducts();
      Logger.log('Loaded ${products.length} products from Stripe');
      return products;
    } on StripeAuthException {
      rethrow;
    } catch (e) {
      Logger.log('Error fetching products from Stripe: $e', level: LoggerLevel.error, error: e);
      // Fallback to mock products on error
      products = _getMockProducts();
      Logger.log('Using ${products.length} MOCK products (Stripe unavailable)');
      return products;
    }
  }

  /// Mock products for development/testing
  List<PurchasableProduct> _getMockProducts() {
    Logger.log('Loading mock products for development/testing', level: LoggerLevel.info);

    return [
      PurchasableProduct(
        ProductDetails(
          id: 'free',
          title: 'Plano Free',
          description: 'Acesso básico por 7 dias',
          price: 'R\$ 0,00',
          rawPrice: 0.0,
          currencyCode: 'BRL',
        ),
        features: [
          'Localizar Devedores próximos',
          'Acesso básico por 7 dias',
        ]
      ),
      PurchasableProduct(
        ProductDetails(
          id: 'bronze',
          title: 'Plano Bronze',
          description: 'Funcionalidades essenciais',
          price: 'R\$ 199,99',
          rawPrice: 199.99,
          currencyCode: 'BRL',
        ),
        features: [
          'Tudo do Plano Free',
          'Consultar Devedores (CPF/CNPJ)',
          'Consultar Processos Judiciais',
          'Suporte por e-mail',
        ]
      ),
      PurchasableProduct(
        ProductDetails(
            id: 'prata',
            title: 'Plano Prata',
            description: 'Recursos avançados',
            price: 'R\$ 399,90',
            rawPrice: 399.90,
            currencyCode: 'BRL',
          ),
          features: [
            'Tudo do Plano Bronze',
            'Consulta por Município',
            'Análise Processual detalhada',
            'Suporte prioritário',
          ]
        ),
      PurchasableProduct(
        ProductDetails(
          id: 'ouro',
          title: 'Plano Ouro',
          description: 'Recursos completos',
          price: 'R\$ 599,90',
          rawPrice: 599.90,
          currencyCode: 'BRL',
        ),
        features: [
          'Tudo do Plano Prata',
          'Gestão de Consultoria',
          'Consultoria personalizada',
          'Acesso antecipado a novos recursos',
          'Suporte 24/7',
        ]
      ),
    ];
  }

  Future<Subscription?> getActiveSubscription() async {
    Logger.log('getActiveSubscription called');
    try {
      final currentSub = await StripeService().getCurrentSubscription();
      if (currentSub == null) return null;
      return Subscription(
        id: currentSub['id'] ?? '',
        subsId: currentSub['items']?['data']?[0]?['id'] ?? '',
        amount: currentSub['items']?['data']?[0]?['price']?['unit_amount_decimal']?.toString(),
      );
    } catch (e) {
      Logger.log('Error getting active subscription: $e', level: LoggerLevel.error, error: e);
      return null;
    }
  }

  Future<List<String>> getEnabledFeatures() async {
    Logger.log('getEnabledFeatures called');
    try {
      return await StripeService().getEnabledFeatures();
    } catch (e) {
      Logger.log('Error getting enabled features: $e', level: LoggerLevel.error, error: e);
      return [];
    }
  }

  Future<List<PlanStripe>> getListSubscription() async {
    Logger.log('getListSubscription called');
    try {
      final subs = await StripeService().getActiveSubscriptions();
      return subs.map((sub) => PlanStripe(
        id: sub['id'] ?? '',
        product: sub['items']?['data']?[0]?['price']?['product'] ?? '',
      )).toList();
    } catch (e) {
      Logger.log('Error getting subscriptions list: $e', level: LoggerLevel.error, error: e);
      return [];
    }
  }

  Future<List<PriceStripe>> getPriceProducts({required String idProduct}) async {
    Logger.log('getPriceProducts called for product: $idProduct');
    try {
      final prices = await StripeService().getPrices(idProduct);
      return prices.map((price) => PriceStripe.fromJson(price)).toList();
    } catch (e) {
      Logger.log('Error getting product prices: $e', level: LoggerLevel.error, error: e);
      return [];
    }
  }

  Future<List<Subscription>> getIdsSubscription() async {
    Logger.log('getIdsSubscription called');
    try {
      final subs = await StripeService().getActiveSubscriptions();
      return subs.map((sub) => Subscription(
        id: sub['id'] ?? '',
        subsId: sub['items']?['data']?[0]?['id'] ?? '',
        amount: sub['items']?['data']?[0]?['price']?['unit_amount_decimal']?.toString(),
      )).toList();
    } catch (e) {
      Logger.log('Error getting subscription IDs: $e', level: LoggerLevel.error, error: e);
      return [];
    }
  }

  Future<void> cancelSubscription({required String subscriptionId}) async {
    Logger.log('cancelSubscription called for ID: $subscriptionId');
    try {
      await StripeService().cancelSubscription(subscriptionId);
      Logger.log('Subscription $subscriptionId cancelled successfully');
    } catch (e) {
      Logger.log('Error cancelling subscription: $e', level: LoggerLevel.error, error: e);
      rethrow;
    }
  }

  Pay get _paymentClient => Pay({
    PayProvider.google_pay: payment_configurations.defaultGooglePayConfig,
    PayProvider.apple_pay: payment_configurations.defaultApplePayConfig,
  });

  void _listenToPurchaseUpdates({required String productID, required Function() onSuccess, required Function(String) onError}) {
    final eventChannel = EventChannel('plugins.flutter.io/pay/payment_result');
    StreamSubscription<Map<String, dynamic>>? paymentResultSubscription;
    paymentResultSubscription = eventChannel
        .receiveBroadcastStream()
        .map((result) => jsonDecode(result as String) as Map<String, dynamic>)
        .listen((result) {
          _handlePurchases(result, productID: productID, onSuccess: onSuccess, onError: onError);
        }, onError: (error) {
          Logger.log('Payment error via Pay: $error', level: LoggerLevel.error, error: error);
          onError('Payment error via Pay: $error');
        }, onDone: () {
          Logger.log('Payment result stream closed');
          paymentResultSubscription?.cancel();
          paymentResultSubscription = null;
        });
  }

  Future<void> _handlePurchases(Map<String, dynamic> purchaseData, {required String productID, required Function() onSuccess, required Function(String) onError}) async {
    Logger.log('Handling purchases: ${jsonEncode(purchaseData)}');

    final purchaseToken = purchaseData['paymentMethodData']['tokenizationData']['token'];
    final acknowledged = await _acknowledgeSubscription(productID, purchaseToken);

    if(acknowledged) {
      Logger.log('Purchase processed successfully: $productID');
      onSuccess();
    } else {
      Logger.log('Purchase acknowledgment failed: $productID', level: LoggerLevel.error);
      onError('Purchase acknowledgment failed');
      throw Exception('Purchase acknowledgment failed');
    }
  }

  Future<bool> _acknowledgeSubscription(String productID, String purchaseToken) async {
    try {
      if (kIsWeb || !Platform.isAndroid) return false;

      var response = await ApiRequestService.instance.post(
        'google/acknowledge_subscription',
        {
          'subscription_id': productID,
          'purchase_token': purchaseToken,
        },
      );

      if (response.statusCode == 200) {
        Logger.log('Purchase acknowledged successfully');
        return true;
      } else {
        Logger.log('Purchase acknowledgment failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
     Logger.log('Error verifying purchase: $e');
      return false;
    }
  }

  Future<void> purchaseSubscription(PurchasableProduct product, {required Function() onSuccess, required Function(String) onError}) async {
    // Free plans don't require payment flow
    if ((product.rawPrice) == 0 || product.productDetails.price == 'R\$ 0,00') {
      Logger.log('Free plan selected, skipping payment flow: ${product.title} (${product.id})');
      onSuccess();
      return;
    }

    try {
      _listenToPurchaseUpdates(productID: product.id, onSuccess: onSuccess, onError: onError);

      Logger.log('Opening Pay sheet for: ${product.title} (${product.id}) - ${product.rawPrice.toStringAsFixed(2)}');
      final provider = (!kIsWeb && Platform.isIOS) ? PayProvider.apple_pay : PayProvider.google_pay;
      final result = await _paymentClient.showPaymentSelector(provider, [product.toPaymentItem()]);

      // The result contains a payment token or payment method details. You should send it to your backend
      // to complete/attach the subscription (e.g., via Stripe). For now, we only log and call onSuccess.
      Logger.log('Payment authorized via Pay. Result: $result');
    } catch (e) {
      // Typical errors: missing/invalid assets configuration, user cancellation, or platform limitations
      final message = 'Erro no pagamento: $e';
      Logger.log(message, level: LoggerLevel.error, error: e);
      onError(message);
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}
