class PriceStripe {
  String id;
  String object;
  bool active;
  String billingScheme;
  int created;
  String currency;
  dynamic customUnitAmount;
  bool livemode;
  dynamic lookupKey;
  Map<String, dynamic> metadata;
  String? nickname;
  String product;
  Recurring recurring;
  String taxBehavior;
  dynamic tiersMode;
  dynamic transformQuantity;
  String type;
  int unitAmount;
  String unitAmountDecimal;

  PriceStripe({
    required this.id,
    required this.object,
    required this.active,
    required this.billingScheme,
    required this.created,
    required this.currency,
    this.customUnitAmount,
    required this.livemode,
    this.lookupKey,
    required this.metadata,
    this.nickname,
    required this.product,
    required this.recurring,
    required this.taxBehavior,
    this.tiersMode,
    this.transformQuantity,
    required this.type,
    required this.unitAmount,
    required this.unitAmountDecimal,
  });

  factory PriceStripe.fromJson(Map<String, dynamic> json) {
    return PriceStripe(
      id: json['id'],
      object: json['object'],
      active: json['active'],
      billingScheme: json['billing_scheme'],
      created: json['created'],
      currency: json['currency'],
      customUnitAmount: json['custom_unit_amount'],
      livemode: json['livemode'],
      lookupKey: json['lookup_key'],
      metadata: json['metadata'] ?? {},
      nickname: json['nickname'],
      product: json['product'],
      recurring: Recurring.fromJson(json['recurring']),
      taxBehavior: json['tax_behavior'],
      tiersMode: json['tiers_mode'],
      transformQuantity: json['transform_quantity'],
      type: json['type'],
      unitAmount: json['unit_amount'],
      unitAmountDecimal: json['unit_amount_decimal'],
    );
  }
}

class Recurring {
  dynamic aggregateUsage;
  String interval;
  int intervalCount;
  dynamic meter;
  dynamic trialPeriodDays;
  String usageType;

  Recurring({
    this.aggregateUsage,
    required this.interval,
    required this.intervalCount,
    this.meter,
    this.trialPeriodDays,
    required this.usageType,
  });

  factory Recurring.fromJson(Map<String, dynamic> json) {
    return Recurring(
      aggregateUsage: json['aggregate_usage'],
      interval: json['interval'],
      intervalCount: json['interval_count'],
      meter: json['meter'],
      trialPeriodDays: json['trial_period_days'],
      usageType: json['usage_type'],
    );
  }
}

class PriceStripeList {
  String object;
  List<PriceStripe> data;
  bool hasMore;
  String url;

  PriceStripeList({
    required this.object,
    required this.data,
    required this.hasMore,
    required this.url,
  });

  factory PriceStripeList.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List;
    List<PriceStripe> priceList =
        dataList.map((i) => PriceStripe.fromJson(i)).toList();

    return PriceStripeList(
      object: json['object'],
      data: priceList,
      hasMore: json['has_more'],
      url: json['url'],
    );
  }
}
