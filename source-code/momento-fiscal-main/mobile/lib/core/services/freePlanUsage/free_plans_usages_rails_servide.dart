import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:momentofiscal/core/utilities/api_constants.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';

class FreePlansUsagesRailsService {
  Future<http.Response> createFreePlanUsage(
      {required String userId, String? status}) async {
    Map<String, dynamic> params = {
      "free_plan_usage": {"user_id": userId, "status": status ?? 'active'}
    };

    String? token = await storage.read(key: 'token');

    var url = '${ApiConstants.baseUrl}/free_plan_usages.json';
    var body = json.encode(params);

    var headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    var response = await http.post(
      Uri.parse(url),
      body: body,
      headers: headers,
    );

    return response;
  }

  Future getFreePlansUsages({required String userId}) async {
    var url =
        "${ApiConstants.baseUrl}/free_plan_usages.json?query[user_id]=$userId";

    String? token = await storage.read(key: 'token');

    var headers = {
      'Authorization': 'Bearer $token',
    };

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return response.body;
    }
  }

  Future putFreePlansUsages(
      {required String id, required String status}) async {
    Map<String, dynamic> params = {
      "free_plan_usage": {"status": status}
    };

    var url = "${ApiConstants.baseUrl}/free_plan_usages/$id";

    String? token = await storage.read(key: 'token');

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    var body = json.encode(params);

    var response =
        await http.patch(Uri.parse(url), body: body, headers: headers);

    return response;
  }
}
