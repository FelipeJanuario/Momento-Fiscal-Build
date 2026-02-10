import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:momentofiscal/core/models/consulting.dart';
import 'package:momentofiscal/core/utilities/api_constants.dart';
import 'package:http/http.dart' as http;

FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

class ConsultingRailsService {
  Future<List<Consulting>> getConsultings({
    int page = 1,
    int perPage = 10,
    Map<String, dynamic>? queryParameters,
  }) async {
    var url =
        "${ApiConstants.baseUrl}/consultings?page=$page&per_page=$perPage&ordr_by=is_favorite&sort_order=asc";

    String? token = await _secureStorage.read(key: 'token');

    if (queryParameters != null && queryParameters.isNotEmpty) {
      String queryString = Uri(
          queryParameters: queryParameters.map(
        (key, value) => MapEntry(key, value.toString()),
      )).query;
      url += "&$queryString";
    }

    var headers = {
      'Authorization': 'Bearer $token',
    };

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);

      List<Consulting> consultings = [];
      for (var consulting in responseBody['data']) {
        consultings.add(Consulting.fromJson(consulting));
      }
      return consultings;
    } else {
      throw Exception('Failed to load Consultings');
    }
  }

  Future createConsulting({
    required double debtValue,
    String? idUser,
    String? idConsultant,
    int? debtsCount,
    String? status,
  }) async {
    String url = '${ApiConstants.baseUrl}/consultings';

    String? token = await _secureStorage.read(key: 'token');
    String formattedTime =
        DateTime.now().toIso8601String().split('T')[1].split('.')[0];

    Map<String, dynamic> body = {
      "consulting": {
        "value": debtValue,
        "client_id": idUser,
        "consultant_id": idConsultant,
        "debts_count": debtsCount,
        "status": status ?? "not_started",
        "sent_at": formattedTime
      }
    };

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    var response = await http.post(Uri.parse(url),
        body: json.encode(body), headers: headers);

    return response;
  }

  Future patchConsulting({
    required String consultingId,
    required Map<String, dynamic> updatedFields,
  }) async {
    String url = '${ApiConstants.baseUrl}/consultings/$consultingId';

    String? token = await _secureStorage.read(key: 'token');

    Map<String, dynamic> body = {
      "consulting": updatedFields,
    };

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    var response = await http.patch(
      Uri.parse(url),
      body: json.encode(body),
      headers: headers,
    );

    return response;
  }

  Future delete({required String id}) async {
    var url = "${ApiConstants.baseUrl}/consultings/$id";

    String? token = await _secureStorage.read(key: 'token');

    var headers = {
      'Authorization': 'Bearer $token',
    };

    var response = await http.delete(Uri.parse(url), headers: headers);

    if (response.statusCode == 204) {
      return true;
    } else {
      return false;
    }
  }

  Future postImportHash(String hash) async {
    String url = '${ApiConstants.baseUrl}/consultings/$hash/import';

    String? token = await _secureStorage.read(key: 'token');

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    var response = await http.post(Uri.parse(url), headers: headers);

    return response;
  }
}
