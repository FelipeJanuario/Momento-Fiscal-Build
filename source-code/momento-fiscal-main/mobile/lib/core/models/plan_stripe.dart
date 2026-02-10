class PlanStripe {
  final String? id;
  // final String? object;
  // final bool? active;
  // final int? amount;
  // final String? amountDecimal;
  // final int? created;
  // final String? currency;
  // final String? interval;
  // final int? intervalCount;
  // final bool? livemode;
  // final Map<String, dynamic>? metadata;
  // final String? meter;
  // final String? nickname;
  final String? product;
  // final String? tiersMode;
  // final String? transformUsage;
  // final int? trialPeriodDays;
  // final String? usageType;

  PlanStripe({
    this.id,
    // this.object,
    // this.active,
    // this.amount,
    // this.amountDecimal,
    // this.created,
    // this.currency,
    // this.interval,
    // this.intervalCount,
    // this.livemode,
    // this.metadata,
    // this.meter,
    // this.nickname,
    this.product,
    // this.tiersMode,
    // this.transformUsage,
    // this.trialPeriodDays,
    // this.usageType,
  });

  // Método para criar uma instância de PlanStripe a partir de um Map
  factory PlanStripe.fromJson(Map<String, dynamic> json) {
    return PlanStripe(
      id: json['id'] as String?,
      // object: json['object'] as String?,
      // active: json['active'] as bool?,
      // amount: json['amount'] as int?,
      // amountDecimal: json['amount_decimal']?.toString(),
      // created: json['created'] as int?,
      // currency: json['currency'] as String?,
      // interval: json['interval'] as String?,
      // intervalCount: json['interval_count'] as int?,
      // livemode: json['livemode'] as bool?,
      // metadata: json['metadata'] as Map<String, dynamic>?,
      // meter: json['meter'] as String?,
      // nickname: json['nickname'] as String?,
      product: json['product'] as String?,
      // tiersMode: json['tiers_mode'] as String?,
      // transformUsage: json['transform_usage'] as String?,
      // trialPeriodDays: json['trial_period_days'] as int?,
      // usageType: json['usage_type'] as String?,
    );
  }

  // Método para converter uma instância de PlanStripe em um Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      // 'object': object,
      // 'active': active,
      // 'amount': amount,
      // 'amount_decimal': amountDecimal,
      // 'created': created,
      // 'currency': currency,
      // 'interval': interval,
      // 'interval_count': intervalCount,
      // 'livemode': livemode,
      // 'metadata': metadata,
      // 'meter': meter,
      // 'nickname': nickname,
      'product': product,
      // 'tiers_mode': tiersMode,
      // 'transform_usage': transformUsage,
      // 'trial_period_days': trialPeriodDays,
      // 'usage_type': usageType,
    };
  }
}
