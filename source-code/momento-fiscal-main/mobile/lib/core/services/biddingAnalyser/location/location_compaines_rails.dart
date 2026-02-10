import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:momentofiscal/core/models/company.dart';
import 'package:momentofiscal/core/models/location.dart';
import 'package:momentofiscal/core/utilities/api_constants.dart';
import 'package:momentofiscal/core/utilities/validations.dart';

var sanitizedUrl = ApiConstants.url.replaceFirst(RegExp(r'^https?://'), '');

/// Helper para criar URI baseado no devMode (http vs https)
Uri _buildUri(String path, Map<String, dynamic> queryParams) {
  if (ApiConstants.devMode) {
    return Uri.http(sanitizedUrl, path, queryParams);
  } else {
    return Uri.https(sanitizedUrl, path, queryParams);
  }
}

class LocationCompaniesRails {
  // Use nossa base de CNPJs + busca por CEP (100% gratuito)
  static const bool useLocalDatabase = true;

  Future<List<Location>> getCountInLocation({
    required double longStarting,
    required double latStarting,
    required double longEnding,
    required double latEnding,
    String? debtNature,
  }) async {
    if (longStarting == longEnding && latStarting == latEnding) {
      return [];
    }

    // Se usar base local, não mostra contagem por clusters (ainda)
    // Por enquanto retorna vazio para focar nos dados reais
    if (useLocalDatabase) {
      return [];
    }

    // Fallback para biddings analyser se necessário
    final endpoint = '/api/v1/biddings_analyser/companies/count_in_location';

    var url = _buildUri(
      endpoint,
      {
        'starting_point[]': [latStarting.toString(), longStarting.toString()],
        'ending_point[]': [latEnding.toString(), longEnding.toString()],
        'rows': '15',
        'columns': '5',
        'debt_nature': debtNature,
      },
    );

    var headers = {
      'Content-Type': 'application/json',
    };

    var response = await http.get(url, headers: headers);

    try {
      var responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        List<Location> locations = [];
        if (responseBody is List) {
          for (var location in responseBody) {
            locations.add(Location.fromJson(location));
          }
        }

        return locations;
      } else {
        return [];
      }
    } catch (e) {
      log('[LocationCompaniesRails] Error in getCountInLocation: $e');
      return [];
    }
  }

  /// Busca empresas por prefixo de CEP (novo endpoint gratuito)
  /// [cep] - CEP do usuário (obtido via geocodificação reversa)
  /// [digits] - Quantidade de dígitos para match (padrão: 3)
  /// [page] - Página para paginação
  Future<List<Company>> getInLocationByCep({
    required String cep,
    int digits = 3,
    int page = 1,
    int pageSize = 50,
  }) async {
    if (cep.isEmpty || cep.length < digits) {
      log('[LocationCompaniesRails] CEP inválido: $cep');
      return [];
    }

    var url = _buildUri(
      '/api/v1/debtors/nearby_cep',
      {
        'cep': cep,
        'digits': digits.toString(),
        'page': page.toString(),
        'page_size': pageSize.toString(),
      },
    );

    log('[LocationCompaniesRails] URL: $url');
    print('[RAILS] URL: $url');

    var headers = {
      'Content-Type': 'application/json',
    };

    try {
      log('[LocationCompaniesRails] Fazendo requisição...');
      print('[RAILS] Fazendo requisição...');
      var response = await http.get(url, headers: headers);
      log('[LocationCompaniesRails] Response status: ${response.statusCode}');
      print('[RAILS] Response status: ${response.statusCode}');
      var responseBody = json.decode(response.body);
      print('[RAILS] total_count: ${responseBody['total_count']}');

      if (response.statusCode == 200) {
        List<Company> companies = [];
        if (responseBody['companies'] is List) {
          print('[RAILS] Parseando ${(responseBody['companies'] as List).length} empresas...');
          for (var company in responseBody['companies']) {
            try {
              companies.add(Company.fromJson(company));
            } catch (e) {
              print('[RAILS] Erro ao parsear empresa: $e');
            }
          }
        }
        print('[RAILS] Parseadas ${companies.length} empresas com sucesso');
        log('[LocationCompaniesRails] Encontradas ${companies.length} empresas para CEP $cep (${digits} dígitos)');
        return companies;
      } else {
        log('[LocationCompaniesRails] Erro: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('[RAILS] EXCEPTION: $e');
      log('[LocationCompaniesRails] Erro em getInLocationByCep: $e');
      return [];
    }
  }

  Future<List<Company>> getInLocation({
    required double? longStarting,
    required double? latStarting,
    required double? longEnding,
    required double? latEnding,
    required int? page,
  }) async {
    if (longStarting == longEnding && latStarting == latEnding) {
      return [];
    }

    // Usa nossa base local de CNPJs
    if (useLocalDatabase) {
      // Calcula centro e raio da região
      final centerLat = (latStarting! + latEnding!) / 2;
      final centerLng = (longStarting! + longEnding!) / 2;
      final radius = _calculateRadius(latStarting, longStarting, latEnding, longEnding);

      var url = _buildUri(
        '/api/v1/debtors/nearby',
        {
          'lat': centerLat.toString(),
          'lng': centerLng.toString(),
          'radius_km': radius.toString(),
          'page': page.toString(),
          'page_size': '100',
        },
      );

      var headers = {
        'Content-Type': 'application/json',
      };

      var response = await http.get(url, headers: headers);

      try {
        var responseBody = json.decode(response.body);

        if (response.statusCode == 200) {
          List<Company> companies = [];
          if (responseBody['companies'] is List) {
            for (var company in responseBody['companies']) {
              companies.add(Company.fromJson(company));
            }
          }

          return companies;
        } else {
          log('[LocationCompaniesRails] Error response: ${response.statusCode} - ${response.body}');
          return [];
        }
      } catch (e) {
        log('[LocationCompaniesRails] Error in getInLocation (local): $e');
        return [];
      }
    }

    // Fallback para biddings analyser se necessário
    final endpoint = '/api/v1/biddings_analyser/companies/in_location';

    var url = _buildUri(
      endpoint,
      {
        'starting_point[]': [latStarting.toString(), longStarting.toString()],
        'ending_point[]': [latEnding.toString(), longEnding.toString()],
        "page": page.toString(),
        "page_size": "10",
        "min_debts_value": "100",
      },
    );

    var headers = {
      'Content-Type': 'application/json',
    };

    var response = await http.get(url, headers: headers);

    try {
      var responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        List<Company> companies = [];

        if (responseBody['companies'] is List) {
          for (var company in responseBody['companies']) {
            try {
              companies.add(Company.fromJson(company));
            } catch (error, stackTrace) {
              log("[LocationCompaniesRails][getInLocation] error on Company from json constructor!",
                  error: error, stackTrace: stackTrace);
            }
          }
        }

        return companies;
      } else {
        return [];
      }
    } catch (e) {
      log('[LocationCompaniesRails] Error in getInLocation (biddings): $e');
      return [];
    }
  }

  // Calcula raio aproximado da região (em km)
  double _calculateRadius(double lat1, double lng1, double lat2, double lng2) {
    // Distância aproximada usando diferença de coordenadas
    final latDiff = (lat2 - lat1).abs();
    final lngDiff = (lng2 - lng1).abs();
    
    // Converte para km (1 grau ≈ 111km)
    final latKm = latDiff * 111.0;
    final lngKm = lngDiff * 111.0;
    
    // Retorna metade da diagonal (raio aproximado)
    return (latKm + lngKm) / 2;
  }

  Future<List> getCompanyByCnpj(String cnpj) async {
    var url = _buildUri('/api/v1/biddings_analyser/companies',
        {"cnpj": cnpjMask(cnpj)});

    var headers = {
      'Content-Type': 'application/json',
    };

    var response = await http.get(url, headers: headers);

    try {
      var responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        List<Company> companies = [];

        if (responseBody['companies'] is List) {
          for (var company in responseBody['companies']) {
            try {
              companies.add(Company.fromJson(company));
            } catch (error, stackTrace) {
              log("[LocationCompaniesRails][getInLocation] error on Company from json constructor!",
                  error: error, stackTrace: stackTrace);
            }
          }
        }

        return companies;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Busca detalhes completos de uma empresa + dívidas SERPRO
  /// [companyId] - ID do estabelecimento no banco
  /// Retorna Map com todos os dados incluindo dívidas detalhadas
  Future<Map<String, dynamic>?> getCompanyDetails(String companyId) async {
    var url = _buildUri(
      '/api/v1/debtors/$companyId/details',
      {},
    );

    log('[LocationCompaniesRails] Buscando detalhes: $url');

    var headers = {
      'Content-Type': 'application/json',
    };

    try {
      var response = await http.get(url, headers: headers);
      log('[LocationCompaniesRails] Details response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        log('[LocationCompaniesRails] Erro ao buscar detalhes: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('[LocationCompaniesRails] Erro em getCompanyDetails: $e');
      return null;
    }
  }

  /// Busca dívidas SERPRO para múltiplos CNPJs em batch
  /// [cnpjs] - Lista de CNPJs para consultar
  /// Retorna Map<cnpj, DebtInfo> com debt_value e debt_count
  Future<Map<String, DebtInfo>> fetchBatchDebts(List<String> cnpjs) async {
    if (cnpjs.isEmpty) {
      return {};
    }

    // Limita a 50 CNPJs por requisição
    final cnpjsToFetch = cnpjs.take(50).toList();
    
    var url = _buildUri('/api/v1/debtors/batch_debts', {});

    log('[LocationCompaniesRails] Buscando dívidas em batch para ${cnpjsToFetch.length} CNPJs');
    print('[RAILS] batch_debts: ${cnpjsToFetch.length} CNPJs');

    var headers = {
      'Content-Type': 'application/json',
    };

    try {
      var response = await http.post(
        url,
        headers: headers,
        body: json.encode({'cnpjs': cnpjsToFetch}),
      );
      
      log('[LocationCompaniesRails] batch_debts response: ${response.statusCode}');
      print('[RAILS] batch_debts status: ${response.statusCode}');

      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);
        Map<String, DebtInfo> results = {};
        
        if (responseBody['results'] is Map) {
          (responseBody['results'] as Map).forEach((cnpj, data) {
            results[cnpj.toString()] = DebtInfo(
              debtValue: (data['debt_value'] as num?)?.toDouble() ?? 0,
              debtCount: (data['debt_count'] as num?)?.toInt() ?? 0,
              fromCache: data['from_cache'] as bool? ?? false,
              checkedAt: data['checked_at'] as String?,
            );
          });
        }
        
        print('[RAILS] batch_debts: ${results.length} resultados, cached: ${responseBody['cached']}, fetched: ${responseBody['fetched']}');
        log('[LocationCompaniesRails] batch_debts: ${results.length} resultados');
        
        return results;
      } else {
        log('[LocationCompaniesRails] Erro batch_debts: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('[RAILS] batch_debts EXCEPTION: $e');
      log('[LocationCompaniesRails] Erro em fetchBatchDebts: $e');
      return {};
    }
  }
}

/// Informações de dívida retornadas pelo batch_debts
class DebtInfo {
  final double debtValue;
  final int debtCount;
  final bool fromCache;
  final String? checkedAt;

  DebtInfo({
    required this.debtValue,
    required this.debtCount,
    required this.fromCache,
    this.checkedAt,
  });
}
