class Jusbrasil {
  final int? total;
  final int? numberOfElements;
  final int? maxElementsSize;
  final List<String>? searchAfter;
  final List<Content>? content;

  Jusbrasil({
    required this.total,
    required this.numberOfElements,
    required this.maxElementsSize,
    required this.searchAfter,
    required this.content,
  });

  factory Jusbrasil.fromJson(Map<String, dynamic> json) {
    return Jusbrasil(
      total: json['total'],
      numberOfElements: json['numberOfElements'],
      maxElementsSize: json['maxElementsSize'],
      searchAfter: json['searchAfter'] != null
          ? List<String>.from(json['searchAfter'])
          : null,
      content: json['content'] != null
          ? List<Content>.from(json['content'].map((x) => Content.fromJson(x)))
          : null,
    );
  }

  /// Factory para converter resposta do Datajud para o formato esperado
  factory Jusbrasil.fromDatajud(Map<String, dynamic> json) {
    final processos = json['processos'] as List? ?? [];
    final total = json['total'] as int? ?? processos.length;
    
    return Jusbrasil(
      total: total,
      numberOfElements: processos.length,
      maxElementsSize: 10,
      searchAfter: null,
      content: processos.map((p) => Content.fromDatajud(p)).toList(),
    );
  }
}

class Content {
  final String numeroProcesso;
  final int nivelSigilo;
  final int idCodexTribunal;
  final String siglaTribunal;
  final List<Tramitacao> tramitacoes;

  Content({
    required this.numeroProcesso,
    required this.nivelSigilo,
    required this.idCodexTribunal,
    required this.siglaTribunal,
    required this.tramitacoes,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      numeroProcesso: json['numeroProcesso'],
      nivelSigilo: json['nivelSigilo'],
      idCodexTribunal: json['idCodexTribunal'],
      siglaTribunal: json['siglaTribunal'],
      tramitacoes: json['tramitacoes'] != null
          ? List<Tramitacao>.from(
              json['tramitacoes'].map((x) => Tramitacao.fromJson(x)))
          : [],
    );
  }

  /// Factory para converter processo do Datajud para o formato esperado
  factory Content.fromDatajud(Map<String, dynamic> json) {
    final tribunal = json['tribunal']?.toString().toUpperCase() ?? 'DESCONHECIDO';
    final numeroProcesso = json['numero_processo'] ?? json['numeroProcesso'] ?? '';
    final sigilo = json['sigilo'] ?? json['nivelSigilo'] ?? 0;
    
    // Cria uma tramitação básica com os dados disponíveis
    final tramitacao = Tramitacao.fromDatajud(json);
    
    return Content(
      numeroProcesso: numeroProcesso,
      nivelSigilo: sigilo is int ? sigilo : 0,
      idCodexTribunal: 0, // Datajud não fornece este campo
      siglaTribunal: tribunal,
      tramitacoes: [tramitacao],
    );
  }
}

class Tramitacao {
  final int idCodex;
  final Tribunal tribunal;
  final Grau grau;
  final bool liminar;
  final int nivelSigilo;
  final double valorAcao;
  final String? dataHoraUltimaDistribuicao;
  final List<Classe> classe;
  final List<Assunto>? assunto;
  final UltimoMovimento? ultimoMovimento;
  final List<Parte> partes;
  final bool ativo;
  final OrgaoJulgador? orgaoJulgador;
  final int idFonteDadosCodex;
  final bool permitePeticionar;

  Tramitacao({
    required this.idCodex,
    required this.tribunal,
    required this.grau,
    required this.liminar,
    required this.nivelSigilo,
    required this.valorAcao,
    required this.dataHoraUltimaDistribuicao,
    required this.classe,
    required this.assunto,
    required this.ultimoMovimento,
    required this.partes,
    required this.ativo,
    required this.orgaoJulgador,
    required this.idFonteDadosCodex,
    required this.permitePeticionar,
  });

