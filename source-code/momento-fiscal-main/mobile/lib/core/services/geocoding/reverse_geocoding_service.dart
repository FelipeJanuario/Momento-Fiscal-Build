import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

/// Service de geocodificação reversa usando Nominatim (OpenStreetMap)
/// 100% gratuito - converte lat/lng em endereço + CEP
class ReverseGeocodingService {
  // Nominatim API (gratuita, 1 req/segundo)
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  
  /// Converte coordenadas (lat/lng) em CEP
  /// Retorna o CEP (apenas números) ou null se não encontrar
  static Future<String?> getCepFromCoordinates(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        '$_nominatimBaseUrl/reverse?lat=$latitude&lon=$longitude&format=json&addressdetails=1'
      );
      
      final response = await http.get(url, headers: {
        'User-Agent': 'MomentoFiscal/1.0 (contato@momentofiscal.df.gov.br)',
        'Accept-Language': 'pt-BR,pt',
      });
      
      if (response.statusCode != 200) {
        log('[ReverseGeocodingService] Erro HTTP: ${response.statusCode}');
        return null;
      }
      
      final data = json.decode(response.body);
      
      // Extrai o CEP (postcode) do endereço
      final address = data['address'];
      if (address == null) {
        log('[ReverseGeocodingService] Endereço não encontrado');
        return null;
      }
      
      final postcode = address['postcode'];
      if (postcode == null) {
        log('[ReverseGeocodingService] CEP não encontrado no endereço');
        return null;
      }
      
      // Remove hífen e espaços, retorna apenas números
      final cepLimpo = postcode.toString().replaceAll(RegExp(r'\D'), '');
      
      if (cepLimpo.length < 3) {
        log('[ReverseGeocodingService] CEP inválido: $cepLimpo');
        return null;
      }
      
      log('[ReverseGeocodingService] CEP encontrado: $cepLimpo');
      return cepLimpo;
      
    } catch (e) {
      log('[ReverseGeocodingService] Erro: $e');
      return null;
    }
  }
  
  /// Obtém endereço completo das coordenadas
  /// Retorna um Map com rua, bairro, cidade, estado, cep
  static Future<Map<String, String>?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        '$_nominatimBaseUrl/reverse?lat=$latitude&lon=$longitude&format=json&addressdetails=1'
      );
      
      final response = await http.get(url, headers: {
        'User-Agent': 'MomentoFiscal/1.0 (contato@momentofiscal.df.gov.br)',
        'Accept-Language': 'pt-BR,pt',
      });
      
      if (response.statusCode != 200) {
        return null;
      }
      
      final data = json.decode(response.body);
      final address = data['address'];
      
      if (address == null) {
        return null;
      }
      
      return {
        'street': address['road'] ?? address['pedestrian'] ?? '',
        'neighborhood': address['suburb'] ?? address['neighbourhood'] ?? '',
        'city': address['city'] ?? address['town'] ?? address['village'] ?? '',
        'state': address['state'] ?? '',
        'postcode': (address['postcode'] ?? '').toString().replaceAll(RegExp(r'\D'), ''),
      };
      
    } catch (e) {
      log('[ReverseGeocodingService] Erro ao obter endereço: $e');
      return null;
    }
  }

  /// FORWARD GEOCODING: Converte endereço em coordenadas (lat/lng)
  /// Usa Nominatim (gratuito, 1 req/seg)
  /// Retorna [latitude, longitude] ou null se não encontrar
  static Future<List<double>?> getCoordinatesFromAddress({
    required String street,
    String? number,
    String? neighborhood,
    required String city,
    required String state,
    String? cep,
  }) async {
    try {
      // Monta query de busca
      final queryParts = <String>[];
      
      if (street.isNotEmpty) {
        queryParts.add(number != null ? '$street, $number' : street);
      }
      if (neighborhood != null && neighborhood.isNotEmpty) {
        queryParts.add(neighborhood);
      }
      queryParts.add(city);
      queryParts.add(state);
      queryParts.add('Brasil');
      
      final query = queryParts.join(', ');
      
      final url = Uri.parse(
        '$_nominatimBaseUrl/search?q=${Uri.encodeComponent(query)}&format=json&limit=1&countrycodes=br'
      );
      
      log('[GeocodingService] Buscando coordenadas para: $query');
      
      final response = await http.get(url, headers: {
        'User-Agent': 'MomentoFiscal/1.0 (contato@momentofiscal.df.gov.br)',
        'Accept-Language': 'pt-BR,pt',
      });
      
      if (response.statusCode != 200) {
        log('[GeocodingService] Erro HTTP: ${response.statusCode}');
        return null;
      }
      
      final data = json.decode(response.body);
      
      if (data is! List || data.isEmpty) {
        log('[GeocodingService] Nenhum resultado para: $query');
        return null;
      }
      
      final result = data[0];
      final lat = double.tryParse(result['lat'].toString());
      final lng = double.tryParse(result['lon'].toString());
      
      if (lat == null || lng == null) {
        return null;
      }
      
      log('[GeocodingService] Coordenadas encontradas: $lat, $lng');
      return [lat, lng];
      
    } catch (e) {
      log('[GeocodingService] Erro: $e');
      return null;
    }
  }

  /// Geocodifica uma empresa pelo endereço
  /// Retorna [latitude, longitude] ou null
  static Future<List<double>?> geocodeCompanyAddress({
    String? street,
    String? number,
    String? neighborhood,
    String? city,
    String? state,
    String? cep,
  }) async {
    // Precisa pelo menos cidade e estado
    if ((city == null || city.isEmpty) || (state == null || state.isEmpty)) {
      return null;
    }
    
    return getCoordinatesFromAddress(
      street: street ?? '',
      number: number,
      neighborhood: neighborhood,
      city: city,
      state: state,
      cep: cep,
    );
  }
}
