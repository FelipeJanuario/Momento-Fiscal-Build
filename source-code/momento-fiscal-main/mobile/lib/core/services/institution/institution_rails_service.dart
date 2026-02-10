import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:momentofiscal/core/models/institution.dart';
import 'package:momentofiscal/core/utilities/api_constants.dart';
import 'package:momentofiscal/core/utilities/validations.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';

class InstitutionRailsService {
  Future createInstitution({
    required String responsibleName,
    required String email,
    required String cnpj,
    required String responsibleCpf,
    required String phone,
    required String cellPhone,
    required double limitDebt,
    required String userPassword,
    required String userPasswordConfirmation,
  }) async {
    Map params = {
      "responsible_name": responsibleName,
      "email": email,
      "cnpj": cnpj,
      "responsible_cpf": removeMask(responsibleCpf),
      "phone": phone,
      "cell_phone": cellPhone,
      "limit_debt": limitDebt,
      "user": {
        "name": responsibleName,
        "cpf": removeMask(responsibleCpf),
        "phone": phone,
        "email": email,
        "birth_date": "2000-01-03",
        "sex": 0,
        "password": userPassword,
        "password_confirmation": userPasswordConfirmation,
      }
    };

    var url = '${ApiConstants.baseUrl}/institutions.json';
    var body = json.encode(params);

    var headers = {
      'Content-Type': 'application/json',
    };

    var response =
        await http.post(Uri.parse(url), body: body, headers: headers);

    return response;
  }

  Future getInstitution({required String cnpj}) async {
    var url = '${ApiConstants.baseUrl}/institutions?query%5Bcnpj%5D=$cnpj';

    String? token = await storage.read(key: 'token');

    var headers = {
      'Authorization': 'Bearer $token',
    };

    var response = await http.get(Uri.parse(url), headers: headers);

    Institution institution;
    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);

      if (responseBody['data'].isNotEmpty) {
        institution = Institution.fromJson(responseBody['data']?[0]);

        return institution;
      } else {
        return null;
      }
    } else {
      throw Exception('Failed to load institutions');
    }
  }

  Future<List<Institution>> getAllInstitution({
    int page = 1,
    int perPage = 10,
    String responsibleCpf = '',
    String cnpj = '',
  }) async {
    var url =
        '${ApiConstants.baseUrl}/institutions?page=$page&per_page=$perPage&query%5Bresponsible_cpf%5D=$responsibleCpf&query%5Bcnpj%5D=$cnpj';

    String? token = await storage.read(key: 'token');

    var headers = {
      'Authorization': 'Bearer $token',
    };

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);

      List<Institution> institutions = [];
      for (var institution in responseBody['data']) {
        institutions.add(Institution.fromJson(institution));
      }
      return institutions;
    } else {
      throw Exception('Failed to load institutions');
    }
  }

  Future putInstitution({
    required String id,
    required String responsibleName,
    required String email,
    required String cnpj,
    required String responsibleCpf,
    required String phone,
    required String cellPhone,
    required double limitDebt,
  }) async {
    Map params = {
      "responsible_name": responsibleName,
      "email": email,
      "cnpj": cnpj,
      "responsible_cpf": responsibleCpf,
      "phone": phone,
      "cell_phone": cellPhone,
      "limit_debt": limitDebt
    };

    String? token = await storage.read(key: 'token');

    var url = '${ApiConstants.baseUrl}/institutions/$id';
    var body = json.encode(params);

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    var response =
        await http.patch(Uri.parse(url), body: body, headers: headers);

    return response;
  }

  Future deleteInstitution(String id) async {
    var url = "${ApiConstants.baseUrl}/institutions/$id";

    String? token = await storage.read(key: 'token');

    var headers = {
      'Authorization': 'Bearer $token',
    };

    var response = await http.delete(Uri.parse(url), headers: headers);
    if (response.statusCode == 204) {
      return true;
    } else {
      return false;
    }
  }
}