  factory Tramitacao.fromJson(Map<String, dynamic> json) {
    return Tramitacao(
      idCodex: json['idCodex'],
      tribunal: Tribunal.fromJson(json['tribunal']),
      grau: Grau.fromJson(json['grau']),
      liminar: json['liminar'],
      nivelSigilo: json['nivelSigilo'],
      valorAcao: json['valorAcao'].toDouble(),
      dataHoraUltimaDistribuicao: json['dataHoraUltimaDistribuicao'],
      classe: json['classe'] != null
          ? List<Classe>.from(json['classe'].map((x) => Classe.fromJson(x)))
          : [],
      assunto: json['assunto'] != null
          ? List<Assunto>.from(json['assunto'].map((x) => Assunto.fromJson(x)))
          : [],
      ultimoMovimento: json['ultimoMovimento'] != null
          ? UltimoMovimento.fromJson(json['ultimoMovimento'])
          : null,
      partes: json['partes'] != null
          ? List<Parte>.from(json['partes'].map((x) => Parte.fromJson(x)))
          : [],
      ativo: json['ativo'],
      orgaoJulgador: json['orgaoJulgador'] != null
          ? OrgaoJulgador.fromJson(json['orgaoJulgador'])
          : null,
      idFonteDadosCodex: json['idFonteDadosCodex'],
      permitePeticionar: json['permitePeticionar'],
    );
  }

  /// Factory para converter dados do Datajud para Tramitacao
  factory Tramitacao.fromDatajud(Map<String, dynamic> json) {
    final tribunalStr = json['tribunal']?.toString().toUpperCase() ?? 'DESCONHECIDO';
    final grauStr = json['grau']?.toString() ?? 'G1';
    final classeNome = json['classe'] ?? 'Processo';
    final classeCodigo = json['classe_codigo'] ?? 0;
    final assuntos = json['assuntos'] as List? ?? [];
    final orgaoNome = json['orgao_julgador'] ?? '';
    final dataAjuizamento = json['data_ajuizamento'];
    final ultimaAtualizacao = json['ultima_atualizacao'];
    final sigilo = json['sigilo'] ?? 0;

    return Tramitacao(
      idCodex: 0,
      tribunal: Tribunal(
        sigla: tribunalStr,
        nome: tribunalStr,
        segmento: 'Justiça',
        jtr: '',
      ),
      grau: Grau(
        sigla: grauStr,
        nome: _grauNome(grauStr),
        numero: _grauNumero(grauStr),
      ),
      liminar: false,
      nivelSigilo: sigilo is int ? sigilo : 0,
      valorAcao: 0.0,
      dataHoraUltimaDistribuicao: dataAjuizamento,
      classe: [Classe(codigo: classeCodigo is int ? classeCodigo : 0, descricao: classeNome.toString())],
      assunto: assuntos.map((a) => Assunto(codigo: 0, descricao: a.toString())).toList(),
      ultimoMovimento: ultimaAtualizacao != null 
          ? UltimoMovimento(dataHora: ultimaAtualizacao.toString(), codigo: 0)
          : null,
      partes: [], // Datajud público não fornece partes
      ativo: true,
      orgaoJulgador: orgaoNome.isNotEmpty 
          ? OrgaoJulgador(id: 0, nome: orgaoNome)
          : null,
      idFonteDadosCodex: 0,
      permitePeticionar: false,
    );
  }

  static String _grauNome(String grau) {
    switch (grau.toUpperCase()) {
      case 'G1': return '1º Grau';
      case 'G2': return '2º Grau';
      case 'JE': return 'Juizado Especial';
      case 'SUP': return 'Tribunal Superior';
      default: return grau;
    }
  }

  static int _grauNumero(String grau) {
    switch (grau.toUpperCase()) {
      case 'G1': return 1;
      case 'G2': return 2;
      case 'JE': return 1;
      case 'SUP': return 3;
      default: return 1;
    }
  }
}

class Tribunal {
  final String sigla;
  final String nome;
  final String segmento;
  final String jtr;

  Tribunal({
    required this.sigla,
    required this.nome,
    required this.segmento,
    required this.jtr,
  });

  factory Tribunal.fromJson(Map<String, dynamic> json) {
    return Tribunal(
      sigla: json['sigla'],
      nome: json['nome'],
      segmento: json['segmento'],
      jtr: json['jtr'],
    );
  }
}

class Grau {
  final String sigla;
  final String nome;
  final int numero;

  Grau({
    required this.sigla,
    required this.nome,
    required this.numero,
  });

  factory Grau.fromJson(Map<String, dynamic> json) {
    return Grau(
      sigla: json['sigla'],
      nome: json['nome'],
      numero: json['numero'],
    );
  }
}

class Classe {
  final int codigo;
  final String descricao;

