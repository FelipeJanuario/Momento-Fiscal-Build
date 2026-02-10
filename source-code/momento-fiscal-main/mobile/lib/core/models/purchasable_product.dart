import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:pay/pay.dart';

enum ProductStatus { purchasable, purchased, pending }

class PurchasableProduct {
  String get id => productDetails.id;
  String get title => productDetails.title;
  String get description => productDetails.description;
  // List<String> get details => productDetails.description.split(RegExp(r'\n+|\. '));
  String get price => productDetails.price;
  double get rawPrice => productDetails.rawPrice;
  bool get isFree => rawPrice == 0.0;
  ProductStatus status;
  ProductDetails productDetails;

  List<String> features;

  PurchasableProduct(this.productDetails, { List<String>? features }) :
    status = ProductStatus.purchasable,
    features = features ?? productDetails.description.split(RegExp(r'\n+|\. '));

  // Constructor to create from Google Play monetization.subscriptions API data
  factory PurchasableProduct.fromGoogleApiData(dynamic apiData) {
    final listing = (apiData['listings'] as List<dynamic>?)?.firstWhere(
      (listing) => listing['language'] == 'pt-BR',
      orElse: () => apiData['listings'][0],
    );

    final basePlan = (apiData['base_plans'] as List<dynamic>?)?.firstWhere(
      (plan) => ['base', 'default', 'standard'].contains(plan['basePlanId']),
      orElse: () => apiData['base_plans']?[0],
    );

    final regionalConfig = (basePlan?['regional_configs'] as List<dynamic>?)?.firstWhere(
      (config) => config['region_code'] == 'BR' && config['state'] == 'ACTIVE',
      orElse: () => basePlan?['regional_configs']?[0],
    );

    final price = double.tryParse('${regionalConfig?['price']?['units'] ?? '0'}.${regionalConfig?['price']?['nanos'] ?? '00'}') ?? 0.0;

    return PurchasableProduct(
      ProductDetails(
        id: apiData['product_id'] ?? '',
        title: listing?['title'] ?? '',
        description: listing?['description'] ?? '',
        price: 'R\$${price.toStringAsFixed(2)}',
        rawPrice: price,
        currencyCode: regionalConfig?['region_code'] ?? 'USD',
      ),
      features: (listing?['benefits'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  PaymentItem toPaymentItem() {
    return PaymentItem(
      label: title,
      amount: rawPrice.toStringAsFixed(2),
      status: PaymentItemStatus.final_price,
    );
  }
}
