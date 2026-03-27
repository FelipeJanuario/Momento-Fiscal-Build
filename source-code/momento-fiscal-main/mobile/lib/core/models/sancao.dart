class Sancao {
  final String tipoCadastro;
  final String? cpfCnpjSancionado;
  final String? nomeSancionado;
  final String? nomeOrgaoSancionador;
  final String? ufSancionado;
  final String? dataInicioSancao;
  final String? dataFimSancao;
  final String? fundamentacaoLegal;
  final String? tipoSancao;
  final String? fonteSancao;

  Sancao({
    required this.tipoCadastro,
    this.cpfCnpjSancionado,
    this.nomeSancionado,
    this.nomeOrgaoSancionador,
    this.ufSancionado,
    this.dataInicioSancao,
    this.dataFimSancao,
    this.fundamentacaoLegal,
    this.tipoSancao,
    this.fonteSancao,
  });

  factory Sancao.fromJson(Map<String, dynamic> json) {
    return Sancao(
      tipoCadastro: json['tipo_cadastro'] ?? '',
      cpfCnpjSancionado: json['cpfCnpjSancionado'] ?? json['cpf_cnpj_sancionado'],
      nomeSancionado: json['nomeSancionado'] ?? json['nome_sancionado'],
      nomeOrgaoSancionador: json['nomeOrgaoSancionador'] ?? json['nome_orgao_sancionador'],
      ufSancionado: json['ufSancionado'] ?? json['uf_sancionado'],
      dataInicioSancao: json['dataInicioSancao'] ?? json['data_inicio_sancao'],
      dataFimSancao: json['dataFimSancao'] ?? json['data_fim_sancao'],
      fundamentacaoLegal: json['fundamentacaoLegal'] ?? json['fundamentacao_legal'],
      tipoSancao: json['tipoSancao'] ?? json['tipo_sancao'],
      fonteSancao: json['fonteSancao'] ?? json['fonte_sancao'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo_cadastro': tipoCadastro,
      'cpf_cnpj_sancionado': cpfCnpjSancionado,
      'nome_sancionado': nomeSancionado,
      'nome_orgao_sancionador': nomeOrgaoSancionador,
      'uf_sancionado': ufSancionado,
      'data_inicio_sancao': dataInicioSancao,
      'data_fim_sancao': dataFimSancao,
      'fundamentacao_legal': fundamentacaoLegal,
      'tipo_sancao': tipoSancao,
      'fonte_sancao': fonteSancao,
    };
  }
}

class SancoesResult {
  final String cpfCnpj;
  final List<Sancao> sancoes;
  final int total;
  final bool fromCache;

  SancoesResult({
    required this.cpfCnpj,
    required this.sancoes,
    required this.total,
    required this.fromCache,
  });

  factory SancoesResult.fromJson(Map<String, dynamic> json) {
    return SancoesResult(
      cpfCnpj: json['cpf_cnpj'] ?? '',
      sancoes: (json['sancoes'] as List?)
              ?.map((s) => Sancao.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] ?? 0,
      fromCache: json['from_cache'] ?? false,
    );
  }
}

List<Sancao> parseSancaoList(List<dynamic> jsonList) {
  return jsonList
      .map((json) => Sancao.fromJson(json as Map<String, dynamic>))
      .toList();
}
