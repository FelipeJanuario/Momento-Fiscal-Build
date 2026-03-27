import 'dart:convert';

import 'package:momentofiscal/core/utilities/api_constants.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';
import 'package:http/http.dart' as http;

class FiscaisService {
  Future<Map<String, dynamic>?> consultarCauc({required String cnpj}) async {
    return _get('fiscais/cauc/$cnpj');
  }

  Future<Map<String, dynamic>?> consultarSiconfi({
    required String codigoIbge,
    int? exercicio,
  }) async {
    var query = <String, String>{};
    if (exercicio != null) query['exercicio'] = exercicio.toString();
    return _get('fiscais/siconfi/$codigoIbge', query: query);
  }

  Future<Map<String, dynamic>?> consultarTransferencias({
    required String cnpj,
    int? ano,
  }) async {
    var query = <String, String>{};
    if (ano != null) query['ano'] = ano.toString();
    return _get('fiscais/transferencias/$cnpj', query: query);
  }

  Future<Map<String, dynamic>?> consultarFnde({
    required String cnpj,
    int? ano,
  }) async {
    var query = <String, String>{};
    if (ano != null) query['ano'] = ano.toString();
    return _get('fiscais/fnde/$cnpj', query: query);
  }

  Future<Map<String, dynamic>?> consultarCompleto({
    required String cnpj,
    String? codigoIbge,
    int? ano,
  }) async {
    var query = <String, String>{};
    if (codigoIbge != null) query['codigo_ibge'] = codigoIbge;
    if (ano != null) query['ano'] = ano.toString();
    return _get('fiscais/completo/$cnpj', query: query);
  }

  Future<Map<String, dynamic>?> _get(
    String endpoint, {
    Map<String, String>? query,
  }) async {
    String url = '${ApiConstants.baseUrl}/$endpoint';

    String? token = await storage.read(key: 'token');

    var headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    var uri = Uri.parse(url);
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }

    var response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      return null;
    }
  }
}
