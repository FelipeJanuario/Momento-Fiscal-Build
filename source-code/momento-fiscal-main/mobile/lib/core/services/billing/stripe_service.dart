import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:momentofiscal/core/utilities/logger.dart';
import 'package:momentofiscal/core/utilities/api_constants.dart';
import 'package:momentofiscal/core/models/purchasable_product.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class StripeService {
  static final StripeService _instance = StripeService._internal();
  factory StripeService() => _instance;
  StripeService._internal();

  final _storage = const FlutterSecureStorage();

  /// Busca produtos/planos ativos do Stripe via API backend
  Future<List<PurchasableProduct>> getProducts() async {
    try {
      String? token = await _storage.read(key: 'token');
      
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };

      // Busca produtos do Stripe
      var response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/products"),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load products: ${response.statusCode}');
      }

      var data = json.decode(response.body);
      var products = data['data'] as List<dynamic>;
      
      List<PurchasableProduct> purchasableProducts = [];

      for (var product in products) {
        // Busca preços para cada produto
        var priceResponse = await http.get(
          Uri.parse("${ApiConstants.baseUrl}/products/${product['id']}/prices"),
          headers: headers,
        );

        if (priceResponse.statusCode == 200) {
          var priceData = json.decode(priceResponse.body);
          var prices = priceData['data'] as List<dynamic>;
          
          if (prices.isNotEmpty) {
            // Pega o primeiro preço ativo
            var price = prices.first;
            var unitAmount = price['unit_amount'] ?? 0;
            var rawPrice = unitAmount / 100.0;

            purchasableProducts.add(
              PurchasableProduct(
                ProductDetails(
                  id: product['id'],
                  title: product['name'] ?? 'Plano',
                  description: product['description'] ?? '',
                  price: 'R\$ ${rawPrice.toStringAsFixed(2)}',
                  rawPrice: rawPrice,
                  currencyCode: 'BRL',
                ),
                features: _extractFeatures(product['description'] ?? '')
              )
            );
          }
        }
      }

      // Ordena por preço
      purchasableProducts.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
      
      Logger.log('Loaded ${purchasableProducts.length} products from Stripe');
      return purchasableProducts;

    } catch (e) {
      Logger.log('Error loading products from Stripe: $e', level: LoggerLevel.error, error: e);
      rethrow;
    }
  }

  /// Extrai features da descrição do produto
  List<String> _extractFeatures(String description) {
    if (description.isEmpty) return [];
    
    // Split por linhas, bullets ou pontos
    return description
        .split(RegExp(r'\n+|\. |• '))
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.trim())
        .toList();
  }

  /// Cria uma sessão de checkout do Stripe
  Future<String> createCheckoutSession({
    required String priceId,
    required String customerEmail,
  }) async {
    try {
      String? token = await _storage.read(key: 'token');
      
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };

      var body = json.encode({
        'price_id': priceId,
        'customer_email': customerEmail,
      });

      var response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/subscriptions"),
        headers: headers,
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create checkout session: ${response.statusCode}');
      }

      var data = json.decode(response.body);
      return data['clientSecret'];

    } catch (e) {
      Logger.log('Error creating checkout session: $e', level: LoggerLevel.error, error: e);
      rethrow;
    }
  }

  /// Busca assinaturas ativas do usuário
  Future<List<dynamic>> getActiveSubscriptions() async {
    try {
      String? token = await _storage.read(key: 'token');
      
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };

      var response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/subscriptions"),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load subscriptions: ${response.statusCode}');
      }

      var data = json.decode(response.body);
      var subscriptions = data['data'] as List<dynamic>;
      
      // Filtra apenas assinaturas ativas
      return subscriptions.where((sub) => sub['status'] == 'active').toList();

    } catch (e) {
      Logger.log('Error loading subscriptions: $e', level: LoggerLevel.error, error: e);
      return [];
    }
  }

  /// Cancela uma assinatura
  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      String? token = await _storage.read(key: 'token');
      
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };

      var response = await http.delete(
        Uri.parse("${ApiConstants.baseUrl}/subscriptions/$subscriptionId"),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel subscription: ${response.statusCode}');
      }

      Logger.log('Subscription cancelled successfully');

    } catch (e) {
      Logger.log('Error cancelling subscription: $e', level: LoggerLevel.error, error: e);
      rethrow;
    }
  }
}
