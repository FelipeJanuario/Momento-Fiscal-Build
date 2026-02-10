class ProductStripe {
  String id;
  String object;
  bool active;
  List<dynamic> attributes;
  int created;
  String? defaultPrice;
  String? description;
  List<dynamic> images;
  bool livemode;
  List<dynamic> marketingFeatures;
  Metadata? metadata;
  String name;
  dynamic packageDimensions;
  dynamic shippable;
  dynamic statementDescriptor;
  dynamic taxCode;
  String type;
  dynamic unitLabel;
  int updated;
  dynamic url;

  ProductStripe({
    required this.id,
    required this.object,
    required this.active,
    required this.attributes,
    required this.created,
    this.defaultPrice,
    this.description,
    required this.images,
    required this.livemode,
    required this.marketingFeatures,
    required this.metadata,
    required this.name,
    this.packageDimensions,
    this.shippable,
    this.statementDescriptor,
    this.taxCode,
    required this.type,
    this.unitLabel,
    required this.updated,
    this.url,
  });

  factory ProductStripe.fromJson(Map<String, dynamic> json) {
    return ProductStripe(
      id: json['id'],
      object: json['object'],
      active: json['active'],
      attributes: List<dynamic>.from(json['attributes']),
      created: json['created'],
      defaultPrice: json['default_price'],
      description: json['description'],
      images: List<dynamic>.from(json['images']),
      livemode: json['livemode'],
      marketingFeatures: List<dynamic>.from(json['marketing_features']),
      metadata: Metadata.fromJson(json['metadata']),
      name: json['name'],
      packageDimensions: json['package_dimensions'],
      shippable: json['shippable'],
      statementDescriptor: json['statement_descriptor'],
      taxCode: json['tax_code'],
      type: json['type'],
      unitLabel: json['unit_label'],
      updated: json['updated'],
      url: json['url'],
    );
  }
}

class Metadata {
  String? order;
  String? featureText;
  String? textOne;
  String? textTwo;
  String? textThree;
  String? textFour;
  String? textFive;
  String? textSix;
  String? textSeven;
  String? highlight;
  String? highlightMessage;
  String? cardDescription;
  String? sucessMessage;
  String? isFree;

  Metadata({
    this.order,
    this.featureText,
    this.textOne,
    this.textTwo,
    this.textThree,
    this.textFour,
    this.textFive,
    this.textSix,
    this.textSeven,
    this.highlight,
    this.highlightMessage,
    this.cardDescription,
    this.sucessMessage,
    this.isFree,
  });

  factory Metadata.fromJson(Map<String, dynamic> json) {
    return Metadata(
      order: json['order'],
      featureText: json['features_title'],
      textOne: json['text_one'],
      textTwo: json['text_two'],
      textThree: json['text_tree'],
      textFour: json['text_four'] ?? '',
      textFive: json['text_five'] ?? '',
      textSix: json['text_six'] ?? '',
      textSeven: json['text_seven'] ?? '',
      highlight: json['highlight'] ?? '',
      highlightMessage: json['highlight_message'] ?? '',
      cardDescription: json['card_description'] ?? '',
      sucessMessage: json['sucess_message'],
      isFree: json['is_free'],
    );
  }
}
