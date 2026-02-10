import 'dart:convert';
import 'dart:typed_data';

import 'package:momentofiscal/core/models/restfull_model.dart';
import 'package:momentofiscal/core/utilities/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:momentofiscal/core/services/storage/storage_service.dart';

class ConsultingProposal extends RestfullModel {
  // static String get endpoint => '/api/v1/consulting_proposals';
  // static const String _endpoint = '/';

  @override
  String get baseUrl => ApiConstants.url;
  @override
  String get endpoint => '/api/v1/consulting_proposals/';
  @override
  String get url => '$baseUrl$endpoint';

  String? consultingId;
  late List<String> services;
  String? description;
  String? comment;
  DateTime? createdAt;
  DateTime? updatedAt;

  ConsultingProposal({
    super.id,
    this.consultingId,
    services,
    this.description,
    this.comment,
    this.createdAt,
    this.updatedAt,
  }) {
    this.services = services ?? [];
  }

  @override
  void fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    consultingId = json['consulting_id'].toString();
    services = json['services']?.map<String>((item) => item.toString()).toList() ?? [];
    description = json['description'];
    comment = json['comment'];
    createdAt = DateTime.parse(json['created_at']);
    updatedAt = DateTime.parse(json['updated_at']);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'consulting_id': consultingId,
      'services': services,
      'description': description,
      'comment': comment,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Future<ConsultingProposal?> getConsultingProposal({
    Map<String, dynamic>? queryParameters,
  }) async {
    var url = "${ApiConstants.baseUrl}/consulting_proposals";

    String? token = await storage.read(key: 'token');

    if (queryParameters != null && queryParameters.isNotEmpty) {
      String queryString = Uri(
          queryParameters: queryParameters.map(
        (key, value) => MapEntry(key, value.toString()),
      )).query;
      url += "?$queryString";
    }

    var headers = {
      'Authorization': 'Bearer $token',
    };

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);

      if (responseBody is List && responseBody.isNotEmpty) {
        var proposal = ConsultingProposal();
        proposal.fromJson(responseBody.first);
        return proposal;
      }
    }

    throw Exception('Erro ao buscar a proposta');
  }

  Future<Uint8List> fetchPDF() async {
    var url = "${ApiConstants.baseUrl}/consulting_proposals/$id.pdf";

    String? token = await storage.read(key: 'token');

    var headers = {
      'Authorization': 'Bearer $token',
    };

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.bodyBytes;
    } else {
      throw Exception('Erro ao buscar o PDF da proposta');
    }
  }
}
