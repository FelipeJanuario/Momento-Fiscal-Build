import 'dart:convert';

import 'package:momentofiscal/core/utilities/api_constants.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';
import 'package:http/http.dart' as http;

class UserInstitutionRailsService {
  Future getUserInsitution({required String institutionId}) async {
    var url =
        "${ApiConstants.baseUrl}/user_institutions??query%5Binstitution_id%5D=$institutionId";

    String? token = await storage.read(key: 'token');

    var headers = {
      'Authorization': 'Bearer $token',
    };

    var response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);

      return responseBody['data'][0];
    } else {
      return null;
    }
  }
}
