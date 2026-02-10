
import 'dart:convert';

import 'package:http/http.dart' as http;
import '../storage/storage_service.dart';
import '../../utilities/api_constants.dart';

class ApiRequestService {
  ApiRequestService._();
  static final ApiRequestService instance = ApiRequestService._();

  final _baseUrl = ApiConstants.baseUrl;
  
  Future get(String endpoint, {Map<String, String>? query}) async {
    var url = '$_baseUrl/$endpoint';

    var response = await http.get(
      Uri.parse(url).replace(queryParameters: query),
      headers: await headers(),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load data from $url');
    }
  }

  Future post(String endpoint, Map<String, dynamic> body) async {
    var url = '$_baseUrl/$endpoint';

    var response = await http.post(
      Uri.parse(url),
      headers: await headers(),
      body: json.encode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.body;
    } else {
      throw Exception('Failed to post data to $url');
    }
  }

  Future<Map<String, String>> headers() async {
    String? token = await storage.read(key: 'token');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
