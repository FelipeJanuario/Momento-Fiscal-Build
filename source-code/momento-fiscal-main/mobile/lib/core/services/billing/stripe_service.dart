import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:momentofiscal/core/services/storage/storage_service.dart';
import 'package:momentofiscal/core/utilities/logger.dart';
import 'package:momentofiscal/core/utilities/api_constants.dart';
import 'package:momentofiscal/core/models/purchasable_product.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class StripeAuthException implements Exception {
  final String message;
  StripeAuthException([this.message = 'Sessão expirada. Faça login novamente.']);
  @override
  String toString() => message;
}

class StripeService {
  static final StripeService _instance = StripeService._internal();
  factory StripeService() => _instance;
  StripeService._internal();

  /// Retorna headers com o token de autenticação. Lança [StripeAuthException] se
  /// o token não estiver disponível no storage.
  Future<Map<String, String>> _authHeaders() async {
    final token = await storage.read(key: 'token');
    if (token == null) {
      throw StripeAuthException();
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Verifica se a resposta indica sessão inválida e lança [StripeAuthException].
  void _checkUnauthorized(int statusCode) {
    if (statusCode == 401) throw StripeAuthException();
  }

  /// Busca produtos/planos ativos do Stripe via API backend
  Future<List<PurchasableProduct>> getProducts() async {
    try {
      var headers = await _authHeaders();

      // Busca produtos do Stripe
      var response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/stripe/products"),
        headers: headers,
      );

      _checkUnauthorized(response.statusCode);
      if (response.statusCode != 200) {
        throw Exception('Failed to load products: ${response.statusCode}');
      }

      var data = json.decode(response.body);
      var products = data['data'] as List<dynamic>;
      
      List<PurchasableProduct> purchasableProducts = [];

      for (var product in products) {
        // Busca preços para cada produto
        var priceResponse = await http.get(
          Uri.parse("${ApiConstants.baseUrl}/stripe/products/${product['id']}/prices"),
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

            final metadata = (product['metadata'] as Map<String, dynamic>?) ?? {};
            final featuresFromMeta = _extractFeaturesFromMetadata(metadata);
            final rawDescription = (metadata['card_description'] ?? metadata['features_title'] ?? product['description'] ?? '').toString().trim();
            final productName = (product['name'] ?? '').toString();
            final description = rawDescription.isNotEmpty ? rawDescription : _getFallbackDescription(productName);

            purchasableProducts.add(
              PurchasableProduct(
                ProductDetails(
                  id: price['id'],
                  title: productName,
                  description: description,
                  price: 'R\$ ${rawPrice.toStringAsFixed(2)}',
                  rawPrice: rawPrice,
                  currencyCode: 'BRL',
                ),
                features: featuresFromMeta.isNotEmpty
                    ? featuresFromMeta
                    : _extractFeatures(product['description'] ?? '').isNotEmpty
                        ? _extractFeatures(product['description'] ?? '')
                        : _getFallbackFeatures(productName),
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

  /// Retorna descrição padrão por nome do plano
  String _getFallbackDescription(String productName) {
    final name = productName.toLowerCase();
    if (name.contains('ouro')) return 'Recursos completos para sua operação';
    if (name.contains('prata')) return 'Recursos avançados com suporte prioritário';
    if (name.contains('bronze')) return 'Funcionalidades essenciais para começar';
    if (name.contains('free') || name.contains('grátis') || name.contains('gratuito')) return 'Experimente grátis por 7 dias';
    return '';
  }

  /// Retorna features padrão por nome do plano quando o Stripe não tem metadata
  List<String> _getFallbackFeatures(String productName) {
    final name = productName.toLowerCase();
    if (name.contains('ouro')) {
      return [
        'Tudo do Plano Prata',
        'Gestão de Consultoria',
        'Consultoria personalizada',
        'Acesso antecipado a novos recursos',
        'Suporte 24/7',
      ];
    }
    if (name.contains('prata')) {
      return [
        'Tudo do Plano Bronze',
        'Consulta por Município',
        'Análise Processual detalhada',
        'Suporte prioritário',
      ];
    }
    if (name.contains('bronze')) {
      return [
        'Localizar Devedores próximos',
        'Consultar Devedores (CPF/CNPJ)',
        'Consultar Processos Judiciais',
        'Suporte por e-mail',
      ];
    }
    if (name.contains('free') || name.contains('grátis') || name.contains('gratuito')) {
      return [
        'Localizar Devedores próximos',
        'Acesso básico por 7 dias',
      ];
    }
    return [];
  }

  /// Extrai features dos metadados Stripe (text_one..text_seven)
  List<String> _extractFeaturesFromMetadata(Map<String, dynamic> metadata) {
    const keys = ['text_one', 'text_two', 'text_tree', 'text_four', 'text_five', 'text_six', 'text_seven'];
    return keys
        .map((k) => (metadata[k] ?? '').toString().trim())
        .where((v) => v.isNotEmpty)
        .toList();
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

  /// Cria uma sessão de checkout hospedada do Stripe e retorna a URL
  Future<String> createCheckoutSession({
    required String priceId,
    required String customerEmail,
    String? successUrl,
  }) async {
    try {
      var headers = await _authHeaders();

      final bodyMap = <String, String>{
        'price_id': priceId,
        'customer_email': customerEmail,
        if (successUrl != null) 'success_url': successUrl,
      };
      var body = json.encode(bodyMap);

      var response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/stripe/checkout_session"),
        headers: headers,
        body: body,
      );

      _checkUnauthorized(response.statusCode);
      if (response.statusCode != 200) {
        throw Exception('Failed to create checkout session: ${response.statusCode}');
      }

      var data = json.decode(response.body);
      return data['checkout_url'];

    } catch (e) {
      Logger.log('Error creating checkout session: $e', level: LoggerLevel.error, error: e);
      rethrow;
    }
  }

  /// Busca assinaturas ativas do usuário
  Future<List<dynamic>> getActiveSubscriptions() async {
    try {
      var headers = await _authHeaders();

      var response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/stripe/subscriptions"),
        headers: headers,
      );

      _checkUnauthorized(response.statusCode);
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
      var headers = await _authHeaders();

      var response = await http.delete(
        Uri.parse("${ApiConstants.baseUrl}/stripe/subscriptions/$subscriptionId"),
        headers: headers,
      );

      _checkUnauthorized(response.statusCode);
      if (response.statusCode != 200) {
        throw Exception('Failed to cancel subscription: ${response.statusCode}');
      }

      Logger.log('Subscription cancelled successfully');

    } catch (e) {
      Logger.log('Error cancelling subscription: $e', level: LoggerLevel.error, error: e);
      rethrow;
    }
  }

  /// Busca features habilitadas para o usuário (entitlements Stripe)
  Future<List<String>> getEnabledFeatures() async {
    try {
      var headers = await _authHeaders();

      var response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/stripe/enabled_features"),
        headers: headers,
      );

      _checkUnauthorized(response.statusCode);
      if (response.statusCode != 200) {
        throw Exception('Failed to load features: ${response.statusCode}');
      }

      var data = json.decode(response.body) as List<dynamic>;
      return data.map((e) => e.toString()).toList();

    } catch (e) {
      Logger.log('Error loading enabled features: $e', level: LoggerLevel.error, error: e);
      return [];
    }
  }

  /// Busca preços para um produto específico
  Future<List<dynamic>> getPrices(String productId) async {
    try {
      var headers = await _authHeaders();

      var response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/stripe/products/$productId/prices"),
        headers: headers,
      );

      _checkUnauthorized(response.statusCode);
      if (response.statusCode != 200) {
        throw Exception('Failed to load prices: ${response.statusCode}');
      }

      var data = json.decode(response.body);
      return data['data'] as List<dynamic>;

    } catch (e) {
      Logger.log('Error loading prices: $e', level: LoggerLevel.error, error: e);
      return [];
    }
  }

  /// Busca a assinatura corrente do usuário
  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    try {
      var headers = await _authHeaders();

      var response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/stripe/current_subscription"),
        headers: headers,
      );

      if (response.statusCode == 401) throw StripeAuthException();
      if (response.statusCode != 200) {
        return null;
      }

      var data = json.decode(response.body);
      if (data == null || (data is Map && data.isEmpty)) return null;
      return data as Map<String, dynamic>;

    } catch (e) {
      Logger.log('Error loading current subscription: $e', level: LoggerLevel.error, error: e);
      return null;
    }
  }
}
