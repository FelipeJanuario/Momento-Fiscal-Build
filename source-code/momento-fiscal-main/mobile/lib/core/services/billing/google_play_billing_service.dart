import 'dart:convert';
import 'dart:developer';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:momentofiscal/core/models/plan_stripe.dart';
import 'package:momentofiscal/core/models/price_stripe.dart';
import 'package:momentofiscal/core/models/product_stripe.dart';
import 'package:momentofiscal/core/models/subscription.dart';
import 'package:momentofiscal/core/utilities/api_constants.dart';

const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

class GooglePlayBillingService {
  GooglePlayBillingService._();
  static final GooglePlayBillingService instance = GooglePlayBillingService._();
  
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  // Google Play product IDs - these should match your Google Play Console setup
  static const Set<String> _productIds = <String>{
    'plan_free',
    'plan_bronze', 
    'plan_prata',
    'plan_ouro',
  };

  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  
  Future<void> initialize() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      _isAvailable = false;
      throw Exception('Google Play Store não está disponível');
    }
    
    if (!kIsWeb && Platform.isAndroid) {
      // Pending purchases are enabled by default in newer versions
      // InAppPurchaseAndroidPlatformAddition.enablePendingPurchases();
    }

    _isAvailable = true;
    await _loadProducts();
    _listenToPurchaseUpdates();
  }

  Future<void> _loadProducts() async {
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_productIds);
    
    if (response.notFoundIDs.isNotEmpty) {
      log('Products not found: ${response.notFoundIDs}');
    }
    
    _products = response.productDetails;
    log('Loaded ${_products.length} products');
  }

  void _listenToPurchaseUpdates() {
    _subscription = _inAppPurchase.purchaseStream.listen(
      (List<PurchaseDetails> purchaseDetailsList) {
        _handlePurchases(purchaseDetailsList);
      },
      onDone: () => _subscription.cancel(),
      onError: (dynamic error) => log('Purchase stream error: $error'),
    );
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final PurchaseDetails purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        // Handle pending purchases
        log('Purchase pending: ${purchase.productID}');
      } else if (purchase.status == PurchaseStatus.purchased || 
                 purchase.status == PurchaseStatus.restored) {
        // Verify purchase with backend
        await _verifyPurchase(purchase);
        
        // Complete the purchase
        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        log('Purchase error: ${purchase.error}');
      }
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchase) async {
    try {
      String? token = await _secureStorage.read(key: 'token');
      
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };

      var body = json.encode({
        'product_id': purchase.productID,
        'purchase_token': purchase.verificationData.serverVerificationData,
        'purchase_id': purchase.purchaseID,
        'platform': 'google_play',
      });

      var response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/subscriptions/verify_purchase"),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        log('Purchase verified successfully');
      } else {
        log('Purchase verification failed: ${response.statusCode}');
      }
    } catch (e) {
      log('Error verifying purchase: $e');
    }
  }

  Future<void> purchaseSubscription(String productId, {required Function() onSuccess, required Function(String) onError}) async {
    if (!_isAvailable) {
      onError('Google Play Store não está disponível');
      return;
    }

    ProductDetails? product;
    try {
      product = _products.firstWhere(
        (ProductDetails product) => product.id == productId,
      );
    } catch (e) {
      onError('Produto não encontrado: $productId');
      return;
    }

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    
    try {
      bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      if (success) {
        log('Purchase initiated for: $productId');
        onSuccess();
      } else {
        onError('Falha ao iniciar a compra');
      }
    } catch (e) {
      log('Purchase error: $e');
      onError('Erro na compra: $e');
    }
  }

  // Get products from backend (to maintain compatibility with existing UI)
  Future<List<ProductStripe>> getProducts() async {
    String? token = await _secureStorage.read(key: 'token');
    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    };
    
    try {
      var response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/products"),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);
        List<ProductStripe> products = [];
        
        for (var product in responseBody['data']) {
          products.add(ProductStripe.fromJson(product));
        }
        
        products.sort((a, b) {
          int orderA = int.tryParse(a.metadata!.order!) ?? 0;
          int orderB = int.tryParse(b.metadata!.order!) ?? 0;
          return orderA.compareTo(orderB);
        });
        
        return products;
      } else {
        log("Failed to load products: ${response.body}");
        return [];
      }
    } catch (e) {
      log("Error in getProducts: $e");
      return [];
    }
  }

  Future<List<PriceStripe>?> getPriceProducts({required String idProduct}) async {
    String? token = await _secureStorage.read(key: 'token');
    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    };
    
    try {
      var response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/products/$idProduct/prices"),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);
        List<PriceStripe> prices = (responseBody['data'] as List)
            .map((item) => PriceStripe.fromJson(item))
            .toList();
        return prices;
      } else {
        log("Failed to load prices: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      log("An error occurred in getPriceProducts: $e");
      return null;
    }
  }

  Future<List<Subscription>> getIdsSubscription() async {
    String? token = await _secureStorage.read(key: 'token');
    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    };
    
    var response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/subscriptions"),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      List<Subscription> subscriptions = [];
      
      for (var subscription in responseBody['data']) {
        if (subscription['status'] == 'active') {
          subscriptions.add(Subscription.fromJson(subscription));
        }
      }
      return subscriptions;
    } else {
      throw Exception('Failed to load subscriptions');
    }
  }

  Future<List<PlanStripe>> getListSubscription() async {
    String? token = await _secureStorage.read(key: 'token');
    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    };
    
    var response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/subscriptions"),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      List<PlanStripe> plans = [];
      
      for (var subscription in responseBody['data']) {
        if (subscription['status'] == 'active') {
          plans.add(PlanStripe.fromJson(subscription['plan']));
        }
      }
      return plans;
    } else {
      throw Exception('Failed to load subscriptions');
    }
  }

  Future<Subscription?> getActiveSubscription() async {
    try {
      String? token = await _secureStorage.read(key: 'token');
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };
      
      var response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/subscriptions/current"),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);
        if (responseBody != null) {
          return Subscription.fromJson(responseBody);
        }
      }
    } catch (e, stackTrace) {
      log("Error in getActiveSubscription: $e", error: e, stackTrace: stackTrace);
    }
    return null;
  }

  Future<List<dynamic>> getEnabledFeatures() async {
    String? token = await _secureStorage.read(key: 'token');
    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    };
    
    try {
      var response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/subscriptions/enabled_features"),
        headers: headers,
      );
      
      return json.decode(response.body);
    } catch (e, stackTrace) {
      log("Error in getEnabledFeatures: $e", error: e, stackTrace: stackTrace);
    }
    return [];
  }

  Future<void> cancelSubscription({required String subscriptionId}) async {
    String? token = await _secureStorage.read(key: 'token');
    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    };
    
    try {
      await http.delete(
        Uri.parse("${ApiConstants.baseUrl}/subscriptions/$subscriptionId"),
        headers: headers,
      );
    } catch (e) {
      log('Error canceling subscription: $e');
    }
  }

  // Handle iOS subscriptions through RevenueCat (existing logic)
  Future<void> handleIOSSubscription(String productId, {required Function() onSuccess, required Function(String) onError}) async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        // final package = offerings.current!.availablePackages.firstWhere(
        //   (pkg) => pkg.storeProduct.identifier == productId,
        // );
        
        // CustomerInfo customerInfo = await Purchases.purchasePackage(package);
        // if (customerInfo.entitlements.all[ApiConstants.entitlementID]?.isActive == true) {
        //   onSuccess();
        // } else {
        //   onError('Compra não ativada');
        // }
      }
    } catch (e) {
      onError('Erro na compra iOS: $e');
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}
