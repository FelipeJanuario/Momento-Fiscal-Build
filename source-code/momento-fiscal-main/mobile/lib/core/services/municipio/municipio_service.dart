import 'dart:convert';

import 'package:momentofiscal/core/models/municipio.dart';
import 'package:momentofiscal/core/utilities/api_constants.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';
import 'package:http/http.dart' as http;

class MunicipioService {
  Future<MunicipioSearchResult?> buscar({
    required String termo,
    String? uf,
  }) async {
    String url = '${ApiConstants.baseUrl}/municipios/buscar';

    String? token = await storage.read(key: 'token');

    var headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    var query = <String, String>{'q': termo};
    if (uf != null) query['uf'] = uf;

    var uri = Uri.parse(url).replace(queryParameters: query);

    var response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      return MunicipioSearchResult.fromJson(responseBody);
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>?> consultarCompleto({
    required String codigoIbge,
    int? ano,
  }) async {
    String url =
        '${ApiConstants.baseUrl}/municipios/$codigoIbge/completo';

    String? token = await storage.read(key: 'token');

    var headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    var uri = Uri.parse(url);
    if (ano != null) {
      uri = uri.replace(queryParameters: {'ano': ano.toString()});
    }

    var response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      return null;
    }
  }
}
