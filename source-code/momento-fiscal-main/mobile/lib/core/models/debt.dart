class Debt {
  String? id;
  String? cpfCnpj;
  DateTime? createdAt;
  String? creditType;
  String? debtState;
  String? debtedName;
  String? debtedPersonType;
  String? debtedType;
  String? fgtsResponsibleEntity;
  String? fgtsUnitSubscription;
  String? judicialIndicator;
  String? mainRevenue;
  String? registrationDate;
  String? registrationNumber;
  String? registrationStatus;
  String? registrationStatusType;
  String? responsibleUnit;
  DateTime? updatedAt;
  String? value;
  String? isFgts;
  String? isPrevidenciary;

  Debt({
    this.id,
    this.cpfCnpj,
    this.createdAt,
    this.creditType,
    this.debtState,
    this.debtedName,
    this.debtedPersonType,
    this.debtedType,
    this.fgtsResponsibleEntity,
    this.fgtsUnitSubscription,
    this.judicialIndicator,
    this.mainRevenue,
    this.registrationDate,
    this.registrationNumber,
    this.registrationStatus,
    this.registrationStatusType,
    this.responsibleUnit,
    this.updatedAt,
    this.value,
    this.isFgts,
    this.isPrevidenciary,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['_id'],
      cpfCnpj: json['cpf_cnpj'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      creditType: json['credit_type'],
      debtState: json['debt_state'],
      debtedName: json['debted_name'],
      debtedPersonType: json['debted_person_type'],
      debtedType: json['debted_type'],
      fgtsResponsibleEntity: json['fgts_responsible_entity'],
      fgtsUnitSubscription: json['fgts_unit_subscription'],
      judicialIndicator: json['judicial_indicator'],
      mainRevenue: json['main_revenue'],
      registrationDate: json['registration_date'],
      registrationNumber: json['registration_number'],
      registrationStatus: json['registration_status'],
      registrationStatusType: json['registration_status_type'],
      responsibleUnit: json['responsible_unit'],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      value: json['value'],
      isFgts: json['is_fgts'].toString(),
      isPrevidenciary: json['is_previdenciary'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'cpf_cnpj': cpfCnpj,
      'created_at': createdAt?.toIso8601String(),
      'credit_type': creditType,
      'debt_state': debtState,
      'debted_name': debtedName,
      'debted_person_type': debtedPersonType,
      'debted_type': debtedType,
      'fgts_responsible_entity': fgtsResponsibleEntity,
      'fgts_unit_subscription': fgtsUnitSubscription,
      'judicial_indicator': judicialIndicator,
      'main_revenue': mainRevenue,
      'registration_date': registrationDate,
      'registration_number': registrationNumber,
      'registration_status': registrationStatus,
      'registration_status_type': registrationStatusType,
      'responsible_unit': responsibleUnit,
      'updated_at': updatedAt?.toIso8601String(),
      'value': value,
      'is_fgts': isFgts,
      'is_previdenciary': isPrevidenciary,
    };
  }
}
