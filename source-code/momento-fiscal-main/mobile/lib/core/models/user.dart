class User {
  late String id;
  late String name;
  late String cpf;
  late String email;
  late String phone;
  late String sex;
  late String birthDate;
  late String role;
  late String oabSubscription;
  late String oabState;
  late String idStripe;
  late String? iosPlan;
  late String token;
  late String? updateAt;
  late String? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.cpf,
    required this.phone,
    required this.sex,
    required this.birthDate,
    required this.role,
    required this.oabSubscription,
    required this.oabState,
    required this.idStripe,
    required this.iosPlan,
    required this.updateAt,
    required this.token,
    required this.createdAt,
  });

  User.fromJson(Map<String, dynamic> json) {
    id = json["id"]?.toString() ?? '';
    name = json["name"]?.toString() ?? '';
    email = json['email']?.toString() ?? '';
    cpf = json['cpf']?.toString() ?? '';
    phone = json['phone']?.toString() ?? '';
    sex = json['sex']?.toString() ?? '';
    birthDate = json['birth_date']?.toString() ?? '';
    role = json['role']?.toString() ?? '';
    oabSubscription = json['oab_subscription']?.toString() ?? '';
    oabState = json['oab_state']?.toString() ?? '';
    idStripe = json['stripe_customer_id']?.toString() ?? '';
    iosPlan = json['ios_plan']?.toString();
    updateAt = json['updated_at']?.toString();
    createdAt = json['created_at']?.toString();
    token = json['token']?.toString() ?? '';
  }
}
