class Company {
  String? id;
  double? debtsValue;
  int? debtsCount;
  DateTime? activityStartDate;
  Address? address;
  String? baseCnpj;
  bool? branch;
  String? cadastralStatus;
  DateTime? cadastralStatusDate;
  String? cadastralStatusReason;
  String? cityName;
  String? cnpj;
  int? companySizeCd;
  String? corporateName;
  String? country;
  String? dvCnpj;
  String? email;
  String? fantasyName;
  String? foreignCityName;
  int? itemsAttachmentsCount;
  String? juridicalNature;
  String? mainCnae;
  bool? matrix;
  String? mei;
  DateTime? meiDate;
  DateTime? meiExclusionDate;
  String? municipalityCode;
  String? name;
  String? orderCnpj;
  List<Phone>? phones;
  String? qualification;
  String? responsibleFederalEntity;
  int? resultsCount;
  String? secondaryCnae;
  String? simple;
  DateTime? simpleDate;
  DateTime? simpleExclusionDate;
  String? socialCapital;
  String? specialSituation;
  DateTime? specialSituationDate;
  String? specialStatus;
  DateTime? specialStatusDate;
  String? uf;
  DateTime? updatedAt;
  // Coordenadas diretas (do endpoint nearby_cep)
  double? latitude;
  double? longitude;

  Company({
    this.id,
    this.debtsValue,
    this.debtsCount,
    this.activityStartDate,
    this.address,
    this.baseCnpj,
    this.branch,
    this.cadastralStatus,
    this.cadastralStatusDate,
    this.cadastralStatusReason,
    this.cityName,
    this.cnpj,
    this.companySizeCd,
    this.corporateName,
    this.country,
    this.dvCnpj,
    this.email,
    this.fantasyName,
    this.foreignCityName,
    this.itemsAttachmentsCount,
    this.juridicalNature,
    this.mainCnae,
    this.matrix,
    this.mei,
    this.meiDate,
    this.meiExclusionDate,
    this.municipalityCode,
    this.name,
    this.orderCnpj,
    this.phones,
    this.qualification,
    this.responsibleFederalEntity,
    this.resultsCount,
    this.secondaryCnae,
    this.simple,
    this.simpleDate,
    this.simpleExclusionDate,
    this.socialCapital,
    this.specialSituation,
    this.specialSituationDate,
    this.specialStatus,
    this.specialStatusDate,
    this.uf,
    this.updatedAt,
    this.latitude,
    this.longitude,
  });

  Company.fromJson(Map<String, dynamic> json) {
    id = json['_id'] ?? json['id']?.toString();
    activityStartDate = json['activity_start_date'] != null
        ? DateTime.parse(json['activity_start_date'])
        : null;
    address =
        json['address'] != null ? Address.fromJson(json['address']) : null;
    baseCnpj = json['base_cnpj'];
    branch = json['branch'];
    cadastralStatus = json['cadastral_status']?.toString();
    cadastralStatusDate = json['cadastral_status_date'] != null
        ? DateTime.parse(json['cadastral_status_date'])
        : null;
    cadastralStatusReason = json['cadastral_status_reason'];
    cityName = json['city_name'];
    cnpj = json['cnpj'];
    companySizeCd = json['company_size_cd'];
    corporateName = json['corporate_name'];
    country = json['country'];
    dvCnpj = json['dv_cnpj'];
    debtsValue = _parseDouble(json['debts_value']);
    debtsCount = json['debts_count'];
    email = json['email'];
    fantasyName = json['fantasy_name'];
    foreignCityName = json['foreign_city_name'];
    itemsAttachmentsCount = json['items_attachments_count'];
    juridicalNature = json['juridical_nature'];
    mainCnae = json['main_cnae'];
    matrix = json['matrix'];
    mei = json['mei'];
    meiDate =
        json['mei_date'] != null ? DateTime.parse(json['mei_date']) : null;
    meiExclusionDate = json['mei_exclusion_date'] != null
        ? DateTime.parse(json['mei_exclusion_date'])
        : null;
    municipalityCode = json['municipality_code'];
    name = json['name'];
    orderCnpj = json['order_cnpj'];
    phones = json['phones'] != null
        ? (json['phones'] as List).map((i) => Phone.fromJson(i)).toList()
        : null;
    qualification = json['qualification'];
    responsibleFederalEntity = json['responsible_federal_entity'];
    resultsCount = json['results_count'];
    secondaryCnae = json['secondary_cnae'];
    simple = json['simple'];
    simpleDate = json['simple_date'] != null
        ? DateTime.parse(json['simple_date'])
        : null;
    simpleExclusionDate = json['simple_exclusion_date'] != null
        ? DateTime.parse(json['simple_exclusion_date'])
        : null;
    socialCapital = json['social_capital'];
    specialSituation = json['special_situation'];
    specialSituationDate = json['special_situation_date'] != null
        ? DateTime.parse(json['special_situation_date'])
        : null;
    specialStatus = json['special_status'];
    specialStatusDate = json['special_status_date'] != null
        ? DateTime.parse(json['special_status_date'])
        : null;
    uf = json['uf'];
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
    // Coordenadas diretas - podem vir como String ou double
    latitude = _parseDouble(json['latitude']);
    longitude = _parseDouble(json['longitude']);
  }