  Classe({
    required this.codigo,
    required this.descricao,
  });

  factory Classe.fromJson(Map<String, dynamic> json) {
    return Classe(
      codigo: json['codigo'],
      descricao: json['descricao'],
    );
  }
}

class Assunto {
  final int? codigo;
  final String? descricao;
  final String? hierarquia;

  Assunto({
    required this.codigo,
    required this.descricao,
    this.hierarquia,
  });

  factory Assunto.fromJson(Map<String, dynamic> json) {
    return Assunto(
      codigo: json['codigo'],
      descricao: json['descricao'],
      hierarquia: json['hierarquia'],
    );
  }
}

class UltimoMovimento {
  final String dataHora;
  final int codigo;

  UltimoMovimento({
    required this.dataHora,
    required this.codigo,
  });

  factory UltimoMovimento.fromJson(Map<String, dynamic> json) {
    return UltimoMovimento(
      dataHora: json['dataHora'],
      codigo: json['codigo'],
    );
  }
}

class Parte {
  final String polo;
  final String tipoParte;
  final String nome;
  final String tipoPessoa;
  final List<DocumentoPrincipal> documentosPrincipais;
  final bool sigilosa;
  final List<Representante>? representantes;

  Parte({
    required this.polo,
    required this.tipoParte,
    required this.nome,
    required this.tipoPessoa,
    required this.documentosPrincipais,
    required this.sigilosa,
    this.representantes,
  });

  factory Parte.fromJson(Map<String, dynamic> json) {
    return Parte(
      polo: json['polo'],
      tipoParte: json['tipoParte'],
      nome: json['nome'],
      tipoPessoa: json['tipoPessoa'],
      documentosPrincipais: List<DocumentoPrincipal>.from(
          json['documentosPrincipais']
                  ?.map((x) => DocumentoPrincipal.fromJson(x)) ??
              []),
      sigilosa: json['sigilosa'],
      representantes: json['representantes'] != null
          ? List<Representante>.from(
              json['representantes'].map((x) => Representante.fromJson(x)))
          : null,
    );
  }
}

class DocumentoPrincipal {
  final String numero;
  final String tipo;

  DocumentoPrincipal({
    required this.numero,
    required this.tipo,
  });

  factory DocumentoPrincipal.fromJson(Map<String, dynamic> json) {
    return DocumentoPrincipal(
      numero: json['numero'],
      tipo: json['tipo'],
    );
  }
}

class Representante {
  final String tipoRepresentacao;
  final String nome;
  final List<CadastroReceitaFederal>? cadastroReceitaFederal;
  final String situacao;
  final List<OAB>? oab;

  Representante({
    required this.tipoRepresentacao,
    required this.nome,
    this.cadastroReceitaFederal,
    required this.situacao,
    this.oab,
  });

  factory Representante.fromJson(Map<String, dynamic> json) {
    return Representante(
      tipoRepresentacao: json['tipoRepresentacao'],
      nome: json['nome'],
      cadastroReceitaFederal: json['cadastroReceitaFederal'] != null
          ? List<CadastroReceitaFederal>.from(json['cadastroReceitaFederal']
              .map((x) => CadastroReceitaFederal.fromJson(x)))
          : null,
      situacao: json['situacao'],
      oab: json['oab'] != null
          ? List<OAB>.from(json['oab'].map((x) => OAB.fromJson(x)))
          : null,
    );
  }
}

class CadastroReceitaFederal {
  final int? numero;
  final String? tipo;

  CadastroReceitaFederal({
    required this.numero,
    required this.tipo,
  });

  factory CadastroReceitaFederal.fromJson(Map<String, dynamic> json) {
    return CadastroReceitaFederal(
      numero: json['numero'],
      tipo: json['tipo'],
    );
  }
}

class OAB {
  final int numero;
  final String? uf;

  OAB({
    required this.numero,
    required this.uf,
  });

  factory OAB.fromJson(Map<String, dynamic> json) {
    return OAB(
      numero: json['numero'],
      uf: json['uf'],
    );
  }
}

class OrgaoJulgador {
  final int id;
  final String nome;

  OrgaoJulgador({
    required this.id,
    required this.nome,
  });

  factory OrgaoJulgador.fromJson(Map<String, dynamic> json) {
    return OrgaoJulgador(
      id: json['id'],
      nome: json['nome'],
    );
  }
}
