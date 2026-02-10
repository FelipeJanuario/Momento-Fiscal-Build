import 'dart:convert';

import 'package:momentofiscal/core/models/serpro.dart';
import 'package:momentofiscal/core/utilities/api_constants.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';
import 'package:http/http.dart' as http;

class SerproService {
  Future getCpfSerpro({required String cpf}) async {
    String url = '${ApiConstants.baseUrl}/consulta_cpf/$cpf';

    String? token = await storage.read(key: 'token');

    var headers = {
      'Authorization': 'Bearer $token',
    };

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);

      if (responseBody.isNotEmpty) {
        List<Serpro> serproList = parseSerproList(responseBody);
        return serproList;
      }
    } else {
      return null;
    }
  }
}
