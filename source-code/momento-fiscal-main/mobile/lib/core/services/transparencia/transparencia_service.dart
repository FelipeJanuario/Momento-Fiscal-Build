import 'dart:convert';

import 'package:momentofiscal/core/models/sancao.dart';
import 'package:momentofiscal/core/utilities/api_constants.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';
import 'package:http/http.dart' as http;

class TransparenciaService {
  Future<SancoesResult?> consultarSancoes({required String cpfCnpj}) async {
    String url = '${ApiConstants.baseUrl}/transparencia/sancoes/$cpfCnpj';

    String? token = await storage.read(key: 'token');

    var headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      return SancoesResult.fromJson(responseBody);
    } else {
      return null;
    }
  }
}
