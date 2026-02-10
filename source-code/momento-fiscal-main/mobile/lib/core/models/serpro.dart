class Serpro {
  final String numeroInscricao;
  final String numeroProcesso;
  final String situacaoInscricao;
  final String situacaoDescricao;
  final String nomeDevedor;
  final String tipoDevedor;
  final String valorTotalConsolidadoMoeda;
  final String cpfCnpj;
  final String codigoSida;
  final String nomeUnidade;
  final String codigoComprot;
  final String codigoUorg;
  final String codigoTipoSituacao;
  final String descricaoTipoSituacao;
  final String tipoRegularidade;
  final String numeroJuizo;
  final String dataInscricao;

  Serpro({
    required this.numeroInscricao,
    required this.numeroProcesso,
    required this.situacaoInscricao,
    required this.situacaoDescricao,
    required this.nomeDevedor,
    required this.tipoDevedor,
    required this.valorTotalConsolidadoMoeda,
    required this.cpfCnpj,
    required this.codigoSida,
    required this.nomeUnidade,
    required this.codigoComprot,
    required this.codigoUorg,
    required this.codigoTipoSituacao,
    required this.descricaoTipoSituacao,
    required this.tipoRegularidade,
    required this.numeroJuizo,
    required this.dataInscricao,
  });

  factory Serpro.fromJson(Map<String, dynamic> json) {
    return Serpro(
      numeroInscricao: json['numeroInscricao'] ?? '',
      numeroProcesso: json['numeroProcesso'] ?? '',
      situacaoInscricao: json['situacaoInscricao'] ?? '',
      situacaoDescricao: json['situacaoDescricao'] ?? '',
      nomeDevedor: json['nomeDevedor'] ?? '',
      tipoDevedor: json['tipoDevedor'] ?? '',
      valorTotalConsolidadoMoeda: json['valorTotalConsolidadoMoeda'] ?? '',
      cpfCnpj: json['cpfCnpj'] ?? '',
      codigoSida: json['codigoSida'] ?? '',
      nomeUnidade: json['nomeUnidade'] ?? '',
      codigoComprot: json['codigoComprot'] ?? '',
      codigoUorg: json['codigoUorg'] ?? '',
      codigoTipoSituacao: json['codigoTipoSituacao'] ?? '',
      descricaoTipoSituacao: json['descricaoTipoSituacao'] ?? '',
      tipoRegularidade: json['tipoRegularidade'] ?? '',
      numeroJuizo: json['numeroJuizo'] ?? '',
      dataInscricao: json['dataInscricao'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numeroInscricao': numeroInscricao,
      'numeroProcesso': numeroProcesso,
      'situacaoInscricao': situacaoInscricao,
      'situacaoDescricao': situacaoDescricao,
      'nomeDevedor': nomeDevedor,
      'tipoDevedor': tipoDevedor,
      'valorTotalConsolidadoMoeda': valorTotalConsolidadoMoeda,
      'cpfCnpj': cpfCnpj,
      'codigoSida': codigoSida,
      'nomeUnidade': nomeUnidade,
      'codigoComprot': codigoComprot,
      'codigoUorg': codigoUorg,
      'codigoTipoSituacao': codigoTipoSituacao,
      'descricaoTipoSituacao': descricaoTipoSituacao,
      'tipoRegularidade': tipoRegularidade,
      'numeroJuizo': numeroJuizo,
      'dataInscricao': dataInscricao,
    };
  }
}

List<Serpro> parseSerproList(List<dynamic> jsonList) {
  return jsonList.map((json) => Serpro.fromJson(json)).toList();
}
