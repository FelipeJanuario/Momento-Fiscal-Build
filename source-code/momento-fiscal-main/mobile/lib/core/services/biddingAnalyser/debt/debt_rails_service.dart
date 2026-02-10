import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:momentofiscal/core/models/debt.dart';
import 'package:momentofiscal/core/utilities/api_constants.dart';
import 'package:momentofiscal/core/utilities/logger.dart';

FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

String sanitizeCnpj(String cnpj) {
  return cnpj.replaceAll(RegExp(r'[^0-9]'), '');
}

String sanitizeCpf(String cpf) {
  String cleanedCpf = cpf.replaceAll(RegExp(r'\D'), '');
  if (cleanedCpf.length == 11) {
    return cleanedCpf.substring(3, 9);
  }
  return '';
}

class DebtsRails {
  Future<Map<String, dynamic>> getDebtsWithTotals(String document, {String? debtedName}) async {
    String? token = await _secureStorage.read(key: 'token');

    String sanitizedDocument;
    bool isCpf = document.length == 14;
    sanitizedDocument = isCpf ? sanitizeCpf(document) : sanitizeCnpj(document);

    Logger.log('[DebtsRails] Buscando dívidas para: $sanitizedDocument (isCpf: $isCpf)');

    try {
      final String url = '${ApiConstants.baseUrl}/biddings_analyser/debts'
          '?cpf_cnpj=$sanitizedDocument'
          '${debtedName != null ? '&debted_name=$debtedName' : ''}';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);
        
        Logger.log('[DebtsRails] Resposta da API recebida');
        Logger.log('[DebtsRails] total_count: ${responseBody['total_count']}');
        Logger.log('[DebtsRails] total_value: ${responseBody['total_value']}');
        
        // Processar debts da mesma resposta (evita chamada duplicada)
        List<Debt> debts = _parseDebtsFromResponse(responseBody, sanitizedDocument);
        
        return {
          'debts': debts,
          'total_count': responseBody['total_count'] ?? 0,
          'total_value': (responseBody['total_value'] is num) 
              ? (responseBody['total_value'] as num).toDouble()
              : double.tryParse(responseBody['total_value'].toString()) ?? 0.0,
        };
      }
    } catch (e) {
      Logger.log('[DebtsRails][getDebtsWithTotals] Error: $e', error: e);
    }

    return {'debts': <Debt>[], 'total_count': 0, 'total_value': 0.0};
  }

  Future<List<Debt>> getDebts(String document, {String? debtedName}) async {
    String? token = await _secureStorage.read(key: 'token');

    String sanitizedDocument;
    bool isCpf = document.length == 14;
    sanitizedDocument = isCpf ? sanitizeCpf(document) : sanitizeCnpj(document);

    Logger.log('[DebtsRails][getDebts] Buscando dívidas para: $sanitizedDocument (isCpf: $isCpf)');

    try {
      final String url = '${ApiConstants.baseUrl}/biddings_analyser/debts'
          '?cpf_cnpj=$sanitizedDocument'
          '${debtedName != null ? '&debted_name=$debtedName' : ''}';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);
        
        Logger.log('[DebtsRails][getDebts] Resposta OK - debts length: ${(responseBody['debts'] ?? []).length}');
        
        return _parseDebtsFromResponse(responseBody, sanitizedDocument);
      }
    } catch (e) {
      Logger.log('[DebtsRails][getDebts] Error: $e', error: e);
    }

    return [];
  }

  String _parseValorMoeda(dynamic valor) {
    if (valor == null) return '0.00';
    
    String valorStr = valor.toString();
    // Converte formato brasileiro (1.234.567,89) para decimal (1234567.89)
    return valorStr
        .replaceAll('.', '')
        .replaceAll(',', '.');
  }

  /// Método auxiliar para extrair lista de Debt do responseBody (evita duplicação de código)
  List<Debt> _parseDebtsFromResponse(Map<String, dynamic> responseBody, String sanitizedDocument) {
    List<Debt> debts = [];
    List<dynamic> debtsList = responseBody['debts'] ?? [];
    
    if (debtsList.isNotEmpty) {
      // Processar lista detalhada da API Serpro
      debts = debtsList.map((debtJson) {
        return Debt(
          id: debtJson['numeroInscricao']?.toString(),
          cpfCnpj: debtJson['cpfCnpj']?.toString().replaceAll(RegExp(r'[^0-9]'), ''),
          debtedName: debtJson['nomeDevedor'],
          value: _parseValorMoeda(debtJson['valorTotalConsolidadoMoeda']),
          registrationNumber: debtJson['numeroInscricao']?.toString(),
          registrationDate: debtJson['dataInscricao'],
          registrationStatus: debtJson['situacaoDescricao'],
          registrationStatusType: debtJson['tipoRegularidade'],
          mainRevenue: debtJson['numeroProcesso'],
          debtState: debtJson['situacaoInscricao']?.toString(),
          debtedType: debtJson['tipoDevedor'],
          responsibleUnit: debtJson['nomeUnidade'],
          isFgts: 'false',
          isPrevidenciary: 'false',
        );
      }).toList();
    } else if (responseBody['total_value'] != null && 
               responseBody['total_value'] != 0) {
      // Fallback: se não tem lista mas tem total, criar um Debt agregado
      double totalValue = responseBody['total_value'] is String 
          ? double.parse(responseBody['total_value'])
          : (responseBody['total_value'] as num).toDouble();
      
      int totalCount = responseBody['total_count'] ?? 0;
      
      debts.add(Debt(
        id: 'total_$sanitizedDocument',
        cpfCnpj: sanitizedDocument,
        value: totalValue.toStringAsFixed(2),
        debtedName: 'Total Consolidado',
        registrationStatus: '$totalCount dívida${totalCount != 1 ? "s" : ""} ativa${totalCount != 1 ? "s" : ""}',
        registrationStatusType: 'IRREGULAR',
        createdAt: DateTime.now(),
      ));
    }
    
    return debts;
  }

  Future<List<Map<String, dynamic>>> getDebtsPerDebtedName(
      String cpfCnpj) async {
    String? token = await _secureStorage.read(key: 'token');

    var sanitizedId = _sanitizeId(cpfCnpj);

    final String url =
        '${ApiConstants.baseUrl}/biddings_analyser/debts/$sanitizedId/debts_per_debted_name';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      var responseBody = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseBody.map<Map<String, dynamic>>((item) {
          return item as Map<String, dynamic>;
        }).toList();
      } else {
        return [];
      }
    } catch (error, stackTrace) {
      Logger.log('[DebtsRails][getDebtsPerDebtedName] Error: $error',
          error: error, stackTrace: stackTrace);
      return [];
    }
  }

  String _sanitizeId(String id) {
    return id.replaceAll(RegExp(r'[^0-9]'), '');
  }
}
