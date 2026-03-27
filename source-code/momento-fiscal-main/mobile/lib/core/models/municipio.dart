class Municipio {
  final int? id;
  final String codigoIbge;
  final String nome;
  final String uf;
  final String? cnpjPrefeitura;
  final int? populacao;
  final double? latitude;
  final double? longitude;

  Municipio({
    this.id,
    required this.codigoIbge,
    required this.nome,
    required this.uf,
    this.cnpjPrefeitura,
    this.populacao,
    this.latitude,
    this.longitude,
  });

  factory Municipio.fromJson(Map<String, dynamic> json) {
    return Municipio(
      id: json['id'],
      codigoIbge: json['codigo_ibge'] ?? '',
      nome: json['nome'] ?? '',
      uf: json['uf'] ?? '',
      cnpjPrefeitura: json['cnpj_prefeitura'],
      populacao: json['populacao'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo_ibge': codigoIbge,
      'nome': nome,
      'uf': uf,
      'cnpj_prefeitura': cnpjPrefeitura,
      'populacao': populacao,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  String get nomeCompleto => '$nome - $uf';
}

class MunicipioSearchResult {
  final List<Municipio> municipios;
  final int total;

  MunicipioSearchResult({
    required this.municipios,
    required this.total,
  });

  factory MunicipioSearchResult.fromJson(Map<String, dynamic> json) {
    return MunicipioSearchResult(
      municipios: (json['municipios'] as List?)
              ?.map((m) => Municipio.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] ?? 0,
    );
  }
}
