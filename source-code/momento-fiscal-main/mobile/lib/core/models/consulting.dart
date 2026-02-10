import 'dart:convert';
import 'package:momentofiscal/core/models/restfull_model.dart';
import 'package:momentofiscal/core/utilities/api_constants.dart';

class Consulting extends RestfullModel {
  @override
  String get baseUrl => ApiConstants.url;
  @override
  String get endpoint => '/api/v1/consultings';
  @override
  String get url => '$baseUrl$endpoint';

  late String? status;
  late String? clientId;
  late String? consultantId;
  late String? clientName;
  late String? consultantName;
  late bool isFavorite;
  late double? limitDebt;
  late DateTime? sentAt;
  late DateTime? createdAt;
  late String? importHash;

  Consulting({
    String? id,
    this.clientId,
    this.consultantId,
    this.clientName,
    this.consultantName,
    isFavorite,
    this.status,
    this.limitDebt,
    this.sentAt,
    this.createdAt,
    this.importHash,
  }) {
    super.id = id;
    this.isFavorite = isFavorite || false;
  }

  Consulting.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    clientId = json['client']?['id'];
    consultantId = json['consultant_id'];
    clientName = json['client']?['name'];
    consultantName = json['consultant']?['name'];
    status = json['status'];
    isFavorite = json['is_favorite'] ?? false;
    limitDebt = double.parse(json['value']);
    sentAt = DateTime.parse(json['sent_at']);
    createdAt = DateTime.parse(json['created_at']);
    importHash = json['import_hash'];
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'consultant_id': consultantId,
      'status': status,
      'is_favorite': isFavorite,
      'value': limitDebt,
      'sent_at': sentAt,
      'created_at': createdAt,
      'import_hash': importHash
    };
  }

  static Future<List<Consulting>> list({
    int page = 1,
    int perPage = 10,
    Map<String, dynamic>? queryParameters,
  }) async {
    var response = await Consulting().get(
      body: {
        "page": page.toString(),
        "perPage": perPage.toString(),
        "query": json.encode(queryParameters ?? {}),
      },
    );

    List<Consulting> list = [];
    for (var item in response['data']) {
      if (item['id'] == null) continue;

      Consulting consulting = Consulting();
      consulting.fromJson(item);
      list.add(consulting);
    }
    return list;
  }
}