  /// Helper para converter valor para double (suporta String, int, double)
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class Address {
  String? id;
  String? city;
  String? complement;
  String? country;
  String? countryCode;
  String? createdAt;
  GeographicCoordinate? geographicCoordinate;
  String? municipalityCode;
  String? neighborhood;
  String? number;
  String? place;
  String? placeType;
  String? state;
  String? street;
  String? updatedAt;
  String? zipCode;

  Address({
    this.id,
    this.city,
    this.complement,
    this.country,
    this.countryCode,
    this.createdAt,
    this.geographicCoordinate,
    this.municipalityCode,
    this.neighborhood,
    this.number,
    this.place,
    this.placeType,
    this.state,
    this.street,
    this.updatedAt,
    this.zipCode,
  });

  Address.fromJson(Map<String, dynamic> json) {
    id = json['_id'] ?? json['id']?.toString();
    city = json['city']?.toString();
    complement = json['complement'];
    country = json['country'];
    countryCode = json['country_code'];
    createdAt = json['created_at'];
    geographicCoordinate = json['geographic_coordinate'] != null
        ? GeographicCoordinate.fromJson(json['geographic_coordinate'])
        : null;
    municipalityCode = json['municipality_code'];
    neighborhood = json['neighborhood'];
    number = json['number'];
    place = json['place'];
    placeType = json['place_type'];
    state = json['state'];
    street = json['street'];
    updatedAt = json['updated_at'];
    zipCode = json['zip_code'];
  }
}

class GeographicCoordinate {
  String? id;
  List<double>? coordinates;
  DateTime? createdAt;
  String? type;
  DateTime? updatedAt;

  GeographicCoordinate({
    this.id,
    this.coordinates,
    this.createdAt,
    this.type,
    this.updatedAt,
  });

  GeographicCoordinate.fromJson(Map<String, dynamic> json) {
    id = json['_id'] ?? json['id']?.toString();
    coordinates = json['coordinates'] != null
        ? (json['coordinates'] as List).map((e) => (e is int) ? e.toDouble() : (e as num).toDouble()).toList()
        : null;
    createdAt =
        json['created_at'] != null ? DateTime.parse(json['created_at']) : null;
    type = json['type'];
    updatedAt =
        json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null;
  }
}

class Phone {
  String? id;
  String? areaCode;
  String? countryCode;
  bool? fax;
  String? number;

  Phone({
    this.id,
    this.areaCode,
    this.countryCode,
    this.fax,
    this.number,
  });

  Phone.fromJson(Map<String, dynamic> json) {
    id = json['_id'];
    areaCode = json['area_code'];
    countryCode = json['country_code'];
    fax = json['fax'];
    number = json['number'];
  }
}
