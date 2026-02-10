class Socio {
  late String name;
  late String age;
  late String cpf;
  late String qualification;
  late String entryDate;

  Socio({
    required this.name,
    required this.age,
    required this.cpf,
    required this.qualification,
    required this.entryDate,
  });

  Socio.fromJson(Map<String, dynamic> json) {
    name = json['nome_socio'];
    age = json['faixa_etaria'];
    cpf = json['cnpj_cpf_do_socio'];
    qualification = json['qualificacao_socio'];
    entryDate = json['data_entrada_sociedade'];
  }
}

class ApiCnpj {
  late String uf;
  late String cep;
  List<Socio> socios = [];
  late String companySize;
  late String complement;
  late String county;
  late String district;
  late double shareCapital;
  late String phone;
  late String registrationStatus;
  late String reasonSocial;
  late String descriptionCnae;
  late String cnpj;

  ApiCnpj(
      {required this.uf,
      required this.cep,
      required this.socios,
      required this.companySize,
      required this.county,
      required this.complement,
      required this.district,
      required this.shareCapital,
      required this.phone,
      required this.registrationStatus,
      required this.reasonSocial,
      required this.descriptionCnae,
      required this.cnpj});

  ApiCnpj.fromJson(Map<String, dynamic> json) {
    uf = json['uf'] ?? '';
    cep = json['cep'] ?? '';
    companySize = json['porte'] ?? '';
    county = json['municipio'] ?? '';
    complement = json['complemento'] ?? '';
    district = json['bairro'] ?? '';
    shareCapital =
        double.tryParse(json['capital_social']?.toString() ?? '0') ?? 0.0;
    phone = json['ddd_telefone_1'] ?? '';
    registrationStatus = json['descricao_situacao_cadastral'] ?? '';
    descriptionCnae = json['cnae_fiscal_descricao'] ?? '';
    reasonSocial = json['razao_social'] ?? '';
    cnpj = json['cnpj'] ?? '';

    if (json['qsa'] != null && json['qsa'] is List) {
      socios = (json['qsa'] as List)
          .map((v) => Socio.fromJson(v as Map<String, dynamic>))
          .toList();
    }
  }
}

class ExampleDebitCnpj {
  late String name;
  late double debt;

  ExampleDebitCnpj({required this.name, required this.debt});

  Map<String, dynamic> toJson() => {'name': name, 'debt': debt};
}

List<ExampleDebitCnpj> examplesDebts = [
  ExampleDebitCnpj(name: 'Ex. Tributário1', debt: 45898.88),
  ExampleDebitCnpj(name: 'Ex. Tributário2', debt: 458498.88),
  ExampleDebitCnpj(name: 'Ex. Tributário3', debt: 785898.88)
];

class ExampleFilial {
  late String companyName;
  late String registrationStatus;

  ExampleFilial({required this.companyName, required this.registrationStatus});

  Map<String, dynamic> toJson() =>
      {'name': companyName, 'status': registrationStatus};
}

List<ExampleFilial> examplesFilial = [
  ExampleFilial(companyName: 'Sarko Digital', registrationStatus: 'ATIVA'),
  ExampleFilial(companyName: '4YOU', registrationStatus: 'ATIVA'),
  ExampleFilial(companyName: 'NoAr', registrationStatus: 'DESATIVADA'),
];
