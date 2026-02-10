class Institution {
  late String id;
  late String responsibleName;
  late String cnpj;
  late String responsibleCpf;
  late String email;
  late String phone;
  late String cellPhone;
  late double limitDebt;

  Institution({
    required this.id,
    required this.responsibleName,
    required this.cnpj,
    required this.responsibleCpf,
    required this.email,
    required this.phone,
    required this.cellPhone,
    required this.limitDebt,
  });

  Institution.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    responsibleName = json['responsible_name'];
    cnpj = json['cnpj'];
    responsibleCpf = json['responsible_cpf'];
    email = json['email'];
    phone = json['phone'];
    cellPhone = json['cell_phone'];
    limitDebt = double.parse(json['limit_debt']);
  }
}
