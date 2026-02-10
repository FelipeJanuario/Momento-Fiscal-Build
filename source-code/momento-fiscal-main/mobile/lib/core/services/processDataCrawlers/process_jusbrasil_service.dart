import 'dart:convert';
import 'package:momentofiscal/core/models/jusbrasil.dart';
import 'package:momentofiscal/core/utilities/api_constants.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';
import 'package:http/http.dart' as http;

class ProcessJusbrasil {
  bool isNotResponse = false;

  Stream<List<Jusbrasil>> getProcessesCpfCnpjStream(
      {required String cpfCnpj}) async* {
    List<Jusbrasil> allProcesses = [];
    String? token = await storage.read(key: 'token');
    List<String>? searchAfter;
    Set<String> seenSearchAfter = {};

    do {
      var url = "${ApiConstants.baseUrl}/processes?cpf_cnpj=$cpfCnpj";
      if (searchAfter != null) {
        url += "&search_after=${searchAfter.join(',')}";
      }

      var headers = {
        'Authorization': 'Bearer $token',
      };

      var response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);
        isNotResponse = false; // Resposta bem-sucedida

        // Atualiza o valor de searchAfter para a próxima iteração
        if (responseBody['searchAfter'] != null) {
          var newSearchAfter = List<String>.from(responseBody['searchAfter']);

          // Gera uma string única para comparar no conjunto
          var newSearchAfterKey = newSearchAfter.join(',');

          // Verifica se já vimos esse searchAfter antes
          if (seenSearchAfter.contains(newSearchAfterKey)) {
            searchAfter = null;
            break;
          } else {
            seenSearchAfter.add(newSearchAfterKey);
            searchAfter = newSearchAfter;
          }
        } else {
          searchAfter = null;
        }

        var newProcesses = [Jusbrasil.fromJson(responseBody)];
        allProcesses.addAll(newProcesses);

        yield allProcesses;
      } else if (response.statusCode == 500 || response.statusCode == 504) {
        isNotResponse = true;
        searchAfter = null;
        throw Exception('Server error: ${response.statusCode}');
      } else if(response.statusCode == 404) {
        searchAfter = null;
        throw Exception('not found: ${response.statusCode}');
      } else {
        searchAfter = null;
        throw Exception('Failed to load Process Jusbrasil');
      }
    } while (searchAfter != null);
  }
}
