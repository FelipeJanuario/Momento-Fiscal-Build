import 'dart:convert';
import 'package:momentofiscal/core/models/jusbrasil.dart';
import 'package:momentofiscal/core/utilities/api_constants.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';
import 'package:http/http.dart' as http;

class ProcessNumberService {
  Future<Jusbrasil?> getProcessByNumber({required String numeroProcesso}) async {
    String? token = await storage.read(key: 'token');

    var url = "${ApiConstants.baseUrl}/processes/$numeroProcesso";

    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      var response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);
        
        // Verifica se é resposta do Datajud (tem "processos" em vez de "content")
        if (responseBody['processos'] != null) {
          return Jusbrasil.fromDatajud(responseBody);
        }
        
        // Resposta padrão Jusbrasil
        return Jusbrasil.fromJson(responseBody);
      } else if (response.statusCode == 404) {
        // Processo não encontrado
        return Jusbrasil(
          total: 0,
          numberOfElements: 0,
          maxElementsSize: 0,
          searchAfter: null,
          content: [],
        );
      } else {
        throw Exception('Failed to load Process: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching process: $e');
    }
  }
}
