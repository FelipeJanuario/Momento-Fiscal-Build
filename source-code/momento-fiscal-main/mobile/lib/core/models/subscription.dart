class Subscription {
  String? id;
  String? subsId;
  String? amount;

  Subscription({required this.id, required this.subsId, required this.amount});

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      subsId: json['items']['data'][0]['id'],
      amount: json['items']['data'][0]['plan']['amount_decimal'],
    );
  }
}
