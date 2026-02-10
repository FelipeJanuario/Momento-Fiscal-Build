import 'dart:convert';
import 'dart:io';

import 'package:momentofiscal/core/services/storage/storage_service.dart';
import 'package:momentofiscal/core/utilities/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:momentofiscal/core/utilities/logger.dart';

class RestfullModel {
  String get baseUrl => ApiConstants.baseUrl;
  String get endpoint => '/api/v1';
  String get url => '$baseUrl$endpoint';

  String? id;

  RestfullModel({this.id});

  Map<String, dynamic> toJson() {
    throw UnimplementedError("toJson method not implemented");
  }

  void fromJson(Map<String, dynamic> json) {
    throw UnimplementedError("fromJson method not implemented");
  }

  Future<Map<String, dynamic>> get(
      {String? path = '', Map<String, String>? body}) async {
    var uri = Uri(
      scheme: 'https',
      host: baseUrl.replaceAll('https://', ''),
      path: '$endpoint$path?',
      queryParameters: body ?? {},
    );
    uri = uri.replace(path: "$endpoint$path");
    String? token = await storage.read(key: 'token');

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode != 200 && response.statusCode != 201) {
      Logger.log("[RestfullModel][get] Error on API response: ${response.body}");
      throw HttpException('Get failed', uri: uri);
    }

    return json.decode(response.body);
  }

  Future<dynamic> post({String? path = '', Map<String, dynamic>? body}) async {
    var uri = Uri.parse(baseUrl);
    uri = uri.replace(path: "$endpoint$path");
    String? token = await storage.read(key: 'token');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      Logger.log("[RestfullModel][post] Error on API response: ${response.body}");
      throw HttpException(response.body, uri: uri);
    }

    return json.decode(response.body);
  }

  Future<dynamic> put({String? path = '', Map<String, dynamic>? body}) async {
    var uri = Uri.parse(baseUrl);
    uri = uri.replace(path: "$endpoint$path");
    String? token = await storage.read(key: 'token');

    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      Logger.log("[RestfullModel][put] Error on API response: ${response.body}");
      throw HttpException('Put failed', uri: uri);
    }

    return json.decode(response.body);
  }

  Future<dynamic> delete({String? path = ''}) async {
    var uri = Uri.parse(baseUrl);
    uri = uri.replace(path: "$endpoint$path");
    String? token = await storage.read(key: 'token');

    final response = await http.delete(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode != 200 && response.statusCode != 201) {
      Logger.log("[RestfullModel][delete] Error on API response: ${response.body}");
      throw HttpException('Delete failed', uri: uri);
    }

    return json.decode(response.body);
  }

  Future<void> save() async {
    try {
      if (id == null) {
        final response = await post(body: toJson());
        fromJson(response);
      } else {
        final response = await put(path: id!, body: toJson());
        fromJson(response);
      }
    } on HttpException catch (e) {
      if (e.uri != null && e.message.contains('Unauthorized')) {
        throw HttpException('Unauthorized - 401', uri: e.uri);
      } else {
        throw HttpException('Save operation failed', uri: e.uri);
      }
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<void> destroy() async {
    await delete(path: id);
  }
}
